# duration
*Production code CMS duration estimation*

## Estimating Methane Emission Durations

This repository contains code used to estimate methane emission durations using concentration observations from a network of point-in-space continuous monitoring systems. The main scripts are: 

  - `estimate_durations.R`: main code for estimating durations
  - `helpers.R`: suite of helper functions sourced internally in `estimate_durations()`

The accompanying paper can be found here: https://doi.org/10.1021/acs.estlett.4c00687

**Of note:** *The code includes a shortened "toy" set of data from the 2023 ADED controlled release experiment. This is meant for demonstration purposes only to get users started with the code and to learn the required structure of input data.*

## Installation & Usage

Access the latest (dev) version of this code:

```r
devtools::install_github("Hammerling-Research-Group/duration")

library(duration)
```

Now, you are free to use the latest version of the code, e.g., 

```r
estimate_durations(plot = TRUE)
```

## Some Notes to Consider

The default values for all arguments are set to allow for simple usage without the need for adjustment. Yet, users could (should) at least adjust the `data`, by supplying real data, instead of the toy data packaged with the `duration` code, meant only for demo purposes. With that, the other arguments include: 

  - `data`: Forward model output data. Format must match output from `MAIN_1_simulate.R` at: <https://github.com/wsdaniels/DLQ/>
  - `directory`: Location where results output is saved. If not specified, a directory is created and the location is shared with the user
  - `events`: Print the number of events per year? Default set to `FALSE`
  - `plot`: Return a plot of the distribution of average duration estimates by source? Default set to `FALSE`
  - `time`: Return the timing of the simulation? Default set to `TRUE`
