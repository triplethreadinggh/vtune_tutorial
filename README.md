# VTune Profiling Tutorial: Matrix Multiplication Optimization

This tutorial demonstrates how to use Intel VTune Profiler to analyze and optimize matrix multiplication algorithms, progressing from a naive implementation to blocked and parallel versions.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Tutorial Overview](#tutorial-overview)
3. [Building the Programs](#building-the-programs)
4. [Understanding the Implementations](#understanding-the-implementations)
5. [VTune Profiling Workflow](#vtune-profiling-workflow)
6. [Analysis Types](#analysis-types)
7. [Step-by-Step Tutorial](#step-by-step-tutorial)
8. [Interpreting Results](#interpreting-results)
9. [Advanced Topics](#advanced-topics)

## Prerequisites

### Required Software
- **Intel VTune Profiler** (part of Intel oneAPI Toolkit or standalone)
- **C Compiler** with C17 support
- **OpenMP** support for parallel implementation
- Linux operating system

### Installing VTune

**Option 1: Intel oneAPI Toolkit (Recommended)**
```bash
# Download from: https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html
# Make sure Linux is selected for the Operating System. Look at the Installation form the Command Line.
# It should have a command similar to this, with the latest oneAPI Toolkit version:
wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/33cb2a22-ddf1-4aa9-8d68-1f5a118acaf2/intel-oneapi-toolkit-2026.1.0.192_offline.sh
sudo sh ./intel-oneapi-toolkit-2026.1.0.192_offline.sh -a --silent --cli --eula accept
# After installation, source the environment:
source /opt/intel/oneapi/setvars.sh
```

**Option 2: Standalone VTune**
```bash
# Download from Intel website and install
# Source the environment:
source <vtune-install-dir>/env/vars.sh
```

**Automatic Intel oneAPI Environment Setup**
```bash
# Initialize Intel oneAPI environment whenever you open a new terminal
vi ~/.bashrci

# Pate the following code at the end of the file
if [[ $- == *i* ]]; then
    source /opt/intel/oneapi/setvars.sh
fi
```

**Verify Installation:**
```bash
vtune --version
```

### System Configuration for VTune

**1. Enabling process tracing with ptrace:**
```bash
#Check current ptrace setting
sysctl kernel.yama.ptrace_scope

#If the output is 1 or 2, allow VTune to attach temporarily
sudo sysctl -w kernel.yama.ptrace_scope=0
```

**2. Set file descriptor limit:**
```bash
#Raise the maximum number of file descriptors for counters
ulimit -n 65536

#If you want to make it permanent (requires reboot)
sudo vi /etc/systemd/user.conf

#Uncomment or add to the file
DefaultLimitNOFILE=65536
```

**3. Enable kernel symbol access**
```bash
#Allows VTune to see kernel function names in profiles
sudo sysctl -w kernel.kptr_restrict=0

#If you want to make it permanent (requires reboot)
vi /etc/sysctl.d/99-sysctl.conf

#Add at the end of the file
kernel.kptr_restrict=0
```

**4. Enable performance event collection**
```bash
#Allows VTune access to hardware performance counters without requiring root privileges
sudo sysctl -w kernel.perf_event_paranoid=-1

#If you want to make it permanent (requires reboot)
vi /etc/sysctl.d/99-sysctl.conf

#Add at the end of the file, or set to -1 if already exists
kernel.perf_event_paranoid=-1
```
**5. Disable watchdog timer
```bash
# Modern CPUs have only a few hardware performance-monioring counters (PMCs) per core.
# There is often 4 to 8 of them and we will need as many as possible for our VTune measurements.
# That is why we need to disable the watchdog timer which usually claims one of these counters.
sudo sysctl -w kernel.nmi_watchdog=0

# If you want to make it permanent (requires reboot)
vi /etc/sysctl.d/99-sysctl.conf

# Add at the end of the file:
kernel.nmi_watchdog=0

**Verify configuration:**
```bash
vtune-self-checker.sh
```

**5. Advanced: VTune sampling driver - DOUBLE CHECK ON A NEW MACHINE**
```bash
# Navigate to the driver source directory
cd /opt/intel/oneapi/vtune/latest/sepdk/src/

# Build the drivers
sudo ./build-driver

# Load the drivers
sudo ./insmod-sep -g vtune

# Verify drivers are loaded, you should see sep5
lsmod | grep sep

# Check driver permissions
ls -l /dev/sep*

# Add your user to vtune group. Requires re-login
sudo usermod -a -G vtune $USER
```

## Tutorial Overview

We'll analyze three implementations of matrix multiplication:

1. **Naive Implementation** (`matrix_naive.cpp`)
   - Simple triple-nested loop: O(n³)
   - Poor cache locality
   - Baseline for comparison

2. **Blocked Implementation** (`matrix_blocked.cpp`)
   - Cache-aware blocking/tiling
   - Improved memory access patterns
   - Better cache utilization

3. **Parallel Blocked Implementation** (`matrix_parallel.cpp`)
   - OpenMP parallelization
   - Multi-threaded execution
   - Combined blocking + parallelism

### Learning Objectives
- Learn VTune interface and workflow
- Identify performance bottlenecks using different analysis types
- Understand cache behavior and memory access patterns
- Analyze thread parallelism and load balancing
- Compare performance metrics across implementations

## Building the Programs

### Quick Build
```bash
cd vtune-tutorial
make all
```

### Manual Build
```bash
# Create build directory
mkdir -p build

# Compile naive version
gcc -O3 -g -fno-omit-frame-pointer -std=c17 src/matrix_naive.c -o build/matrix_naive

# Compile blocked version
gcc -O3 -g -fno-omit-frame-pointer -std=c17 src/matrix_blocked.c -o build/matrix_blocked

# Compile parallel version
gcc -O3 -g -fno-omit-frame-pointer -std=c17 -fopenmp src/matrix_parallel.c -o build/matrix_parallel
```

### Test the Programs
```bash
make test

# Or manually:
./build/matrix_naive 512
./build/matrix_blocked 512 64
./build/matrix_parallel 512 64 4
```

### Compilation Flags Explained
- `-O3`: Enable aggressive optimization
- `-g`: Include debug symbols so vTune can map assembly back to C code
- `-fno-omit-frame-pointer`: Keep the frame pointer register so VTune can reliably reconstruct call stack
- `-std=c17`: Use C17 standard
- `-fopenmp`: Enable OpenMP support

## Understanding the Implementations

### Naive Implementation

**Algorithm:**
```
for i = 0 to N-1:
    for j = 0 to N-1:
        for k = 0 to N-1:
            C[i][j] += A[i][k] * B[k][j]
```

**Performance Characteristics:**
- ❌ Poor cache locality (accesses B column-wise)
- ❌ High cache miss rate
- ❌ Memory bandwidth bottleneck
- ✅ Simple to understand

### Blocked Implementation

**Algorithm:**
```
for ii = 0 to N-1 step BLOCK_SIZE:
    for jj = 0 to N-1 step BLOCK_SIZE:
        for kk = 0 to N-1 step BLOCK_SIZE:
            for i = ii to min(ii+BLOCK_SIZE, N-1):
                for j = jj to min(jj+BLOCK_SIZE, N-1):
                    for k = kk to min(kk+BLOCK_SIZE, N-1):
                        C[i][j] += A[i][k] * B[k][j]
```

**Performance Characteristics:**
- ✅ Better cache locality (processes small blocks that fit in cache)
- ✅ Reduced cache misses
- ✅ More efficient memory access
- ⚠️ Optimal block size depends on cache size

### Parallel Blocked Implementation

**Algorithm:**
- Same as blocked but with OpenMP parallelization
- `#pragma omp parallel for` distributes blocks across threads

```
#pragma omp parallel for schedule(dynamic)
for ii = 0 to N-1 step BLOCK_SIZE:
    for jj = 0 to N-1 step BLOCK_SIZE:
        for kk = 0 to N-1 step BLOCK_SIZE:
            for i = ii to min(ii+BLOCK_SIZE, N-1):
                for j = jj to min(jj+BLOCK_SIZE, N-1):
                    for k = kk to min(kk+BLOCK_SIZE, N-1):
                        C[i][j] += A[i][k] * B[k][j]
```

**Performance Characteristics:**
- ✅ Exploits multi-core processors
- ✅ Better cache locality from blocking
- ✅ Scalable performance
- ⚠️ Requires thread management overhead

## VTune Profiling Workflow

### Basic Workflow

```
1. Compile with debug symbols (-g flag)
2. Run VTune collection
3. Analyze results in VTune GUI or command line
4. Identify bottlenecks
5. Optimize code
6. Re-profile and compare
```

### VTune Command Structure

```bash
vtune -collect <analysis-type> \
      -result-dir <output-directory> \
      [options] \
      -- <your-application> [app-args]
```

## Analysis Types

### 1. Hotspots Analysis
**Purpose:** Identify CPU-intensive functions and code regions

**Use When:**
- Starting performance analysis
- Finding where program spends most time
- Comparing execution time across functions

**Metrics:**
- CPU Time
- Function call counts
- Time per function

**Command:**
```bash
vtune -collect hotspots -result-dir results/hotspots -- ./build/matrix_naive 1024
```

### 2. Memory Access Analysis
**Purpose:** Analyze memory access patterns and cache behavior

**Use When:**
- Investigating cache misses
- Understanding memory bandwidth utilization
- Optimizing data structures

**Metrics:**
- L1/L2/L3 cache hit rates
- Memory bandwidth
- DRAM accesses
- Average latency

**Command:**
```bash
vtune -collect memory-access -result-dir results/memory -- ./build/matrix_naive 1024
```

### 3. Threading Analysis
**Purpose:** Analyze parallel program behavior and thread utilization

**Use When:**
- Profiling multi-threaded applications
- Identifying load imbalance
- Detecting synchronization issues

**Metrics:**
- Thread concurrency
- Wait time
- Spin time
- Effective CPU utilization

**Command:**
```bash
vtune -collect threading -result-dir results/threading -- ./build/matrix_parallel 1024 64 4
```

### 4. Microarchitecture Exploration
**Purpose:** Deep dive into CPU microarchitecture bottlenecks

**Use When:**
- Need detailed hardware performance counters
- Investigating pipeline stalls
- Advanced optimization

**Metrics:**
- Instructions per cycle (IPC)
- Branch mispredictions
- Pipeline stalls
- Port utilization

**Command:**
```bash
vtune -collect uarch-exploration -result-dir results/uarch -- ./build/matrix_blocked 1024 64
```

## Step-by-Step Tutorial

### Part 1: Profile Naive Implementation

#### Step 1: Run Hotspots Analysis

```bash
# Profile the naive implementation
vtune -collect hotspots \
      -result-dir results/naive_hotspots \
      -- ./build/matrix_naive 1024

# View summary in terminal
vtune -report summary -result-dir results/naive_hotspots

# View detailed hotspots report
vtune -report hotspots -result-dir results/naive_hotspots

# Open in GUI (recommended)
vtune-gui results/naive_hotspots
```

**What to Look For:**
- Time spent in `matrix_multiply_naive` function
- Time spent in individual loops

#### Step 2: Run Memory Access Analysis

```bash
vtune -collect memory-access \
      -result-dir results/naive_memory \
      -- ./build/matrix_naive 1024

# Open in GUI
vtune-gui results/naive_memory
```

**What to Look For:**
- How often was the CPU stalled on each of L1/L2/L3 Cache or DRAM
- On CPUs with heterogeneous architecture these metrics are per type of Core
- Number of Loads and Stores
- Latency Histogram

### Part 2: Profile Blocked Implementation

#### Step 1: Run Hotspots Analysis

```bash
vtune -collect hotspots \
      -result-dir results/blocked_hotspots \
      -- ./build/matrix_blocked 1024 64

vtune-gui results/blocked_hotspots
```

**Compare with Naive:**
- Total execution time should be lower

#### Step 2: Run Memory Access Analysis

```bash
vtune -collect memory-access \
      -result-dir results/blocked_memory \
      -- ./build/matrix_blocked 1024 64

vtune-gui results/blocked_memory

# You can also compare results. Vtune will calculate naive_memory - blocked_memory metrics
vtune-gui results/naive_memory/ results/blocked_memory/
```

**What to Look For:**
- Check memory bound metrics. Lower percentages for memory stalls
- Lower Average Latency (cycles)

#### Step 3: Experiment with Block Sizes

```bash
# Try different block sizes
for BS in 16 32 64 128 256; do
    vtune -collect hotspots \
          -result-dir results/blocked_bs${BS} \
          -- ./build/matrix_blocked 1024 $BS
done

# Compare results
vtune -report summary -result-dir results/blocked_bs16
vtune -report summary -result-dir results/blocked_bs64
vtune -report summary -result-dir results/blocked_bs128
```

### Part 3: Profile Parallel Implementation

#### Step 1: Run Hotspots Analysis

```bash
# Profile with different thread counts
for T in 1 2 4 8; do
    vtune -collect hotspots \
          -result-dir results/parallel_t${T}_hotspots \
          -- ./build/matrix_parallel 1024 64 $T
done
```

#### Step 2: Run Threading Analysis

```bash
vtune -collect threading \
      -result-dir results/parallel_threading \
      -- ./build/matrix_parallel 1024 64 4

vtune-gui results/parallel_threading
```

**What to Look For:**
- Effective CPU Utilization
- Thread utilization timeline

#### Step 3: Run Memory Access Analysis

```bash
vtune -collect memory-access \
      -result-dir results/parallel_memory \
      -- ./build/matrix_parallel 1024 64 4

vtune-gui results/parallel_memory
```

**What to Look For:**
- In Bottom-up analysis window, you can select the Grouping: Function/Thread/Logical Core/Call Stack and here you can observe on which physical core is each thread spending time.


### Part 4: Compare All Implementations

Use the automated script:

```bash
./scripts/profile_all.sh
```

This will generate all profiles for easy comparison.

## Interpreting Results

### VTune GUI Overview

When you open VTune GUI (`vtune-gui results/your_result`), you'll see:

1. **Summary Tab**
   - Elapsed time
   - Top hotspots
   - Key metrics

2. **Bottom-up Tab**
   - Function list sorted by CPU time
   - Call stacks
   - Source code view

3. **Top-down Tree**
   - Call hierarchy
   - Time spent in each function and its callees

4. **Caller/Callee**
   - Who calls this function
   - What this function calls

## Advanced Topics

### 1. Comparing Multiple Results

```bash
# Generate comparison report
vtune -report summary -result-dir results/naive_hotspots -format csv > naive.csv
vtune -report summary -result-dir results/blocked_hotspots -format csv > blocked.csv
vtune -report summary -result-dir results/parallel_hotspots -format csv > parallel.csv

# Or use GUI comparison feature
vtune-gui results/naive_hotspots results/blocked_hotspots results/parallel_hotspots
```

### 2. Source Code Analysis

In VTune GUI:
1. Click on a function in Bottom-up view
2. Double-click to see source code
3. View line-by-line performance data
4. Compare C code to Assembly code

### 3. Analyzing Different Matrix Sizes

```bash
for SIZE in 256 512 1024 2048; do
    echo "Profiling size: $SIZE"
    vtune -collect hotspots \
          -result-dir results/naive_${SIZE} \
          -- ./build/matrix_naive $SIZE
done

# Compare performance scaling
for SIZE in 256 512 1024 2048; do
    echo "=== Size: $SIZE ==="
    vtune -report summary -result-dir results/naive_${SIZE} | grep "Time elapsed:"
done
```

### 4. Finding Optimal Block Size

```bash
#!/bin/bash
echo "Block Size, Elapsed Time, GFLOPS" > block_size_analysis.csv

for BS in 8 16 24 32 48 64 96 128 192 256; do
    vtune -collect hotspots \
          -result-dir results/bs_test_${BS} \
          -- ./build/matrix_blocked 1024 $BS 2>&1 | \
          grep -E "Time elapsed|Performance" >> block_size_analysis.csv
done
```

### 5. Profiling with Different Optimization Levels

Rebuild with different optimization flags and compare:

```bash
# -O0 (no optimization)
gcc -O0 -g -std=c17 src/matrix_blocked.c -o build/matrix_blocked_O0

# -O2 (moderate optimization)
gcc -O2 -g -std=c17 src/matrix_blocked.c -o build/matrix_blocked_O2

# -O3 (aggressive optimization)
gcc -O3 -g -std=c17 src/matrix_blocked.c -o build/matrix_blocked_O3

# Profile each
for OPT in O0 O2 O3; do
    vtune -collect hotspots \
          -result-dir results/blocked_${OPT} \
          -- ./build/matrix_blocked_${OPT} 1024 64
done
```

## Quick Reference

### Common Commands

```bash
# Build everything
make all

# Full automated profiling
./scripts/profile_all.sh

# View results
vtune-gui results/

# Generate text report
vtune -report summary -result-dir results/naive_hotspots
```

## Next Steps

1. **Experiment**: Try different matrix sizes and block sizes
2. **Optimize**: Use insights from VTune to improve code
3. **Compare**: Profile before and after each optimization
4. **Learn**: Study VTune documentation for advanced features
5. **Apply**: Use these techniques on your own applications

## Additional Resources

- [Intel 64 and IA-32 Architectures Software Developer's Manual Combined Volumes](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [Intel VTune Profiler Documentation](https://www.intel.com/content/www/us/en/develop/documentation/vtune-help/top.html)
- [VTune Cookbook](https://www.intel.com/content/www/us/en/develop/documentation/vtune-cookbook/top.html)
- [Performance Analysis Guide for Intel Core Processors](https://www.intel.com/content/www/us/en/develop/documentation/vtune-help/top/analyze-performance.html)

