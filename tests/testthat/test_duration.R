library(testthat)
devtools::load_all()


# Load toy data packaged with the duration code
df <- list.files(system.file("input_data", package = "duration"), full.names = TRUE)
data <- readr::read_rds(df[1])

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
  expect_true(any(is.na(cleaned_obs)))
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
