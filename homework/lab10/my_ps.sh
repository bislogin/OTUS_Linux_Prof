#!/bin/bash

# Print the table header with wide spacing for the full command
printf "%-7s %-7s %-8s %s\n" "PID" "PPID" "STATUS" "COMMAND_LINE"
echo "--------------------------------------------------------"

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
        # xargs removes trailing whitespaces and formats it nicely
        cmd=$(tr '\0' ' ' < "${pid_dir}cmdline" | xargs)
    else
        # If cmdline is empty (kernel thread), get the name from stat brackets
        cmd="[$(awk -F'(' '{print $2}' "${pid_dir}stat" | awk -F')' '{print $1}')]"
    fi

    # Print the formatted table row (command is not truncated anymore)
    printf "%-7s %-7s %-8s %s\n" "$pid" "$ppid" "$state" "$cmd"
done
