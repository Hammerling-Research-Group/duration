# duration
*Production code CMS duration estimation*

[![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/duration)](http://cran.r-project.org/package=duration)
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

## Estimating Methane Emission Durations

This repository contains code used to estimate methane emission durations using concentration observations from a network of point-in-space continuous monitoring systems. The scripts include: 

  - `estimate_durations.R`: main code for estimating durations
  - `helpers.R`: suite of helper functions sourced internally in `estimate_durations()`

The accompanying paper can be found here: https://doi.org/10.1021/acs.estlett.4c00687

*Note: The code includes a shortened "toy" set of data from the 2023 ADED controlled release experiment. This is meant for demonstration purposes only to get users started with the code and to learn the required structure of input data.*

## Installation & Usage

Access the latest (dev) version:

```r
#install.packages("devtools") # if needed on first usage

devtools::install_github("Hammerling-Research-Group/duration")

library(duration)
```

Once installed and loaded, users should start with the core function, which produces duration estimates by emission source. 

For example, run the following line to generate emission duration estimates, return a plot of the distributions of duration estimates by source using the supplied "toy" data, and store results on your Desktop (*note: full output is saved by default, the location of which is shared with the user*): 

```r
estimate_durations(plot = TRUE, directory = "Desktop")
```

## Some Notes to Consider

The default values are meant to allow for simple usage without the need for adjustment. Yet, given that toy data are used as input by default, at a minimum users should adjust the `data` by supplying real site data.

Available arguments for `estimate_durations()` include:

  - `data`: Forward model output data stored as a list object. The format must match that of the sample input data in the `duration` package, or output data from other similar implementations, e.g., from `MAIN_1_simulate.R` in <https://github.com/wsdaniels/DLQ/> (*more details on data structure are in the following section*)
  - `tz`: Time zone. Default set to `America/Denver`
  - `directory`: Location where results output is saved. If not specified, a directory is created and the location is shared with the user
  - `events`: Print the number of events per year? Default set to `FALSE`
  - `plot`: Return a plot of the distribution of average duration estimates by source? Default set to `FALSE`
  - `time`: Return the timing of the simulation? Default set to `TRUE`

## Input Data Structure

A key piece of working reliably with the `duration` package is the *structure of the input data*, which is very specific. To get a sense of what is required, users can read in and explore the provided sample data to learn about the structure, which must be contained in a list object. Each of the following basic options should be sufficient to allow users to structure their input data accordingly in order for the code to work as intended, and for the results to be reliable. 

  1. Read in the data:

```r
> df <- list.files(system.file("input_data", package = "duration"), full.names = TRUE)
> data <- readr::read_rds(df[1])
```

  2. Once read in, users can explore the data directly:

```r
> head(data)
```

  3. Check out which objects are stored in the list for reference:

```r
> names(data)

[1] "times"   "obs"   "WD"    "WS"    "Tank"    "Separator.East"    "Wellhead.East"   "Wellhead.West"   "Separator.West"
```

  4. Or, inspect the structure of the input data directly:

```r
> str(data)

List of 9
 $ times         : POSIXct[1:4001], format: "2023-02-21 21:19:00" "2023-02-21 21:20:00" "2023-02-21 21:21:00" "2023-02-21 21:22:00" ...
 $ obs           :'data.frame':	4001 obs. of  10 variables:
  ..$ ENE: num [1:4001] 2.02 2.04 2.03 2.06 2.01 ...
  ..$ ESE: num [1:4001] 2.25 2.25 NA 2.24 2.24 ...
 $ WD            : num [1:4001] 1.98 1.98 2.02 2.04 1.93 ...
 $ WS            : num [1:4001] 3.41 3.52 3.25 2.71 2.72 2.94 3.08 2.81 3.16 3.07 ...
 $ Tank          :'data.frame':	4001 obs. of  10 variables:
  ..$ ENE: num [1:4001] 1.86e-49 3.11e-49 2.44e-49 1.32e-50 2.62e-85 ...
  ..$ ESE: num [1:4001] 1.81e-59 2.50e-59 2.12e-59 1.61e-60 9.60e-104 ...
 $ Separator.East:'data.frame':	4001 obs. of  10 variables:
  ..$ ENE: num [1:4001] 6.41e-43 8.05e-43 6.14e-43 2.61e-43 1.04e-75 ...
  ..$ ESE: num [1:4001] 1.35e-55 1.42e-55 1.87e-55 1.77e-55 6.67e-98 ...
 $ Wellhead.East :'data.frame':	4001 obs. of  10 variables:
  ..$ ENE: num [1:4001] 4.00e-24 5.48e-24 1.71e-24 9.56e-26 1.83e-40 ...
  ..$ ESE: num [1:4001] 1.26e-37 1.66e-37 1.07e-37 3.09e-38 3.09e-66 ...
 $ Wellhead.West :'data.frame':	4001 obs. of  10 variables:
  ..$ ENE: num [1:4001] 7.44e-90 1.47e-89 8.16e-90 5.46e-91 1.21e-151 ...
  ..$ ESE: num [1:4001] 1.95e-104 3.68e-104 2.18e-104 3.86e-105 1.78e-177 ...
 $ Separator.West:'data.frame':	4001 obs. of  10 variables:
  ..$ ENE: num [1:4001] 2.79e-60 1.03e-59 9.98e-60 5.54e-62 2.39e-101 ...
  ..$ ESE: num [1:4001] 6.40e-69 2.46e-68 2.46e-68 1.97e-70 5.61e-117 ...
```

*Note:* The sources (tank, separators, wellheads, etc.) will vary based on site-level details unique to users' contexts. But at a minimum, users can see that times (vector), sensor observations (data frame), wind data (vectors: direction/`WD` and speed/`WS`), and at least one source (data frame) are required to be in the list. 
