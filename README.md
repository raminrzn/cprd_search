# cprd.search

An R package for searching the **CPRD Aurum Medical Dictionary**. Quickly find medical codes by keyword for building code lists in epidemiological research.

## Installation

```r
# Install dependencies
install.packages(c("data.table", "stringdist"))

# Install from source (from the parent directory)
install.packages("cprd.search", repos = NULL, type = "source")

# Or using devtools from inside the package folder
# devtools::install()
```

## Quick Start

```r
library(cprd.search)

# 1. Load the dictionary (only needed once per session)
load_cprd_dictionary("/path/to/CPRDAurumMedical.txt")

# 2. Search for family history of lung cancer
results <- cprd_search("family history", "lung cancer")
print(results)

# 3. Export to CSV
cprd_export(results, "fh_lung_cancer_codes.csv")
```

## Search Functions

### `cprd_search()` — AND logic (all keywords must match)
```r
# All keywords must appear in the term
cprd_search("family history", "lung cancer")
cprd_search("diabetes", "type 2")
cprd_search("hypertension", min_obs = 100)
```

### `cprd_search_or()` — OR logic (any keyword can match)
```r
# Any of these keywords will match
cprd_search_or("lung cancer", "bronchial carcinoma", "pulmonary neoplasm")
```

### `cprd_search_exclude()` — Search with exclusions
```r
# Diabetes but NOT gestational
cprd_search_exclude(
  include = c("diabetes"),
  exclude = c("gestational", "pregnancy")
)

# Family history of cancer, but not breast
cprd_search_exclude(
  include = c("family history", "cancer"),
  exclude = c("breast")
)
```

### `cprd_search_fuzzy()` — Fuzzy / approximate matching
```r
# Handles misspellings
cprd_search_fuzzy("diabeties")
cprd_search_fuzzy("hypertenshun")
```

### `cprd_browse()` — Interactive browser
```r
# Opens an interactive search prompt
cprd_browse()
# Type keywords, get instant results
# Type 'q' to quit
```

## Filtering

All search functions support:
- **`min_obs`**: Minimum number of observations (filters rare codes)
- **`column`**: Search in a specific column (`"Term"`, `"OriginalReadCode"`, `"CleansedReadCode"`, `"MedCodeId"`, `"SnomedCTConceptId"`)

```r
# Only codes with 50+ observations
cprd_search("asthma", min_obs = 50)

# Search by Read code prefix
cprd_search("H33", column = "CleansedReadCode")
```

## Exporting

```r
results <- cprd_search("family history", "lung cancer")
cprd_export(results, "my_code_list.csv")
```

## Example Workflow: Building a Code List

```r
library(cprd.search)

# Load dictionary
load_cprd_dictionary("CPRDAurumMedical.txt")

# Step 1: Broad search
broad <- cprd_search_or("lung cancer", "lung carcinoma", "lung neoplasm",
                         "bronchial cancer", "bronchial carcinoma")

# Step 2: Refine — exclude screening/family history if you only want diagnoses
refined <- cprd_search_exclude(
  include = c("lung cancer"),
  exclude = c("family history", "screening", "suspected")
)

# Step 3: Review and export
print(refined)
cprd_export(refined, "lung_cancer_codes.csv")
```

## License

MIT
