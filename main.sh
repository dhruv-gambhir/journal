#!/bin/bash

ENTRY_DIR="entries"
mkdir -p "$ENTRY_DIR"
TODAY=$(date +"%d-%m-%Y")
DAY_OF_WEEK=$(date +"%A")

display_help() {
    echo "Welcome to your journal!"
    echo "Today is: $TODAY, $DAY_OF_WEEK"
    echo "Use --help for commands"
    echo "Available commands:"
    echo "  --help                 Show this help message"
    echo "  --list                 List all journal entries"
    echo "  --read [DATE]          Read the journal entry for the specified date (format: DD-MM-YYYY)"
    echo "  --delete [DATE]        Delete the journal entry for the specified date"
    echo "  --search [KEYWORD]     Search entries for a keyword"
}

list_entries() {
    echo "Available entries:"
    for entry in "$ENTRY_DIR"/*.txt; do
        [ -e "$entry" ] || continue
        ENTRY_DATE=$(basename "$entry" .txt)
        echo "$ENTRY_DATE"
    done
}

read_entry() {
    ENTRY_DATE="$1"
    if [ -z "$ENTRY_DATE" ]; then
        echo "Please provide a date for the entry to read. Format: DD-MM-YYYY"
        exit 1
    fi
    ENTRY_FILE="$ENTRY_DIR/$ENTRY_DATE.txt"
    if [ -f "$ENTRY_FILE" ]; then
        echo "Entry for $ENTRY_DATE:"
        cat "$ENTRY_FILE"
    else
        echo "No entry found for $ENTRY_DATE."
    fi
}

write_entry() {
    ENTRY_FILE="$ENTRY_DIR/$TODAY.txt"
    echo "Writing entry for $TODAY, $DAY_OF_WEEK"
    echo "Type your entry. Press Ctrl+D when finished."
    ENTRY_CONTENT=$(cat)
    if [ -z "$ENTRY_CONTENT" ]; then
        echo "No content entered. Entry not saved."
        exit 1
    fi
    echo "$ENTRY_CONTENT" >> "$ENTRY_FILE"
    echo "Entry saved."
}

delete_entry() {
    ENTRY_DATE="$1"
    if [ -z "$ENTRY_DATE" ]; then
        echo "Please provide a date for the entry to delete. Format: DD-MM-YYYY"
        exit 1
    fi
    ENTRY_FILE="$ENTRY_DIR/$ENTRY_DATE.txt"
    if [ -f "$ENTRY_FILE" ]; then
        rm "$ENTRY_FILE"
        echo "Entry for $ENTRY_DATE deleted."
    else
        echo "No entry found for $ENTRY_DATE."
    fi
}

search_entries() {
    KEYWORD="$1"
    if [ -z "$KEYWORD" ]; then
        echo "Please provide a keyword to search for."
        exit 1
    fi
    grep -ri --color=always "$KEYWORD" "$ENTRY_DIR"
}

if [ "$#" -eq 0 ]; then
    write_entry
    exit 0
fi

case "$1" in
    --help)
        display_help
        ;;
    --list)
        list_entries
        ;;
    --read)
        read_entry "$2"
        ;;
    --delete)
        delete_entry "$2"
        ;;
    --search)
        search_entries "$2"
        ;;
    *)
        echo "Invalid option. Use --help for available commands."
        ;;
esac

