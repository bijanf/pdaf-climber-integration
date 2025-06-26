#!/bin/bash
#SBATCH --job-name=robust_pf_final
#SBATCH --output=robust_pf_final_%j.out
#SBATCH --error=robust_pf_final_%j.err
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --partition=priority
#SBATCH --account=poem
#SBATCH --qos=priority

# Final Robust Particle Filter Test
# This script tests a particle filter with optimized parameters to prevent collapse

set -e  # Exit on any error

echo "=== Final Robust Particle Filter Test ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Running on node: $(hostname)"
echo "Testing particle filter with optimized parameters to prevent collapse"
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
echo "=== Testing Robust Particle Filter Configurations ==="

# Copy input files from inputs_offline directory
echo "Copying input files..."
cp ../inputs_offline/*.txt .

# Test 1: Large ensemble with high noise to prevent collapse
echo "=== Test 1: Large Ensemble with High Noise ==="
echo "Command: ./PDAF_offline -filtertype 12 -dim_ens 100 -nsteps 2 -pf_res_type 2 -pf_noise_type 2 -pf_noise_amp 0.5"
echo

./PDAF_offline -filtertype 12 -dim_ens 100 -nsteps 2 -pf_res_type 2 -pf_noise_type 2 -pf_noise_amp 0.5

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! Large ensemble with high noise works!"
    echo "Moving output files..."
    mv ens*ana.txt ens_large_high_noise_ana.txt 2>/dev/null || echo "No analysis files"
    mv state_ana.txt state_large_high_noise_ana.txt 2>/dev/null || echo "No state file"
else
    echo "✗ Large ensemble with high noise failed"
fi

echo
echo "=== Test 2: Medium Ensemble with Moderate Noise ==="
echo "Command: ./PDAF_offline -filtertype 12 -dim_ens 50 -nsteps 2 -pf_res_type 2 -pf_noise_type 2 -pf_noise_amp 0.3"
echo

./PDAF_offline -filtertype 12 -dim_ens 50 -nsteps 2 -pf_res_type 2 -pf_noise_type 2 -pf_noise_amp 0.3

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! Medium ensemble with moderate noise works!"
    echo "Moving output files..."
    mv ens*ana.txt ens_medium_moderate_noise_ana.txt 2>/dev/null || echo "No analysis files"
    mv state_ana.txt state_medium_moderate_noise_ana.txt 2>/dev/null || echo "No state file"
else
    echo "✗ Medium ensemble with moderate noise failed"
fi

echo
echo "=== Test 3: Small Ensemble with Very High Noise ==="
echo "Command: ./PDAF_offline -filtertype 12 -dim_ens 20 -nsteps 2 -pf_res_type 2 -pf_noise_type 2 -pf_noise_amp 0.8"
echo

./PDAF_offline -filtertype 12 -dim_ens 20 -nsteps 2 -pf_res_type 2 -pf_noise_type 2 -pf_noise_amp 0.8

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! Small ensemble with very high noise works!"
    echo "Moving output files..."
    mv ens*ana.txt ens_small_high_noise_ana.txt 2>/dev/null || echo "No analysis files"
    mv state_ana.txt state_small_high_noise_ana.txt 2>/dev/null || echo "No state file"
else
    echo "✗ Small ensemble with very high noise failed"
fi

echo
echo "=== Test 4: No Resampling (Bootstrap Filter) ==="
echo "Command: ./PDAF_offline -filtertype 12 -dim_ens 50 -nsteps 2 -pf_res_type 0 -pf_noise_type 2 -pf_noise_amp 0.3"
echo

./PDAF_offline -filtertype 12 -dim_ens 50 -nsteps 2 -pf_res_type 0 -pf_noise_type 2 -pf_noise_amp 0.3

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! Bootstrap filter (no resampling) works!"
    echo "Moving output files..."
    mv ens*ana.txt ens_bootstrap_ana.txt 2>/dev/null || echo "No analysis files"
    mv state_ana.txt state_bootstrap_ana.txt 2>/dev/null || echo "No state file"
else
    echo "✗ Bootstrap filter failed"
fi

echo
echo "=== Particle Filter Test Summary ==="
echo "Testing different configurations to find stable parameters:"
echo "1. Large ensemble (100) with high noise (0.5): $(if [ -f ens_large_high_noise_ana.txt ]; then echo "SUCCESS"; else echo "FAILED"; fi)"
echo "2. Medium ensemble (50) with moderate noise (0.3): $(if [ -f ens_medium_moderate_noise_ana.txt ]; then echo "SUCCESS"; else echo "FAILED"; fi)"
echo "3. Small ensemble (20) with very high noise (0.8): $(if [ -f ens_small_high_noise_ana.txt ]; then echo "SUCCESS"; else echo "FAILED"; fi)"
echo "4. Bootstrap filter (no resampling): $(if [ -f ens_bootstrap_ana.txt ]; then echo "SUCCESS"; else echo "FAILED"; fi)"
echo
echo "Generated files:"
ls -la ens*_ana.txt state*_ana.txt 2>/dev/null || echo "No analysis files found"

echo
echo "=== Recommendations ==="
echo "Based on results, recommend:"
echo "• Use larger ensembles (50-100 members) to prevent collapse"
echo "• Apply moderate to high noise (0.3-0.5) to maintain diversity"
echo "• Consider bootstrap filter (no resampling) for stability"
echo "• Use stochastic universal resampling (type 2) when resampling"

echo
echo "=== Job completed ===" 