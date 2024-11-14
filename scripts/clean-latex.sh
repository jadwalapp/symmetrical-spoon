#!/bin/bash

# Set color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

target_dir="${1:-.}"  # Use provided directory or . if none provided

if [ ! -d "$target_dir" ]; then
    echo -e "${RED}Error: Directory '$target_dir' does not exist!${NC}"
    echo "Usage: $0 [directory_path]"
    exit 1
fi

# Convert to absolute path for clearer output
target_dir=$(cd "$target_dir" && pwd)
echo -e "${BLUE}🧹 Cleaning LaTeX build files recursively in: ${NC}$target_dir"
echo -e "${BLUE}This will clean ALL subdirectories under $target_dir${NC}"

# Optional confirmation
read -p "Continue? (y/N) " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Track number of files removed
count=0

# First, show what will be removed
echo -e "\n${BLUE}Finding files to clean...${NC}"

while IFS= read -r -d '' file; do
    echo "Will remove: $file"
    ((count++))
done < <(find "$target_dir" -type f \( \
    -name "*.aux" \
    -o -name "*.log" \
    -o -name "*.toc" \
    -o -name "*.lof" \
    -o -name "*.lot" \
    -o -name "*.fls" \
    -o -name "*.out" \
    -o -name "*.fdb_latexmk" \
    -o -name "*.synctex.gz" \
    -o -name "*.synctex" \
    -o -name "*.bbl" \
    -o -name "*.blg" \
    -o -name "*.run.xml" \
    -o -name "*.bcf" \
    -o -name "*.nav" \
    -o -name "*.snm" \
    -o -name "*.vrb" \
    -o -name "*.dvi" \
    -o -name "*.xdv" \
    -o -name "*.fls" \
    -o -name "*.pdf_tex" \
    -o -name "_minted*" \
    -o -name "*.pyg" \
    -o -name "*.listing" \
    -o -name "*.indices" \
    -o -name "*.ind" \
    -o -name "*.ilg" \
    -o -name "*.gls" \
    -o -name "*.glg" \
    -o -name "*.acn" \
    -o -name "*.acr" \
    -o -name "*.alg" \
    -o -name "*.ist" \
    -o -name "*.glo" \
    -o -name "*.xdy" \
    -o -name "*.sta" \
    -o -name "*.stp" \
    -o -name "*.auxlock" \
    -o -name "*.dpth" \
    -o -name "*.dep" \
    -o -name "*.atfi" \
\) -print0)

if [ $count -eq 0 ]; then
    echo -e "${GREEN}No LaTeX build files found to clean.${NC}"
    exit 0
fi

echo -e "\n${BLUE}Found $count files to clean.${NC}"
read -p "Proceed with deletion? (y/N) " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Now actually remove the files
find "$target_dir" -type f \( \
    -name "*.aux" \
    -o -name "*.log" \
    -o -name "*.toc" \
    -o -name "*.lof" \
    -o -name "*.lot" \
    -o -name "*.fls" \
    -o -name "*.out" \
    -o -name "*.fdb_latexmk" \
    -o -name "*.synctex.gz" \
    -o -name "*.synctex" \
    -o -name "*.bbl" \
    -o -name "*.blg" \
    -o -name "*.run.xml" \
    -o -name "*.bcf" \
    -o -name "*.nav" \
    -o -name "*.snm" \
    -o -name "*.vrb" \
    -o -name "*.dvi" \
    -o -name "*.xdv" \
    -o -name "*.fls" \
    -o -name "*.pdf_tex" \
    -o -name "_minted*" \
    -o -name "*.pyg" \
    -o -name "*.listing" \
    -o -name "*.indices" \
    -o -name "*.ind" \
    -o -name "*.ilg" \
    -o -name "*.gls" \
    -o -name "*.glg" \
    -o -name "*.acn" \
    -o -name "*.acr" \
    -o -name "*.alg" \
    -o -name "*.ist" \
    -o -name "*.glo" \
    -o -name "*.xdy" \
    -o -name "*.sta" \
    -o -name "*.stp" \
    -o -name "*.auxlock" \
    -o -name "*.dpth" \
    -o -name "*.dep" \
    -o -name "*.atfi" \
\) -delete

# Remove specific directories
find "$target_dir" -type d \( \
    -name "_minted*" \
    -o -name ".texpadtmp" \
\) -exec rm -rf {} +

echo -e "${GREEN}✨ LaTeX cleanup complete! Removed $count files under: $target_dir${NC}"