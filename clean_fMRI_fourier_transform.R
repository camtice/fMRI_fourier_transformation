# Required libraries
library(R.matlab)

# Load data
data <- readMat("ts_adhd_dc.mat")

# Define parameters
num_regions <- dim(data[[1]][[1]][[1]])[2]
frequencies <- seq(0.01, 0.49, length.out = 4)

# Initialize an empty data frame for the Fourier dataset
fourier_dataset <- data.frame()

# Loop over the four groups
for (group in 1:4) {
  num_participants <- length(data[[group]])  # Get number of participants in current group
  adhd_status <- ifelse(group == 2, 0, 1)  # ADHD status based on group number (everything but group 2(control) is 1)

  # Initialize a temporary data frame for the current group
  temp_data <- data.frame(ADHD = rep(adhd_status, num_participants))

  for (region in 1:num_regions) {
    for (freq_idx in 1:length(frequencies)) {
      freq <- frequencies[freq_idx]
      col_name <- paste0("Region", region, "_Freq", freq_idx)
      intensities <- numeric(num_participants)

      for (participant in 1:num_participants) {
        time_series <- data[[group]][[participant]][[1]][, region]

        # Perform Fourier analysis
        fft_output <- fft(time_series)
        magnitude <- abs(fft_output)
        power <- magnitude^2

        # Calculate the frequency resolution
        freq_res <- 1 / length(time_series)

        # Calculate the frequency values corresponding to each FFT output
        fft_freqs <- seq(0, 1 - freq_res, by = freq_res)

        # Interpolate the power at the specific frequency
        intensities[participant] <- approx(fft_freqs, power, xout = freq)$y
      }

      # Assign the intensities vector to the corresponding column in temp_data
      temp_data[[col_name]] <- intensities
    }
  }

  # Append the data from the current group to the main dataset
  if (nrow(fourier_dataset) == 0) {
    fourier_dataset <- temp_data
  } else {
    fourier_dataset <- rbind(fourier_dataset, temp_data)
  }
}

# Write the Fourier dataset to a CSV file
write.csv(fourier_dataset, file = "fourier_dataset.csv", row.names = FALSE)
