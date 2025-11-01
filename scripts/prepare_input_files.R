library(tidyverse)
library(readxl)
library(feather)
library(janitor)


##################################################################
# Prepare pharmacy (apotek) data ---------------------------------
##################################################################

# Swedish pharmacies and their coordinates downloaded from Pipos:
# https://pipos.se/vara-tjanster/serviceanalys
df_apotek_raw <- read_xlsx("input/raw_data/pipos_apoteksvaror_2025-11-01.xlsx")

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
  select(huvudman, namn, adress, postnummer, postort,
kommun, lan, long, lat)

df_apotek |> 
  write_feather("input/df_apotek.feather")


##################################################################
# Prepare population squares (rutor) -----------------------------
##################################################################

# Populated 1km square meters downloaded from SCB:
# https://www.scb.se/vara-tjanster/oppna-data/oppna-geodata/statistik-pa-rutor/
df_rutor_raw <- st_read("input/raw_data/befolkning_1km_2024.gpkg")

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

df_rutor |> 
  write_rds("input/df_rutor.rds")
