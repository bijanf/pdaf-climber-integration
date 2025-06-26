# PDAF Integration with CLIMBER-X - Complete Guide

## Overview
This document records the successful integration of PDAF (Parallel Data Assimilation Framework) with CLIMBER-X climate model using Intel OneAPI compiler.

## System Information
- **Cluster**: PIK HPC system
- **Account**: poem
- **Partition**: priority
- **Compiler**: Intel OneAPI 2024.0.0
- **Date**: June 26, 2024

## Step-by-Step Process

### 1. PDAF Installation
```bash
cd /home/fallah/scripts/POEM/TESTS/software/PDAF

# Create Intel configuration
# File: make.arch/linux_intel.h
FC = mpiifx
OPT = -O3 -cpp -qopenmp
MODULEOPT = -module

# Build PDAF
export PDAF_ARCH=linux_intel
make clean && make
```

### 2. CLIMBER-X Setup (Original Working Configuration)
```bash
cd /home/fallah/scripts/POEM/TESTS/climber-x

# Load modules (exact working configuration)
module purge
module use /p/system/modulefiles/compiler \
           /p/system/modulefiles/gpu \
           /p/system/modulefiles/libraries \
           /p/system/modulefiles/parallel \
           /p/system/modulefiles/tools

module load intel/oneAPI/2024.0.0
module load netcdf-c/4.9.2
module load netcdf-fortran-intel/4.6.1
module load udunits/2.2.28
module load ncview/2.1.10
module load cdo/2.4.2
```

### 3. FESM-UTILS Installation
```bash
cd src/utils/fesm-utils/utils
python config.py config/pik_hpc2024_ifx
make clean
make fesmutils-static openmp=0  # serial version
make fesmutils-static openmp=1  # parallel version
cd ../../../..
```

### 4. PDAF Integration
```bash
# Add PDAF configuration to Makefile
# PDAF Integration
PDAFROOT = ../software/PDAF
INC_PDAF = -I${PDAFROOT}/include
LIB_PDAF = -L${PDAFROOT}/lib -lpdaf-var

# Add PDAF to existing flags
FFLAGS_FULL := $(FFLAGS_FULL) $(INC_PDAF)
FFLAGS_CLIM := $(FFLAGS_CLIM) $(INC_PDAF)
LFLAGS_FULL := $(LFLAGS_FULL) $(LIB_PDAF)
LFLAGS_CLIM := $(LFLAGS_CLIM) $(LIB_PDAF)
```

### 5. Compilation Script
```bash
# File: compile_with_pdaf.slurm
#!/bin/bash
#SBATCH --job-name=climber_pdaf_compile
#SBATCH --account=poem
#SBATCH --partition=priority
#SBATCH --qos=priority
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=compile_%j.out
#SBATCH --error=compile_%j.err

# Load modules
module purge
module use /p/system/modulefiles/compiler \
           /p/system/modulefiles/gpu \
           /p/system/modulefiles/libraries \
           /p/system/modulefiles/parallel \
           /p/system/modulefiles/tools

module load intel/oneAPI/2024.0.0
module load netcdf-c/4.9.2
module load netcdf-fortran-intel/4.6.1
module load udunits/2.2.28
module load ncview/2.1.10
module load cdo/2.4.2

# Set PDAF environment
export PDAF_ROOT=/home/fallah/scripts/POEM/TESTS/software/PDAF
export PDAF_ARCH=linux_intel
export PDAF_INC=${PDAF_ROOT}/include
export PDAF_LIB=${PDAF_ROOT}/lib

# Compile
cd /home/fallah/scripts/POEM/TESTS/climber-x
make clean && make climber-clim
```

## Key Files Created/Modified

### PDAF Configuration
- `make.arch/linux_intel.h` - Intel compiler configuration for PDAF

### CLIMBER-X Integration
- `Makefile` - Modified to include PDAF paths and libraries
- `compile_with_pdaf.slurm` - SLURM script for compilation

### FESM-UTILS
- `src/utils/fesm-utils/utils/include-omp/libfesmutils.a` - OpenMP version
- `src/utils/fesm-utils/utils/include-serial/libfesmutils.a` - Serial version

## Environment Variables
```bash
export PDAF_ROOT=/home/fallah/scripts/POEM/TESTS/software/PDAF
export PDAF_ARCH=linux_intel
export PDAF_INC=${PDAF_ROOT}/include
export PDAF_LIB=${PDAF_ROOT}/lib
```

## Compilation Commands
```bash
# Submit compilation job
sbatch compile_with_pdaf.slurm

# Monitor progress
squeue -j <job_id>
tail -f compile_<job_id>.out
```

## Troubleshooting

### Memory Issues
- Use `-O2 -no-ipo` instead of `-Ofast` for memory-friendly compilation
- Allocate sufficient memory (32GB recommended)

### Module Issues
- Always use the exact module configuration that worked for original CLIMBER-X
- Intel OneAPI 2024.0.0 is the working version

### FESM-UTILS Issues
- Must build both serial and OpenMP versions
- Use `python config.py config/pik_hpc2024_ifx` for configuration

## Next Steps for Particle Filter Testing
1. Set up input data
2. Configure PDAF particle filter parameters
3. Create assimilation experiment
4. Run test simulation

## Files to Backup
- `Makefile` (with PDAF integration)
- `compile_with_pdaf.slurm`
- `make.arch/linux_intel.h`
- FESM-UTILS libraries
- Compiled `climber.x` executable

---
*Generated on: June 26, 2024*
*Status: SUCCESS - CLIMBER-X compiled with PDAF support* 