library(testthat)
library(lubridate)
library(devtools)

devtools::load_all()

##
## SIM DATA (mirroring toy set from duration code)
##

times <- seq(ymd_hms("2023-02-21 21:19:00"), by = "min", length.out = 4001)

set.seed(123)

obs <- data.frame(
  ENE = runif(4001, 2.0, 2.1),
  ESE = runif(4001, 2.2, 2.3),
  N = runif(4001, 1.7, 1.8),
  NE = runif(4001, 2.2, 2.3),
  NW = runif(4001, 2.0, 2.1),
  S = runif(4001, 1.7, 1.8),
  SE = runif(4001, 1.8, 1.9),
  SW = runif(4001, 2.5, 2.6),
  WNW = runif(4001, 2.0, 2.5),
  WSW = runif(4001, 2.0, 2.5)
)

WD <- runif(4001, 1.9, 2.1)
WS <- runif(4001, 2.5, 3.5)

create_sim_df <- function() {
  data.frame(
    ENE = rexp(4001, rate = 1e50),
    ESE = rexp(4001, rate = 1e50),
    N = rexp(4001, rate = 1e50),
    NE = rexp(4001, rate = 1e50),
    NW = rexp(4001, rate = 1e50),
    S = rexp(4001, rate = 1e50),
    SE = rexp(4001, rate = 1e50),
    SW = rexp(4001, rate = 1e50),
    WNW = rexp(4001, rate = 1e50),
    WSW = rexp(4001, rate = 1e50)
  )
}

Tank <- create_sim_df()
Separator_East <- create_sim_df()
Wellhead_East <- create_sim_df()
Wellhead_West <- create_sim_df()
Separator_West <- create_sim_df()

data <- list(
  times = times,
  obs = obs,
  WD = WD,
  WS = WS,
  Tank = Tank,
  Separator.East = Separator_East,
  Wellhead.East = Wellhead_East,
  Wellhead.West = Wellhead_West,
  Separator.West = Separator_West
)

##
## TESTS
##

# Test input data is validated
test_that("Input data is validated correctly", {
  incomplete_data <- data
  incomplete_data$obs <- NULL

  expect_error(
    estimate_durations(data = incomplete_data),
    "The input data list is missing the following required elements"
  )
})

test_that("Input data is validated correctly", {
  expect_type(data, "list")
})

# Test remove.background behavior
test_that("Background removal works as expected", {
  obs <- zoo::na.approx(data$obs, na.rm = FALSE)
  times <- data$times

  cleaned_obs <- remove.background(
    times = times,
    obs = obs,
    going.up.threshold = 0.25,
    amp.threshold = 0.75,
    gap.time = 30
  )

  expect_true(any(!is.na(cleaned_obs)))
  expect_false(all(is.na(cleaned_obs)))
})

# Test for spike detection
test_that("Inputs to perform.event.detection are valid", {
  obs <- zoo::na.approx(data$obs, na.rm = FALSE)
  times <- data$times
  max_obs <- apply(obs, 1, max, na.rm = TRUE)

  expect_true(all(!is.na(max_obs)))
  expect_equal(length(times), length(max_obs))
})


test_that("Spike detection identifies naive events", {
  obs <- zoo::na.approx(data$obs, na.rm = FALSE)
  times <- data$times
  max_obs <- apply(obs, 1, max, na.rm = TRUE)

  # Ensure inputs are valid
  expect_equal(length(times), length(max_obs))
  expect_true(all(!is.na(max_obs)))

  spikes <- perform.event.detection(
    times = times,
    max.obs = max_obs,
    gap.time = 30,
    length.threshold = 15
  )

  expect_type(spikes, "list")
  expect_true("events" %in% names(spikes))
  expect_true(any(!is.na(spikes$events)))
})



# Test for localization estimates
test_that("Localization estimates are computed correctly", {
  obs <- zoo::na.approx(data$obs, na.rm = FALSE)
  times <- data$times
  sims <- data[5:length(data)]
  max_obs <- apply(obs, 1, max, na.rm = TRUE)
  
  spikes <- perform.event.detection(
    times = times,
    max.obs = max_obs,
    gap.time = 30,
    length.threshold = 15
  )

  loc_est_all_events <- perform.localization(
    spikes = spikes,
    obs = obs,
    sims = sims
  )

  expect_true(length(loc_est_all_events) > 0)
})

# Test for quantification estimates
test_that("Quantification estimates are computed correctly", {
  obs <- zoo::na.approx(data$obs, na.rm = FALSE)
  times <- data$times
  sims <- data[5:length(data)]
  max_obs <- apply(obs, 1, max, na.rm = TRUE)
  
  spikes <- perform.event.detection(
    times = times,
    max.obs = max_obs,
    gap.time = 30,
    length.threshold = 15
  )
  
  loc_est_all_events <- perform.localization(
    spikes = spikes,
    obs = obs,
    sims = sims
  )

  all_q_vals <- perform.quantification(
    times = times,
    spikes = spikes,
    obs = obs,
    sims = sims,
    loc.est.all.events = loc_est_all_events
  )

  expect_type(all_q_vals, "list")
  expect_true(length(all_q_vals) > 0)
})

# Test for duration estimation
test_that("Durations are estimated correctly", {
  obs <- zoo::na.approx(data$obs, na.rm = FALSE)
  times <- data$times
  sims <- data[5:length(data)]
  max_obs <- apply(obs, 1, max, na.rm = TRUE)
  info.list <- create.info.mask(times, sims, gap.time = 0, length.threshold = 15)
  
  spikes <- perform.event.detection(
    times = times,
    max.obs = max_obs,
    gap.time = 30,
    length.threshold = 15
  )
  
  loc_est_all_events <- perform.localization(
    spikes = spikes,
    obs = obs,
    sims = sims
  )
  
  all_q_vals <- perform.quantification(
    times = times,
    spikes = spikes,
    obs = obs,
    sims = sims,
    loc.est.all.events = loc_est_all_events
  )

  out <- get.durations(
    spikes = spikes,
    info.list = info.list,
    loc.est.all.events = loc_est_all_events,
    rate.est.all.events = sapply(all_q_vals, mean, na.rm = TRUE),
    tz = "America/Denver"
  )

  expect_type(out, "list")
  expect_true("all.durations" %in% names(out))
  expect_true(length(out$all.durations) > 0)
})

