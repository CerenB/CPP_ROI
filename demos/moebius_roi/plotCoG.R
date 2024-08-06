rm(list=ls()) #clean console
library(ggplot2)
library(plotly)
library(dplyr)
library(Rmisc)

pathResults <- '/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-roi/group/'

########
data <- read.csv(paste(pathResults, 'mototopyCoGCoordandVoxelNbforROIs_unthreshhcpex_202407301623.csv', sep ='/'))

# somatotopyCoGCoordandVoxelNbforROIs_unthreshhcpex_202407291230
# mototopyCoGCoordandVoxelNbforROIs_unthreshhcpex_202407301623

# mototopyCoGCoordandVoxelNbforROIs_hcpex_202407242323
# somatotopyCoGCoordandVoxelNbforROIs_hcpex_202407242250

# Use the dplyr filter function to omit rows where coordinateX is 0
#filtered_data <- data %>% filter(voxelNb != 0)
filtered_data <- data %>%
  mutate(group = ifelse(grepl("mbs", subLabel), "mbs", "ctrl"))

# Ensure the required columns are present
filtered_data <- filtered_data %>%
  select(subLabel, imageContrastName,  maskHemi, voxelNb,
         centroidCoordinateX, centroidCoordinateY, centroidCoordinateZ, group)

# Convert  maskHemi, and group to factors
filtered_data$maskHemi <- as.factor(filtered_data$maskHemi)
filtered_data$group <- as.factor(filtered_data$group)
filtered_data$imageContrastName <- as.factor(filtered_data$imageContrastName)

#convert Y coordinate to right value
filtered_data <- filtered_data %>%
  mutate(
    centroidCoordinateY =  -centroidCoordinateY,
  )

# Create a new column that combines maskHemi and imageContrastName for plotting
filtered_data$combined_x <- interaction(filtered_data$maskHemi, filtered_data$imageContrastName, drop = TRUE)

# Summarize the data to calculate mean, standard deviation, and standard error
df <- summarySE(data = filtered_data, 
                groupvars=c('imageContrastName','group','maskHemi', 'combined_x '),
                measurevar='voxelNb', na.rm = TRUE)
df

# Create the plot
p <- ggplot(filtered_data, aes(x = imageContrastName, y = voxelNb, color = group)) +
  geom_jitter(position = position_dodge(width = 0.5), size = 2, alpha = 0.6, shape = 16) +  # Filled circles
  geom_errorbar(data = df, aes(ymin = voxelNb - se, ymax = voxelNb + se, color = group),
                width = 0.2, position = position_dodge(width = 0.5)) +
  geom_point(data = df, aes(y = voxelNb, color = group),
             position = position_dodge(width = 0.5), size = 3, shape = 16) +  # Filled circles
  facet_grid(. ~ maskHemi) +  # Facet by maskHemi
  theme_bw() +
  labs(
    title = "Mean and Standard Deviation of Voxel Numbers Across Body Parts",
    x = "Body Parts",
    y = "Voxel Numbers",
    color = "Group"
  ) +
  theme(
    axis.text.x = element_text(size = 10, face = "bold"),  # Smaller, bold x-axis labels
    strip.text = element_text(size = 12, face = "bold"),  # Bold facet labels
    axis.title = element_text(size = 12, face = "bold")   # Bold axis titles
  )

# Print the plot
p




# # do stats on voxelNb
library(broom)

levels(filtered_data$group)

# Perform t-tests for each condition in imageContrastName
t_test_results <- filtered_data %>%
  group_by(imageContrastName, maskHemi) %>%
  do({
    t_test <- t.test(voxelNb ~ group, data = .)
    tidy(t_test) # Use tidy to get a clean summary of the results
  })

# Print t-test results
print(t_test_results)


# Adjust for multiple comparisons using Bonferroni correction
# Number of tests performed (total number of conditions in imageContrastName)
n_tests <- length(unique(filtered_data$imageContrastName))

# Apply Bonferroni correction
t_test_results <- t_test_results %>%
  mutate(p.adj = p.value * n_tests) %>%
  mutate(p.adj = pmin(p.adj, 1)) # Ensure p-values do not exceed 1

# Print adjusted t-test results
print(t_test_results)

# # do stats on voxelNb
# library(broom) # for tidy results
# library(car) # for Levene's test
# library(emmeans) # for post-hoc testing
# 
# 
# # Perform Two-Way ANOVA
# anova_results <- aov(voxelNb ~ imageContrastName * maskHemi * group, data = filtered_data)
# 
# # Tidy the ANOVA results
# tidy_anova <- tidy(anova_results)
# print(tidy_anova)
# 
# # Calculate estimated marginal means (EMMs) and perform pairwise comparisons
# emm <- emmeans(anova_results, ~ imageContrastName * maskHemi | group)
# pairwise_comparisons <- pairs(emm)
# print(pairwise_comparisons)
# 
# # Check normality of residuals
# normality_check <- filtered_data %>%
#   group_by(group) %>%
#   do({
#     aov_result <- aov(voxelNb ~ imageContrastName * maskHemi, data = filtered_data)
#     shapiro.test(residuals(aov_result))
#   })
# print(normality_check)
# 
# # Check homogeneity of variances
# levene_test <- leveneTest(voxelNb ~ imageContrastName * maskHemi * group, data = filtered_data)
# print(levene_test)

##### 


# CoG euclidean distances 
pathResults <- '/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-roi/group/'

########
data <- read.csv(paste(pathResults, 'mototopyCoGDistance_unthreshhcpex_202407301623.csv', sep ='/'))
# somatotopyCoGDistance_unthreshhcpex_202407291232
# 
head(data)

new_data <- data %>%
  filter(!is.nan(Distance))

# Summarize the data to calculate mean, standard deviation, and standard error
df <- summarySE(data = new_data, 
                groupvars=c('Pair','Group','Hemi'),
                measurevar='Distance', na.rm = TRUE)
df

# Define custom x-axis labels
custom_labels <- c('Foot-Fore', 'Foot-Hand', 'Foot-Lips', 'Foot-T', 
                   'Fore-Hand', 'Fore-Lips', 'Fore-T', 
                   'Hand-Lips', 'Hand-T', 'Lips-T')

# Create the plot with error bars and custom x-axis labels
p <- ggplot(new_data, aes(x = Pair, y = Distance, color = Group)) +
  geom_jitter(position = position_dodge(width = 0.5), size = 2, alpha = 0.6, shape = 16) +  # Filled circles
  geom_errorbar(data = df, aes(ymin = Distance - se, ymax = Distance + se),
                width = 0.2, position = position_dodge(width = 0.5)) +  # Error bars
  facet_grid(. ~ Hemi) +  # Facet by Hemi
  scale_x_discrete(labels = custom_labels) +  # Apply custom x-axis labels
  theme_bw() +
  labs(
    title = "CoG Euclidean Distance Across BodyParts",
    x = "Pair",
    y = "Distance",
    color = "Group"
  ) +
  theme(
    axis.text.x = element_text(size = 10, face = "bold"),  # Smaller, bold x-axis labels
    strip.text = element_text(size = 12, face = "bold"),  # Bold facet labels
    axis.title = element_text(size = 12, face = "bold")   # Bold axis titles
  )

# Print the plot
p







##### DOESNT WORK CURRENTLY
# WHAT WE wanted is to reoder the x-axis pairs


# Calculate summary statistics with mean and standard error
summary_stats <- data %>%
  group_by(Hemi, Group, Pair) %>%
  summarize(
    mean_Distance = mean(Distance, na.rm = TRUE),
    n_subjects = sum(!is.na(Distance)),  # Number of non-missing values
    SE = sd(Distance, na.rm = TRUE) / sqrt(n_subjects),  # Standard Error
    .groups = 'drop'
  )

# Check the summary statistics
print(summary_stats)

# Desired order of pairs
desired_order <- c("Foot-Tongue", "Hand-Tongue", "Forehead-Tongue", "Lips-Tongue",
                   "Foot-Hand", "Hand-Forehead", "Foot-Lips", "Hand-Lips",
                   "Foot-Forehead", "Lips-Forehead")

# Reorder the Pair factor in data and summary_stats
data$Pair <- factor(data$Pair, levels = desired_order)
summary_stats$Pair <- factor(summary_stats$Pair, levels = desired_order)

# Create the plot
p <- ggplot(data, aes(x = Pair, y = Distance, color = Group)) +
  geom_jitter(position = position_dodge(0.5), size = 2) +
  geom_errorbar(data = summary_stats, aes(ymin = mean_Distance - SE, ymax = mean_Distance + SE), 
                width = 0.2, position = position_dodge(0.5), color = "black") +
  geom_point(data = summary_stats, aes(y = mean_Distance), position = position_dodge(0.5), size = 3, shape = 18, color = "black") +
  facet_grid(. ~ Hemi) +  # Facet by Hemi
  theme_bw() +
  labs(
    title = "Mean and Standard Deviation of Distance by Group and Hemisphere",
    x = "BodyParts",
    y = "Distance",
    color = "Group"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)  # Tilt x-axis labels if needed
  )

# Display the plot
print(p)











######
# plot just the average for a clear picture
# Summarize the data to calculate mean, standard deviation, and standard error

df <- summarySE(data = new_data, 
                groupvars=c('Pair','Group','Hemi'),
                measurevar='Distance', na.rm = TRUE)
df


# Define custom x-axis labels
custom_labels <- c('Foot-Fore', 'Foot-Hand', 'Foot-Lips', 'Foot-T', 
                   'Fore-Hand', 'Fore-Lips', 'Fore-T', 
                   'Hand-Lips', 'Hand-T', 'Lips-T')

# Create the plot with error bars and custom x-axis labels
p <- ggplot(df, aes(x = Pair, y = Distance, color = Group)) +
  geom_jitter(position = position_dodge(width = 0.5), size = 2, alpha = 0.6, shape = 16) +  # Filled circles
  geom_errorbar(aes(ymin = Distance - se, ymax = Distance + se),
                width = 0.2, position = position_dodge(width = 0.5)) +  # Error bars
  facet_grid(. ~ Hemi) +  # Facet by Hemi
  scale_x_discrete(labels = custom_labels) +  # Apply custom x-axis labels
  theme_bw() +
  labs(
    title = "Average Distance Across Pair, Hemi, and Group with Error Bars",
    x = "Pair",
    y = "Mean Distance",
    color = "Group"
  ) +
  theme(
    axis.text.x = element_text(size = 10, face = "bold"),  # Smaller, bold x-axis labels
    strip.text = element_text(size = 12, face = "bold"),  # Bold facet labels
    axis.title = element_text(size = 12, face = "bold")   # Bold axis titles
  )

# Print the plot
p
