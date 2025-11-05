# Data Directory

This directory contains all data files used in the Swedish Pharmacy Accessibility Analysis.

## Directory Structure

```
data/
├── raw/                           # Raw source data and prepared datasets
│   ├── befolkning_1km_2024.gpkg  # SCB population grid (download)
│   ├── pipos_apoteksvaror_*.xlsx # Pipos pharmacy data (download)
│   ├── df_apotek.rds             # Prepared pharmacy data (generated)
│   └── df_rutor.rds              # Prepared population grid (generated)
└── results/                       # Analysis output files (generated)
    └── accessibility_N_pharmacies.rds
```

## Data Sources

### 1. Population Grid (`befolkning_1km_2024.gpkg`)

**Source:** Statistics Sweden (SCB)
**URL:** https://www.scb.se/vara-tjanster/oppna-data/oppna-geodata/statistik-pa-rutor/
**Description:** 1km² grid squares covering Sweden with population counts
**Format:** GeoPackage (.gpkg)
**License:** Open data (CC0)
**Download:** Manual download required

**Contents:**
- Geographic boundaries of 1km² grid squares
- Population counts (as of 2024)
- Square identifiers

### 2. Pharmacy Locations (`pipos_apoteksvavor_*.xlsx`)

**Source:** Pipos (Swedish pharmacy industry service)
**URL:** https://pipos.se/vara-tjanster/serviceanalys
**Description:** All registered pharmacies in Sweden with coordinates
**Format:** Excel (.xlsx)
**License:** Publicly available
**Download:** Manual download required

**Contents:**
- Pharmacy names and addresses
- Coordinates (SWEREF99 TM, EPSG:3006)
- Service types (Apotek vs Apoteksombud)
- Operating organizations

### 3. Swedish Administrative Boundaries

**Source:** swemaps2 R package
**Description:** County (län) and municipality (kommun) boundaries
**Format:** R package data
**License:** Open data
**Access:** `library(swemaps2)`

## Prepared Datasets

After running `scripts/prepare_input_files.R`, the following files are created:

### `df_apotek.rds`

Processed pharmacy data ready for analysis.

**Columns:**
- `pharmacy_id` (integer): Unique identifier for each pharmacy
- `huvudman` (character): Operating organization
- `namn` (character): Pharmacy name
- `adress` (character): Street address
- `postnummer` (character): Postal code
- `postort` (character): City
- `kommun` (character): Municipality name
- `lan` (character): County name
- `long` (numeric): Longitude (WGS84, EPSG:4326)
- `lat` (numeric): Latitude (WGS84, EPSG:4326)

**Transformations:**
- Filtered to only include pharmacies (Apotek), excluding pharmacy agents (Apoteksombud)
- Coordinates transformed from SWEREF99 TM to WGS84
- Sequential pharmacy_id assigned

### `df_rutor.rds`

Processed population grid ready for analysis.

**Columns:**
- `id` (character): Grid square identifier (rutid_scb)
- `pop` (numeric): Population count
- `long` (numeric): Centroid longitude (WGS84, EPSG:4326)
- `lat` (numeric): Centroid latitude (WGS84, EPSG:4326)
- `kommun` (character): Municipality name
- `lan` (character): County name
- `sp_geometry` (sf): Spatial geometry (point)

**Transformations:**
- Filtered to only populated squares (population > 0)
- Converted to centroids for distance calculations
- Coordinates transformed to WGS84
- Joined with administrative boundaries (county and municipality)
- Squares outside boundaries matched to nearest region

## File Formats

This project uses **RDS format** (.rds) for prepared datasets:

**Advantages:**
- Native R format with full type preservation
- Built-in compression (smaller files)
- Handles complex objects (sf geometries, factors, dates)
- No additional dependencies required

**Why not Feather:**
- Feather is better for R ↔ Python interoperability
- Not needed for this R-only analysis

## Data Not Included in Git

For reproducibility and storage efficiency, the following are excluded from version control (see `.gitignore`):

- ✅ **Included:** `.gitkeep` files (maintain directory structure)
- ❌ **Excluded:** `data/raw/*.rds` (prepared datasets, large files)
- ❌ **Excluded:** `data/results/` (analysis outputs, regenerable)
- ❌ **Excluded:** Raw data files (downloadable from sources)

## Reproducing the Data

To reproduce the analysis data:

1. Download raw data files (see sources above)
2. Place files in `data/raw/`
3. Run `scripts/prepare_input_files.R`
4. Prepared datasets will be created in `data/raw/`

## Data Privacy

All data used is publicly available open data:
- No personal information
- Aggregate population counts only
- Public pharmacy locations only
- No sales or financial data included
