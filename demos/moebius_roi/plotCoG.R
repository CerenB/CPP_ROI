rm(list=ls()) #clean console
library(ggplot2)
library(plotly)
library(dplyr)
library(Rmisc)

pathResults <- '/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-roi/group/'

########
data <- read.csv(paste(pathResults, 'mototopyCoGCoordandVoxelNbforROIs_unthreshhcpex_label4_202409251138.csv', sep ='/'))

# mototopy with M1 (area 4) mask
# mototopyCoGCoordandVoxelNbforROIs_unthreshhcpex_label4_202409251138

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
data <- read.csv(paste(pathResults, 'mototopyCoGDistance_unthreshhcpex_label4_202409251138.csv', sep ='/'))

# moto within area M1 (label4)
# mototopyCoGDistance_unthreshhcpex_label4_202409251138

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










# 06/08/2024
#####

# work on somatotopy and mototopy data together to make comparisons later on

#####



# CoG euclidean distances 
pathResults <- '/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-roi/group/'

########
datam <- read.csv(paste(pathResults, 'mototopyCoGDistance_unthreshhcpex_label4_202409251138.csv', sep ='/'))
datas <- read.csv(paste(pathResults, 'somatotopyCoGDistance_unthreshhcpex_202407291232.csv', sep ='/'))

# motor area M1 for mototopy data
# mototopyCoGDistance_unthreshhcpex_label4_202409251138

# mototopy in label123ab 
# mototopyCoGDistance_unthreshhcpex_202407301623


datam$Exp <- 'moto'
datas$Exp <- 'somato'
data<- rbind(datam, datas)

head(data)

data <- data %>%
  filter(!is.nan(Distance))

# make a column related to pairs of face pairs vs. non-face pairs
data$Category <- ifelse(
    data$Pair == "Foot-Hand", "no-face",
    ifelse(data$Pair %in% c("Lips-Tongue", "Forehead-Lips", "Forehead-Tongue"), "face", "mixed")
    )

#####
# 0. try plotting the pairs as they are, with somato/moto next to each other 
# make a new column for plot organisation

# Replace 'Forehead' with 'Fore' and 'Tongue' with 'T' in the Pair column
data$Pair <- gsub("Forehead", "Fore", data$Pair)
data$Pair <- gsub("Tongue", "T", data$Pair)

# View the updated Pair column
head(data$Pair)


data <- data %>%
  mutate(PairExp = ifelse(
    Exp == "moto", paste0(Pair, "-m"),
    paste0(Pair, "-s")
  ))

# View the updated data
head(data)


#####

# plotting moto/somato side by side by using alpha/ opacity - not so great
# bar plot 

#####
df <- summarySE(data = data, 
                groupvars=c('PairExp','Group','Hemi', 'Exp'),
                measurevar='Distance', na.rm = TRUE)
df

p<- ggplot(df, aes(x = PairExp, y = Distance, fill = Group, alpha = Exp)) +
  geom_bar(stat = "identity", position = "dodge") + 
  facet_grid(~ Hemi) + 
  labs(x = "Pair and Experiment", y = "CoG Euclidian Distance", title = "Pairise Distance by Exp and BodyParts") +
  theme_minimal() +
  theme(
    strip.text = element_text(size = 12),
    axis.text.x = element_text(angle = 45, hjust = 1)
  ) +
  scale_alpha_manual(values = c("moto" = 0.8, "somato" = 0.4))

p


#####

# BETTER alternative split them into different colors

#####
# titleX = "BodyPart pairs"
# titleY = "CoG Euc Distance"
# titleMid = "Pairwise Euclidean Distance by BodyParts"
# 
# df <- summarySE(data = data,
#                 groupvars=c('Pair','Group','Hemi', 'Exp'),
#                 measurevar='Distance', na.rm = TRUE)
# df
# 
# p<- ggplot(df, aes(x = Pair, y = Distance, color = interaction(Group, Exp))) +
#   geom_point(position = position_dodge(width = 0.8), size = 3) +
#   geom_errorbar(aes(ymin = Distance - se, ymax = Distance + se),
#                 width = 0.2, position = position_dodge(width = 0.8)) +
#   facet_grid(Hemi ~ .) +
#   labs(x = titleX, y = titleY, title = titleMid) +
#   theme_minimal() +
#   theme(
#     strip.text = element_text(size = 12),
#     axis.text.x = element_text(angle = 45, hjust = 1),
#     panel.grid.major.x = element_blank(), # Optional, to reduce grid lines on x
#     panel.grid.minor.x = element_blank()
#   ) +
#   scale_color_manual(values = c(
#     "ctrl.moto" = "#FF6666", "ctrl.somato" = "#FFCCCC",
#     "mbs.moto" = "#6666FF", "mbs.somato" = "#CCCCFF"
#   ))
# 
# p
# 

# modify a bit further
p <- ggplot(df, aes(x = Pair, y = Distance, color = interaction(Group, Exp))) +
  # Add jittered individual data points
  geom_jitter(data = data,
              aes(x = Pair, y = Distance, color = interaction(Group, Exp)),
              position = position_jitterdodge(jitter.width = 0.15, dodge.width = 0.8),
              size = 1.5, alpha = 0.5) +
  # Add summary points (mean) with dodge positioning
  geom_point(position = position_dodge(width = 0.8), size = 3) + 
  # Add error bars with dodge positioning
  geom_errorbar(aes(ymin = Distance - se, ymax = Distance + se), 
                width = 0.2, position = position_dodge(width = 0.8)) +
  # Facet wrap by Hemi
  facet_wrap(~ Hemi) +
  # Labels and theme customization
  labs(x = titleX, y = titleY, title = titleMid, color = "Groups") +
  theme_minimal() +
  theme(
    strip.text = element_text(size = 12, hjust = 0.5),  # Adjust text size and alignment
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.major.x = element_blank(), # Optional, to reduce grid lines on x
    panel.grid.minor.x = element_blank(),
    legend.position = "top"  # Place legend in the top
  ) +
  # Custom color scheme
  scale_color_manual(values = c(
    "ctrl.moto" = "#FF6666", "ctrl.somato" = "#FFCCCC",
    "mbs.moto" = "#6666FF", "mbs.somato" = "#CCCCFF"
  ))

# Print the plot
print(p)

# save the plot
filename <- paste(pathResults, "PairwiseCoGDistancePlot_MotoSomato_individualDots.png", sep = '')
ggsave(filename, plot = p, width = 18, height = 6, units = "in", dpi = 300)


# Now with average values instead of individual dots
# modify a bit further

# example 
datam <- data %>% filter(Exp == "moto")
datas <- data %>% filter(Exp == "somato")

df <- summarySE(data = datam, 
                groupvars=c('Pair','Group','Hemi'),
                measurevar='Distance', na.rm = TRUE)
df


df2 <- summarySE(data = datas, 
                groupvars=c('Pair','Group','Hemi'),
                measurevar='Distance', na.rm = TRUE)
df2

# Define custom x-axis labels
custom_labels <- c('Foot-Fore', 'Foot-Hand', 'Foot-Lips', 'Foot-T', 
                   'Fore-Hand', 'Fore-Lips', 'Fore-T', 
                   'Hand-Lips', 'Hand-T', 'Lips-T')


p <- ggplot(df2, aes(x = Pair, y = Distance, color = Group)) +
  # Add summary points (mean) with dodge positioning
  geom_point(position = position_dodge(width = 0.8), size = 6) + 
  # Add error bars with dodge positioning
  geom_errorbar(aes(ymin = Distance - se, ymax = Distance + se), 
                width = 0.2, position = position_dodge(width = 0.8)) +
  # Facet wrap by Hemi
  facet_wrap(~ Hemi) +
  # Set fixed y-axis range
  ylim(0, 45) +  # Fix the y-axis range from 0 to 40
  # Labels and theme customization
  labs(x = titleX, y = titleY,color = "Groups") +
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

filename <- paste(pathResults, "PairwiseCoGDistancePlot_Somato_Averaged.pdf", sep = '')
ggsave(filename, plot = p, width = 18, height = 6, units = "in", dpi = 300)






#combine the data and separate again
data <- rbind(datam,datas)


# Prepare the data
data$Pair <- as.factor(data$Pair)
data$Group <- as.factor(data$Group)
data$Exp <- as.factor(data$Exp)
data$Hemi <- as.factor(data$Hemi)
data$Category <- as.factor(data$Category)
data$PairExp <- as.factor(data$PairExp)

# # Assuming your data frame is named df
# factor_columns <- sapply(data, is.factor)
# 
# # Print the result
# factor_columns

#####


# # here let's check the stats - anova
# anova_model <- aov(Distance ~ Pair * Group * Exp * Hemi, data = data)
# 
# # Check residuals for normality
# qqnorm(anova_model$residuals)
# qqline(anova_model$residuals)
# 
# # Shapiro-Wilk test for normality
# shapiro.test(anova_model$residuals)
# 
# 
# library(car)
# leveneTest(Distance ~ Pair * Group * Exp * Hemi, data = data)




#####


# fail at normality and homogeneity of the datasets.
# two options: permmutation anova and or GLMs

install.packages("permuco")
library(permuco)
# Fit permutation-based ANOVA model with unbalanced design
# ignores random effect  (1 | Subject)
perm_model <- aovperm(Distance ~ Pair * Group * Exp * Hemi, data = data, np = 2000)
results<- summary(perm_model)
print(results)

# results_rounded <- as.data.frame(lapply(results, function(x) {
#   if (is.numeric(x)) round(x, 3) else x
# }))

# Extract permutation results as a data frame
filename <- paste(pathResults, "permutationAnovaTable_MotoSomato_CoGDistancePairwise.csv", sep = '')
write.csv(results, filename)





# divide data into2 
datam <- data %>% filter(Exp == "moto")
datas <- data %>% filter(Exp == "somato")

#moto
perm_model <- aovperm(Distance ~ Pair * Group * Hemi, data = datam, np = 2000)
results<- summary(perm_model)
print(results)

# Extract permutation results as a data frame
filename <- paste(pathResults, "permutationAnovaTable_Moto_CoGDistancePairwise.csv", sep = '')
write.csv(results, filename)





# somato
perm_model <- aovperm(Distance ~ Pair * Group * Hemi, data = datas, np = 2000)
results<- summary(perm_model)
print(results)

# Extract permutation results as a data frame
filename <- paste(pathResults, "permutationAnovaTable_Somato_CoGDistancePairwise.csv", sep = '')
write.csv(results, filename)





#####
# interaction Pair:Group
#####


# Prepare the data for interaction plotting
# Create a new data frame that summarizes the interaction
titleX = "BodyPart pairs"
titleY = "Mean CoG Euc Distance"
titleMid = "Interaction Pair:Group (PermutationANOVA)"

df <- summarySE(data = data, 
                groupvars=c('Pair','Group'),
                measurevar='Distance', na.rm = TRUE)
df

p<- ggplot(df, aes(x = Pair, y = Distance, color = Group, shape = Group)) +
  geom_point(size = 3) +
  geom_line(aes(group = Group), linetype = "dashed") +
  geom_errorbar(aes(ymin = Distance - se, ymax = Distance + se), width = 0.2) +
  labs(x = titleX, y = titleY, color = "Group", title = titleMid) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels if needed

p

filename <- paste(pathResults, "PairGroup_Interaction_PairwiseCoGDistancePlot.png", sep = '')
ggsave(filename, plot = p, width = 12, height = 6, units = "in", dpi = 300)







#####
# interaction Pair:Exp
#####


# Prepare the data for interaction plotting
# Create a new data frame that summarizes the interaction
titleX = "BodyPart pairs"
titleY = "Mean CoG Euc Distance"
titleMid = "Interaction Pair:Exp (PermutationANOVA)"

df <- summarySE(data = data, 
                groupvars=c('Pair','Exp'),
                measurevar='Distance', na.rm = TRUE)
df

p<- ggplot(df, aes(x = Pair, y = Distance, color = Exp, shape = Exp)) +
  geom_point(size = 3) +
  geom_line(aes(group = Exp), linetype = "dashed") +
  geom_errorbar(aes(ymin = Distance - se, ymax = Distance + se), width = 0.2) +
  labs(x = titleX, y = titleY, color = "Exp", title = titleMid) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5))  # Rotate x-axis labels if needed

p

filename <- paste(pathResults, "PairExp_Interaction_PairwiseCoGDistancePlot.png", sep = '')
ggsave(filename, plot = p, width = 12, height = 6, units = "in", dpi = 300)




#####

# not very meaningful this below plot, isn't it?
# it shows the interaction(Group:Exp) which is not sig, 

#####
# first look at the only averages data (all pairs are averaged) x Groups x Exp
# Summarize the data to calculate mean, standard deviation, and standard error
titleX = "Experiments"
titleY = "Mean CoG Euc Distance"
titleMid = "Averaged Pairwise Distance by Experiments"

df <- summarySE(data = data, 
                groupvars=c('Group','Hemi', 'Exp'),
                measurevar='Distance', na.rm = TRUE)
df

p <- ggplot(df, aes(x = Exp, y = Distance, color = Group)) +
  geom_point(position = position_dodge(width = 0.8), size = 3) + 
  geom_errorbar(aes(ymin = Distance - se, ymax = Distance + se), 
                width = 0.2, position = position_dodge(width = 0.8)) +
  facet_wrap(~ Hemi) +  # Use facet_wrap for easier customization
  labs(x = titleX, y = titleY, title = titleMid, color = "Groups") +
  theme_minimal() +
  theme(
    strip.text = element_text(size = 14, hjust = 0.5),  # Increase facet labels size
    axis.text.x = element_text(size = 12, angle = 0, hjust = 1),  # Increase x-axis text size
    axis.text.y = element_text(size = 12),  # Increase y-axis text size
    axis.title.x = element_text(size = 14),  # Increase x-axis title size
    axis.title.y = element_text(size = 14),  # Increase y-axis title size
    legend.text = element_text(size = 10),  # Increase legend text size
    legend.title = element_text(size = 12),  # Increase legend title size
    panel.grid.major.x = element_blank(),  # Optional, to reduce grid lines on x
    panel.grid.minor.x = element_blank(),
    legend.position = "top"  # Place legend in the top
  ) +
  scale_color_manual(values = c(
    "mbs" = "#FF6666", 
    "ctrl" = "#6666FF"
  ))

print(p)

filename <- paste(pathResults, "ExpGroup_Interaction_PairwiseCoGDistancePlot.png", sep = '')
ggsave(filename, plot = p, width = 8, height = 6, units = "in", dpi = 300)









# second look at the face/no/face/mixed data split  x Groups x Exp
# consider 3 (Category) face_wraps


titleX = "BodyPart pairs"
titleY = "CoG Euc Distance"
titleMid = "Pairwise Euclidean Distance by BodyParts"

df <- summarySE(data = data,
                groupvars=c('Category','Group','Hemi', 'Exp'),
                measurevar='Distance', na.rm = TRUE)
df

# modify a bit further

p <- ggplot(df, aes(x = Category, y = Distance, color = interaction(Group, Exp))) +
  geom_point(position = position_dodge(width = 0.8), size = 3) + 
  geom_errorbar(aes(ymin = Distance - se, ymax = Distance + se), 
                width = 0.2, position = position_dodge(width = 0.8)) +
  facet_wrap(~ Hemi) +  # Use facet_wrap for easier customization
  labs(x = titleX, y = titleY, title = titleMid, color = "Groups") +
  theme_minimal() +
  theme(
    strip.text = element_text(size = 14, hjust = 0.5),  # Increase facet labels size
    axis.text.x = element_text(size = 12, angle = 0, hjust = 1),  # Increase x-axis text size
    axis.text.y = element_text(size = 12),  # Increase y-axis text size
    axis.title.x = element_text(size = 14),  # Increase x-axis title size
    axis.title.y = element_text(size = 14),  # Increase y-axis title size
    legend.text = element_text(size = 10),  # Increase legend text size
    legend.title = element_text(size = 12),  # Increase legend title size
    panel.grid.major.x = element_blank(),  # Optional, to reduce grid lines on x
    panel.grid.minor.x = element_blank(),
    legend.position = "top"  # Place legend in the top
  ) +
  scale_color_manual(values = c(
    "ctrl.moto" = "#FF6666", "ctrl.somato" = "#FFCCCC",
    "mbs.moto" = "#6666FF", "mbs.somato" = "#CCCCFF"
  ))

print(p)

# save the plot
filename <- paste(pathResults, "PairwiseCoGDistancePlot_MotoSomato_3Categories.png", sep = '')
ggsave(filename, plot = p, width = 12, height = 6, units = "in", dpi = 300)




# let's do permutation anova for these pairs
perm_model <- aovperm(Distance ~ Category * Group * Exp * Hemi, data = data, np = 2000)
results<- summary(perm_model)
print(results)


# Extract permutation results as a data frame
filename <- paste(pathResults, "permutationAnovaTable_MotoSomato_CoGDistancePairwise_3Categories.csv", sep = '')
write.csv(results, filename)







# copy pasted figure snippet from previous plot
# change it according to the need
# Define custom x-axis labels





