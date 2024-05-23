# Tice ADHD Fourier Transformation

This repository contains the R script and related files for the Tice ADHD Fourier Transformation project. This project aims to preprocess fMRI data using Fourier transformations to retain a better representaion compared to traditional functional connectivty analysis.

## Overview

In this project, we explored a method to preprocess fMRI data that minimizes data loss while remaining consice. We focused on using Fourier transformations to analyze the raw time-series data from fMRI scans, extracting the magnitude of four pre-defined frequencies.

### Key Advantages

1. **Non-linear Relationships**: Unlike functional connectivity analysis, which assumes linear relationships between the time series of regions of interest (ROIs), Fourier transformation does not have this limitation.
2. **Identification of Individual Regions**: Fourier transformation allows for the direct analysis of individual regions, making it easier to identify regions of importance without relying on the relationships between ROIs.

### Current Implementation

The current R script (`fourier_transform.R`) performs the following steps:

1. Loads the fMRI time-series data from the `ts_adhd_dc.mat` file.
2. Defines the parameters, including the number of brain regions and the frequencies of interest.
3. Initializes an empty data frame to store the Fourier transformation results.
4. Iterates over four groups of participants, performing Fourier analysis on each participant's time-series data.
5. Interpolates the power at the specified frequencies to handle differences in time series lengths between participants.
6. Compiles the results into a final data frame and writes it to a CSV file (`fourier_dataset.csv`).

### Limitations

Due to time constraints, the current implementation interpolates the magnitude based on the closest frequencies to the target, rather than directly returning the magnitude of the specific frequency of interest. This is a workaround, and future improvements could refine this approach to handle specific frequencies more accurately.

### Next Steps

Future work could explore the use of additional frequencies (e.g., 8, 12, or 40) to potentially improve the accuracy of the analysis. The benefits of increasing the number of frequencies need to be evaluated.

## Usage

### Prerequisites

- R programming language
- Required libraries: `R.matlab`

### Running the Script

1. Clone the repository:

   ```sh
   git clone https://github.com/camtice/fMRI_fourier_transformation.git
   cd fMRI_fourier_transformation
