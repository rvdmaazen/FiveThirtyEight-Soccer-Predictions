library(ggplot2)
library(dplyr)
library(scales)
library(ggrepel)
library(ggalt)
library(data.table)
library(directlabels)
library(extrafont)
library(gridExtra)

# Load fonts
loadfonts(device = "win", quiet = TRUE)

competition = "premier-league"
season = "2018-2019"

data <- read.csv(paste("../data/", season, "/", competition, ".csv", sep=""))
data$last_updated <- as.Date(data$last_updated)

######################
# Preprocessing data #
######################

# Select data only up to last match day
final_day <- as.Date("2019-05-12")
data <- data %>%
  filter(last_updated <= final_day)

# Calculate predicted points
data$predicted_points <- (3 * data$wins) + data$ties

######################
# Data visualization #
######################

# Create custom theme
opta_theme <- function() {
  theme_minimal() +
    theme(
      panel.background = element_rect(fill = "#141622", colour = "#141622"),
      plot.background = element_rect(fill = "#141622"),
      panel.grid.major = element_line(colour = "#3f3e44"),
      panel.grid.minor = element_line(colour = "#3f3e44"),
      axis.line.x = element_line(colour = "#ffffff"),
      axis.line.y = element_line(colour = "#ffffff"),
      text = element_text(family = "Century Gothic", colour = "#ffffff"),
      axis.text = element_text(family = "Century Gothic", colour = "#ffffff")
    )
}
update_geom_defaults("text", list(colour = "#ffffff", family = "Century Gothic"))

save_table <- function(filename, data_table) {
  require(gridExtra)
  pdf(filename, height = 7, width = 15)
  grid.table(data_table, rows = NULL)
  dev.off()
}

# Set theme
theme_set(opta_theme())

# Predicted final standing
pred_final_standing <- data %>%
  filter(last_updated == tail(unique(last_updated), n=1)) %>%
  select(name, predicted_points, wins, ties, losses, goal_diff, goals_scored, goals_against) %>%
  arrange(desc(predicted_points))
pred_final_standing[,-1] <- round(pred_final_standing[,-1], 2)
pred_final_standing %>%
  rename("Team Name" = name, "Predicted Points" = predicted_points, "Wins" = wins, "Ties" = ties,
         "Losses" = losses, "Goal Difference" = goal_diff, "Goals Scored" = goals_scored, 
         "Goals Conceded" = goals_against) %>%
  save_table("../images/predicted_final_standing.pdf", .)

# Actual final standing
final_standing <- data %>%
  filter(last_updated == head(unique(last_updated), n=1)) %>%
  select(name, current_points, current_wins, current_ties, current_losses, goal_diff, 
         goals_scored, goals_against) %>%
  arrange(desc(current_points),desc(goal_diff), desc(goals_scored)) %>%
  distinct() %>%
  mutate(final_place = frank(., -current_points, -goal_diff, -goals_scored)) 
final_standing[0:8] %>%
  rename("Team Name" = name, "Points" = current_points, "Wins" = current_wins,
         "Ties" = current_ties, "Losses" = current_losses, "Goal Difference" = goal_diff,
         "Goals Scored" = goals_scored, "Goals Conceded" = goals_against) %>%
  save_table("../images/actual_final_standing.pdf", .)

# Relative performance
relative_performance <- final_standing %>%
  mutate(current_points = current_points / pred_final_standing$predicted_points, 
         current_wins = current_wins / pred_final_standing$wins, 
         current_ties = current_ties / pred_final_standing$ties, 
         current_losses = current_losses / pred_final_standing$losses, 
         goal_diff = goal_diff / pred_final_standing$goal_diff, 
         goals_scored = goals_scored / pred_final_standing$goals_scored, 
         goals_against = goals_against / pred_final_standing$goals_against) %>%
  arrange(final_place)
relative_performance[,-1] <- round(relative_performance[,-1], 2)
relative_performance[0:8] %>%
  rename("Team Name" = name, "Points" = current_points, "Wins" = current_wins, "Ties" = current_ties,
         "Losses" = current_losses, "Goal Difference" = goal_diff, "Goals Scored" = goals_scored,
         "Goals Conceded" = goals_against) %>%
  save_table("../images/relative_performance.pdf", .)

p <- final_standing %>%
  mutate(relative_points = round(current_points / pred_final_standing$predicted_points, 2),
         performance = ifelse(relative_points >= 1, "above", "below")) %>%
  arrange(-final_place) %>%
  # Change levels of factor variable to change y-axis ordering
  mutate(name = factor(name, levels=.$name)) %>%
  ggplot(aes(x=relative_points, y=name, label=relative_points, 2)) +
  geom_point(stat = "identity", aes(col = performance, alpha = 0.7), size = 9) +
  scale_color_manual(labels = c("Better than predicted", "Worse than predicted"),
                     values = c("above"="#007000", "below"="#d2222d")) +
  geom_text(colour = "#ffffff", size = 3.3) +
  xlim(0.4, 1.4) +
  guides(color = FALSE) +
  labs(x = "Relative number of points",
       y = "Team",
       title = "Relative performance",
       subtitle = "Premier League | 2018/19",
       caption = "Number of points relative to the predicted number of points 
                  by the FiveThirtyEight SPI model \nY-axis ordered by place in final standing") +
  theme(legend.position = "none")
ggsave(filename = "relative_performance.png", plot = p, device = "png", path = "../images/", 
         width = 24, height = 13.5, units = "cm", dpi= "retina", scale = 1.2)

# Title race
top_teams <- head(final_standing$name, n=5)

## Number of points
p <- data %>%
  filter(name %in% top_teams) %>%
  ggplot(aes(x = last_updated, y = current_points, color = name)) + 
    geom_line(size = 1, alpha = 0.7) +
    labs(x = "Date", 
         y = "Points", 
         color = "Team name",
         title = "Number of points throughout the season for the top 5 teams",
         subtitle = "Premier League | 2018/19") +
  geom_dl(aes(label = name), method = list(dl.trans(x = x + 0.2), 
                                           fontfamily = "Century Gothic", "last.bumpup")) +
  guides(color = FALSE) +
  expand_limits(x = head(data$last_updated, 1) + 35)
ggsave(filename = "points_total_top.png", plot = p, device = "png", path = "../images/", 
       width = 24, height = 13.5, units = "cm", dpi= "retina", scale = 1.2)

## Chance to win the league
p <- data %>%
  filter(name %in% top_teams) %>%
  ggplot(aes(x = last_updated, y = win_league * 100, color = name)) + 
  geom_line(size = 1) +
  labs(x = "Date", 
       y = "Chance to win the league (%)", 
       color = "Team name",
       title = "Chance to win the league throughout the season for the top 5 teams",
       subtitle = "Premier League | 2018/19",
       caption = "Percentage chance to win the league as predicted by the FiveThirtyEight SPI model") +
  geom_dl(aes(label = name), method = list(dl.trans(x = x - 0.2), 
                                           fontfamily = "Century Gothic", "first.bumpup")) +
  guides(color = FALSE) +
  expand_limits(x = tail(data$last_updated, 1) - 45)
ggsave(filename = "chance_to_win.png", plot = p, device = "png", path = "../images/", 
       width = 24, height = 13.5, units = "cm", dpi= "retina", scale = 1.2)

# Relegation battle
bottom_teams <- tail(final_standing$name, 5)

## Number of points
p <- data %>%
  filter(name %in% bottom_teams) %>%
  ggplot(aes(x = last_updated, y = current_points, color = name)) + 
  geom_line(size = 1) +
  labs(x = "Date", 
       y = "Points", 
       color = "Team name",
       title = "Number of points throughout the season for the bottom 5 teams",
       subtitle = "Premier League | 2018/19") +
  geom_dl(aes(label = name), method = list(dl.trans(x = x + 0.2), 
                                           fontfamily = "Century Gothic", "last.bumpup")) +
  guides(color = FALSE) +
  expand_limits(x = head(data$last_updated, 1) + 45)
ggsave(filename = "points_total_bottom.png", plot = p, device = "png", path = "../images/", 
       width = 24, height = 13.5, units = "cm", dpi= "retina", scale = 1.4)

## Chance to get relegated
p <- data %>%
  filter(name %in% bottom_teams) %>%
  ggplot(aes(x = last_updated, y = relegated * 100, color = name)) + 
  geom_line(size = 1) +
  labs(x = "Date", 
       y = "Chance to get relegated (%)", 
       color = "Team name",
       title= "Chance to get relegated throughout the season for the bottom 5 teams",
       subtitle = "Premier League | 2018/19",
       caption = "Percentage chance to get relegated as predicted by the FiveThirtyEight SPI model") +
  geom_dl(aes(label = name), method = list(dl.trans(x = x - 0.2), 
                                           fontfamily = "Century Gothic", "first.bumpup")) +
  expand_limits(x = tail(data$last_updated, 1) - 45) +
  theme(legend.position = "none")
ggsave(filename = "chance_to_relegate.png", plot = p, device = "png", path = "../images/", 
       width = 24, height = 13.5, units = "cm", dpi= "retina", scale = 1.4)

# Team scores
# Top 5 teams (by average SPI team rating over the season)
top_5_team <- data %>%
  group_by(name) %>%
  summarize(average_team_score = round(mean(global_rating), 2)) %>%
  arrange(desc(average_team_score)) %>%
  top_n(5, average_team_score) %>%
  select(name, average_team_score) %>%
  rename("Team Name" = name, "Average Team Score" = average_team_score)
save_table("../images/top_5_team.pdf", top_5_team)

# Top 5 defenses (by average defense score over the season)
top_5_def <- data %>%
  group_by(name) %>%
  summarize(average_def_score = round(mean(global_d), 2)) %>%
  arrange(average_def_score) %>%
  top_n(-5, average_def_score) %>%
  select(name, average_def_score) %>%
  rename("Team Name" = name, "Average Defensive Score" = average_def_score)
save_table("../images/top_5_def.pdf", top_5_def)

# Top 5 offenses (by average defense score over the season)
top_5_off <- data %>%
  group_by(name) %>%
  summarize(average_off_score = round(mean(global_o), 2)) %>%
  arrange(desc(average_off_score)) %>%
  top_n(5, average_off_score) %>%
  select(name, average_off_score) %>%
  rename("Team Name" = name, "Average Offensive Score" = average_off_score)
save_table("../images/top_5_off.pdf", top_5_off)

# Global ratings
p <- data %>%
  group_by(name) %>%
  summarize(average_off_score = mean(global_o),
            average_def_score = mean(global_d),
            average_team_score = mean(global_rating)) %>%
  ggplot(aes(x = average_def_score, y = average_off_score, size = average_team_score, 
             colour = name, label = name)) +
  geom_point() +
  geom_text_repel(size = 3, point.padding = 0.3, seed = 123, family = "Century Gothic") +
  scale_x_reverse() +
  scale_color_discrete(guide = FALSE) +
  guides(size = guide_legend(override.aes = list(colour = "#ffffff"))) +
  labs(x = "Defensive score\n(lower is better)",
       y = "Offensive score\n(higher is better)",
       size = "Average team score\n(SPI rating)",
       title = "Global team scores",
       subtitle = "Premier League | 2018/19",
       caption = "Average global score over the whole season as calculated by the FiveThirtyEight SPI model")
ggsave(filename = "global_spi_scores.png", plot = p, device = "png", path = "../images/", 
       width = 24, height = 13.5, units = "cm", dpi= "retina", scale = 1.2)

# Domestic ratings
p <- data %>%
  group_by(name) %>%
  summarize(average_off_score = mean(o_rating),
            average_def_score = mean(d_rating),
            average_team_score = mean(global_rating)) %>%
  ggplot(aes(x = average_def_score, y = average_off_score, size = average_team_score, 
             colour = name, label = name)) +
  geom_point() +
  geom_text_repel(size = 3, point.padding = 0.3, seed = 123, family = "Century Gothic") +
  scale_x_reverse() +
  scale_color_discrete(guide = FALSE) +
  guides(size = guide_legend(override.aes = list(colour = "#ffffff"))) +
  labs(x = "Defensive score\n(lower is better)",
       y = "Offensive score\n(higher is better)",
       size = "Average team score\n(SPI rating)",
       title = "Domestic team scores",
       caption = "Average domestic team score over the whole season as calculated by the FiveThirtyEight SPI model")
ggsave(filename = "domestic_spi_scores.png", plot = p, device = "png", path = "../images/", 
       width = 24, height = 13.5, units = "cm", dpi= "retina", scale = 1.2)

# Positions held during the season
# Remove first weeks since it skews results 
# (no points have been earned and no meaningful rank can be assigned)
p <- data %>%
  #filter(last_updated != tail(unique(data$last_updated), 1)) %>%
  filter(last_updated >= as.Date("2018-08-12")) %>%
  group_by(last_updated) %>%
  arrange(last_updated, desc(current_points, goal_diff, goals_scored), name) %>%
  mutate(place = dense_rank(desc(current_points, goal_diff, goals_scored))) %>%
  group_by(name) %>%
  summarize(highest_place = min(place),
            lowest_place = max(place)) %>%
  ungroup() %>%
  mutate(name = factor(name, levels=rev(final_standing$name))) %>%
  ggplot(aes(x=lowest_place, xend=highest_place, y=name)) + 
  geom_dumbbell(size = 1.5, color = "#34AA91", colour_x = "#8AB833", size_x = 5, 
                colour_xend = "#0989B1", size_xend = 5, alpha = 0.7) +
  labs(x = "Place",
       y = "Team name",
       title = "Places held throughout the season",
       subtitle = "Premier League 2018-2019",
       caption = "Teams are ordered by their place in the final ranking. First gameday is excluded.")
ggsave(filename = "places_throughout_season.png", plot = p, device = "png", path = "../images/", 
       width = 24, height = 13.5, units = "cm", dpi= "retina", scale = 1.2)