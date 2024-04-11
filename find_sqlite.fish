#!/usr/bin/env fish

# Check if a bundle identifier is provided
if not set -q argv[1]
    echo "Usage: $argv[0] <bundle-identifier>"
    exit 1
end

set -l bundle_identifier $argv[1]

# Identify the active iOS Simulator
set -l active_simulator (xcrun simctl list devices | grep '(Booted)' | awk -F '[()]' '{print $2}')

# Check if an active simulator was found
if not test -n "$active_simulator"
    echo "No active iOS Simulator found."
    exit 1
end

# Find the app's container directory for the specified bundle identifier
set -l container_directory (xcrun simctl get_app_container $active_simulator $bundle_identifier data)

# Construct the path to the Library/Application Support directory
set -l app_support_directory "$container_directory/Library/Application Support"

# Check if the Application Support directory was found
if not test -d "$app_support_directory"
    echo "Application Support directory not found for bundle identifier: $bundle_identifier"
    set_color normal
    exit 1
end

# Locate .sqlite files within the Application Support directory, excluding httpstorages.sqlite
echo "Searching for SQLite databases for $bundle_identifier in the active iOS Simulator..."
set_color green
find $app_support_directory -name '*.sqlite' -not -name 'httpstorages.sqlite'
set_color normal

# Open the Application Support directory in Finder
echo "Opening the Application Support directory in Finder."
open "$app_support_directory"

