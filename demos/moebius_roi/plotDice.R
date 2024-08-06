rm(list=ls()) #clean console
library(ggplot2)
library(plotly)
library(dplyr)
library(Rmisc)

pathResults <- '/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-roi/group/'

########
data <- read.csv(paste(pathResults, 'somatotopyDiceCoeff_hcpex_202407301213.csv', sep ='/'))

# somatotopyDiceCoeff_hcpex_202407301213
# mototopyDiceCoeff_hcpex_202407301637
head(data)


# Ensure the required columns are present
filtered_data <- data %>%
  select(Subject, Hemi,  Pair, Dice, Group, OverlapVoxels, TotVoxels)

# Convert  to factors
filtered_data$Hemi <- as.factor(filtered_data$Hemi)
filtered_data$Group <- as.factor(filtered_data$Group)
filtered_data$Pair<- as.factor(filtered_data$Pair)

# Summarize the data to calculate mean, standard deviation, and standard error
df <- summarySE(data = filtered_data, 
                groupvars=c('Pair','Group','Hemi'),
                measurevar='Dice', na.rm = TRUE)
df

# Define custom x-axis labels
custom_labels <- c('Foot-Fore', 'Foot-Hand', 'Foot-Lips', 'Foot-T', 
                   'Fore-Hand', 'Fore-Lips', 'Fore-T', 
                   'Hand-Lips', 'Hand-T', 'Lips-T')

# Create the plot with error bars and custom x-axis labels
p <- ggplot(filtered_data, aes(x = Pair, y = Dice, color = Group)) +
  geom_jitter(position = position_dodge(width = 0.5), size = 2, alpha = 0.6, shape = 16) +  # Filled circles
  geom_errorbar(data = df, aes(ymin = Dice - se, ymax = Dice + se),
                width = 0.2, position = position_dodge(width = 0.5)) +  # Error bars
  facet_grid(. ~ Hemi) +  # Facet by Hemi
  scale_x_discrete(labels = custom_labels) +  # Apply custom x-axis labels
  theme_bw() +
  labs(
    title = "Mototopy Dice Coefficient Across BodyParts",
    x = "Pair",
    y = "Dice Coeff",
    color = "Group"
  ) +
  theme(
    axis.text.x = element_text(size = 10, face = "bold"),  # Smaller, bold x-axis labels
    strip.text = element_text(size = 12, face = "bold"),  # Bold facet labels
    axis.title = element_text(size = 12, face = "bold")   # Bold axis titles
  )

# Print the plot
p


# # do stats on dice coeff
library(broom)

levels(filtered_data$Group)

# Perform t-tests for each condition in imageContrastName
t_test_results <- filtered_data %>%
  group_by(Pair, Hemi) %>%
  do({
    t_test <- t.test(Dice ~ Group, data = .)
    tidy(t_test) # Use tidy to get a clean summary of the results
  })

# Print t-test results
print(t_test_results)


# Adjust for multiple comparisons using Bonferroni correction
# Number of tests performed (total number of conditions in imageContrastName)
n_tests <- length(unique(filtered_data$Pair))

# Apply Bonferroni correction
t_test_results <- t_test_results %>%
  mutate(p.adj = p.value * n_tests) %>%
  mutate(p.adj = pmin(p.adj, 1)) # Ensure p-values do not exceed 1

# Print adjusted t-test results
print(t_test_results)






#####
# plot the overlapping voxels
# Summarize the data to calculate mean, standard deviation, and standard error
df <- summarySE(data = filtered_data, 
                groupvars=c('Pair','Group','Hemi'),
                measurevar='OverlapVoxels', na.rm = TRUE)
df

# Define custom x-axis labels
custom_labels <- c('Foot-Fore', 'Foot-Hand', 'Foot-Lips', 'Foot-T', 
                   'Fore-Hand', 'Fore-Lips', 'Fore-T', 
                   'Hand-Lips', 'Hand-T', 'Lips-T')

# Create the plot with error bars and custom x-axis labels
p <- ggplot(filtered_data, aes(x = Pair, y = OverlapVoxels, color = Group)) +
  geom_jitter(position = position_dodge(width = 0.5), size = 2, alpha = 0.6, shape = 16) +  # Filled circles
  geom_errorbar(data = df, aes(ymin = OverlapVoxels - se, ymax = OverlapVoxels + se),
                width = 0.2, position = position_dodge(width = 0.5)) +  # Error bars
  facet_grid(. ~ Hemi) +  # Facet by Hemi
  scale_x_discrete(labels = custom_labels) +  # Apply custom x-axis labels
  theme_bw() +
  labs(
    title = "ROI Overlapping Voxel Count ",
    x = "Pair",
    y = "Voxel Count",
    color = "Group"
  ) +
  theme(
    axis.text.x = element_text(size = 10, face = "bold"),  # Smaller, bold x-axis labels
    strip.text = element_text(size = 12, face = "bold"),  # Bold facet labels
    axis.title = element_text(size = 12, face = "bold")   # Bold axis titles
  )

# Print the plot
p

# run stats on overlapping voxels

levels(filtered_data$Group)

# Perform t-tests for each condition in imageContrastName
t_test_results <- filtered_data %>%
  group_by(Pair, Hemi) %>%
  do({
    t_test <- t.test(OverlapVoxels ~ Group, data = .)
    tidy(t_test) # Use tidy to get a clean summary of the results
  })

# Print t-test results
print(t_test_results)


# Adjust for multiple comparisons using Bonferroni correction
# Number of tests performed (total number of conditions in imageContrastName)
n_tests <- length(unique(filtered_data$Pair))

# Apply Bonferroni correction
t_test_results <- t_test_results %>%
  mutate(p.adj = p.value * n_tests) %>%
  mutate(p.adj = pmin(p.adj, 1)) # Ensure p-values do not exceed 1

# Print adjusted t-test results
print(t_test_results)

