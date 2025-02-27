#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 <example-name>"
    echo "  <example-name>: Name of the example"
    exit 1
}

# Check if the correct number of arguments is provided
if [ $# -ne 1 ]; then
    echo "Error: Incorrect number of arguments"
    usage
fi

# Parse and store arguments
example_name="$1"

# Validate arguments
if [ -z "$example_name" ]; then
    echo "Error: Both arguments must be non-empty"
    usage
fi

# Print the parsed arguments
echo "Example Name: $example_name"

# Change to the parent directory and run a command
(
    cd "$(dirname "$0")/../cosim" || exit
    echo "Current directory: $(pwd)"
    echo "Running command with arguments: $@"

    if ! make -C $example_name/vivado pack_bitstream; then
        echo "Error: 'make pack_bitstream' failed."
        exit 1
    fi

    if [ ! -f $example_name/*.*.*.tar.xz.b64 ]; then
        echo "bitstream not found"
        exit 1
    fi
)

