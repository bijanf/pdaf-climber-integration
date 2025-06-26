#!/bin/bash
# Environment setup script for PDAF-CLIMBER-X integration

echo "Setting up PDAF-CLIMBER-X environment..."

# Load modules (adjust for your system)
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

# Set PDAF environment variables (adjust paths for your system)
export PDAF_ROOT=/path/to/your/PDAF/installation
export PDAF_ARCH=linux_intel
export PDAF_INC=${PDAF_ROOT}/include
export PDAF_LIB=${PDAF_ROOT}/lib

echo "Environment setup complete!"
echo "PDAF_ROOT: $PDAF_ROOT"
echo "PDAF_ARCH: $PDAF_ARCH"
echo ""
echo "Note: Please adjust PDAF_ROOT to point to your PDAF installation"
