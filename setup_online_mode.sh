#!/bin/bash
# Setup Online Mode for CLIMBER-X Integration
# This script prepares the online mode for CLIMBER-X integration

set -e  # Exit on any error

echo "=== Setting Up Online Mode for CLIMBER-X Integration ==="
echo "This will prepare online mode which integrates PDAF directly into CLIMBER-X"
echo

# Check if we're in the right directory
if [ ! -f "Makefile" ]; then
    echo "Error: Please run this script from the PDAF root directory"
    exit 1
fi

# Load required modules
echo "Loading required modules..."
module load intel/oneAPI/2023.2.0
module load mkl/2023.2.0
module load netcdf-fortran-intel/4.6.1

# Set PDAF architecture
export PDAF_ARCH=linux_intel

echo "Using PDAF architecture: $PDAF_ARCH"
echo

# Change to tutorial directory
cd tutorial/online_2D_serialmodel

echo "=== Compiling Online Tutorial ==="
make clean
make PDAF_online

if [ $? -eq 0 ]; then
    echo "✓ Online compilation successful!"
else
    echo "✗ Online compilation failed!"
    exit 1
fi

echo
echo "=== Online Mode Features ==="
echo "Online mode integrates PDAF directly into the model:"
echo "• Model and assimilation run together"
echo "• No need for separate ensemble files"
echo "• Better for real-time applications"
echo "• More efficient for large models"
echo

# Copy input files
echo "Copying input files..."
cp ../inputs_online/*.txt .

echo
echo "=== Testing Online Particle Filter ==="
echo "Running online particle filter with 20 ensemble members..."
echo "Command: ./PDAF_online -filtertype 12 -dim_ens 20 -nsteps 3 -pf_res_type 2 -pf_noise_type 2 -pf_noise_amp 0.3"
echo

./PDAF_online -filtertype 12 -dim_ens 20 -nsteps 3 -pf_res_type 2 -pf_noise_type 2 -pf_noise_amp 0.3

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! Online particle filter works!"
    echo
    echo "=== Online Mode Advantages ==="
    echo "✓ No ensemble file management needed"
    echo "✓ Direct integration with model"
    echo "✓ Better performance for large models"
    echo "✓ Real-time assimilation capability"
    echo
    echo "=== Next Steps for CLIMBER-X ==="
    echo "1. Copy PDAF integration files to CLIMBER-X"
    echo "2. Modify CLIMBER-X Makefile to include PDAF"
    echo "3. Add assimilation calls in CLIMBER-X code"
    echo "4. Test with CLIMBER-X model"
else
    echo "✗ Online particle filter failed"
    echo "This might indicate issues that need to be resolved before CLIMBER-X integration"
fi

echo
echo "=== Online Mode Setup Complete ===" 