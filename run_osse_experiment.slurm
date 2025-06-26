#!/bin/bash
#SBATCH --job-name=osse_experiment
#SBATCH --output=osse_experiment_%j.out
#SBATCH --error=osse_experiment_%j.err
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=priority
#SBATCH --account=poem
#SBATCH --qos=priority

# CLIMBER-X OSSE Experiment with Particle Filter
# Tests different ensemble sizes: 20, 40, 60, 80, 100

set -e

echo "=== CLIMBER-X OSSE Experiment ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Running on node: $(hostname)"
echo "Testing particle filter with different ensemble sizes"
echo

# Load required modules
echo "Loading required modules..."
module load intel/oneAPI/2023.2.0
module load mkl/2023.2.0
module load netcdf-fortran-intel/4.6.1
module load python/3.9.0

# Set PDAF architecture
export PDAF_ARCH=linux_intel

echo "Using PDAF architecture: $PDAF_ARCH"
echo

# OSSE experiment parameters
ENSEMBLE_SIZES=(20 40 60 80 100)
N_OBS_TAS=100
N_OBS_PR=100
N_YEARS=1000

echo "=== OSSE Experiment Configuration ==="
echo "Ensemble sizes to test: ${ENSEMBLE_SIZES[*]}"
echo "Observations per year: $N_OBS_TAS tas + $N_OBS_PR pr"
echo "Experiment length: $N_YEARS years"
echo

# Step 1: Generate synthetic observations
echo "=== Step 1: Generating Synthetic Observations ==="
if [ ! -f "nature_run.nc" ]; then
    echo "Error: nature_run.nc not found!"
    echo "Please run CLIMBER-X first to generate the nature run."
    exit 1
fi

echo "Generating synthetic observations from nature run..."
python3 generate_synthetic_obs.py \
    --nature_run nature_run.nc \
    --output_dir obs_data \
    --n_obs_tas $N_OBS_TAS \
    --n_obs_pr $N_OBS_PR \
    --n_years $N_YEARS

if [ $? -eq 0 ]; then
    echo "✓ Synthetic observations generated successfully"
else
    echo "✗ Failed to generate synthetic observations"
    exit 1
fi

echo
echo "=== Step 2: Running OSSE Experiments ==="

# Run experiments for each ensemble size
for ensemble_size in "${ENSEMBLE_SIZES[@]}"; do
    echo "Running OSSE experiment with ensemble size: $ensemble_size"
    
    # Create experiment directory
    exp_dir="osse_exp_${ensemble_size}"
    mkdir -p $exp_dir
    cd $exp_dir
    
    # Copy observation data
    cp -r ../obs_data .
    
    # Run CLIMBER-X with PDAF integration
    echo "  Compiling CLIMBER-X with PDAF..."
    make clean
    make climber_x_pdaf
    
    if [ $? -eq 0 ]; then
        echo "  ✓ CLIMBER-X compiled successfully"
    else
        echo "  ✗ CLIMBER-X compilation failed"
        cd ..
        continue
    fi
    
    # Run the OSSE experiment
    echo "  Running OSSE experiment..."
    ./climber_x_pdaf \
        --ensemble_size $ensemble_size \
        --n_obs_tas $N_OBS_TAS \
        --n_obs_pr $N_OBS_PR \
        --n_years $N_YEARS \
        --filter_type 12 \
        --output_dir osse_output
    
    if [ $? -eq 0 ]; then
        echo "  ✓ OSSE experiment completed for ensemble size $ensemble_size"
        
        # Save results
        cp -r osse_output ../osse_results_${ensemble_size}
        echo "  Results saved to: osse_results_${ensemble_size}"
    else
        echo "  ✗ OSSE experiment failed for ensemble size $ensemble_size"
    fi
    
    cd ..
    echo
done

echo
echo "=== Step 3: Analyzing Results ==="

# Run evaluation script
echo "Running evaluation script..."
python3 evaluate_osse_results.py \
    --ensemble_sizes "${ENSEMBLE_SIZES[*]}" \
    --n_years $N_YEARS \
    --output_dir osse_analysis

if [ $? -eq 0 ]; then
    echo "✓ Results analysis completed"
else
    echo "✗ Results analysis failed"
fi

echo
echo "=== OSSE Experiment Summary ==="
echo "Experiments completed for ensemble sizes: ${ENSEMBLE_SIZES[*]}"
echo "Results saved in: osse_results_* directories"
echo "Analysis saved in: osse_analysis directory"
echo
echo "=== Key Files Generated ==="
echo "• Synthetic observations: obs_data/"
echo "• OSSE results: osse_results_*/"
echo "• Analysis plots: osse_analysis/"
echo "• Final diagnostics: osse_analysis/final_diagnostics.txt"
echo
echo "=== Next Steps ==="
echo "1. Review results in osse_analysis/"
echo "2. Check particle filter performance vs ensemble size"
echo "3. Analyze RMS error reduction for tas and pr"
echo "4. Examine effective sample size trends"
echo
echo "=== Job completed ===" 