install.packages("ggplot2")
install.packages("rlang")
install.packages("plotly")

library(ggplot2)
library(plotly)
library(dplyr)



pathResults <- '/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-roi/group/'

########
data <- read.csv(paste(pathResults, 'somatotopyPeakVoxels_hcpex_202407172248.csv', sep ='/'))

# Use the dplyr filter function to omit rows where coordinateX is 0
filtered_data <- data %>% filter(coordinateX != 0)


# Add a new 'group' column based on the 'subLabel' column
filtered_data <- filtered_data %>%
  mutate(group = ifelse(grepl("mbs", subLabel), "mbs", "ctrl"))

# Ensure the required columns are present
filtered_data <- filtered_data %>%
  select(subLabel, maskLabel, maskHemi, dataImageContrast, wordX, wordY, wordZ, group)

# Convert maskLabel, maskHemi, and group to factors
filtered_data$maskLabel <- as.factor(filtered_data$maskLabel)
filtered_data$maskHemi <- as.factor(filtered_data$maskHemi)
filtered_data$group <- as.factor(filtered_data$group)
filtered_data$dataImageContrast <- as.factor(filtered_data$dataImageContrast)

# # Create the faceted plot using ggplot2
# # Example ggplot2 plot with 3D coordinates
# p <- ggplot(filtered_data, aes(x = wordX, y = wordY, z = wordZ, color = group)) +
#   geom_point() +
#   facet_grid(maskHemi ~ maskLabel) +
#   theme_bw() +
#   labs(
#     title = "3D Scatter Plot of Participants by maskLabel and maskHemi",
#     x = "X-axis",
#     y = "Y-axis"
#   )
# 
# plotly_plot <- ggplotly(p, tooltip = c("wordX", "wordY", "wordZ", "group", "maskHemi", "maskLabel"))
# plotly_plot




p <- ggplot(filtered_data, aes(x = wordX, y = wordY, z = wordZ, color = dataImageContrast, shape = group)) +
  geom_point(size = 3) +
  facet_grid(maskHemi ~ maskLabel) +
  theme_bw() +
  labs(
    title = "3D Scatter Plot of Participants by maskLabel and maskHemi",
    x = "X-axis",
    y = "Y-axis",
    color = "Data Image Contrast",
    shape = "Group"
  )

# Convert ggplot2 plot to plotly object
plotly_plot <- ggplotly(p, tooltip = c("wordX", "wordY", "wordZ", "group", "dataImageContrast", "maskHemi", "maskLabel"))

# Display the plotly plot
plotly_plot





# # # Example: Create separate 3D scatter plots for each combination of maskHemi and maskLabel
# # plots <- list()
# # 
# # # Get unique combinations of maskHemi and maskLabel
# # combinations <- unique(filtered_data %>% select(maskHemi, maskLabel))
# # 
# # for (i in 1:nrow(combinations)) {
# #   maskHemi_value <- combinations$maskHemi[i]
# #   maskLabel_value <- combinations$maskLabel[i]
# #   
# #   # Filter data for the current combination of maskHemi and maskLabel
# #   filtered_subset <- filtered_data %>%
# #     filter(maskHemi == maskHemi_value, maskLabel == maskLabel_value)
# #   
# #   # Create a 3D scatter plot for the current subset
# #   p <- plot_ly(data = filtered_subset, x = ~wordX, y = ~wordY, z = ~wordZ, color = ~group,
# #                type = "scatter3d", mode = "markers",
# #                marker = list(size = 5)) %>%
# #     layout(
# #       scene = list(
# #         xaxis = list(title = 'X-axis'),
# #         yaxis = list(title = 'Y-axis'),
# #         zaxis = list(title = 'Z-axis')
# #       ),
# #       title = paste("3D Scatter Plot for maskHemi =", maskHemi_value, "and maskLabel =", maskLabel_value)
# #     )
# #   
# #   plots[[i]] <- p
# # }
# 
# # Combine plots into a grid or display them individually
# # Assuming you want to display them individually
# for (i in 1:length(plots)) {
#   print(plots[[i]])
# }






# Filter data for maskLabel == "123ab"
filtered_subset <- filtered_data %>%
  filter(maskLabel == "123ab", dataImageContrast == "ForeheadGtAll")

# Create a 3D scatter plot for the filtered subset
plot <- plot_ly(data = filtered_subset, x = ~wordX, y = ~wordY, z = ~wordZ, color = ~group,
                type = "scatter3d", mode = "markers",
                marker = list(size = 5)) %>%
  layout(
    scene = list(
      xaxis = list(title = 'X-axis'),
      yaxis = list(title = 'Y-axis'),
      zaxis = list(title = 'Z-axis')
    ),
    title = "3D Scatter Plot for maskLabel = 123ab and Forehead"
  )

# Display the plot
plot



# # # stats
# Load required libraries
library(car)
library(stats)

library(lme4)
library(lmerTest)

# Filter data for maskLabel == "123ab" and dataImageContrast == "ForeheadGtAll"
filtered_subset <- filtered_data %>%
  filter(maskLabel == "123ab", dataImageContrast == "ForeheadGtAll")

# Ensure 'subject' is a factor if it is not already
filtered_subset$subject <- as.factor(filtered_subset$subLabel)

# Fit linear mixed models
model_wordX <- lmer(wordX ~ maskHemi +  group + (1 | subject), data = filtered_subset)
model_wordY <- lmer(wordY ~ maskHemi + group + (1 | subject), data = filtered_subset)
model_wordZ <- lmer(wordZ ~ maskHemi + group + (1 | subject), data = filtered_subset)

# Summary of the models
summary_wordX <- summary(model_wordX)
summary_wordY <- summary(model_wordY)
summary_wordZ <- summary(model_wordZ)

# Print summaries
print(summary_wordX)
print(summary_wordY)
print(summary_wordZ)




