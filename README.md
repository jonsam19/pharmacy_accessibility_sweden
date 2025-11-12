# Swedish Pharmacy Accessibility Analysis

## Overview

This repository contains a **2025 reproduction** of the pharmacy accessibility analysis originally conducted at TLV (Dental and Pharmaceutical Benefits Agency) in 2023. The analysis uses the same methodology to determine optimal pharmacy placement across Sweden to maximize population accessibility. 

The original 2023 analysis established a 300-pharmacy threshold cited in proposed Swedish pharmacy legislation. The goal was to ensure accessibility to medicines for all of Sweden in case of crisis or war.

**Purpose of this repository:**
- Demonstrates the analytical methodology used in the original study
- Provides a fully reproducible analysis using open data
- Serves as a portfolio example of geospatial optimisation and policy analysis
- Allows others to apply similar methods to pharmacy accessibility analysis

The original methodology and findings were published in a [TLV report (2023)][TLV_REPORT_URL].

**Related Resources:**
- 📄 [TLV Report (2023) - Original Analysis][TLV_REPORT_URL]
- 💊 [Pipos - Swedish Pharmacy Data Source][PIPOS_URL]
- 🗺️ [OpenRouteService - Routing API][ORS_URL]


## Key Findings (Original 2023 Analysis)

- **300 pharmacies** identified as the critical threshold for maintaining national accessibility
- **90% of population** within 20km driving distance with 300 optimally located pharmacies
- **Geographic optimisation** using regional populations Maximum Coverage Location Problem (MCLP)
- Analysis informed **proposed pharmacy legislation** in Sweden

*Note: The results from this 2025 reproduction will differ numerically from the original 2023 analysis due to updated data sources, but the methodology and approach remain identical.*

## Methodology

### 1. Data Sources (All Open Data)

This 2025 reproduction uses publicly available data:

- **Population Grid**: 1km² grid squares covering Sweden with population counts ([Statistics Sweden][SCB_URL], 2024)
- **Pharmacy Locations**: Current pharmacy locations from [Pipos][PIPOS_URL] (November 2025), including coordinates
- **Geographic Data**: Swedish administrative boundaries (counties, municipalities) via swemaps2 package
- **Road Network**: OpenStreetMap via [OpenRouteService API][ORS_URL]


### 2. Optimisation Approach

The analysis uses the **Maximum Coverage Location Problem (MCLP)** to identify optimal pharmacy locations:

1. **County Allocation**: Each county receives one base pharmacy, then remaining pharmacies are distributed proportionally by population
2. **Location Optimisation**: Within each county, MCLP identifies locations that maximise coverage of populated areas within a 10km radius
3. **Distance Calculation**: Both straight-line and driving distances from each populated square to each pharmacy calculated for validation

### 3. Accessibility Metrics

Two complementary distance measures:

- **Straight-line distance (fågelväg)**: Simple Euclidean distance for rapid calculation and baseline understanding
- **Driving distance (körväg)**: Actual road network distances using isochrones at 5, 10, 20, 30, 40, and 50 km intervals

### 4. Analysis Process

1. **Input Data**: Population Grid (1km²) + Pharmacy Locations
2. **County Allocation**: Allocate pharmacies by county (proportional to population)
3. **Location Optimisation**: Optimise locations using MCLP (maximise 10km coverage)
4. **Accessibility Calculation**: Calculate accessibility metrics (straight-line + driving distance)
5. **Results & Impact**: Generate final results and assess impact

## Project Structure

```
pharmacy-accessibility-sweden/
├── README.md                                    # Project overview and documentation
├── .env.example                                 # Template for API keys
├── scripts/
│   ├── prepare_input_files.R                   # Step 1: Process raw data
│   ├── accessibility_analysis.R                # Step 2: Run MCLP analysis
│   └── descriptive_statistics.R                # Step 3: Generate summaries
├── data/
│   ├── raw/                                    # Raw data files (not in git)
│   │   ├── befolkning_1km_2024.gpkg           # SCB population grid (download)
│   │   └── pipos_apoteksvaror_2025-11-01.xlsx # Pipos pharmacy data (download)
│   ├── processed/                              # Processed data (not in git)
│   │   ├── df_apotek.rds                      # Prepared pharmacies (generated)
│   │   └── df_rutor.rds                       # Prepared population grid (generated)
│   └── results/                                # Analysis outputs (not in git)
│       └── accessibility_N_pharmacies.rds      # Results for N pharmacies
└── outputs/                                    # Plots and tables (not in git)
    ├── coverage_by_pharmacy_count.png
    ├── marginal_benefit.png
    ├── distance_distribution.png
    └── county_summary_300_pharmacies.csv
```

## Requirements

### R Packages

```r
# Core analysis
tidyverse        # Data manipulation and visualisation
sf               # Spatial data handling
nngeo            # Nearest neighbour operations
geosphere        # Geographic distance calculations
maxcovr          # Maximum coverage optimisation
swemaps2         # Swedish administrative boundaries

# Data handling
readxl           # Reading Excel files
janitor          # Data cleaning

# API access
openrouteservice # Driving distance calculations
```

### API Setup

For driving distance calculations, you need an [OpenRouteService][ORS_URL] API key:

1. Sign up at [OpenRouteService][ORS_URL]
2. Get your free API key
3. Copy `.env.example` to `.env` and add your key:
   ```bash
   cp .env.example .env
   # Edit .env and replace 'your_api_key_here' with your actual key
   ```

The analysis script automatically loads the API key from the `.env` file.

## Usage

### Step 1: Download Data

Download the required open data files:

1. **Population grid** from [Statistics Sweden (SCB)][SCB_URL]:
   - Download from: [SCB Open Geodata][SCB_URL]
   - File: `befolkning_1km_2024.gpkg`
   - Save to: `data/raw/`

2. **Pharmacy locations** from [Pipos][PIPOS_URL]:
   - Download from: [Pipos Service Analysis][PIPOS_URL]
   - File: Current pharmacy list Excel file
   - Save to: `data/raw/`

### Step 2: Prepare Data

Process the raw data files:

```r
setwd("scripts")  # Work from scripts directory
source("prepare_input_files.R")

# This creates:
# - data/processed/df_apotek.rds (pharmacies with pharmacy_id, coordinates, regions)
# - data/processed/df_rutor.rds (population grid with coordinates, regions)
```

### Step 3: Run Analysis

Analyse pharmacy accessibility scenarios:

```r
setwd("scripts")  # Work from scripts directory
source("accessibility_analysis.R")

# Analyse specific scenarios (example with 300 pharmacies)
result_300 <- analyse_accessibility(300)

# Or run multiple scenarios
results_all <- map(seq(50, 700, by = 50), analyse_accessibility)

# Results saved to: data/results/accessibility_N_pharmacies.rds
```

**Expected Runtime for 300 pharmacies:** 11 minutes 
*Note: Runtime depends on OpenRouteService API response times and your internet connection.*

### Step 4: Generate Statistics

Calculate summary statistics and create visualisations:

```r
setwd("scripts")
source("descriptive_statistics.R")

# Generates in outputs/:
# - National and regional summaries
# - Coverage plots
# - Distance distributions
# - Comparison tables
```

## Key Results (2025 Reproduction)

| Metric | 100 Pharmacies | 300 Pharmacies | 500 Pharmacies | 1,408 Pharmacies (Current) |
|--------|----------------|----------------|----------------|---------------------------|
| Population per pharmacy | 105,608 | 35,202 | 21,335 | 7,501 |
| Mean straight-line distance to pharmacy | 15km | 8km | 5km | 3km |
| Median straight-line distance | 8km | 4km | 3km | 1km |
| Population within 10km (driving) | 45% | 69% | 80% | 87% |
| Population within 20km (driving) | 74% | 90% | 94% | 96% |


## Policy Impact (Original 2023 Analysis)

The original analysis conducted at TLV directly contributed to:

1. **[TLV Report (2023)][TLV_REPORT_URL]**: Published methodology and findings
2. **[Legislative Proposal][PROPOSAL_URL]**: 300-pharmacy threshold cited in proposed pharmacy legislation

## Limitations & Caveats

- **County-level optimisation**: Computational constraints required county-by-county analysis rather than nationwide simultaneous optimisation
- **Population proxy**: Used populated grid squares as proxy for population density (simplification)
- **Static analysis**: Does not account for temporal variations in pharmacy demand or seasonal population changes
- **Distance vs. access**: Physical distance is proxy for accessibility; doesn't capture operating hours, services, or capacity

## Citation

If using this methodology or referencing the original analysis:

**Original TLV Report (2023):**
```
Stärkt fömåga på apoteksmarknaden, slutrapport 2023.
Dental and Pharmaceutical Benefits Agency (TLV). Stockholm, Sweden.
```

**This Reproduction (2025):**
```
Samuelsson, J. (2025). Swedish Pharmacy Accessibility Analysis:
A Reproduction Using Open Data. GitHub Repository.
https://github.com/jonsam19/pharmacy-accessibility-sweden
```

## Author

**Jonas Samuelsson**  
Data Analyst, Dental and Pharmaceutical Benefits Agency (TLV)  
Stockholm, Sweden  
[GitHub](https://github.com/jonsam19) | [LinkedIn](https://linkedin.com/in/jonsam19)

## License

**Code:** MIT License - see [LICENSE](LICENSE) file for details
**Data:** Public data sources - see [data/README.md](data/README.md) for individual licenses
**Methodology:** Based on analysis originally conducted at TLV (Dental and Pharmaceutical Benefits Agency), 2023
**This Reproduction:** 2025, using open data

---

<!-- Link References -->
[TLV_REPORT_URL]: https://www.tlv.se/download/18.36ee6fe218c8adcaa227f01b/1704182347630/Starkt_formaga_p%C3%A5_apoteksmarknaden-slutrapport_2023.pdf
[PIPOS_URL]: https://pipos.se/vara-tjanster/serviceanalys
[ORS_URL]: https://openrouteservice.org/
[SCB_URL]: https://www.scb.se/vara-tjanster/oppna-data/oppna-geodata/statistik-pa-rutor/
[PROPOSAL_URL]: https://www.svenskfarmaci.se/2024/12/05/apoteket-ab-ska-starta-kopa-och-driva-300-statliga-riksapotek/
