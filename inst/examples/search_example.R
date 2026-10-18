# Runnable example using only fabricated dictionary data.
library(cprd.search)
load_cprd_dictionary(system.file("extdata", "synthetic-dictionary.tsv",
                                 package = "cprd.search"))
diabetes <- cprd_search_exclude("diabetes", exclude = "gestational")
asthma <- cprd_search("asthma")
codes <- cprd_combine(diabetes, asthma, select = c("MedCodeId", "Term"))
print(codes)
output <- tempfile(fileext = ".csv")
cprd_export(codes, output)
print(utils::read.csv(output, colClasses = "character"))
unlink(output)
