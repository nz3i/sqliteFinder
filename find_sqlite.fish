#!/usr/bin/env fish

function print_usage
    echo "Usage: $argv[0] [-d] <bundle-identifier>"
    echo "Options:"
    echo "  -d    Open Documents directory instead of SQLite location"
    echo "Example: $argv[0] com.example.app    # finds SQLite location"
    echo "         $argv[0] -d com.example.app # opens Documents directory"
end

# Parse arguments
set -l open_documents 0
set -l bundle_id ""

for arg in $argv
    switch $arg
        case -h --help
            print_usage
            exit 0
        case -d
            set open_documents 1
        case '*'
            set bundle_id $arg
    end
end

if test -z "$bundle_id"
    print_usage
    exit 1
end

# Get the booted simulator
set -l device_id (xcrun simctl list devices | string match -r '.*Booted.*' | string match -r '[A-Fa-f0-9-]{36}' | head -1)

if test -z "$device_id"
    echo "No booted simulator found"
    exit 1
end

# Try the primary method first
set -l container_path (xcrun simctl get_app_container $device_id $bundle_id data)

if test $status -eq 0
    if test $open_documents -eq 1
        set -l docs_path "$container_path/Documents"
        if test -d $docs_path
            echo "Opening Documents directory..."
            open "$docs_path"
            exit 0
        else
            echo "Documents directory not found at: $docs_path"
            exit 1
        end
    else
        # Common locations to check
        set -l locations
        set -a locations "$container_path/Library/Application Support"
        set -a locations "$container_path/Library"
        set -a locations "$container_path/Documents"

        for loc in $locations
            set -l sqlite_files (find $loc -name "*.sqlite" 2>/dev/null)
            if test -n "$sqlite_files"
                echo "Found SQLite files in: $loc"
                echo "Files:"
                for file in $sqlite_files
                    echo "- "(basename $file)
                end
                echo "Opening directory..."
                open "$loc"
                exit 0
            end
        end
    end
end

# Fallback method (only for SQLite search)
if test $open_documents -eq 0
    set -l base_path "$HOME/Library/Developer/CoreSimulator/Devices/$device_id/data/Containers/Data/Application"
    for app_dir in $base_path/*/
        if test -d $app_dir
            set -l found_files (find $app_dir -name "*.sqlite" 2>/dev/null)
            if test -n "$found_files"
                echo "Found SQLite files in: $app_dir"
                echo "Files:"
                for file in $found_files
                    echo "- "(basename $file)
                end
                set -l dir_path (dirname $found_files[1])
                echo "Opening directory..."
                open "$dir_path"
                exit 0
            end
        end
    end
end

if test $open_documents -eq 1
    echo "Could not find Documents directory for bundle ID: $bundle_id"
else
    echo "No SQLite files found for bundle ID: $bundle_id"
end
exit 1
