# duration
*Production code CMS duration estimation*

## Estimating Methane Emission Durations

This repository contains code used to estimate methane emission durations using concentration observations from a network of point-in-space continuous monitoring systems. For now, in the active development stage, the main body of code is contained in the `MAIN_1_estimate_durations.R` script in `code`. The `MAIN_2_analyze_controlled_release_results.R` script makes all of the plots shown in the [manuscript](https://doi.org/10.1021/acs.estlett.4c00687) related to the *controlled release* evaluations. The `MAIN_3_analyze_case_study_results.R` script makes all of the plots for the accompanying [manuscript](https://doi.org/10.1021/acs.estlett.4c00687) related to the *real data case study*. Finally, the `helper_functions.R` script contains helpers used throughout. 

The accompanying paper can be found here: https://doi.org/10.1021/acs.estlett.4c00687

**Of note:** *The data included in the `./input_data/` subdirectory are toy data shortened for quick running of the code. This is meant for demonstration purposes only to get users started with the code and to learn the required structure of input data, rather than for full replication of the results in the above-linked paper.*

## Installation & Usage

Though the current code is still largely in "research code" form, users are still encouraged to engage with it. 

To do so, the simplest approach is to clone the repo and work from the `duration` directory. 

1. Set your desired directory from which to work. E.g., for your Desktop:

```bash
$ cd Desktop
```

2. Clone and store `duration` at the desired location:

```bash
$ git clone https://github.com/Hammerling-Research-Group/duration.git
```

3. Once cloned, go into the `duration` folder and open `duration.Rproj` by double clicking it. This should open a new RStudio session, with `duration.Rproj` set as the root. 

4. In the session, navigate to the `Files` tab and then open the `R` subdirectory.
     - Start by opening and running the `MAIN_1_estimate_durations.R` script
     - Then, proceed to and source other scripts as interested
