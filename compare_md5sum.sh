#!/bin/bash

# --- Script to compare md5sum of all files in two specified directories --- 
# Support for cases where there are files with different names but the same contents
# Example: Confirm that xxx/yyy/a.txt and xxx/yyy/b.txt have different names but the same contents

# Check the arguments
if [ $# -ne 2 ]; then
    printf "Usage: $0 <dir1> <dir2>\n"
    printf "ex: sh compare_md5sum.sh model_id=1111 model_id=2222\n"
    exit 1
fi

dir1=$1
dir2=$2

# Define pairs of files that have different names but the same contents
file_pairs1=("a.txt" "b.txt" "c.txt")
file_pairs2=("d.txt" "e.txt" "f.txt")

mismatch_count=0
comparison_count=0

# Compare all corresponding file pairs in directory 1 and directory 2
file_list=$(find $dir1 -type f)
for file in $file_list; do
    relative_path=${file#$dir1/}

    # Check if file pairs are defined
    pair_index=$(echo ${file_pairs1[@]} | tr ' ' '\n' | grep -nx "${relative_path##*/}" | cut -f1 -d:)
    if [ -n "$pair_index" ]; then
        # If a pair is defined, get the corresponding file
        pair_path=${relative_path%/*}/${file_pairs2[$((pair_index-1))]}
    else
        # If no pair is defined, get file with same name
        pair_path=$relative_path
    fi

    # Check if the corresponding file exists in directory 2
    if [ -f "$dir2/$pair_path" ]; then
        comparison_count=$((comparison_count+1))
        printf "\nComparing file pair #%d: %s and %s\n" $comparison_count $relative_path $pair_path
        
        # Calculate md5sum
        md5sum1=$(md5sum "$file" | awk '{ print $1 }')
        md5sum2=$(md5sum "$dir2/$pair_path" | awk '{ print $1 }')

        # Print md5sum
        printf "md5sum of %s/%s: %s\n" $dir1 $relative_path $md5sum1
        printf "md5sum of %s/%s: %s\n" $dir2 $pair_path $md5sum2

        # Compare md5sum
        if [ "$md5sum1" != "$md5sum2" ]; then
            printf "NG\n" 
            mismatch_count=$((mismatch_count+1))
        else
            printf "OK\n" 
        fi
    else
        printf "File not found: %s/%s\n" $dir2 $pair_path
        mismatch_count=$((mismatch_count+1))
    fi
done

# Check if all comparisons match.
if [ $mismatch_count -eq 0 ]; then
    printf "\nAll %d comparisons matched.\n" $comparison_count
else
    printf "\nMismatch found in %d out of %d comparisons.\n" $mismatch_count $comparison_count
fi
