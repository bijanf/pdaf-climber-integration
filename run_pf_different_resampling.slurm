#!/bin/bash
#SBATCH --job-name=pdaf_pf_resampling
#SBATCH --output=pf_resampling_test_%j.out
#SBATCH --error=pf_resampling_test_%j.err
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=8G
#SBATCH --partition=priority
#SBATCH --account=poem
#SBATCH --qos=priority

# Test Different Resampling Algorithms for Particle Filter
# This script tests various resampling methods to fix the crash

set -e  # Exit on any error

echo "=== Testing Different Resampling Algorithms ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Running on node: $(hostname)"
echo "Testing various resampling methods to fix particle filter crash"
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
cd tutorial/offline_2D_serial

echo "=== Compiling offline tutorial ==="
make clean
make PDAF_offline

if [ $? -eq 0 ]; then
    echo "✓ Compilation successful!"
else
    echo "✗ Compilation failed!"
    exit 1
fi

echo
echo "=== Testing Different Resampling Algorithms ==="

# Copy input files from inputs_offline directory
echo "Copying input files..."
cp ../inputs_offline/*.txt .

# Test 1: Residual Resampling (type 3)
echo "=== Test 1: Residual Resampling (type 3) ==="
echo "Command: ./PDAF_offline -filtertype 12 -dim_ens 50 -nsteps 3 -pf_res_type 3 -pf_noise_type 2 -pf_noise_amp 0.3"
echo

./PDAF_offline -filtertype 12 -dim_ens 50 -nsteps 3 -pf_res_type 3 -pf_noise_type 2 -pf_noise_amp 0.3

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! Residual resampling works!"
    echo "Moving output files..."
    mv ens*ana.txt ens_residual_ana.txt 2>/dev/null || echo "No analysis files"
    mv state_ana.txt state_residual_ana.txt 2>/dev/null || echo "No state file"
else
    echo "✗ Residual resampling failed"
fi

echo
echo "=== Test 2: Stochastic Universal Resampling (type 2) ==="
echo "Command: ./PDAF_offline -filtertype 12 -dim_ens 50 -nsteps 3 -pf_res_type 2 -pf_noise_type 2 -pf_noise_amp 0.3"
echo

./PDAF_offline -filtertype 12 -dim_ens 50 -nsteps 3 -pf_res_type 2 -pf_noise_type 2 -pf_noise_amp 0.3

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! Stochastic universal resampling works!"
    echo "Moving output files..."
    mv ens*ana.txt ens_stochastic_ana.txt 2>/dev/null || echo "No analysis files"
    mv state_ana.txt state_stochastic_ana.txt 2>/dev/null || echo "No state file"
else
    echo "✗ Stochastic universal resampling failed"
fi

echo
echo "=== Test 3: Probabilistic Resampling with No Noise (type 1) ==="
echo "Command: ./PDAF_offline -filtertype 12 -dim_ens 50 -nsteps 3 -pf_res_type 1 -pf_noise_type 0 -pf_noise_amp 0.0"
echo

./PDAF_offline -filtertype 12 -dim_ens 50 -nsteps 3 -pf_res_type 1 -pf_noise_type 0 -pf_noise_amp 0.0

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! Probabilistic resampling with no noise works!"
    echo "Moving output files..."
    mv ens*ana.txt ens_probabilistic_ana.txt 2>/dev/null || echo "No analysis files"
    mv state_ana.txt state_probabilistic_ana.txt 2>/dev/null || echo "No state file"
else
    echo "✗ Probabilistic resampling with no noise failed"
fi

echo
echo "=== Test 4: Probabilistic Resampling with Constant Noise (type 1) ==="
echo "Command: ./PDAF_offline -filtertype 12 -dim_ens 50 -nsteps 3 -pf_res_type 1 -pf_noise_type 1 -pf_noise_amp 0.1"
echo

./PDAF_offline -filtertype 12 -dim_ens 50 -nsteps 3 -pf_res_type 1 -pf_noise_type 1 -pf_noise_amp 0.1

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! Probabilistic resampling with constant noise works!"
    echo "Moving output files..."
    mv ens*ana.txt ens_probabilistic_const_ana.txt 2>/dev/null || echo "No analysis files"
    mv state_ana.txt state_probabilistic_const_ana.txt 2>/dev/null || echo "No state file"
else
    echo "✗ Probabilistic resampling with constant noise failed"
fi

echo
echo "=== Resampling Test Summary ==="
echo "Testing different resampling algorithms to find the most stable one:"
echo "1. Residual resampling (type 3): $(if [ -f ens_residual_ana.txt ]; then echo "SUCCESS"; else echo "FAILED"; fi)"
echo "2. Stochastic universal resampling (type 2): $(if [ -f ens_stochastic_ana.txt ]; then echo "SUCCESS"; else echo "FAILED"; fi)"
echo "3. Probabilistic resampling, no noise (type 1): $(if [ -f ens_probabilistic_ana.txt ]; then echo "SUCCESS"; else echo "FAILED"; fi)"
echo "4. Probabilistic resampling, constant noise (type 1): $(if [ -f ens_probabilistic_const_ana.txt ]; then echo "SUCCESS"; else echo "FAILED"; fi)"
echo
echo "Generated files:"
ls -la ens*_ana.txt state*_ana.txt 2>/dev/null || echo "No analysis files found"

echo
echo "=== Job completed ===" 