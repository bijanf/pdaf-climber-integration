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

echo "Starting CLIMBER-X compilation with PDAF..."

# Load required modules (exact same as working CLIMBER-X setup)
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

# Set PDAF environment variables
export PDAF_ROOT=/home/fallah/scripts/POEM/TESTS/software/PDAF
export PDAF_ARCH=linux_intel
export PDAF_INC=${PDAF_ROOT}/include
export PDAF_LIB=${PDAF_ROOT}/lib

echo "PDAF environment variables set:"
echo "  PDAF_ROOT: $PDAF_ROOT"
echo "  PDAF_ARCH: $PDAF_ARCH"

# Navigate to CLIMBER-X directory
cd /home/fallah/scripts/POEM/TESTS/climber-x

# Clean and compile
echo "Cleaning previous build..."
make clean

echo "Starting compilation..."
make climber-clim

# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo "SUCCESS: CLIMBER-X compiled successfully with PDAF!"
    ls -la climber-clim.x
else
    echo "ERROR: Compilation failed!"
    exit 1
fi 