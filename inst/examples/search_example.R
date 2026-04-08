# ============================================================
# Example: Using the cprd.search package
# ============================================================

library(cprd.search)

# ------ Step 1: Load the dictionary ------
# Update this path to where your CPRDAurumMedical.txt file is
load_cprd_dictionary("../CPRDAurumMedical.txt")

# ------ Step 2: Search examples ------

# Family history of lung cancer (AND logic - both must match)
fh_lc <- cprd_search("family history", "lung cancer")
print(fh_lc)

# Broader search: any lung cancer term
lung_cancer <- cprd_search_or("lung cancer", "lung carcinoma",
                               "bronchial carcinoma", "pulmonary neoplasm")
print(lung_cancer)

# Diabetes but exclude gestational
diabetes <- cprd_search_exclude(
    include = c("diabetes"),
    exclude = c("gestational", "pregnancy", "neonatal")
)
print(head(diabetes, 20))

# Only frequently used codes
common_diabetes <- cprd_search("diabetes", "type 2", min_obs = 100)
print(common_diabetes)

# Search by Read code prefix
h33_codes <- cprd_search("H33", column = "CleansedReadCode")
print(h33_codes)

# ------ Step 3: Export results ------
cprd_export(fh_lc, "family_history_lung_cancer.csv")
cprd_export(lung_cancer, "lung_cancer_all.csv")

message("Done! Check the CSV files in your working directory.")
