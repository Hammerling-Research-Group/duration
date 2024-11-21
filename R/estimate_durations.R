#' @title Estimate emission durations using CMS, accounting for CMS non-detect times
#' 
#' @usage estimate_durations(data, directory, events, plot, time)
#' @param data List. Forward model output data. The format must match that of the sample (default) shortened data from the 2023 ADED controlled release experiment, which is released with the \code{duration} package.
#' @param tz Character. Time zone. Default set to \code{America/Denver}.
#' @param directory Character. Location where results output is saved. If not specified, a directory is created and the location is shared with the user.
#' @param events Logical. Print the number of events per year? Default set to \code{FALSE}.
#' @param plot Logical. Return a plot of the distribution of average duration estimates by source? Default set to \code{FALSE}.
#' @param time Logical. Return the timing of the simulation. Default set to \code{TRUE}.
#' @return Listed output of estimated durations by emission source. Saved in a newly created directory (\code{Results Output}).
#' 
#' @author William Daniels, Philip Waggoner, Dorit Hammerling
#' 
#' @export
#' @examples
#' estimate_durations(directory = "Desktop", plot = TRUE)
estimate_durations <- function(data = system.file("input_data/ADED2023_short.rds", package = "duration"),
                               tz = "America/Denver",
                               directory = NULL,
                               events = FALSE, 
                               plot = FALSE,
                               time = TRUE){
  
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

  timer <- system.time(
    {
      
  cli::cli_h1("Reading & cleaning data")

  data <- suppressWarnings(readr::read_rds(data))

  # check if input data is a list; throw error if it's not
  if (!is.list(data)) {
    stop("The input data must be a list. Please provide a list object containing the required data.")
  }
  
  required <- c("times", "obs", "WD", "WS")
  missing <- setdiff(required, names(data))
  
  if (length(missing) > 0) {
    stop(paste("The input data list is missing the following required elements:", paste(missing, collapse = ", ")))
  }
  
  obs <- zoo::na.approx(data$obs, na.rm = F)
  n.r <- ncol(obs)
  times <- data$times
  sims <- data[5:length(data)]
  n.s <- length(sims) 
  source_names <- names(sims)

# STEP 2: REMOVE BACKGROUND FROM CMS OBSERVATIONS

  obs <- remove.background(times, obs,
                           going.up.threshold = 0.25, 
                           amp.threshold = 0.75, 
                           gap.time = 30)

  cli::cli_alert_success("Complete")

  cli::cli_h1("Identifying naive events & creating localization + quantification estimates for each")

# STEP 3: IDENTIFY NAIVE EVENTS

  # minute-by-minute max value time series across all CMS sensors
  max.obs <- apply(obs, 1, max, na.rm = T)

  # identify spikes/"naive events"
  spikes <- perform.event.detection(times, max.obs, gap.time = 30, length.threshold = 15)
  event.nums <- na.omit(unique(spikes$events))
  n.ints <- length(event.nums)

# STEP 4: CREATE LOCALIZATION AND QUANTIFICATION ESTIMATES FOR EACH NAIVE EVENT

  # estimate source location for each naive event
  loc_est_all_events <- perform.localization(spikes, obs, sims)

  # estimate emission rate for each naive event
  all.q.vals <- perform.quantification(times, spikes, obs, sims, loc_est_all_events)
  rate_est_all_events <- sapply(all.q.vals, mean, na.rm = T)
  error.lower.all.events <- sapply(all.q.vals, function(X) quantile(X, probs = 0.05, na.rm = T))
  error.upper.all.events <- sapply(all.q.vals, function(X) quantile(X, probs = 0.95, na.rm = T))

# STEP 5: CREATE INFORMATION MASK

  # scale sims by the estimated emission rate for each naive event
  sims <- scale.sims(times, sims, spikes, loc_est_all_events, rate_est_all_events)

  # create information mask based on simulated concentrations
  info.list <- create.info.mask(times, sims, gap.time = 0, length.threshold = 15)

  cli::cli_alert_success("Complete")

  cli::cli_h1("Estimating durations")

# STEP 6: ESTIMATE DURATIONS

  # estimate durations
  out <- get.durations(spikes = spikes, 
                       info.list = info.list, 
                       loc_est_all_events, 
                       rate_est_all_events, 
                       tz = tz)

  # distribution of possible durations for each naive event
  all_durations <- out$all.durations

  # equipment-level duration distributions
  est_durations <- out$est.durations

  # start & end times of naive events
  event.starts <- out$event.starts
  event.ends <- out$event.ends

  # earliest & latest possible start time for each naive event
  start.bounds <- out$start.bounds
  end.bounds <- out$end.bounds
  start.similarity.scores <- out$start.similarity.scores
  end.similarity.scores <- out$end.similarity.scores

  # naive event durations
  original_durations <- as.numeric(difftime(event.ends, event.starts, units = "hours"))

  est_durations <- vector(mode = "list", length = n.s)
  names(est_durations) <- source_names

  for (i in 1:length(all_durations)){
    list.ind <- which(names(all_durations)[i] == source_names)
    est_durations[[list.ind]] <- c(est_durations[[list.ind]], mean(all_durations[[i]]))
  }

  est.average.durations <- sapply(est_durations, mean)
  est.min.interval <- sapply(est_durations, function(X) quantile(X, probs = 0.05))
  est.max.interval <- sapply(est_durations, function(X) quantile(X, probs = 0.95))

  cli::cli_alert_success("Complete")

  cli::cli_h1("Estimating frequencies")

# STEP 7: ESTIMATE FREQUENCIES

# distribution of possible event counts for each equipment group
  event.counts <- get.event.counts(spikes = spikes, 
                                   info.list = info.list,
                                   loc_est_all_events, 
                                   rate_est_all_events, 
                                   tz = tz)

  total.time <- as.numeric(difftime(range(times)[2], range(times)[1], 
                                    units = "days"))

  num.events.per.year <- 365 * event.counts / total.time

  freq.mean <- apply(num.events.per.year, 2, mean)
  freq.int <- apply(num.events.per.year, 2, function(X) quantile(X, probs = c(0.05, 0.95)))
  frequency.results <- rbind(freq.mean, freq.int[1,], freq.int[2,])

  if(events == TRUE){
    print(t(round(frequency.results, 0)))
  }

  cli::cli_alert_success("Complete")

  cli::cli_h1("Writing out results to working directory")

# STEP 8: WRITE OUT KEY RESULTS & RETURN TIME

  duration_estimates <- list(
    all_durations = all_durations,
    est_durations = est_durations,
    original_durations = original_durations,
    rate_est_all_events = rate_est_all_events,
    loc_est_all_events = loc_est_all_events,
    source_names = source_names
    )

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

  cli::cli_alert_success("Complete")
  
    }
  )
  
  final_time <- timer[3]
  
  if(time == TRUE){
    cli::cli_h1("Timing")
    
    cli::cli_alert_info(c(
      "The process took ",
      "{prettyunits::pretty_sec(final_time)} ",
      "to run"))
  }

  cli::cli_div(theme = list(span.emph = list(color = "blue")))
  cli::cli_alert(c(
    "Results saved at: ",
    "{output_path}"))
  cli::cli_end()

# STEP 9: (OPTIONAL) PLOT DISTRIBUTION OF AVG DURATION EST BY SOURCE (HIST OR DENS OPTS)

  if(plot == TRUE){
    plot_durations(est_durations)
    }

}
