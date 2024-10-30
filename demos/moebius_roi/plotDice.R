rm(list=ls()) #clean console
library(ggplot2)
library(plotly)
library(dplyr)
library(Rmisc)

pathResults <- '/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-roi/group/'

########
data <- read.csv(paste(pathResults, 'somatotopyDiceCoeff_hcpex_202407301213.csv', sep ='/'))

# moto in M1 
# mototopyDiceCoeff_hcpex_label4_202409251139

# both in sensory cx, area 123ab
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



p <- ggplot(df, aes(x = Pair, y = Dice, color = Group)) +
  # Add summary points (mean) with dodge positioning
  geom_point(position = position_dodge(width = 0.5), size = 6) + 
  # Add error bars with dodge positioning
  geom_errorbar(aes(ymin = Dice - se, ymax = Dice + se), 
                width = 0.2, position = position_dodge(width = 0.5)) +
  # Facet wrap by Hemi
  facet_wrap(~ Hemi) +
  # Set fixed y-axis range
  ylim(0, 1) +  # Fix the y-axis range from 0 to 40
  # Labels and theme customization
  labs(x = 'Body Parts', y = 'Dice Coeff', color = "Groups") +
  theme_minimal() +
  theme(
    # Increase axis title sizes
    axis.title.x = element_text(size = 24),
    axis.title.y = element_text(size = 24),
    
    # Increase axis tick sizes
    axis.text.x = element_text(size = 20, angle = 45, hjust = 1),
    axis.text.y = element_text(size = 20),
    
    # Increase legend title and text size
    legend.title = element_text(size = 22),
    legend.text = element_text(size = 20),
    
    # Increase facet label text size
    strip.text = element_text(size = 22, hjust = 0.5),
    
    # Optional: Adjust panel grid and legend position
    panel.grid.major.x = element_blank(),  # Optional, to reduce grid lines on x
    panel.grid.minor.x = element_blank(),
    legend.position = "top"  # Place legend on top
  ) +
  # Custom color scheme
  scale_color_manual(values = c(
    "ctrl" = "#FF6666", "mbs" = "#6666FF"
  ))

# Print the plot
print(p)

filename <- paste(pathResults, "DiceCoeffPlot_Moto_Averaged.pdf", sep = '')
ggsave(filename, plot = p, width = 18, height = 6, units = "in", dpi = 300)









# with individual data points
# Create the plot with error bars and custom x-axis labels
p <- ggplot(filtered_data, aes(x = Pair, y = Dice, color = Group)) +
  geom_jitter(position = position_dodge(width = 0.5), size = 2, alpha = 0.6, shape = 16) +  # Filled circles
  geom_errorbar(data = df, aes(ymin = Dice - se, ymax = Dice + se),
                width = 0.2, position = position_dodge(width = 0.5)) +  # Error bars
  facet_grid(. ~ Hemi) +  # Facet by Hemi
 # scale_x_discrete(labels = custom_labels) +  # Apply custom x-axis labels
  theme_bw() +
  labs(
    title = "Somatotopy Dice Coefficient Across BodyParts",
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



p <- ggplot(df, aes(x = Pair, y = OverlapVoxels, color = Group)) +
  # Add summary points (mean) with dodge positioning
  geom_point(position = position_dodge(width = 0.5), size = 6) + 
  # Add error bars with dodge positioning
  geom_errorbar(aes(ymin = OverlapVoxels - se, ymax = OverlapVoxels + se), 
                width = 0.2, position = position_dodge(width = 0.5)) +
  # Facet wrap by Hemi
  facet_wrap(~ Hemi) +
  # Set fixed y-axis range
  #ylim(0, 1) +  # Fix the y-axis range from 0 to 40
  # Labels and theme customization
  labs(x = 'Body Parts', y = ' Voxel Count', color = "Groups") +
  theme_minimal() +
  theme(
    # Increase axis title sizes
    axis.title.x = element_text(size = 24),
    axis.title.y = element_text(size = 24),
    
    # Increase axis tick sizes
    axis.text.x = element_text(size = 20, angle = 45, hjust = 1),
    axis.text.y = element_text(size = 20),
    
    # Increase legend title and text size
    legend.title = element_text(size = 22),
    legend.text = element_text(size = 20),
    
    # Increase facet label text size
    strip.text = element_text(size = 22, hjust = 0.5),
    
    # Optional: Adjust panel grid and legend position
    panel.grid.major.x = element_blank(),  # Optional, to reduce grid lines on x
    panel.grid.minor.x = element_blank(),
    legend.position = "top"  # Place legend on top
  ) +
  # Custom color scheme
  scale_color_manual(values = c(
    "ctrl" = "#FF6666", "mbs" = "#6666FF"
  ))

# Print the plot
print(p)

filename <- paste(pathResults, "VoxelCountPlot_Somato_Averaged.pdf", sep = '')
ggsave(filename, plot = p, width = 18, height = 6, units = "in", dpi = 300)







# individual points
# Create the plot with error bars and custom x-axis labels
p <- ggplot(df, aes(x = Pair, y = OverlapVoxels, color = Group)) +
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

