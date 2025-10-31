# =============================================================================
# Simplified Example: Understanding the MCLP Approach
# =============================================================================
# This is a toy example to demonstrate the Maximum Coverage Location Problem
# concept without requiring the full Swedish pharmacy dataset.
#
# Great for blog posts, teaching, or understanding the methodology
# =============================================================================

library(tidyverse)

# Create Toy Dataset ----------------------------------------------------------

# Imagine a small region with 20 populated locations
set.seed(42)
population_points <- tibble(
  id = 1:20,
  lat = runif(20, 55, 60),
  long = runif(20, 12, 18),
  population = sample(100:5000, 20, replace = TRUE)
)

# 10 possible pharmacy locations
pharmacy_candidates <- tibble(
  pharmacy_id = 1:10,
  lat = runif(10, 55, 60),
  long = runif(10, 12, 18)
)


# Simple Distance Function ----------------------------------------------------

#' Calculate Euclidean distance between two points
euclidean_distance <- function(lat1, long1, lat2, long2) {
  sqrt((lat1 - lat2)^2 + (long1 - long2)^2) * 111  # Rough km conversion
}


# Manual MCLP Implementation --------------------------------------------------

#' Greedy algorithm for MCLP
#' 
#' This is a simplified version to demonstrate the concept.
#' The real analysis uses the optimized maxcovr package.
#' 
#' @param population Population points with coordinates
#' @param candidates Candidate pharmacy locations
#' @param n_facilities Number of pharmacies to select
#' @param max_distance Maximum coverage distance (km)
#' @return Selected pharmacy IDs
greedy_mclp <- function(population, candidates, n_facilities, max_distance) {
  
  selected <- numeric(0)
  covered_pop <- numeric(nrow(population))
  
  for (i in 1:n_facilities) {
    
    best_coverage <- 0
    best_candidate <- NA
    
    # For each remaining candidate
    for (candidate_id in setdiff(candidates$pharmacy_id, selected)) {
      
      # Calculate which population points this pharmacy would cover
      candidate_info <- candidates |> filter(pharmacy_id == candidate_id)
      
      distances <- population |> 
        mutate(
          dist_to_candidate = euclidean_distance(
            lat, long, 
            candidate_info$lat, candidate_info$long
          ),
          newly_covered = (dist_to_candidate <= max_distance) & (covered_pop == 0)
        )
      
      # Calculate newly covered population
      new_coverage <- sum(distances$population[distances$newly_covered])
      
      # Is this the best candidate so far?
      if (new_coverage > best_coverage) {
        best_coverage <- new_coverage
        best_candidate <- candidate_id
      }
    }
    
    # Select the best candidate
    selected <- c(selected, best_candidate)
    
    # Update coverage
    best_info <- candidates |> filter(pharmacy_id == best_candidate)
    population <- population |> 
      mutate(
        dist_to_new = euclidean_distance(
          lat, long,
          best_info$lat, best_info$long
        ),
        is_covered = (dist_to_new <= max_distance)
      )
    covered_pop <- covered_pop | population$is_covered
    
    message(sprintf("Selected pharmacy %d: covers %.0f new people (%.1f%% total)", 
                    best_candidate, best_coverage, 
                    sum(population$population[covered_pop]) / sum(population$population) * 100))
  }
  
  selected
}


# Run the Example -------------------------------------------------------------

# Select 3 pharmacies with 200km coverage radius
selected_pharmacies <- greedy_mclp(
  population_points, 
  pharmacy_candidates, 
  n_facilities = 3,
  max_distance = 200
)

cat("\nOptimal pharmacy locations:", selected_pharmacies, "\n")


# Visualize Results -----------------------------------------------------------

# Calculate coverage for visualization
results <- population_points
for (pharm_id in selected_pharmacies) {
  pharm_info <- pharmacy_candidates |> filter(pharmacy_id == pharm_id)
  
  results <- results |> 
    mutate(
      !!paste0("dist_to_", pharm_id) := euclidean_distance(
        lat, long, pharm_info$lat, pharm_info$long
      )
    )
}

# Find nearest pharmacy for each population point
results <- results |> 
  rowwise() |> 
  mutate(
    nearest_pharmacy = selected_pharmacies[which.min(c_across(starts_with("dist_to")))],
    distance_to_nearest = min(c_across(starts_with("dist_to")))
  ) |> 
  ungroup() |> 
  mutate(is_covered = distance_to_nearest <= 200)


# Create visualization
ggplot() +
  # Population points
  geom_point(
    data = results,
    aes(x = long, y = lat, size = population, color = is_covered),
    alpha = 0.6
  ) +
  # Selected pharmacies
  geom_point(
    data = pharmacy_candidates |> filter(pharmacy_id %in% selected_pharmacies),
    aes(x = long, y = lat),
    color = "red",
    size = 5,
    shape = 18
  ) +
  # Unselected pharmacy candidates
  geom_point(
    data = pharmacy_candidates |> filter(!pharmacy_id %in% selected_pharmacies),
    aes(x = long, y = lat),
    color = "gray",
    size = 3,
    shape = 4
  ) +
  # Coverage circles (approximate)
  ggforce::geom_circle(
    data = pharmacy_candidates |> filter(pharmacy_id %in% selected_pharmacies),
    aes(x0 = long, y0 = lat, r = 200/111),  # Rough degree conversion
    alpha = 0.1,
    fill = "red"
  ) +
  scale_color_manual(
    values = c("TRUE" = "darkgreen", "FALSE" = "orange"),
    labels = c("TRUE" = "Covered", "FALSE" = "Not covered")
  ) +
  scale_size_continuous(range = c(2, 10)) +
  labs(
    title = "Maximum Coverage Location Problem (MCLP) - Toy Example",
    subtitle = "3 pharmacies selected to maximize population coverage within 200km",
    x = "Longitude",
    y = "Latitude",
    color = "Coverage Status",
    size = "Population"
  ) +
  theme_minimal() +
  coord_fixed()

ggsave("outputs/mclp_toy_example.png", width = 10, height = 8)


# Summary Statistics ----------------------------------------------------------

cat("\n=== Coverage Summary ===\n")
cat(sprintf("Total population: %d\n", sum(results$population)))
cat(sprintf("Covered population: %d (%.1f%%)\n", 
            sum(results$population[results$is_covered]),
            sum(results$population[results$is_covered]) / sum(results$population) * 100))
cat(sprintf("Mean distance to pharmacy: %.1f km\n", 
            weighted.mean(results$distance_to_nearest, results$population)))
cat(sprintf("Median distance to pharmacy: %.1f km\n", 
            median(results$distance_to_nearest)))
cat(sprintf("Max distance to pharmacy: %.1f km\n", 
            max(results$distance_to_nearest)))


# Compare with Random Selection -----------------------------------------------

# What if we just picked 3 pharmacies randomly?
set.seed(123)
random_selection <- sample(pharmacy_candidates$pharmacy_id, 3)

results_random <- population_points
for (pharm_id in random_selection) {
  pharm_info <- pharmacy_candidates |> filter(pharmacy_id == pharm_id)
  
  results_random <- results_random |> 
    mutate(
      !!paste0("dist_to_", pharm_id) := euclidean_distance(
        lat, long, pharm_info$lat, pharm_info$long
      )
    )
}

results_random <- results_random |> 
  rowwise() |> 
  mutate(
    distance_to_nearest = min(c_across(starts_with("dist_to"))),
    is_covered = distance_to_nearest <= 200
  ) |> 
  ungroup()

cat("\n=== Comparison: Optimized vs Random Selection ===\n")
cat(sprintf("Optimized coverage: %.1f%%\n", 
            sum(results$population[results$is_covered]) / sum(results$population) * 100))
cat(sprintf("Random coverage: %.1f%%\n", 
            sum(results_random$population[results_random$is_covered]) / sum(results_random$population) * 100))
cat(sprintf("Improvement: %.1f percentage points\n",
            (sum(results$population[results$is_covered]) - 
             sum(results_random$population[results_random$is_covered])) / 
              sum(results$population) * 100))


# Key Takeaway ----------------------------------------------------------------

cat("\n=== Key Insight ===\n")
cat("The MCLP optimization ensures pharmacies are placed where they cover\n")
cat("the most people, rather than being randomly or evenly distributed.\n")
cat("This is especially important in countries like Sweden with uneven\n")
cat("population distribution (dense cities, sparse rural areas).\n")
