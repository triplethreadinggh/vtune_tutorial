#!/bin/bash

# VTune Profiling Scripts for Matrix Multiplication Tutorial
# This script demonstrates different VTune analysis types

RESULTS_DIR="./results"
BUILD_DIR="./build"

# Create results directory if it doesn't exist
mkdir -p ${RESULTS_DIR}

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== VTune Profiling Script for Matrix Multiplication ===${NC}\n"

# Function to run hotspots analysis
run_hotspots() {
    local app=$1
    local args=$2
    local output_name=$3
    
    echo -e "${BLUE}Running Hotspots Analysis: ${output_name}${NC}"
    
    vtune -collect hotspots \
          -result-dir ${RESULTS_DIR}/${output_name}_hotspots \
          -- ${BUILD_DIR}/${app} ${args}
    
    echo -e "${GREEN}Hotspots analysis complete!${NC}"
    echo "View results with: vtune-gui ${RESULTS_DIR}/${output_name}_hotspots"
    echo ""
}

# Function to run memory access analysis
run_memory_access() {
    local app=$1
    local args=$2
    local output_name=$3
    
    echo -e "${BLUE}Running Memory Access Analysis: ${output_name}${NC}"
    
    vtune -collect memory-access \
          -result-dir ${RESULTS_DIR}/${output_name}_memory \
          -- ${BUILD_DIR}/${app} ${args}
    
    echo -e "${GREEN}Memory access analysis complete!${NC}"
    echo "View results with: vtune-gui ${RESULTS_DIR}/${output_name}_memory"
    echo ""
}

# Function to run threading analysis
run_threading() {
    local app=$1
    local args=$2
    local output_name=$3
    
    echo -e "${BLUE}Running Threading Analysis: ${output_name}${NC}"
    
    vtune -collect threading \
          -result-dir ${RESULTS_DIR}/${output_name}_threading \
          -- ${BUILD_DIR}/${app} ${args}
    
    echo -e "${GREEN}Threading analysis complete!${NC}"
    echo "View results with: vtune-gui ${RESULTS_DIR}/${output_name}_threading"
    echo ""
}

# Function to run microarchitecture analysis
run_uarch() {
    local app=$1
    local args=$2
    local output_name=$3
    
    echo -e "${BLUE}Running Microarchitecture Exploration: ${output_name}${NC}"
    
    vtune -collect uarch-exploration \
          -result-dir ${RESULTS_DIR}/${output_name}_uarch \
          -- ${BUILD_DIR}/${app} ${args}
    
    echo -e "${GREEN}Microarchitecture analysis complete!${NC}"
    echo "View results with: vtune-gui ${RESULTS_DIR}/${output_name}_uarch"
    echo ""
}

# Main execution
# Matrix size for profiling
MATRIX_SIZE=1024
BLOCK_SIZE=64
NUM_THREADS=4

echo "=== Profiling Configuration ==="
echo "Matrix Size: ${MATRIX_SIZE}"
echo "Block Size: ${BLOCK_SIZE}"
echo "Threads: ${NUM_THREADS}"
echo ""

# Profile Naive Implementation
echo "=========================================="
echo "1. NAIVE IMPLEMENTATION"
echo "=========================================="
run_hotspots "matrix_naive" "${MATRIX_SIZE}" "naive"
run_memory_access "matrix_naive" "${MATRIX_SIZE}" "naive"

# Profile Blocked Implementation
echo "=========================================="
echo "2. BLOCKED IMPLEMENTATION"
echo "=========================================="
run_hotspots "matrix_blocked" "${MATRIX_SIZE} ${BLOCK_SIZE}" "blocked"
run_memory_access "matrix_blocked" "${MATRIX_SIZE} ${BLOCK_SIZE}" "blocked"

# Profile Parallel Implementation
echo "=========================================="
echo "3. PARALLEL IMPLEMENTATION"
echo "=========================================="
run_hotspots "matrix_parallel" "${MATRIX_SIZE} ${BLOCK_SIZE} ${NUM_THREADS}" "parallel"
run_threading "matrix_parallel" "${MATRIX_SIZE} ${BLOCK_SIZE} ${NUM_THREADS}" "parallel"
run_memory_access "matrix_parallel" "${MATRIX_SIZE} ${BLOCK_SIZE} ${NUM_THREADS}" "parallel"

echo -e "${GREEN}=== All profiling complete! ===${NC}"
echo ""
echo "To view all results in VTune GUI:"
echo "  vtune-gui ${RESULTS_DIR}"
echo ""
