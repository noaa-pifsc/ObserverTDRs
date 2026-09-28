# Author: Johanna Wren
# Date: 2026-09-28
# email: johanna.wren@noaa.gov
# Description: Script to generate NCEI style manifest files
#              Each file submitted to NCEI needs an accompanying manifest file 
#              The file is the filename, md5 checksum, size in bytes, comma separated with no spaces 
#              and the manifest filename should match the filename with an .mnf appended at the end. 

# Load libraries
library(digest)

# Path to TDR drive
tdrDrive <- '~/Google Drive/Shared drives/NMFS PIC ESD PRP GutsNGravy/ObserverTDRs'
# Full file path
data_file <- file.path(tdrDrive, "PIROP_TDR_metadata.csv")
# # For the TDR files
# data_file <- Sys.glob(file.path(tdrDrive, 'TDR_LL8804_TDR1*.csv'))

# Check if file exists
if (!file.exists(data_file)) {
  stop(paste("File not found:", data_file))
}

# Extract metadata
file_name  <- basename(data_file)                         # Ensures path is omitted
file_md5   <- digest::digest(data_file, algo = "md5", file = TRUE)  # MD5 checksum
file_bytes <- file.info(data_file)$size                   # File size in bytes

# Construct NCEI comma-delimited manifest string
# Format: filename,md5,bytes
manifest_content <- paste(file_name, file_md5, file_bytes, sep = ",")

# Define output manifest file path (.csv.mnf)
manifest_file <- paste0(data_file, ".mnf")

# Write to manifest file
writeLines(manifest_content, con = manifest_file)

