# Swedish Pharmacy Accessibility Analysis

**Impact**: The original 2023 analysis established a 300-pharmacy threshold cited in proposed Swedish pharmacy legislation. The goal is to ensure accessibility to medicines for all of Sweden in case of crisis or war.

## Overview

This repository contains a **2025 reproduction** of the pharmacy accessibility analysis originally conducted at TLV (Dental and Pharmaceutical Benefits Agency) in 2023. The analysis uses the same methodology to determine optimal pharmacy placement across Sweden to maximize population accessibility.

### Important Notes

⚠️ **This is a reproduction using current (2025) open-source data, not the original 2023 analysis.**

**Key Differences:**
- **Original (2023)**: Used internal TLV data with actual pharmacy sales from May 2023
- **This version (2025)**: Uses publicly available Pipos pharmacy data (November 2025) and SCB population data (2024)
- **Results**: Will differ from the published 2023 report due to:
  - Different pharmacy landscape (2025 vs 2023)
  - Different data sources (open data vs internal TLV data)
  - Updated population distribution (2024 vs 2023)

**Purpose of this repository:**
- Demonstrates the analytical methodology used in the original study
- Provides a fully reproducible analysis using open data
- Serves as a portfolio example of geospatial optimization and policy analysis
- Allows others to apply similar methods to pharmacy accessibility analysis

The original methodology and findings were published in a [TLV report (2023)][TLV_REPORT_URL] and influenced Swedish pharmacy policy.

**Related Resources:**
- 📄 [TLV Report (2023) - Original Analysis][TLV_REPORT_URL]
- 💊 [Pipos - Swedish Pharmacy Data Source][PIPOS_URL]
- 🗺️ [OpenRouteService - Routing API][ORS_URL]


## Key Findings (Original 2023 Analysis)

- **300 pharmacies** identified as the critical threshold for maintaining national accessibility
- **XX% of population** within 10km driving distance with 300 pharmacies
- **Geographic optimization** using Maximum Coverage Location Problem (MCLP)
- Analysis informed **proposed pharmacy legislation** in Sweden

*Note: The results from this 2025 reproduction will differ numerically from the original 2023 analysis due to updated data sources, but the methodology and approach remain identical.*

## Methodology

### 1. Data Sources (All Open Data)

This 2025 reproduction uses publicly available data:

- **Population Grid**: 1km² grid squares covering Sweden with population counts ([Statistics Sweden][SCB_URL], 2024)
- **Pharmacy Locations**: Current pharmacy locations from [Pipos][PIPOS_URL] (November 2025), including coordinates
- **Geographic Data**: Swedish administrative boundaries (counties, municipalities) via swemaps2 package
- **Road Network**: OpenStreetMap via [OpenRouteService API][ORS_URL]

*The original 2023 analysis used internal TLV pharmacy sales data from May 2023.*


### 2. Optimization Approach

The analysis uses the **Maximum Coverage Location Problem (MCLP)** to identify optimal pharmacy locations:

1. **County Allocation**: Each county receives one base pharmacy, then remaining pharmacies are distributed proportionally by population
2. **Location Optimization**: Within each county, MCLP identifies locations that maximize coverage of populated areas within a 10km radius
3. **Distance Calculation**: Both straight-line and driving distances calculated for validation

### 3. Accessibility Metrics

Two complementary distance measures:

- **Straight-line distance (fågelväg)**: Simple Euclidean distance for rapid calculation and baseline understanding
- **Driving distance (körväg)**: Actual road network distances using isochrones at 5, 10, 20, 30, 40, and 50 km intervals

### 4. Analysis Process

```
Population Grid (1km²) + Pharmacy Locations
              ↓
    Allocate pharmacies by county
    (proportional to population)
              ↓
    Optimize locations using MCLP
    (maximize 10km coverage)
              ↓
    Calculate accessibility metrics
    (straight-line + driving distance)
              ↓
         Results & Impact
```

## Project Structure

```
pharmacy-accessibility-sweden/
├── README.md                                    # Project overview and documentation
├── .env.example                                 # Template for API keys
├── scripts/
│   ├── prepare_input_files.R                   # Step 1: Process raw data
│   ├── pharmacy_accessibility_analysis.R       # Step 2: Run MCLP analysis
│   └── descriptive_statistics.R                # Step 3: Generate summaries
├── data/
│   ├── raw/                                    # Raw and prepared data (not in git)
│   │   ├── befolkning_1km_2024.gpkg           # SCB population grid (download)
│   │   ├── pipos_apoteksvaror_2025-11-01.xlsx # Pipos pharmacy data (download)
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
tidyverse        # Data manipulation and visualization
sf               # Spatial data handling
nngeo            # Nearest neighbor operations
geosphere        # Geographic distance calculations
maxcovr          # Maximum coverage optimization
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
# - data/raw/df_apotek.rds (pharmacies with pharmacy_id, coordinates, regions)
# - data/raw/df_rutor.rds (population grid with coordinates, regions)
```

### Step 3: Run Analysis

Analyze pharmacy accessibility scenarios:

```r
setwd("scripts")  # Work from scripts directory
source("pharmacy_accessibility_analysis.R")

# Analyze specific scenarios
result_300 <- analyze_accessibility(300)
result_400 <- analyze_accessibility(400)

# Or run multiple scenarios
results_all <- map(seq(50, 700, by = 50), analyze_accessibility)

# Results saved to: data/results/accessibility_N_pharmacies.rds
```

### Step 4: Generate Statistics

Calculate summary statistics and create visualizations:

```r
setwd("scripts")
source("descriptive_statistics.R")

# Generates in outputs/:
# - National and regional summaries
# - Coverage plots
# - Distance distributions
# - Comparison tables
```

## Key Results (2025 Reproduction - 300 Pharmacies)

| Metric | Value |
|--------|-------|
| Mean distance to pharmacy | *To be calculated* |
| Median distance | *To be calculated* |
| Population within 10km (driving) | *To be calculated* |
| Population within 20km (driving) | *To be calculated* |
| Grid squares analyzed | *To be calculated* |

*Results will be updated after running the analysis with 2025 data. These will differ from the original 2023 findings due to changes in pharmacy landscape and population distribution.*

## Policy Impact (Original 2023 Analysis)

The original analysis conducted at TLV directly contributed to:

1. **[TLV Report (2023)][TLV_REPORT_URL]**: Published methodology and findings
2. **Legislative Proposal**: 300-pharmacy threshold cited in proposed pharmacy legislation
3. **Ministerial Broadcast**: Findings featured in nationwide policy discussion
4. **Ongoing Policy**: Informs emergency pharmacy placement decisions

*This 2025 reproduction demonstrates the methodology but was not used for policy decisions. The policy impact reflects the original 2023 work. Read the [original report here][TLV_REPORT_URL].*

## Limitations & Caveats

- **County-level optimization**: Computational constraints required county-by-county analysis rather than nationwide simultaneous optimization
- **Population proxy**: Used populated grid squares as proxy for population density (simplification)
- **Static analysis**: Does not account for temporal variations in pharmacy demand or seasonal population changes
- **Distance vs. access**: Physical distance is proxy for accessibility; doesn't capture operating hours, services, or capacity

## Future Improvements

- [ ] Municipal-level analysis for more granular insights
- [ ] Incorporate actual population density (not just binary occupied/unoccupied)
- [ ] Dynamic optimization considering temporal demand patterns
- [ ] Service quality metrics beyond simple distance
- [ ] Validation against actual utilization data

## Citation

If using this methodology or referencing the original analysis:

**Original TLV Report (2023):**
```
Samuelsson, J. (2023). Geographic Analysis of Pharmacy Accessibility in Sweden.
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

*This analysis demonstrates how geographic optimization and open data can directly influence public policy to improve healthcare accessibility for millions of people.*

<!-- Link References -->
[TLV_REPORT_URL]: https://www.tlv.se/download/18.36ee6fe218c8adcaa227f01b/1704182347630/Starkt_formaga_p%C3%A5_apoteksmarknaden-slutrapport_2023.pdf
[PIPOS_URL]: https://pipos.se/vara-tjanster/serviceanalys
[ORS_URL]: https://openrouteservice.org/
[SCB_URL]: https://www.scb.se/vara-tjanster/oppna-data/oppna-geodata/statistik-pa-rutor/
