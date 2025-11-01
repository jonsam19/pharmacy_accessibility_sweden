# =============================================================================
# Swedish Pharmacy Accessibility Analysis
# =============================================================================
# This script analyzes optimal pharmacy placement in Sweden using the Maximum
# Coverage Location Problem (MCLP) and calculates population accessibility
# via both straight-line and driving distances.
#
# Author: Jonas Samuelsson
# Organization: TLV (Dental and Pharmaceutical Benefits Agency)
# Date: 2023
# =============================================================================

# Libraries -------------------------------------------------------------------
library(tidyverse)
library(sf)
library(nngeo)
library(geosphere)
library(maxcovr)
library(openrouteservice)

# The analysis assumes you have two prepared datasets:
# - df_apotek: All pharmacy locations with coordinates (lat, long, gln)
# - df_rutor: 1km² population grid squares with coordinates and population

# Helper Functions ------------------------------------------------------------

#' Allocate pharmacies across counties
#' 
#' Each county receives 1 base pharmacy, then remaining pharmacies are
#' distributed proportionally by population
#' 
#' @param df Data frame with population by county
#' @param n Total number of pharmacies to allocate
#' @return Data frame with pharmacy allocation per county
allocate_pharmacies <- function(df, n) {
  df <- df |> 
    mutate(
      pharmacies = 1,  # Each county gets 1 base pharmacy
      pop_ratio = pop / sum(pop)
    )
  
  remaining_pharmacies <- n - nrow(df)
  
  df <- df |> 
    mutate(extra_pharmacies = floor(pop_ratio * remaining_pharmacies))
  
  # Distribute leftover pharmacies to largest counties
  leftover_pharmacies <- remaining_pharmacies - sum(df$extra_pharmacies)
  
  if (leftover_pharmacies > 0) {
    df <- df |> 
      arrange(desc(pop)) |> 
      mutate(extra_pharmacies = if_else(
        row_number() <= leftover_pharmacies, 
        extra_pharmacies + 1, 
        extra_pharmacies
      ))
  }
  
  df |> 
    mutate(total_pharmacies = pharmacies + extra_pharmacies) |> 
    select(-pharmacies, -extra_pharmacies, -pop_ratio)
}


#' Find optimal pharmacy locations using MCLP
#' 
#' Uses Maximum Coverage Location Problem to identify pharmacy locations
#' that maximize population coverage within specified radius
#' 
#' @param county County code
#' @param radius Coverage radius in meters (e.g., 10000 for 10km)
#' @param n_pharmacies Number of pharmacies to place
#' @return Vector of selected pharmacy GLN codes
find_optimal_locations <- function(county, radius, n_pharmacies) {
  
  # Create dummy existing facility (maxcovr package requirement)
  dummy_facility <- tibble(gln = 999999999, long = 0, lat = 0)
  
  # Run MCLP optimization
  model <- max_coverage(
    existing_facility = dummy_facility,
    proposed_facility = df_apotek |> 
      filter(lan == county, apoteksombud == 0),
    user = df_rutor |> 
      filter(lan == county),
    n_added = n_pharmacies,
    distance_cutoff = radius
  )
  
  # Extract selected pharmacy IDs
  model$facility_selected[[1]] |> 
    pull(gln)
}


#' Calculate straight-line distances to nearest pharmacy
#' 
#' Calculates the distance from each populated grid square to the nearest
#' pharmacy using Haversine and Vincenty ellipsoid methods
#' 
#' @param pop_grid Data frame of populated grid squares
#' @param pharmacies Data frame of pharmacy locations
#' @return Data frame with distance to nearest pharmacy added
calculate_straight_line_distances <- function(pop_grid, pharmacies) {
  
  pharm_coords <- pharmacies |> 
    select(gln, lat, long)
  
  # Calculate Haversine distances to all pharmacies
  dist_matrix <- distm(
    pop_grid[, c("long", "lat")], 
    pharm_coords[, c("long", "lat")], 
    fun = distHaversine
  )
  
  # Find nearest pharmacy for each grid square
  nearest_index <- max.col(-dist_matrix)
  
  pop_grid <- pop_grid |> 
    mutate(nearest_gln = pharm_coords$gln[nearest_index])
  
  # Join pharmacy coordinates
  pop_grid <- pop_grid |> 
    left_join(
      pharm_coords, 
      by = c("nearest_gln" = "gln"), 
      suffix = c("_grid", "_pharmacy")
    )
  
  # Calculate precise distance using Vincenty ellipsoid
  pop_grid <- pop_grid |> 
    rowwise() |> 
    mutate(
      distance_km = distVincentyEllipsoid(
        p1 = c(long_grid, lat_grid), 
        p2 = c(long_pharmacy, lat_pharmacy)
      ) / 1000  # Convert to km
    ) |> 
    ungroup()
  
  pop_grid
}


#' Generate driving distance isochrones
#' 
#' Creates isochrones (areas reachable within specific driving distances)
#' around pharmacies using OpenRouteService
#' 
#' @param pharmacies Data frame with pharmacy locations
#' @param distances Vector of distances in meters (e.g., c(5000, 10000, 20000))
#' @return sf object with isochrones
generate_isochrones <- function(pharmacies, distances) {
  
  # OpenRouteService has rate limits, so process in chunks of 3
  chunks <- split(pharmacies, ceiling(seq_along(pharmacies$gln) / 3))
  
  isochrones_list <- chunks |> 
    map(\(chunk) {
      ors_isochrones(
        chunk |> select(long, lat),
        profile = "driving-car",
        range_type = "distance",
        range = distances,
        output = "sf"
      )
    })
  
  # Combine all isochrones
  bind_rows(isochrones_list)
}


#' Calculate driving distance accessibility
#' 
#' Determines which population grid squares fall within specified driving
#' distances of any pharmacy
#' 
#' @param pharmacies Selected pharmacy locations
#' @param pop_grid Population grid with calculated straight-line distances
#' @return Data frame with driving distance accessibility indicators
calculate_driving_distances <- function(pharmacies, pop_grid) {
  
  # Define distance bands (in meters)
  distance_bands <- c(5000, 10000, 20000, 30000, 40000, 50000)
  
  # Generate isochrones
  isochrones <- generate_isochrones(pharmacies, distance_bands)
  
  # Convert population grid to sf object
  pop_sf <- pop_grid |> 
    st_as_sf(crs = 4326, coords = c("long_grid", "lat_grid"))
  
  # Check which grid squares fall within each distance band
  for (dist in distance_bands) {
    dist_km <- dist / 1000
    col_name <- paste0("within_", dist_km, "km_driving")
    
    within_distance <- pop_sf |> 
      st_within(
        isochrones |> 
          filter(value == dist) |> 
          st_make_valid()
      ) |> 
      lengths() |> 
      as.logical()
    
    pop_grid[[col_name]] <- within_distance
  }
  
  # Ensure logical consistency (if within 10km, must be within 20km, etc.)
  pop_grid <- pop_grid |> 
    mutate(
      within_50km_driving = if_else(
        !within_50km_driving & within_40km_driving, 
        TRUE, 
        within_50km_driving
      ),
      within_40km_driving = if_else(
        !within_40km_driving & within_30km_driving, 
        TRUE, 
        within_40km_driving
      ),
      within_30km_driving = if_else(
        !within_30km_driving & within_20km_driving, 
        TRUE, 
        within_30km_driving
      ),
      within_20km_driving = if_else(
        !within_20km_driving & within_10km_driving, 
        TRUE, 
        within_20km_driving
      ),
      within_10km_driving = if_else(
        !within_10km_driving & within_5km_driving, 
        TRUE, 
        within_10km_driving
      )
    )
  
  pop_grid
}


# Main Analysis Function ------------------------------------------------------

#' Run complete accessibility analysis for n pharmacies
#' 
#' Main workflow that:
#' 1. Allocates pharmacies across counties by population
#' 2. Finds optimal locations using MCLP (10km radius)
#' 3. Calculates straight-line distances
#' 4. Calculates driving distance accessibility
#' 5. Saves results
#' 
#' @param n_pharmacies Total number of pharmacies to analyze
#' @return Saves results to data/results/ directory
analyze_accessibility <- function(n_pharmacies) {
  
  message(sprintf("Analyzing accessibility with %d pharmacies...", n_pharmacies))
  
  # Step 1: Allocate pharmacies across counties
  county_allocation <- df_rutor |> 
    group_by(lan) |> 
    summarise(pop = sum(pop)) |> 
    allocate_pharmacies(n_pharmacies) |> 
    arrange(lan)
  
  message("  Pharmacies allocated across counties")
  
  # Step 2: Find optimal locations using MCLP
  selected_pharmacies <- map2_dfr(
    county_allocation$lan, 
    county_allocation$total_pharmacies,
    \(county, n_pharm) {
      
      optimal_gln <- find_optimal_locations(
        county = county,
        radius = 10000,  # 10km radius for MCLP
        n_pharmacies = n_pharm
      )
      
      df_apotek |> 
        filter(gln %in% optimal_gln)
    }
  )
  
  message(sprintf("  Selected %d optimal pharmacy locations", nrow(selected_pharmacies)))
  
  # Step 3: Calculate straight-line distances
  results <- calculate_straight_line_distances(df_rutor, selected_pharmacies)
  
  message("  Calculated straight-line distances")
  
  # Step 4: Add pharmacy metadata
  results <- results |> 
    left_join(
      df_apotek |> select(gln, apotek, apoteksombud),
      by = c("nearest_gln" = "gln")
    )
  
  # Step 5: Calculate driving distance accessibility
  results <- calculate_driving_distances(selected_pharmacies, results)
  
  message("  Calculated driving distance accessibility")
  
  # Step 6: Save results
  output_file <- sprintf("data/results/accessibility_%d_pharmacies.rds", n_pharmacies)
  saveRDS(results, output_file)
  
  message(sprintf("  Results saved to %s\n", output_file))
  
  results
}


# Run Analysis ----------------------------------------------------------------

# Analyze for different numbers of pharmacies
# The key finding was that ~300 pharmacies provide good national coverage

pharmacy_scenarios <- seq(50, 700, by = 50)

results_list <- map(pharmacy_scenarios, analyze_accessibility)

beep(3)
message("Analysis complete!")
