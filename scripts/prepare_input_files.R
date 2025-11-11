# =============================================================================
# Prepare Input Files - Swedish Pharmacy Accessibility Analysis
# =============================================================================
# This script processes raw open data files into prepared datasets for analysis.
#
# Data sources:
# - Pipos pharmacy locations (November 2025)
# - SCB population grid (2024)
# - Swedish administrative boundaries (swemaps2)
#
# Outputs:
# - data/processed/df_apotek.rds: Prepared pharmacy locations with coordinates
# - data/processed/df_rutor.rds: Prepared population grid with administrative regions
#
# =============================================================================

library(tidyverse)
library(readxl)
library(janitor)
library(sf)
library(nngeo)


##################################################################
# Prepare pharmacy (apotek) data ---------------------------------
##################################################################

# Swedish pharmacies and their coordinates downloaded from Pipos:
# https://pipos.se/vara-tjanster/serviceanalys
# Determine data directory path (handle running from scripts/ or root)
data_raw_dir <- if (dir.exists("data/raw")) "data/raw" else "../data/raw"
df_apotek_raw <- read_xlsx(file.path(data_raw_dir, "pipos_apoteksvaror_2025-11-01.xlsx"))

df_apotek <- df_apotek_raw |>
  filter(Serviceform == "Apotek") |>
  clean_names() |>
  mutate(across(c(x,y), as.numeric)) |>
  filter(!is.na(x)) |>
  st_as_sf(crs = 3006, coords = c("x", "y")) |>
  st_transform(crs = 4326) |>
  mutate(
    long = st_coordinates(geometry)[,1],
    lat = st_coordinates(geometry)[,2]
) |>
  as_tibble() |>
  select(huvudman, namn, adress, postnummer, postort, kommun, lan, long, lat) |>
  # Standardise county names (remove " län" suffix to match swemaps2)
  mutate(lan = str_remove(lan, " län$")) |>
  # Create unique pharmacy_id (sequential numbering)
  mutate(pharmacy_id = row_number(), .before = 1)

# Save prepared pharmacy data
data_processed_dir <- if (dir.exists("data/processed")) "data/processed" else "../data/processed"
df_apotek |>
  write_rds(file.path(data_processed_dir, "df_apotek.rds"))

message(sprintf("✓ Prepared %d pharmacies with coordinates", nrow(df_apotek)))


##################################################################
# Prepare population squares (rutor) -----------------------------
##################################################################

# Populated 1km square metres downloaded from SCB:
# https://www.scb.se/vara-tjanster/oppna-data/oppna-geodata/statistik-pa-rutor/
df_rutor_raw <- st_read(file.path(data_raw_dir, "befolkning_1km_2024.gpkg"))

df_rutor_raw <- df_rutor_raw |> 
  clean_names() |> 
  # we only need populated squares
  filter(beftotalt > 0) |> 
  st_transform(crs = 4326) |> 
  st_centroid(sp_geometry) |> 
  mutate(
    long = st_coordinates(sp_geometry)[,1],
    lat = st_coordinates(sp_geometry)[,2]
) |> 
  select(id = rutid_scb, pop = beftotalt, long, lat)

# get borders for municipalities (kommuner) and counties (län)
kommun_map <- swemaps2::municipality |> 
  select(kommun = kn_namn) |> 
  st_transform(crs = 4326)
lan_map <- swemaps2::county |> 
  select(lan = ln_namn) |> 
  st_transform(crs = 4326)

# add regions to squares
df_rutor_raw <- df_rutor_raw |> 
  st_join(kommun_map, join = st_within, left = TRUE) |> 
  st_join(lan_map, join = st_within, left = TRUE)

# some squares ended up outside the borders
# calculate the nearest neighbour for them
na_rutor <- df_rutor_raw |> filter(is.na(kommun) | is.na(lan))
not_na_rutor <- df_rutor_raw |> filter(!is.na(kommun) & !is.na(lan))

na_rutor_fixed <- na_rutor |> 
  select(-c(lan, kommun)) |> 
  st_join(
    lan_map,
    join = nngeo::st_nn,
    k = 1,
    maxdist = 2e4
) |> 
  st_join(
    kommun_map,
    join = nngeo::st_nn,
    k = 1,
    maxdist = 2e4
)

df_rutor <- bind_rows(not_na_rutor, na_rutor_fixed) |>
  # one could still not be found (population=5), drop it
  filter(!is.na(kommun))

# Save population grid data
df_rutor |>
  write_rds(file.path(data_processed_dir, "df_rutor.rds"))

message(sprintf("✓ Prepared %d populated grid squares (total population: %s)",
                nrow(df_rutor),
                format(sum(df_rutor$pop), big.mark = ",")))
