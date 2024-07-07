#!/bin/bash

today="$(date '+%d-%m-%y')"
file="$today".txt

echo Welcome to your journal! 
echo Today is: "$today", "$(date '+%A')"
echo Use --help for commands

mkdir -p entries
cd entries || exit


help() {
    echo This is the help menu
}

new_entry() {
    echo Creating new entry for "$today"
    touch "$today".txt
    read -r response
    echo "$(date '+%H:%M')" >> "$file"
    echo "$response" >> "$file"
    echo  >> "$file"
    
}


read_entry() {
    echo displaying entry
    if [ -f "$file" ]; then
        cat "$file"
    else
        echo "No entry for today"
    fi
}

new_entry
read_entry








