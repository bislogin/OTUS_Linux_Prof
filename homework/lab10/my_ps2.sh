#!/bin/bash

# Print the table header with the new OPENED_FILE column
printf "%-7s %-7s %-8s %-40s %s\n" "PID" "PPID" "STATUS" "COMMAND" "OPENED_FILE"
echo "------------------------------------------------------------------------------------------------------------------------"

# Iterate through all directories in /proc that consist only of numbers
for pid_dir in /proc/[0-9]*/; do
    # Extract the PID from the directory path
    pid=$(basename "$pid_dir")

    # Check if the stat file exists (the process might have terminated)
    if [ ! -f "${pid_dir}stat" ]; then
        continue
    fi

    # Read the process state ($3) and PPID ($4) from the stat file
    read -r state ppid <<< "$(awk '{print $3, $4}' "${pid_dir}stat")"

    # Read the command line arguments (replace null bytes with spaces)
    if [ -s "${pid_dir}cmdline" ]; then
        cmd=$(tr '\0' ' ' < "${pid_dir}cmdline" | xargs)
    else
        # If cmdline is empty (kernel thread), get the name from stat brackets
        cmd="[$(awk -F'(' '{print $2}' "${pid_dir}stat" | awk -F')' '{print $1}')]"
    fi

    # Get the last opened file from /proc/[PID]/fd/ (if accessible)
    opened_file="-"
    if [ -d "${pid_dir}fd" ]; then
        # Find the newest symlink in fd directory and resolve its path
        # 2>/dev/null hides permission denied errors for processes you don't own
        last_fd=$(ls -t "${pid_dir}fd" 2>/dev/null | head -n 1)
        if [ ! -z "$last_fd" ]; then
            opened_file=$(readlink "${pid_dir}fd/$last_fd" 2>/dev/null)
            # Default to dash if readlink fails or returns empty
            [ -z "$opened_file" ] && opened_file="-"
        fi
    fi

    # Truncate long command lines for better terminal readability
    if [ ${#cmd} -gt 37 ]; then
        cmd="${cmd:0:34}..."
    fi

    # Truncate long file paths as well
    if [ ${#opened_file} -gt 50 ]; then
        opened_file="${opened_file:0:47}..."
    fi

    # Print the formatted table row
    printf "%-7s %-7s %-8s %-40s %s\n" "$pid" "$ppid" "$state" "$cmd" "$opened_file"
done
