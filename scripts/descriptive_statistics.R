# =============================================================================
# Descriptive Statistics and Visualization
# =============================================================================
# This script calculates summary statistics and creates visualizations from
# the pharmacy accessibility analysis results
#
# Run this after pharmacy_accessibility_analysis.R
# =============================================================================

library(tidyverse)
library(sf)

# Load Results ----------------------------------------------------------------

# Load a specific scenario (e.g., 300 pharmacies)
results_300 <- readRDS("data/results/accessibility_300_pharmacies.rds")

# Or load all scenarios
pharmacy_scenarios <- seq(50, 700, by = 50)
all_results <- map(
  pharmacy_scenarios,
  \(n) readRDS(sprintf("data/results/accessibility_%d_pharmacies.rds", n)) |>
    mutate(n_pharmacies = n)
) |> 
  bind_rows()


# National Summary Statistics -------------------------------------------------

#' Calculate national accessibility metrics
#' 
#' @param results Results data frame from main analysis
#' @return Summary statistics tibble
calculate_national_summary <- function(results) {
  
  # Straight-line distance statistics
  distance_stats <- results |> 
    summarise(
      mean_distance_km = weighted.mean(distance_km, pop),
      median_distance_km = median(distance_km),
      max_distance_km = max(distance_km),
      n_grid_squares = n(),
      total_population = sum(pop)
    )
  
  # Driving distance coverage
  driving_coverage <- results |> 
    summarise(
      within_5km = sum(pop[within_5km_driving]) / sum(pop) * 100,
      within_10km = sum(pop[within_10km_driving]) / sum(pop) * 100,
      within_20km = sum(pop[within_20km_driving]) / sum(pop) * 100,
      within_30km = sum(pop[within_30km_driving]) / sum(pop) * 100,
      within_40km = sum(pop[within_40km_driving]) / sum(pop) * 100,
      within_50km = sum(pop[within_50km_driving]) / sum(pop) * 100
    )
  
  bind_cols(distance_stats, driving_coverage)
}

national_summary_300 <- calculate_national_summary(results_300)

print(national_summary_300)


# County-Level Statistics -----------------------------------------------------

county_summary_300 <- results_300 |> 
  group_by(lan) |> 
  summarise(
    county = first(lan),
    population = sum(pop),
    mean_distance_km = weighted.mean(distance_km, pop),
    median_distance_km = median(distance_km),
    max_distance_km = max(distance_km),
    pct_within_10km = sum(pop[within_10km_driving]) / sum(pop) * 100,
    pct_within_20km = sum(pop[within_20km_driving]) / sum(pop) * 100
  ) |> 
  arrange(desc(population))

print(county_summary_300)


# Municipal-Level Statistics --------------------------------------------------

municipal_summary_300 <- results_300 |> 
  group_by(kommun) |> 
  summarise(
    municipality = first(kommun),
    population = sum(pop),
    mean_distance_km = weighted.mean(distance_km, pop),
    pct_within_10km = sum(pop[within_10km_driving]) / sum(pop) * 100
  ) |> 
  arrange(desc(population))


# Compare Scenarios -----------------------------------------------------------

# How does accessibility change with number of pharmacies?
scenario_comparison <- all_results |> 
  group_by(n_pharmacies) |> 
  summarise(
    mean_distance_km = weighted.mean(distance_km, pop),
    pct_within_5km = sum(pop[within_5km_driving]) / sum(pop) * 100,
    pct_within_10km = sum(pop[within_10km_driving]) / sum(pop) * 100,
    pct_within_20km = sum(pop[within_20km_driving]) / sum(pop) * 100
  )

print(scenario_comparison)


# Visualizations --------------------------------------------------------------

# 1. Coverage by number of pharmacies
ggplot(scenario_comparison, aes(x = n_pharmacies)) +
  geom_line(aes(y = pct_within_10km, color = "10 km")) +
  geom_line(aes(y = pct_within_20km, color = "20 km")) +
  geom_vline(xintercept = 300, linetype = "dashed", alpha = 0.5) +
  labs(
    title = "Population Coverage by Number of Pharmacies",
    subtitle = "Driving distance accessibility",
    x = "Number of Pharmacies",
    y = "Population Coverage (%)",
    color = "Within"
  ) +
  theme_minimal() +
  annotate(
    "text", 
    x = 300, 
    y = 85, 
    label = "300 pharmacies\n(policy threshold)", 
    hjust = -0.1
  )

ggsave("outputs/coverage_by_pharmacy_count.png", width = 10, height = 6)


# 2. Marginal benefit of additional pharmacies
scenario_comparison <- scenario_comparison |> 
  mutate(
    marginal_benefit = (pct_within_10km - lag(pct_within_10km)) / 
                       (n_pharmacies - lag(n_pharmacies))
  )

ggplot(scenario_comparison, aes(x = n_pharmacies, y = marginal_benefit)) +
  geom_line() +
  geom_point() +
  geom_vline(xintercept = 300, linetype = "dashed", alpha = 0.5) +
  labs(
    title = "Marginal Benefit of Additional Pharmacies",
    subtitle = "Change in coverage per additional 50 pharmacies",
    x = "Number of Pharmacies",
    y = "Marginal Benefit (percentage points)"
  ) +
  theme_minimal()

ggsave("outputs/marginal_benefit.png", width = 10, height = 6)


# 3. Distance distribution histogram
ggplot(results_300, aes(x = distance_km, weight = pop)) +
  geom_histogram(binwidth = 5, fill = "steelblue", alpha = 0.7) +
  geom_vline(xintercept = 10, linetype = "dashed", color = "red") +
  labs(
    title = "Distribution of Distances to Nearest Pharmacy (300 pharmacies)",
    subtitle = "Population-weighted",
    x = "Distance to Nearest Pharmacy (km)",
    y = "Population"
  ) +
  theme_minimal()

ggsave("outputs/distance_distribution.png", width = 10, height = 6)


# 4. Map of accessibility (requires spatial data)
# This would create a map showing areas by accessibility
# Uncomment if you have the spatial data ready

# results_300_sf <- results_300 |> 
#   st_as_sf(crs = 4326, coords = c("long_grid", "lat_grid"))
# 
# ggplot() +
#   geom_sf(data = results_300_sf, aes(color = within_10km_driving)) +
#   scale_color_manual(
#     values = c("TRUE" = "green", "FALSE" = "red"),
#     labels = c("TRUE" = "Within 10km", "FALSE" = "Beyond 10km")
#   ) +
#   labs(
#     title = "Pharmacy Accessibility in Sweden (300 pharmacies)",
#     subtitle = "10km driving distance threshold",
#     color = "Accessibility"
#   ) +
#   theme_minimal()


# Export Summary Tables -------------------------------------------------------

write_csv(
  scenario_comparison, 
  "outputs/scenario_comparison.csv"
)

write_csv(
  county_summary_300, 
  "outputs/county_summary_300_pharmacies.csv"
)

write_csv(
  municipal_summary_300,
  "outputs/municipal_summary_300_pharmacies.csv"
)

message("Descriptive statistics calculated and saved!")
