rm(list = ls()) #clean console
library(ggplot2)
library(plotly)
library(dplyr)
library(Rmisc)

# CoG euclidean distances
path_results <-
  paste0("/Volumes/extreme/Cerens_files/fMRI/MoebiusProject_backup/",
    "MoebiusProject/derivatives/cpp_spm-roi/group"
  )

datam <- read.csv(paste(path_results,
                        paste0("mototopyCoGDistance_unthreshhcpex_",
                               "label4_202409251138.csv"),
                        sep = "/"))
datas <- read.csv(paste(path_results,
                        paste0("somatotopyCoGDistance_unthreshhcpex_",
                               "202407291232.csv"), sep = "/"))


# combine to filter the whole data once
datam$Exp <- "moto"
datas$Exp <- "somato"
data <- rbind(datam, datas)
head(data)

data <- data %>%
  filter(!is.nan(Distance))

# now separate
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
custom_pair_order <- c(
  "Lips-Tongue", "Forehead-Lips", "Forehead-Tongue", "Forehead-Hand",
  "Hand-Lips", "Hand-Tongue", "Foot-Hand", "Foot-Forehead",
  "Foot-Lips", "Foot-Tongue"
)
df$pair_order_dist <- match(df$Pair, custom_pair_order)
df$Pair <- factor(df$Pair, levels = custom_pair_order)

df2$pair_order_dist <- match(df2$Pair, custom_pair_order)
df2$Pair <- factor(df2$Pair, levels = custom_pair_order)

width_dist_btwn_groups <- 0.8
errorbar_colors <- c("ctrl" = "#606060ff", "mbs" = "#448c6dff")

bar_p <- ggplot(df, aes(x = Pair, y = Distance, fill = Group)) +
  geom_bar(
    stat = "identity",
    position = position_dodge(width = width_dist_btwn_groups),
    width = 0.8
  ) +
  geom_errorbar(
    aes(ymin = Distance - se, ymax = Distance + se, color = Group),
    width = 0.2,
    position = position_dodge(width = width_dist_btwn_groups),
    size = 1
  ) +
  geom_jitter(
    data = datam,
    aes(x = Pair, y = Distance, color = Group, fill = Group),
    position = position_jitterdodge(
      jitter.width = 0.2,
      dodge.width = width_dist_btwn_groups
    ),
    shape = 21, size = 2, alpha = 0.8
  ) +
  facet_wrap(Hemi ~ .) +
  ylim(0, 62) +
  labs(
    x = "Body Part pairs",
    y = "CoG Euc Distance (mm)",
    fill = "Groups",
    color = "Groups"
  ) +
  theme_minimal() +
  theme(
    text = element_text(family = "Avenir", color = "black"),
    panel.spacing = unit(2, "lines"),
    axis.title.x = element_text(size = 22, face = "bold"),
    axis.title.y = element_text(size = 22, face = "bold"),
    axis.text.x = element_text(size = 20, # angle = 45,
                               hjust = 1, color = "black"),
    axis.text.y = element_text(size = 20, color = "black"),
    legend.title = element_text(size = 22),
    legend.text = element_text(size = 20),
    strip.placement = "inside",
    strip.text = element_text(size = 22, hjust = 0.5),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    legend.position = "top"
  ) +
  scale_fill_manual(values = c("ctrl" = "#7b7979", "mbs" = "#63c599")) +
  scale_color_manual(values = errorbar_colors) +
  coord_flip()
print(bar_p)

filename <- paste(
  path_results,
  "/Flipped_HorizontalCOGDistance_barPlot_Averaged_Ordered_mototopy.pdf", sep = ""
)
ggsave(filename,
       plot = bar_p, width = 18, height = 8, units = "in", dpi = 300)

# filename <- paste(
#   path_results,
#   "/VerticalCOGDistance_barPlot_Averaged_Ordered_mototopy.pdf", sep = ""
# )
# 
# ggsave(filename, plot = bar_p, width = 18, height = 12, units = "in", dpi = 300)




# somatototopy
bar_p <- ggplot(df2, aes(x = Pair, y = Distance, fill = Group)) +
  geom_bar(
    stat = "identity",
    position = position_dodge(width = width_dist_btwn_groups),
    width = 0.8
  ) +
  geom_errorbar(
    aes(ymin = Distance - se, ymax = Distance + se, color = Group),
    width = 0.2,
    position = position_dodge(width = width_dist_btwn_groups),
    size = 1
  ) +
  geom_jitter(
    data = datam,
    aes(x = Pair, y = Distance, color = Group, fill = Group),
    position = position_jitterdodge(
      jitter.width = 0.2,
      dodge.width = width_dist_btwn_groups
    ),
    shape = 21, size = 2, alpha = 0.8
  ) +
  facet_wrap(Hemi ~ .) +
  ylim(0, 62) +
  labs(
    x = "Body Part pairs",
    y = "CoG Euc Distance (mm)",
    fill = "Groups",
    color = "Groups"
  ) +
  theme_minimal() +
  theme(
    text = element_text(family = "Avenir", color = "black"),
    panel.spacing = unit(2, "lines"),
    axis.title.x = element_text(size = 22, face = "bold"),
    axis.title.y = element_text(size = 22, face = "bold"),
    axis.text.x = element_text(size = 20, # angle = 45,
                               hjust = 1, color = "black"),
    axis.text.y = element_text(size = 20, color = "black"),
    legend.title = element_text(size = 22),
    legend.text = element_text(size = 20),
    strip.placement = "inside",
    strip.text = element_text(size = 22, hjust = 0.5),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    legend.position = "top"
  ) +
  scale_fill_manual(values = c("ctrl" = "#7b7979", "mbs" = "#63c599")) +
  scale_color_manual(values = errorbar_colors) +
  coord_flip()
print(bar_p)

filename <- paste(
  path_results,
  "/Flipped_HorizontalCOGDistance_barPlot_Averaged_Ordered_somatotopy.pdf", sep = ""
)
ggsave(filename,
       plot = bar_p, width = 18, height = 8, units = "in", dpi = 300)

# filename <- paste(
#   path_results,
#   "/VerticalCOGDistance_barPlot_Averaged_Ordered_mototopy.pdf", sep = ""
# )
# 
# ggsave(filename, plot = bar_p, width = 18, height = 12, units = "in", dpi = 300)
