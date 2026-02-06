# VTune Tutorial - Project Structure

## Directory Layout

```
vtune-tutorial/
│
├── README.md                      # Complete tutorial (30+ pages)
├── TROUBLESHOOTING.md             # Common issues encountered
├── Makefile                       # Build system
│
├── src/                           # Source code
│   ├── matrix_naive.cpp       # Naive O(n³) implementation
│   ├── matrix_blocked.cpp     # Cache-optimized blocked version
│   └── matrix_parallel.cpp    # OpenMP parallel version
│
├── scripts/                       # Helper scripts
│   ├── profile_all.sh         # Automated full profiling
│
├── build/                         # Compiled binaries (created by make)
│   ├── matrix_naive
│   ├── matrix_blocked
│   └── matrix_parallel
│
└── results/                       # VTune profiling results (created with profile_all.sh)
    ├── naive_hotspots/
    ├── naive_memory/
    ├── blocked_hotspots/
    ├── blocked_memory/
    ├── parallel_hotspots/
    ├── parallel_threading/
    └── parallel_memory/
```

## File Descriptions

### Documentation

**README.md** - Main tutorial document
- Prerequisites and installation
- Detailed explanations of implementations
- VTune workflow and analysis types
- Step-by-step profiling tutorial
- Results interpretation guide
- Advanced topics

**TROUBLESHOOTING.md** - Tutorial presentation
- Common issues encountered with fixes

### Source Code

**matrix_naive.cpp** - Baseline implementation
```cpp
Key features:
- Simple triple-nested loop
- Row-major for A and C, column-major access for B
- Poor cache locality
```

**matrix_blocked.cpp** - Blocked/tiled version
```cpp
Key features:
- 6-deep nested loops (3 block + 3 element)
- Configurable block size
- Better cache locality
```

**matrix_parallel.cpp** - Parallel blocked version
```cpp
Key features:
- OpenMP #pragma omp parallel for
- Dynamic scheduling
- Thread count configurable
- Combines blocking + parallelism
```

### Scripts

**profile_all.sh** - Comprehensive profiling
```bash
Features:
- Profiles all three implementations
- Multiple analysis types per implementation
- Automated execution
```

### Build System

**Makefile** - Build automation
```makefile
Targets:
- all:   Build all three programs
- clean: Remove build directory
- test:  Quick functionality test
```

## Extension Ideas

### For Learning

1. **Add vectorization:**
   - Use compiler auto-vectorization
   - Add explicit SIMD intrinsics
   - Profile with VTune vectorization analysis

2. **Try different algorithms:**
   - Strassen's algorithm
   - Recursive blocking
   - Cache-oblivious version

3. **GPU acceleration:**
   - CUDA implementation
   - OpenCL version
   - Profile with VTune GPU analysis

### For Teaching

1. **Create exercises:**
   - Find optimal block size for different CPUs depending on the cache size
   - Compare with Intel oneAPI Math Kernel Library (oneMKL)
   - Use different compilers or different optimization levels

2. **Add visualizations:**
   - Cache behavior animations
   - Thread timeline visualization
   - Performance comparison charts

