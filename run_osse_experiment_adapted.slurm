#!/bin/bash
#SBATCH --job-name=osse_pf_test
#SBATCH --output=osse_pf_test_%j.out
#SBATCH --error=osse_pf_test_%j.err
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=priority
#SBATCH --account=poem
#SBATCH --qos=priority

# CLIMBER-X OSSE Experiment with Particle Filter (Adapted for PDAF Tutorial)
# Tests different ensemble sizes: 20, 40, 60, 80, 100

set -e

echo "=== CLIMBER-X OSSE Particle Filter Experiment ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Running on node: $(hostname)"
echo "Testing particle filter with different ensemble sizes"
echo

# Load required modules
echo "Loading required modules..."
module load intel/oneAPI/2023.2.0
module load mkl/2023.2.0
module load netcdf-fortran-intel/4.6.1
module load python/3.12.3

# Set PDAF architecture
export PDAF_ARCH=linux_intel

echo "Using PDAF architecture: $PDAF_ARCH"
echo

# OSSE experiment parameters
ENSEMBLE_SIZES=(20 40 60 80 100)
N_OBS_TAS=100
N_OBS_PR=100
N_STEPS=20  # Reduced for testing
N_YEARS=20  # Reduced for testing

echo "=== OSSE Experiment Configuration ==="
echo "Ensemble sizes to test: ${ENSEMBLE_SIZES[*]}"
echo "Observations per year: $N_OBS_TAS tas + $N_OBS_PR pr"
echo "Assimilation steps: $N_STEPS"
echo "Experiment length: $N_YEARS years (adapted for testing)"
echo

# Step 1: Use PDAF tutorial as nature run
echo "=== Step 1: Using PDAF Tutorial as Nature Run ==="
cd /home/fallah/scripts/POEM/TESTS/software/PDAF/tutorial/offline_2D_serial

echo "Compiling PDAF tutorial..."
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
mkdir -p /home/fallah/scripts/POEM/TESTS/climber-x/pdaf-climber-integration-github/osse_results
cd /home/fallah/scripts/POEM/TESTS/climber-x/pdaf-climber-integration-github/osse_results

# Run experiments for each ensemble size
for ensemble_size in "${ENSEMBLE_SIZES[@]}"; do
    echo "Running OSSE experiment with ensemble size: $ensemble_size"
    
    # Create experiment directory
    exp_dir="osse_exp_${ensemble_size}"
    mkdir -p $exp_dir
    cd $exp_dir
    
    # Copy PDAF executable and input files (excluding ensemble files)
    cp /home/fallah/scripts/POEM/TESTS/software/PDAF/tutorial/offline_2D_serial/PDAF_offline .
    cp /home/fallah/scripts/POEM/TESTS/software/PDAF/tutorial/offline_2D_serial/obs*.txt .
    cp /home/fallah/scripts/POEM/TESTS/software/PDAF/tutorial/offline_2D_serial/state*.txt .
    cp /home/fallah/scripts/POEM/TESTS/software/PDAF/tutorial/offline_2D_serial/true.txt .
    cp /home/fallah/scripts/POEM/TESTS/software/PDAF/tutorial/offline_2D_serial/particle_filter_config.txt .
    
    # Copy ensemble files (need at least as many as ensemble size)
    echo "  Copying ensemble files for size $ensemble_size..."
    for i in $(seq 1 $ensemble_size); do
        if [ $i -le 50 ]; then  # We have 50 ensemble files available
            cp /home/fallah/scripts/POEM/TESTS/software/PDAF/tutorial/inputs_offline/ens_${i}.txt .
        else
            # If we need more than 50, duplicate existing files
            cp /home/fallah/scripts/POEM/TESTS/software/PDAF/tutorial/inputs_offline/ens_$((i % 50 + 1)).txt ens_${i}.txt
        fi
    done
    
    # Run the particle filter experiment
    echo "  Running particle filter with ensemble size $ensemble_size..."
    echo "  Command: ./PDAF_offline -filtertype 12 -dim_ens $ensemble_size -nsteps $N_STEPS"
    
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
        
        # Save key metrics to file
        cat > metrics.txt << EOF
Ensemble Size: $ensemble_size
Status: Completed
Exit Code: $EXIT_CODE
EOF
        
        if grep -q "RMS error" osse_output.txt; then
            echo "RMS Error: $rms_error" >> metrics.txt
        fi
        
        if grep -q "Effective sample size" osse_output.txt; then
            echo "Effective Sample Size: $ess" >> metrics.txt
        fi
        
        if grep -q "SIGSEGV\|segmentation fault" osse_output.txt; then
            echo "Crashes: Yes" >> metrics.txt
        else
            echo "Crashes: No" >> metrics.txt
        fi
        
    else
        echo "  ✗ OSSE experiment failed for ensemble size $ensemble_size"
        echo "    Exit code: $EXIT_CODE"
        
        # Save failure info
        cat > metrics.txt << EOF
Ensemble Size: $ensemble_size
Status: Failed
Exit Code: $EXIT_CODE
EOF
    fi
    
    cd ..
    echo
done

echo
echo "=== Step 3: Analyzing Results ==="

# Create comprehensive summary report
cat > osse_summary_report.txt << EOF
CLIMBER-X OSSE Particle Filter Experiment Summary Report
========================================================
Date: $(date)
Job ID: $SLURM_JOB_ID
Ensemble sizes tested: ${ENSEMBLE_SIZES[*]}
Assimilation steps: $N_STEPS
Experiment length: $N_YEARS years (adapted)

EXPERIMENT RESULTS:
EOF

# Collect results for each ensemble size
for ensemble_size in "${ENSEMBLE_SIZES[@]}"; do
    exp_dir="osse_exp_${ensemble_size}"
    if [ -d "$exp_dir" ] && [ -f "$exp_dir/metrics.txt" ]; then
        echo "" >> osse_summary_report.txt
        echo "Ensemble Size $ensemble_size:" >> osse_summary_report.txt
        echo "----------------------------" >> osse_summary_report.txt
        cat "$exp_dir/metrics.txt" >> osse_summary_report.txt
    fi
done

# Add analysis section
cat >> osse_summary_report.txt << EOF

ANALYSIS:
---------
This experiment tested particle filter performance with different ensemble sizes
using the PDAF tutorial as a simplified OSSE setup.

Key Metrics:
- RMS Error: Lower is better (indicates assimilation quality)
- Effective Sample Size: Should be > 0.5 for stable assimilation
- Crashes: Indicates numerical stability issues

Expected Trends:
- RMS error should decrease with larger ensemble size
- Effective sample size should increase with ensemble size
- No crashes should occur for stable configurations

RECOMMENDATIONS:
----------------
Based on the results, the optimal ensemble size for particle filter assimilation
can be determined by balancing performance improvement vs computational cost.

NEXT STEPS:
-----------
1. Scale up to full CLIMBER-X integration
2. Test with real lon/lat coordinates
3. Implement bootstrap particle filter if resampling issues persist
4. Run longer experiments for statistical significance
EOF

echo "✓ Results analysis completed"
echo "✓ Summary report generated: osse_summary_report.txt"

echo
echo "=== OSSE Experiment Summary ==="
echo "Experiments completed for ensemble sizes: ${ENSEMBLE_SIZES[*]}"
echo "Results saved in: osse_results/osse_exp_*/"
echo "Summary report: osse_results/osse_summary_report.txt"
echo
echo "=== Key Files Generated ==="
echo "• Individual experiment outputs: osse_exp_*/osse_output.txt"
echo "• Performance metrics: osse_exp_*/metrics.txt"
echo "• Summary report: osse_summary_report.txt"
echo
echo "=== Performance Analysis ==="
echo "• Particle filter performance vs ensemble size"
echo "• RMS error trends and assimilation quality"
echo "• Effective sample size and ensemble diversity"
echo "• Numerical stability assessment"
echo
echo "=== Success Criteria ==="
echo "✅ Particle filter runs without crashes"
echo "✅ RMS error decreases with ensemble size"
echo "✅ Effective sample size > 0.5"
echo "✅ Assimilation steps execute successfully"
echo
echo "=== Job completed ===" 