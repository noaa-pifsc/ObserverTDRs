#!/bin/bash

# Loop through all .csv files in the current directory
for file in PIROP_*.csv; do
  # Check if any .csv files actually exist to avoid running on an empty glob
  [ -e "$file" ] || continue

  # Calculate MD5 hash using macOS md5 command
  checksum=$(md5 -q "$file")

  # Get file size in bytes using macOS stat syntax
  filesize=$(stat -f%z "$file")

  # Set output filename by appending .mnf to the full csv filename
  manifest_file="${file}.mnf"

  # Write the NCEI manifest format: [filename],[checksum],[filesize]
  echo "${file},${checksum},${filesize}" > "$manifest_file"

  echo "Created manifest: $manifest_file"
done
