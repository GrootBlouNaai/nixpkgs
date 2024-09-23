#!/usr/bin/env nix-shell
#!nix-shell --pure --keep NIX_PATH -i python3 -p git nix-update "python3.withPackages (ps: [ ps.beautifulsoup4 ps.requests ])"

import sys
import re
import requests
import subprocess
from bs4 import BeautifulSoup

# Regular expression pattern to match Steam version filenames
# This pattern captures the version number from filenames like 'steam_1.2.3.tar.gz'
VERSION_PATTERN = re.compile(r'^steam_(?P<ver>(\d+\.)+)tar.gz$')

# List to store found Steam versions
found_versions = []

# Fetch the HTML content from the Steam archive URL
# This URL contains links to various Steam versions
response = requests.get("https://repo.steampowered.com/steam/archive/stable/")
soup = BeautifulSoup(response.text, "html.parser")

# Iterate through all anchor tags in the HTML content
for a in soup.find_all("a"):
    href = a["href"]
    
    # Skip links that do not end with '.tar.gz'
    if not href.endswith(".tar.gz"):
        continue

    # Match the href against the version pattern
    match = VERSION_PATTERN.match(href)
    if match is not None:
        # Extract and store the version number
        version = match.groupdict()["ver"][0:-1]
        found_versions.append(version)

# Check if any versions were found
if len(found_versions) == 0:
    print("Failed to find available versions!", file=sys.stderr)
    sys.exit(1)

# Sort the found versions in ascending order
found_versions.sort()

# Update the Nix package with the latest found version
# This command updates the Steam package in the Nix package manager
subprocess.run(["nix-update", "--version", found_versions[-1], "steamPackages.steam"])

# Output the oldest found version for reference
print(found_versions[0])
