#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 <example-name> <tool-name>"
    echo "  <example-name>: Name of the example"
    echo "  <tool-name>: Name of the tool"
    exit 1
}

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
    echo "Error: Incorrect number of arguments"
    usage
fi

# Parse and store arguments
example_name="$1"
tool_name="$2"

run_path=$example_name/$tool_name

# Validate arguments
if [ -z "$example_name" ] || [ -z "$tool_name" ]; then
    echo "Error: Both arguments must be non-empty"
    usage
fi

# Print the parsed arguments
echo "Example Name: $example_name"
echo "Tool Name: $tool_name"

# Change to the parent directory and run a command
(
    cd "$(dirname "$0")/../cosim" || exit
    echo "Current directory: $(pwd)"
    echo "Running command with arguments: $@"

    if ! make -C $run_path clean build; then
        echo "Error: 'make clean build' failed."
        exit 1
    fi

    if ! make -C $run_path run; then
        echo "Error: 'make run' failed."
        exit 1
    fi

    # Check if run.log exists and contains the required string
    log_file="$run_path/run.log"
    search_string="done() called"

    # Check if run.log exists and contains the required string
    if [ ! -f "$log_file" ]; then
        echo "Error: Log file '$log_file' not found."
        exit 1
    fi

    if ! grep -q "$search_string" "$log_file"; then
        echo "Error: Log file does not contain the required string: '$search_string'."
        exit 1
    fi
)
