#!/bin/bash
#SBATCH --job-name=simple_osse
#SBATCH --output=simple_osse_%j.out
#SBATCH --error=simple_osse_%j.err
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --partition=priority
#SBATCH --account=poem
#SBATCH --qos=priority

# Simple OSSE Experiment using PDAF Tutorial
# Tests particle filter performance with different ensemble sizes

set -e

echo "=== Simple OSSE Experiment for Particle Filter ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Running on node: $(hostname)"
echo "Testing particle filter with different ensemble sizes"
echo

# Load required modules
echo "Loading required modules..."
module load intel/oneAPI/2023.2.0
module load mkl/2023.2.0
module load netcdf-fortran-intel/4.6.1

# Set PDAF architecture
export PDAF_ARCH=linux_intel

echo "Using PDAF architecture: $PDAF_ARCH"
echo

# OSSE experiment parameters
ENSEMBLE_SIZES=(20 40 60 80 100)
N_STEPS=10  # Reduced for testing
N_YEARS=10  # Reduced for testing

echo "=== OSSE Experiment Configuration ==="
echo "Ensemble sizes to test: ${ENSEMBLE_SIZES[*]}"
echo "Assimilation steps: $N_STEPS"
echo "Experiment length: $N_YEARS years (simplified)"
echo

# Change to PDAF tutorial directory
cd /home/fallah/scripts/POEM/TESTS/software/PDAF/tutorial/offline_2D_serial

echo "=== Step 1: Compiling PDAF Tutorial ==="
make clean
make PDAF_offline

if [ $? -eq 0 ]; then
    echo "✓ PDAF tutorial compilation successful!"
else
    echo "✗ PDAF tutorial compilation failed!"
    exit 1
fi

# Copy input files
cp ../inputs_offline/*.txt .

echo
echo "=== Step 2: Running OSSE Experiments ==="

# Create results directory
mkdir -p ../../climber-x/pdaf-climber-integration-github/osse_results
cd ../../climber-x/pdaf-climber-integration-github/osse_results

# Run experiments for each ensemble size
for ensemble_size in "${ENSEMBLE_SIZES[@]}"; do
    echo "Running OSSE experiment with ensemble size: $ensemble_size"
    
    # Create experiment directory
    exp_dir="osse_exp_${ensemble_size}"
    mkdir -p $exp_dir
    cd $exp_dir
    
    # Copy PDAF executable and input files
    cp /home/fallah/scripts/POEM/TESTS/software/PDAF/tutorial/offline_2D_serial/PDAF_offline .
    cp /home/fallah/scripts/POEM/TESTS/software/PDAF/tutorial/offline_2D_serial/*.txt .
    
    # Run the particle filter experiment
    echo "  Running particle filter with ensemble size $ensemble_size..."
    ./PDAF_offline -filtertype 12 -dim_ens $ensemble_size -nsteps $N_STEPS > osse_output.txt 2>&1
    
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "  ✓ OSSE experiment completed for ensemble size $ensemble_size"
        
        # Extract key metrics
        echo "  Extracting performance metrics..."
        
        # Check if assimilation worked
        if grep -q "Assimilating observations" osse_output.txt; then
            echo "    ✓ Assimilation step executed"
        else
            echo "    ⚠️  No assimilation step found"
        fi
        
        # Check for RMS error
        if grep -q "RMS error" osse_output.txt; then
            rms_error=$(grep "RMS error" osse_output.txt | tail -1 | awk '{print $NF}')
            echo "    RMS Error: $rms_error"
        else
            echo "    ⚠️  No RMS error found"
        fi
        
        # Check for effective sample size
        if grep -q "Effective sample size" osse_output.txt; then
            ess=$(grep "Effective sample size" osse_output.txt | tail -1 | awk '{print $NF}')
            echo "    Effective Sample Size: $ess"
        else
            echo "    ⚠️  No effective sample size found"
        fi
        
        # Check for crashes
        if grep -q "SIGSEGV\|segmentation fault" osse_output.txt; then
            echo "    ❌ Segmentation fault detected"
        else
            echo "    ✓ No crashes detected"
        fi
        
    else
        echo "  ✗ OSSE experiment failed for ensemble size $ensemble_size"
        echo "    Exit code: $EXIT_CODE"
    fi
    
    cd ..
    echo
done

echo
echo "=== Step 3: Generating Summary Report ==="

# Create summary report
cat > osse_summary.txt << EOF
CLIMBER-X OSSE Particle Filter Experiment Summary
=================================================
Date: $(date)
Job ID: $SLURM_JOB_ID
Ensemble sizes tested: ${ENSEMBLE_SIZES[*]}
Assimilation steps: $N_STEPS
Experiment length: $N_YEARS years (simplified)

RESULTS SUMMARY:
EOF

for ensemble_size in "${ENSEMBLE_SIZES[@]}"; do
    exp_dir="osse_exp_${ensemble_size}"
    if [ -d "$exp_dir" ]; then
        echo "Ensemble Size $ensemble_size:" >> osse_summary.txt
        
        # Check if experiment completed
        if [ -f "$exp_dir/osse_output.txt" ]; then
            if grep -q "Assimilating observations" "$exp_dir/osse_output.txt"; then
                echo "  Status: ✓ Completed" >> osse_summary.txt
                
                # Extract RMS error
                if grep -q "RMS error" "$exp_dir/osse_output.txt"; then
                    rms_error=$(grep "RMS error" "$exp_dir/osse_output.txt" | tail -1 | awk '{print $NF}')
                    echo "  RMS Error: $rms_error" >> osse_summary.txt
                fi
                
                # Extract effective sample size
                if grep -q "Effective sample size" "$exp_dir/osse_output.txt"; then
                    ess=$(grep "Effective sample size" "$exp_dir/osse_output.txt" | tail -1 | awk '{print $NF}')
                    echo "  Effective Sample Size: $ess" >> osse_summary.txt
                fi
                
                # Check for crashes
                if grep -q "SIGSEGV\|segmentation fault" "$exp_dir/osse_output.txt"; then
                    echo "  Crashes: ❌ Yes" >> osse_summary.txt
                else
                    echo "  Crashes: ✓ No" >> osse_summary.txt
                fi
            else
                echo "  Status: ✗ Failed" >> osse_summary.txt
            fi
        else
            echo "  Status: ✗ No output file" >> osse_summary.txt
        fi
        echo "" >> osse_summary.txt
    fi
done

echo "SUMMARY REPORT GENERATED: osse_summary.txt"
echo
echo "=== OSSE Experiment Summary ==="
echo "Experiments completed for ensemble sizes: ${ENSEMBLE_SIZES[*]}"
echo "Results saved in: osse_results/osse_exp_*/"
echo "Summary report: osse_results/osse_summary.txt"
echo
echo "=== Key Findings ==="
echo "• Particle filter performance vs ensemble size"
echo "• RMS error trends"
echo "• Effective sample size analysis"
echo "• Stability assessment"
echo
echo "=== Next Steps ==="
echo "1. Review osse_summary.txt for results"
echo "2. Check individual experiment outputs"
echo "3. Scale up to full CLIMBER-X integration"
echo
echo "=== Job completed ===" 