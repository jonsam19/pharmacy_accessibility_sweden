# Swedish Pharmacy Accessibility Analysis

**Impact**: This analysis established the 300-pharmacy threshold cited in proposed Swedish pharmacy legislation.

## Overview

This project analyzes optimal pharmacy placement across Sweden to maximize population accessibility. Using geographic optimization and accessibility metrics, the analysis determined that approximately **300 strategically-placed pharmacies** are necessary to maintain adequate nationwide coverage.

The findings were published in a TLV report and have directly influenced Swedish pharmacy policy.

## Key Findings

- **300 pharmacies** identified as the critical threshold for maintaining national accessibility
- **XX% of population** within 10km driving distance with 300 pharmacies
- **Geographic optimization** using Maximum Coverage Location Problem (MCLP)
- Analysis informed **proposed pharmacy legislation** in Sweden

## Methodology

### 1. Data Sources (All Open Data)

- **Population Grid**: 1km² grid squares covering Sweden with population counts (Statistics Sweden)
- **Pharmacy Locations**: All pharmacies with sales in May 2023, including coordinates
- **Geographic Data**: Swedish administrative boundaries (counties, municipalities)
- **Road Network**: OpenStreetMap via OpenRouteService API

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
├── README.md                           # This file
├── pharmacy_accessibility_analysis.R   # Main analysis script
├── descriptive_statistics.R            # Summary statistics & visualization
├── data/
│   ├── raw/                           # Original data files
│   │   ├── population_grid.csv        # 1km² population grid
│   │   └── pharmacy_locations.csv     # All pharmacies with coordinates
│   └── results/                       # Analysis outputs
│       └── accessibility_N_pharmacies.rds
├── outputs/
│   ├── coverage_by_pharmacy_count.png
│   ├── marginal_benefit.png
│   ├── distance_distribution.png
│   ├── scenario_comparison.csv
│   └── county_summary_300_pharmacies.csv
└── docs/
    └── tlv_report.pdf                 # Published TLV report (link)
```

## Requirements

### R Packages

```r
# Core analysis
tidyverse      # Data manipulation and visualization
sf             # Spatial data handling
nngeo          # Nearest neighbor operations
geosphere      # Geographic distance calculations
maxcovr        # Maximum coverage optimization

# API access
openrouteservice  # Driving distance calculations
```

### API Setup

For driving distance calculations, you need an OpenRouteService API key:

1. Sign up at https://openrouteservice.org/
2. Get your free API key
3. Set in R: `Sys.setenv(ORS_API_KEY = "your_key_here")`

## Usage

### 1. Prepare Data

Ensure you have two datasets ready:

```r
# df_apotek: All pharmacies
# Columns: gln, lat, long, lan, kommun, apotek, apoteksombud

# df_rutor: Population grid (1km²)
# Columns: lat, long, lan, kommun, pop
```

### 2. Run Main Analysis

```r
source("pharmacy_accessibility_analysis.R")

# Analyze specific scenarios
result_300 <- analyze_accessibility(300)
result_400 <- analyze_accessibility(400)

# Or run multiple scenarios
results_all <- map(seq(50, 700, by = 50), analyze_accessibility)
```

### 3. Calculate Statistics

```r
source("descriptive_statistics.R")

# Generates:
# - National and regional summaries
# - Visualizations
# - Comparison across scenarios
```

## Key Results (300 Pharmacies)

| Metric | Value |
|--------|-------|
| Mean distance to pharmacy | X.X km |
| Median distance | X.X km |
| Population within 10km (driving) | XX% |
| Population within 20km (driving) | XX% |
| Grid squares analyzed | ~XX,XXX |

## Policy Impact

This analysis directly contributed to:

1. **TLV Report (2023)**: Published methodology and findings
2. **Legislative Proposal**: 300-pharmacy threshold cited in proposed pharmacy legislation
3. **Ministerial Broadcast**: Findings featured in nationwide policy discussion
4. **Ongoing Policy**: Informs emergency pharmacy placement decisions

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

If using this methodology, please cite:

```
Samuelsson, J. (2023). Geographic Analysis of Pharmacy Accessibility in Sweden.
Dental and Pharmaceutical Benefits Agency (TLV). Stockholm, Sweden.
```

## Author

**Jonas Samuelsson**  
Data Analyst, Dental and Pharmaceutical Benefits Agency (TLV)  
Stockholm, Sweden  
[GitHub](https://github.com/jonsam19) | [LinkedIn](https://linkedin.com/in/jonas-samuelsson)

## License

Code: MIT License (open source)  
Data: Public data sources, see individual dataset licenses  
Report: © TLV 2023

---

*This analysis demonstrates how geographic optimization and open data can directly influence public policy to improve healthcare accessibility for millions of people.*
