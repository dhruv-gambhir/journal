#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to handle unexpected errors
error_exit() {
    echo "${RED}Error: $1${RESET}" >&2
    exit 1
}

# Check if the terminal supports colors
if command -v tput >/dev/null 2>&1; then
    ncolors=$(tput colors)
fi

if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
    # Define color variables
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    WHITE=$(tput setaf 7)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    # Define empty variables if no color support
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    WHITE=""
    BOLD=""
    RESET=""
fi

ENTRY_DIR="entries"
mkdir -p "$ENTRY_DIR" || error_exit "Failed to create directory '$ENTRY_DIR'. Check permissions."

TODAY=$(date +"%d-%m-%Y")
DAY_OF_WEEK=$(date +"%A")

display_help() {
    printf "${GREEN}Welcome to your journal!${RESET}\n"
    printf "${CYAN}Today is: ${YELLOW}%s, %s${RESET}\n" "$TODAY" "$DAY_OF_WEEK"
    printf "${GREEN}Use -help for commands${RESET}\n"
    printf "${MAGENTA}Available commands:${RESET}\n"
    printf "  ${BLUE}-help${RESET}            Show this help message\n"
    printf "  ${BLUE}-ls${RESET}              List all journal entries\n"
    printf "  ${BLUE}-r [DATE]${RESET}        Read the journal entry for the specified date(defaults to today).\n"
    printf "  ${BLUE}-d [DATE]${RESET}        Delete the journal entry for the specified date\n"
    printf "  ${BLUE}-s [KEYWORD]${RESET}     Search entries for a keyword\n"
}

list_entries() {
    printf "${GREEN}Available entries:${RESET}\n"
    local found=0
    for entry in "$ENTRY_DIR"/*.txt; do
        [ -e "$entry" ] || continue
        ENTRY_DATE=$(basename "$entry" .txt)
        printf "  ${YELLOW}%s${RESET}\n" "$ENTRY_DATE"
        found=1
    done
    if [ "$found" -eq 0 ]; then
        printf "${YELLOW}No entries found.${RESET}\n"
    fi
}

read_entry() {
    ENTRY_DATE="$1"

    # If no date is provided, default to today
    if [ -z "$ENTRY_DATE" ]; then
        ENTRY_DATE="$TODAY"
    fi

    ENTRY_FILE="$ENTRY_DIR/$ENTRY_DATE.txt"

    if [ -f "$ENTRY_FILE" ]; then
        printf "${GREEN}Entry for %s:${RESET}\n\n" "$ENTRY_DATE"
        while IFS= read -r line; do
            printf "${WHITE}%s${RESET}\n" "$line"
        done < "$ENTRY_FILE"
    else
        printf "${RED}No entry found for %s.${RESET}\n" "$ENTRY_DATE"
    fi
}

write_entry() {
    ENTRY_FILE="$ENTRY_DIR/$TODAY.txt"

    printf "${GREEN}Writing entry for %s, %s${RESET}\n" "$TODAY" "$DAY_OF_WEEK"
    printf "${CYAN}Type your entry. Type 'end' on a new line when finished.${RESET}\n"

    ENTRY_CONTENT=""

    while IFS= read -r line
    do
        if [[ "$line" == "end" ]]; then
            break
        fi
        ENTRY_CONTENT+="$line"$'\n'
    done

    if [ -z "$ENTRY_CONTENT" ]; then
        printf "${YELLOW}No content entered. Entry not saved.${RESET}\n"
        exit 1
    fi

    # Capture the current time in 12-hour format with AM/PM and append it
    CURRENT_TIME=$(date +"%I:%M %p")
    {
        printf "${MAGENTA}Time: %s${RESET}\n" "$CURRENT_TIME"
        printf "%s" "$ENTRY_CONTENT"
        printf "\n"  # **Added New Line After Each Entry**
    } >> "$ENTRY_FILE" || error_exit "Failed to write to '$ENTRY_FILE'."

    printf "${GREEN}Entry saved.${RESET}\n"
}

delete_entry() {
    ENTRY_DATE="$1"
    if [ -z "$ENTRY_DATE" ]; then
        printf "${RED}Please provide a date for the entry to delete. Format: DD-MM-YYYY${RESET}\n"
        exit 1
    fi
    ENTRY_FILE="$ENTRY_DIR/$ENTRY_DATE.txt"
    if [ -f "$ENTRY_FILE" ]; then
        # Confirm deletion
        printf "${YELLOW}Are you sure you want to delete the entry for %s? (y/N): ${RESET}" "$ENTRY_DATE"
        read -r confirmation
        case "$confirmation" in
            [yY][eE][sS]|[yY])
                rm "$ENTRY_FILE" && printf "${GREEN}Entry for %s deleted.${RESET}\n" "$ENTRY_DATE" || error_exit "Failed to delete '$ENTRY_FILE'."
                ;;
            *)
                printf "${CYAN}Deletion cancelled.${RESET}\n"
                ;;
        esac
    else
        printf "${RED}No entry found for %s.${RESET}\n" "$ENTRY_DATE"
    fi
}

edit_entry() {
    ENTRY_DATE="$1"

    # Default to today's entry if no date is provided
    if [ -z "$ENTRY_DATE" ]; then
        ENTRY_DATE="$TODAY"
    fi

    ENTRY_FILE="$ENTRY_DIR/$ENTRY_DATE.txt"

    if [ -f "$ENTRY_FILE" ]; then
        # Open the entry file with the default editor (use $EDITOR or fallback to nano)
        "${EDITOR:-nano}" "$ENTRY_FILE" || error_exit "Failed to open editor for '$ENTRY_FILE'."
        printf "${GREEN}Entry for %s updated.${RESET}\n" "$ENTRY_DATE"
    else
        printf "${RED}No entry found for %s.${RESET}\n" "$ENTRY_DATE"
    fi
}

search_entries() {
    KEYWORD="$1"
    if [ -z "$KEYWORD" ]; then
        printf "${RED}Please provide a keyword to search for.${RESET}\n"
        exit 1
    fi
    printf "${GREEN}Searching for \"%s\" in entries:${RESET}\n" "$KEYWORD"
    if grep -ri --color=always "$KEYWORD" "$ENTRY_DIR"; then
        :
    else
        printf "${YELLOW}No matches found for \"%s\".${RESET}\n" "$KEYWORD"
    fi
}

# Main logic
if [ "$#" -eq 0 ]; then
    write_entry
    exit 0
fi

case "$1" in
    -help | -h)
        display_help
        ;;
    -ls | -list)
        list_entries
        ;;
    -r | -read)
        # Pass the second argument if provided, else pass empty string
        read_entry "$2"
        ;;
    -d | delete)
        delete_entry "$2"
        ;;
    -s | search)
        search_entries "$2"
        ;;
    -e | -editor)
        edit_entry "$2"
        ;;
    *)
        printf "${RED}Invalid option. Use -help for available commands.${RESET}\n"
        ;;
esac

