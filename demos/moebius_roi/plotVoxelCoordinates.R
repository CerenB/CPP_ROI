install.packages("ggplot2")
install.packages("rlang")
install.packages("plotly")
install.packages("dplyr")

rm(list=ls()) #clean console
library(ggplot2)
library(plotly)
library(dplyr)
library(Rmisc)

pathResults <- '/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-roi/group/'

########
data <- read.csv(paste(pathResults, 'somatotopyPeakVoxels_unthreshTmapshcpex_202407291222.csv', sep ='/'))

# mototopy in Area 4 
# mototopyPeakVoxels_unthreshTmapshcpex_202409251121

# somatotopyPeakVoxels_unthreshTmapshcpex_202407291222
# mototopyPeakVoxels_unthreshTmapshcpex_202407301611

# mototopyPeakVoxels_hcpex_202407242314
# somatotopyPeakVoxels_hcpex_202407172248.csv - old
# somatotopyPeakVoxels_hcpex_202407242235

# Use the dplyr filter function to omit rows where coordinateX is 0
#filtered_data <- data %>% filter(!is.na(tValue))

# Add a new 'group' column based on the 'subLabel' column
filtered_data <- data %>%
  mutate(group = ifelse(grepl("mbs", subLabel), "mbs", "ctrl"))

# Ensure the required columns are present
filtered_data <- filtered_data %>%
  select(subLabel, maskLabel, maskHemi, dataImageContrast,
         worldCoordX, worldCoordY, worldCoordZ, tValue, group)

# Convert maskLabel, maskHemi, and group to factors
filtered_data$maskLabel <- as.factor(filtered_data$maskLabel)
filtered_data$maskHemi <- as.factor(filtered_data$maskHemi)
filtered_data$group <- as.factor(filtered_data$group)
filtered_data$dataImageContrast <- as.factor(filtered_data$dataImageContrast)




####### new plot - 25th July 

# Assuming filtered_data is your data frame
# Transform the data and assign to plotData
plotData <- filtered_data %>%
  mutate(
    worldCoordY =  -worldCoordY,
    combined_facet = interaction(maskHemi, maskLabel, dataImageContrast)
  )

# Custom labels with newline characters
facet_labels <- list(
  maskHemi = c("L" = "L", "R" = "R"),
  dataImageContrast = c("FootGtAll" = "Foot", "ForeheadGtAll" = "Forehead", 
                        "HandGtAll" = "Hand", "LipsGtAll" = "Lips", 
                        "TongueGtAll" = "Tongue") 
)
# Precompute the combined facet labels with newline characters
plotData <- plotData %>%
  mutate(combined_facet = paste(facet_labels$maskHemi[maskHemi], facet_labels$dataImageContrast[dataImageContrast])) # , sep = "\n"

# Verify unique levels of combined_facet to ensure proper facets
unique_facet_levels <- unique(plotData$combined_facet)
print(unique_facet_levels)

# Ensure combined_facet is a factor with the correct order and labels
plotData$combined_facet <- factor(
  plotData$combined_facet,
  levels = unique_facet_levels
)

# Create the plot with custom labels and facet layout
p <- ggplot(plotData, aes(x = worldCoordX, y = worldCoordY, z = worldCoordZ, color = dataImageContrast, shape = group)) +
  geom_point(size = 3) +
  facet_wrap(~ combined_facet, nrow = 2, ncol = 5) +
  theme_bw() +
  labs(
    x = "X-axis",
    y = "Y-axis",
    color = "Body parts",
    shape = "Group"
  ) +
  scale_color_discrete(labels = c("Foot", "Forehead", "Hand", "Lips", "Tongue")) +
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(size = 10, face = "bold"),
    strip.text = element_text(size = 12, face = "bold"),
    axis.title = element_text(size = 12, face = "bold")
  )

# Convert ggplot2 plot to plotly object with custom tooltips
plotly_plot <- ggplotly(p, tooltip = c("worldCoordX", "worldCoordY", "worldCoordZ", "group", "dataImageContrast", "maskHemi", "maskLabel"))

# Display the plotly plot
plotly_plot





# 3d plots
# Create the 3D scatter plot using plotly
plotly_plot <- plot_ly(plotData, x = ~worldCoordX, y = ~worldCoordY, z = ~worldCoordZ, 
                       color = ~dataImageContrast, symbol = ~group, 
                       symbols = c("circle", "square"), # Adjust symbol types as needed
                       type = 'scatter3d', mode = 'markers', 
                       marker = list(size = 5)) %>%
  layout(
    scene = list(
      xaxis = list(title = "X-axis"),
      yaxis = list(title = "Y-axis"),
      zaxis = list(title = "Z-axis")
    ),
    legend = list(title = list(text = "Body Parts"))
  )

# Display the plotly plot
plotly_plot


# going back to 2D plot - september 25th
# Assuming you want to rename 'dataImageContrast' values with shorter labels
plotData <- plotData %>%
  mutate(dataImageContrast_short = recode(dataImageContrast,
                                          "ForeheadGtAll" = "Forehead",
                                          "FootGtAll" = "Toes",  
                                          "HandGtAll" = "Thumbs",
                                          "LipsGtAll" = "Lips",
                                          "TongueGtAll" = "Tongue"))

# 2D scatter plot
plotly_plot <- plot_ly(plotData, 
                       x = ~jitter(worldCoordX, amount = 0.1),  # Jitter on X-axis
                       y = ~jitter(worldCoordZ, amount = 0.1),  # Jitter on Y-axis
                       color = ~dataImageContrast_short, 
                       symbol = ~group, 
                       symbols = c("circle", "square"),  # Adjust symbol types as needed
                       type = 'scatter', 
                       mode = 'markers', 
                       marker = list(size = 8)) %>%
  layout(
    xaxis = list(
      title = list(
        text = "X-axis",
        font = list(size = 24)  # Font size for X-axis label
      ),
      range = c(-90, 90), 
      tickfont = list(size = 18)  # Font size for X-axis ticks
    ),
    yaxis = list(
      title = list(
        text = "Y-axis",
        font = list(size = 24)  # Font size for Y-axis label
      ),
      range = c(10, 80), 
      tickfont = list(size = 18)  # Font size for Y-axis ticks
    ),
    legend = list(title = list(text = "Body Parts"))
  )

# Display the plotly plot
plotly_plot







# with ggplot instead
plotData <- plotData %>%
  mutate(dataImageContrast_short = recode(dataImageContrast,
                                          "ForeheadGtAll" = "Forehead",
                                          "FootGtAll" = "Toes",  
                                          "HandGtAll" = "Thumbs",
                                          "LipsGtAll" = "Lips",
                                          "TongueGtAll" = "Tongue"))

# Create the 2D scatter plot with jitter using ggplot2
ggplot_plot <- ggplot(plotData, aes(x = jitter(worldCoordX, amount = 0.1), 
                                    y = jitter(worldCoordZ, amount = 0.1), 
                                    color = dataImageContrast_short, 
                                    shape = group)) +
  geom_point(size = 4) +  # Adjust point size
  scale_shape_manual(values = c(16, 17)) +  # Use different shapes for groups (circle and square)
  labs(
    title = "2D Scatter Plot",
    x = "X-axis",
    y = "Z-axis",
    color = "Body Parts",  # Legend title for colors
    shape = "Group"        # Legend title for shapes
  ) +
  theme_bw() +
  theme(
    axis.title.x = element_text(size = 24),  # Font size for X-axis label
    axis.title.y = element_text(size = 24),  # Font size for Y-axis label
    axis.text.x = element_text(size = 18),   # Font size for X-axis ticks
    axis.text.y = element_text(size = 18),   # Font size for Y-axis ticks
    legend.title = element_text(size = 20),  # Font size for legend titles
    legend.text = element_text(size = 16)    # Font size for legend items
  ) +
  coord_cartesian(xlim = c(-90, 90), ylim = c(10, 80))  # Set axis limits

ggplot_plot
# Save the plot as a PDF
filename <- paste(pathResults, "Somatotopy_label123ab_peakVoxels_scatter_plot.pdf", sep = '')
ggsave(filename, plot = ggplot_plot, width = 18, height = 8, units = "in", dpi = 300)


############### perform some stats on tValue

# Define the dataImageContrast conditions
conditions <- c("ForeheadGtAll", "TongueGtAll", "LipsGtAll", "HandGtAll", "FootGtAll")

# Initialize a list to store the t-test results
t_test_results <- list()

# Loop through each condition and perform the t-test
for (condition in conditions) {
  # Filter the data for the current condition
  condition_data <- filtered_data %>%
    filter(dataImageContrast == !!condition)
  
  # Perform the t-test
  t_test_result <- t.test(
    tValue ~ group,
    data = condition_data,
    var.equal = TRUE  # Assuming equal variances, set to FALSE if unequal variances are assumed
  )
  
  # Store the result in the list
  t_test_results[[condition]] <- t_test_result
}

# Print the results
for (condition in conditions) {
  cat("\nT-test results for", condition, ":\n")
  print(t_test_results[[condition]])
}




# nothing is significant for somototopy
# mototopy forehead is and tongue is p =0.055
# somatotopy unthresholded nothing sig.
# momotopy unthresholded nothing sig.


df <- summarySE(data = filtered_data, 
                groupvars=c('dataImageContrast','group', 'maskLabel','maskHemi'),
                measurevar='tValue', na.rm = TRUE)
df

p <- ggplot(filtered_data, aes(x = dataImageContrast, y = tValue, color = group)) +
  geom_jitter(position = position_dodge(0.5), size = 2) +
  geom_errorbar(data = df, aes(ymin = tValue-se, ymax = tValue+se), 
                width = 0.2, position = position_dodge(0.5), color = "black") +
  geom_point(data = df, aes(y = tValue), position = position_dodge(0.5), size = 3, shape = 18, color = "black") +
  facet_grid(. ~ maskHemi) +  # Facet by maskHemi
  theme_bw() +
  labs(
    title = "Mean and Standard Deviation of tValues by Group and Hemisphere",
    x = "BodyParts",
    y = "Peak Coordinate tValue",
    color = "Group"
  )

# Display the plot
print(p)







