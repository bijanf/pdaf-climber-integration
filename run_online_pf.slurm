#!/bin/bash
#SBATCH --job-name=online_pf
#SBATCH --output=online_pf_%j.out
#SBATCH --error=online_pf_%j.err
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=20
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --partition=priority
#SBATCH --account=poem
#SBATCH --qos=priority

# Run Online Mode Particle Filter (model_pdaf)
# Fixed: ntasks=20 to match dim_ens=20

set -e

echo "=== Online Mode Particle Filter Test ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Running on node: $(hostname)"
echo "MPI processes: $SLURM_NTASKS"
echo

# Load required modules
module load intel/oneAPI/2023.2.0
module load mkl/2023.2.0
module load netcdf-fortran-intel/4.6.1

# Set PDAF architecture
export PDAF_ARCH=linux_intel
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

echo "Environment setup complete"
echo "PDAF architecture: $PDAF_ARCH"
echo "OpenMP threads: $OMP_NUM_THREADS"
echo "MPI processes: $SLURM_NTASKS"
echo

# Change to online tutorial directory
cd tutorial/online_2D_serialmodel

# Clean and compile
make clean
make model_pdaf

if [ $? -eq 0 ]; then
    echo "✓ Compilation successful!"
else
    echo "✗ Compilation failed!"
    exit 1
fi

# Copy input files
cp ../inputs_online/*.txt .

echo "=== Running model_pdaf (Particle Filter) ==="
echo "Command: mpirun -np 20 ./model_pdaf -filtertype 12 -dim_ens 20 -nsteps 3 -pf_res_type 2 -pf_noise_type 2 -pf_noise_amp 0.3"

mpirun -np 20 ./model_pdaf -filtertype 12 -dim_ens 20 -nsteps 3 -pf_res_type 2 -pf_noise_type 2 -pf_noise_amp 0.3

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! Online particle filter completed!"
else
    echo "✗ Online particle filter failed!"
fi

echo "=== Job completed ===" 