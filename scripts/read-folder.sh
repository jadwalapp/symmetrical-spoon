#!/bin/bash

# Initialize variables
directory=""
include_pattern="*"
exclude_pattern=""
show_help=0

# Function to display help
print_help() {
    echo "Usage: $0 -d <directory> [-i include_pattern] [-e exclude_pattern]"
    echo
    echo "Options:"
    echo "  -d    Directory path (required)"
    echo "  -i    Include pattern (glob pattern, e.g., '*.txt' or '*.{txt,md}')"
    echo "  -e    Exclude pattern (glob pattern, e.g., '*.log' or '*{.git,.env}*')"
    echo "  -h    Show this help message"
    echo
    echo "Examples:"
    echo "  $0 -d /path/to/folder -i '*.txt'"
    echo "  $0 -d /path/to/folder -i '*.{txt,md}' -e '*{.git,.env}*'"
    exit 1
}

# Parse command line options
while getopts "d:i:e:h" opt; do
    case $opt in
        d) directory="$OPTARG";;
        i) include_pattern="$OPTARG";;
        e) exclude_pattern="$OPTARG";;
        h) show_help=1;;
        \?) echo "Invalid option: -$OPTARG" >&2; print_help;;
    esac
done

# Show help if requested or if no directory specified
if [ $show_help -eq 1 ] || [ -z "$directory" ]; then
    print_help
fi

# Check if directory exists
if [ ! -d "$directory" ]; then
    echo "Error: Directory '$directory' does not exist"
    exit 1
fi

# Function to process a file
process_file() {
    local file="$1"
    
    # Skip if not a regular file
    if [ ! -f "$file" ]; then
        return
    fi
    
    # Get relative path from the base directory
    local relative_path="${file#$directory/}"
    
    # Check if file matches exclude pattern
    if [ ! -z "$exclude_pattern" ] && [[ "$relative_path" == $exclude_pattern ]]; then
        return
    fi
    
    # Print filename as header
    echo "### File: $relative_path ###"
    echo
    
    # Print file contents
    cat "$file"
    
    # Print separator
    echo
    echo "### End of file: $relative_path ###"
    echo
    echo "----------------------------------------"
    echo
}

# Process files matching the patterns
if [ -z "$exclude_pattern" ]; then
    find "$directory" -type f -name "$include_pattern" -print0
else
    find "$directory" -type f -name "$include_pattern" -print0
fi | while IFS= read -r -d '' file; do
    process_file "$file"
done