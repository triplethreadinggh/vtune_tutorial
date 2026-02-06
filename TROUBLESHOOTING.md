# Support and Troubleshooting

This document provides quick fixes for common issues encountered when using VTune on Linux.

---

## Quick Fixes

### 1. VTune not found
```bash
# Source environment
source /opt/intel/oneapi/setvars.sh

# Check
which vtune
vtune --version
```

### 2. Permission errors
```bash
# Adjust perf settings (temporary)
echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
```

