# duration
*Production code CMS duration estimation*

[![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/duration)](http://cran.r-project.org/package=duration)
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

## Estimating Methane Emission Durations

This repository contains code used to estimate methane emission durations using concentration observations from a network of point-in-space continuous monitoring systems. The scripts include: 

  - `estimate_durations.R`: main code for estimating durations
  - `helpers.R`: suite of helper functions sourced internally in `estimate_durations()`

The accompanying paper can be found here: https://doi.org/10.1021/acs.estlett.4c00687

*Of note: The code includes a shortened "toy" set of data from the 2023 ADED controlled release experiment. This is meant for demonstration purposes only to get users started with the code and to learn the required structure of input data.*

## Installation & Usage

Access the latest (dev) version:

```r
devtools::install_github("Hammerling-Research-Group/duration")

library(duration)
```

Once installed and loaded, users should start with the core function, which produces duration estimates by emission source. 

For example, run the following line to generate emission duration estimates, return a plot of the distributions of duration estimates by source using the supplied "toy" data, and store results on your Desktop (*of note: full output is saved by default, the location of which is shared with the user*): 

```r
estimate_durations(plot = TRUE, directory = "Desktop")
```

## Some Notes to Consider

The default values are meant to allow for simple usage without the need for adjustment. Yet, given that toy data are used as input by default, at a minimum users should adjust the `data` by supplying real site data.

Available arguments for `estimate_durations()` include:

  - `data`: Forward model output data stored as a list object. The format must match that of the sample input data in the `duration` package, or output data from other similar implementations, e.g., from `MAIN_1_simulate.R` in <https://github.com/wsdaniels/DLQ/>
  - `tz`: Time zone. Default set to `America/Denver`
  - `directory`: Location where results output is saved. If not specified, a directory is created and the location is shared with the user
  - `events`: Print the number of events per year? Default set to `FALSE`
  - `plot`: Return a plot of the distribution of average duration estimates by source? Default set to `FALSE`
  - `time`: Return the timing of the simulation? Default set to `TRUE`
