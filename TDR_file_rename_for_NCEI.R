# Quick script to rename all the OBserver TDR files to follow the naming convention for ingesting into NCEI
# The convention they wanted us to follow is:
# TDR_LL????_TDR?_cYYYYMMDD_sYYYYMMDD_eYYYYDDMM.csv

# For that we need the create date aof the file s well as the start and end date of the data in the file
# We can pull the start and end dates from the metadata file, but we need to get the create date from 
# the files metadata exactly. Becuase we are using a combination of Linux/Unix and Windows systems,
# I'm using the fs packaged to pull birth date to make sure it's not the date the file was modified

# This is an issue though as we switch from storing files on an on-prem server to storing them on Google Drive.
# Google Drive overwrites the original files metadata and the create date is the date the file was uploaded to Google Drive,
# and not the date the file was created. This shouldn't be an issue moving forward, but all the files prior to LL8783 will
# have the same create date if pulled from google drive. I thankfully had a local copy from the on-prem server saved 
# and was able to get the create date from those files. Moving forward though, hopefully this isn't an issue.  

# Install if you don't have it: install.packages("fs")
library(fs)
library(readxl)
library(stringr)
library(dplyr)
library(lubridate)

# Path to your folder that has the TDR data in it. I don't think we can do this from the Google Drive but I haven't tried
folder_path <- "TDR_Data/"

# Get full paths of all CSV files in that folder
tdr_files <- list.files(path = folder_path, pattern = "\\.csv$", full.names = TRUE)
# Read in metadata
tdr_meta <- read_xlsx('TDR_Data/PIROP_TDR_metadata.xlsx')

# I'm doing this in a loop because it's easier for me to think that way
for (i in seq_along(tdr_files)) {
  # Read in the tdr file's metadata to get the birth time
  tdr <- fs::file_info(tdr_files[i])
  # format the birth time to YYYYMMDD
  cDate <- format(tdr$birth_time, '%Y%m%d')
  # Get the trip number from the tdr file name. We are using this to match with the observer metadata
  fileName <- str_extract(tdr$path, "(?<=/).*")
  # Isolate the observer metadata for the file
  meta <- tdr_meta |> 
    filter(FileName == fileName)
  # Get the trip number from the observer metadata
  TripNum <- meta$TripID
  # Get the data start date from the observer metadata
  sDate <- meta |> 
    mutate(newDate=format(mdy(StartDate_HST), "%Y%m%d")) |> 
    pull(newDate)
  # Get the data end date from the observer metadata
  eDate <- meta |> distinct(EndDate_HST) |> 
    mutate(newDate=format(mdy(EndDate_HST), "%Y%m%d")) |> pull(newDate)
  # Pull out wheter the TDR was on a shallow or deep hook, or if it was TDR1 or TDR2.
  # We have to grab this from the tdr filename becuase the observer metadata has two entries per Trip Number
  # Extract characters between the last "_" and ".csv"
  # Pattern breaks down as: 
  #   (?<=_)  -> Look behind for an underscore (don't include it in output)
  #   [^_]+   -> Match 1 or more characters that are NOT underscores
  #   (?=\\.csv) -> Look ahead for '.csv' (don't include it in output)
  tdrID <- str_extract(tdr$path, "(?<=_)[^_]+(?=\\.csv)") 
  # Make the ncei file name
  nceiName <- paste0(paste('TDR', TripNum, tdrID, cDate, sDate, eDate, sep='_'), '.csv')
  
  # Read in the csv file
  myDat <- read_csv(tdr_files[i], skip = 2, show_col_types = FALSE)
  write_csv(myDat, paste0('TDR_for_NCEI/', nceiName))
}



# This is code to pull the dates directly from google drive, but see the issue with that in the notes at the top of this document
# 
library(googledrive)
library(dplyr)
library(purrr)

# 1. Authenticate with Google (only needs to run once)
drive_auth()

# 2. Locate the specific "ObserverTDRs" folder within your Shared Drive
# This step retrieves a "dribble" (a Google Drive tibble object) representing the folder
tdr_folder <- drive_get(
  path = "ObserverTDRs", 
  shared_drive = "NMFS PIC ESD PRP GutsNGravy"
)

# 3. List the CSV files inside that specific folder object
tdr_gdrive_files <- drive_ls(
  path = tdr_folder, 
  pattern = "\\.csv$"
)

# 4. Extract the file names and creation dates
# 3. Pull both timestamps from the API metadata
tdr <- tdr_gdrive_files %>%
  mutate(
    # The date it was uploaded to Google Drive
    upload_time = map_chr(drive_resource, "createdTime") %>% ymd_hms(),
    
    # The date the original file was last edited/saved locally before upload
    original_modified_time = map_chr(drive_resource, "modifiedTime") %>% ymd_hms()
  ) %>%
  select(name, upload_time, original_modified_time)

# View your timestamps side-by-side
print(tdr)
