#!/bin/bash

# Build and run oMessage_Model unit tests

set -e  # Exit on any error

echo "Building and running oMessage_Model unit tests..."

# Check if build directory exists, create if not
if [ ! -d "build" ]; then
    mkdir build
fi

cd build

# Configure with CMake
echo "Configuring with CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Debug

# Build the project
echo "Building project..."
make -j$(nproc)

# Run the tests
echo "Running tests..."
ctest --output-on-failure --verbose

echo "All tests completed successfully!"