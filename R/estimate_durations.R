#' @title Estimate emission durations using CMS, accounting for CMS non-detect times
#' 
#' @usage estimate_durations(data, directory, events, plot, time)
#' @param data List. Forward model output data. Format must match output from MAIN_1_simulate.R, which can be found at: <https://github.com/wsdaniels/DLQ/>. Default set to shortened "toy" set from the 2023 ADED controlled release experiment (embedded in \code{duration} package).
#' @param directory Character. Location where results output is saved. If not specified, a directory is created and the location is shared with the user.
#' @param events Logical. Print the number of events per year? Default set to \code{FALSE}.
#' @param plot Logical. Return a plot of the distribution of average duration estimates by source? Default set to \code{FALSE}.
#' @param time Logical. Return the timing of the simulation. Default set to \code{TRUE}.
#' @return Listed output estimated durations by source. Saved in a newly created directory (\code{Results Output}).
#' 
#' @author William Daniels, Philip Waggoner, Dorit Hammerling
#' 
#' @export
#' @examples
#' estimate_durations(directory = "Desktop", plot = TRUE)
estimate_durations <- function(data = system.file("input_data/ADED2023_short.rds", package = "duration"),
                               directory = NULL,
                               events = FALSE, 
                               plot = FALSE,
                               time = TRUE){

  # Source helper files which contain functions that do most of the analysis
  #source("../code/helpers.R")
  
  suppressWarnings(
    suppressPackageStartupMessages(
      using_packages(
        "lubridate",
        "zoo",
        "scales",
        "prettyunits",
        "cli",
        "tools",
        "tidyverse")
    )
  )

# NOTE: using shortened version of ADED 2023 controlled release experiment as toy/sample set for user

  timer <- system.time(
    {
      
  cli::cli_h1("Reading & cleaning data")

# step 1: read in data
  #data <- read_rds(here("input_data", "ADED2023_forward_model_output_short.RData"))

  data <- suppressWarnings(read_rds(data))

# Pull out sensor observations and replace NA's that are not on edge of the time series with interpolated values
obs <- na.approx(data$obs, na.rm = F)

# Number of sensors
n.r <- ncol(obs)

# Pull out time stamps of observations and simulations
times <- data$times

# Pull out the simulation predictions
sims <- data[5:length(data)]

# Grab source info
n.s <- length(sims) 
source_names <- names(sims)


# STEP 2: REMOVE BACKGROUND FROM CMS OBSERVATIONS
#---------------------------------------------------------------------------

# Remove background from CMS observations
obs <- remove.background(times, obs,
                         going.up.threshold = 0.25, amp.threshold = 0.75, 
                         gap.time = 30)


cli::cli_alert_success("Complete")


cli::cli_h1("Identifying naive events & creating localization + quantification estimates for each")


# STEP 3: IDENTIFY NAIVE EVENTS
#---------------------------------------------------------------------------

# Create minute-by-minute maximum value time series across all CMS sensors
max.obs <- apply(obs, 1, max, na.rm = T)

# Identify spikes in the max.obs time series. These are the "naive events"
spikes <- perform.event.detection(times, max.obs, gap.time = 30, length.threshold = 15)

# Pull event "event numbers" that uniquely identify each naive event
event.nums <- na.omit(unique(spikes$events))

# Number of naive events
n.ints <- length(event.nums)



# STEP 4: CREATE LOCALIZATION AND QUANTIFICATION ESTIMATES FOR EACH NAIVE EVENT
#---------------------------------------------------------------------------

# Estimate source location for each naive event
loc_est_all_events <- perform.localization(spikes, obs, sims)

# Estimate emission rate for each naive event
all.q.vals <- perform.quantification(times, spikes, obs, sims, loc_est_all_events)

# Grab emission rate point estimate and 90% interval for each naive event from the MC output
rate_est_all_events <- sapply(all.q.vals, mean, na.rm = T)
error.lower.all.events <- sapply(all.q.vals, function(X) quantile(X, probs = 0.05, na.rm = T))
error.upper.all.events <- sapply(all.q.vals, function(X) quantile(X, probs = 0.95, na.rm = T))



# STEP 5: CREATE INFORMATION MASK
#---------------------------------------------------------------------------

# Scale simulations by the estimated emission rate for each naive event
sims <- scale.sims(times, sims, spikes, loc_est_all_events, rate_est_all_events)

# Create information mask based on simulated concentrations
info.list <- create.info.mask(times, sims, gap.time = 0, length.threshold = 15)


cli::cli_alert_success("Complete")


cli::cli_h1("Estimating durations")

# STEP 6: ESTIMATE DURATIONS
#---------------------------------------------------------------------------

# Estimate durations. "out" contains a number of different fields (see below).
out <- get.durations(spikes = spikes, 
                     info.list = info.list, 
                     loc_est_all_events, 
                     rate_est_all_events, 
                     tz = "America/New_York")

# Grab distribution of possible durations for each naive event
all_durations <- out$all.durations

# Grab equipment-level duration distributions
est_durations <- out$est.durations

# Grab start time of naive events
event.starts <- out$event.starts

# Grab end time of naive events
event.ends <- out$event.ends

# Grab earliest possible start time for each naive event. The "start bounds"
start.bounds <- out$start.bounds

# Grab latest possible end time for each naive event. The "end bounds"
end.bounds <- out$end.bounds

start.similarity.scores <- out$start.similarity.scores

end.similarity.scores <- out$end.similarity.scores

# Calculate naive event durations
original_durations <- as.numeric(difftime(event.ends, event.starts, units = "hours"))

# Initialize variables to hold duration estimates by equipment group
# Mean of distribution of possible durations is used here
est_durations <- vector(mode = "list", length = n.s)
names(est_durations) <- source_names

# Grab durations
for (i in 1:length(all_durations)){
  list.ind <- which(names(all_durations)[i] == source_names)
  est_durations[[list.ind]] <- c(est_durations[[list.ind]], mean(all_durations[[i]]))
}

# Get mean and 90% interval for each equipment group across all emission events
est.average.durations <- sapply(est_durations, mean)
est.min.interval <- sapply(est_durations, function(X) quantile(X, probs = 0.05))
est.max.interval <- sapply(est_durations, function(X) quantile(X, probs = 0.95))



cli::cli_alert_success("Complete")


cli::cli_h1("Estimating frequencies")


# STEP 7: ESTIMATE FREQUENCIES
#---------------------------------------------------------------------------

# Get distribution of possible event counts for each equipment group
event.counts <- get.event.counts(spikes = spikes, 
                                 info.list = info.list,
                                 loc_est_all_events, 
                                 rate_est_all_events, 
                                 tz = "America/Denver")

# Compute total time of experiment window
total.time <- as.numeric(difftime(range(times)[2], range(times)[1], 
                                  units = "days"))

# Scale event counts to annual-basis
num.events.per.year <- 365 * event.counts / total.time

# Get mean and 90% interval on emission frequencies for each equipment group
freq.mean <- apply(num.events.per.year, 2, mean)
freq.int <- apply(num.events.per.year, 2, function(X) quantile(X, probs = c(0.05, 0.95)))
frequency.results <- rbind(freq.mean, freq.int[1,], freq.int[2,])



if(events == TRUE){
  
  print(t(round(frequency.results, 0)))

  }

cli::cli_alert_success("Complete")



cli::cli_h1("Writing out results to working directory")

# STEP 8: WRITE OUT KEY RESULTS & RETURN TIME
#---------------------------------------------------------------------------

duration_estimates <- list(all_durations = all_durations,
     est_durations = est_durations,
     original_durations = original_durations,
     rate_est_all_events = rate_est_all_events,
     loc_est_all_events = loc_est_all_events,
     source_names = source_names)

# if no location specified by user, create new dir wherever user is currently working; save rds and let them know where output is saved

if (is.null(directory)) {
  output_dir <- file.path(path.expand("~"), "Results Output")
} else {
  output_dir <- file.path(path.expand("~"), directory, "Results Output")
}

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

output_path <- file.path(output_dir, "duration_estimates.rds")
readr::write_rds(duration_estimates, output_path)

    }
  )
  
  final_time <- timer[3]
  
  # return time if requested
  if(time == TRUE){
    cli::cli_h1("Timing")
    
    cli::cli_alert_info(c(
      "The simulation took ",
      "{prettyunits::pretty_sec(final_time)} ",
      "to run"))
  }

cli_div(theme = list(span.emph = list(color = "blue")))
cli_alert(c(
  "Results saved at: ",
  "{output_path}"))
cli_end()

# STEP 9: (OPTIONAL) PLOT DISTRIBUTION OF AVG DURATION EST BY SOURCE (HIST OR DENS OPTS)
#---------------------------------------------------------------------------

## sanity check plot: dist of average durations by source, where each plot is a histogram of durations for each source
#
# INPUT: duration_estimates$est_durations, which is average duration estimate for each naive event, grouped by emission source. E.g., in the sample data, there are five possible sources. The average value is just the average of the 100,000 samples from duration_estimates$all_durations.

if(plot == TRUE){
  
  plot_durations(est_durations)
  
  }

}
