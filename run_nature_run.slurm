#!/bin/bash
#SBATCH --job-name=nature_run
#SBATCH --output=nature_run_%j.out
#SBATCH --error=nature_run_%j.err
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --partition=priority
#SBATCH --account=poem
#SBATCH --qos=priority

# CLIMBER-X Nature Run for OSSE Experiment
# This script runs CLIMBER-X for 1000 years to generate the "truth" simulation

set -e

echo "=== CLIMBER-X Nature Run for OSSE ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Running on node: $(hostname)"
echo "Generating 1000-year nature run for OSSE experiment"
echo

# Load required modules
echo "Loading required modules..."
module load intel/oneAPI/2023.2.0
module load mkl/2023.2.0
module load netcdf-fortran-intel/4.6.1

echo "Using modules:"
module list
echo

# Set up environment
export CLIMBER_X_DIR=/home/fallah/scripts/POEM/TESTS/climber-x
export NATURE_RUN_DIR=${CLIMBER_X_DIR}/nature_run_output
export OSSE_DATA_DIR=${CLIMBER_X_DIR}/osse_data

# Create output directories
mkdir -p ${NATURE_RUN_DIR}
mkdir -p ${OSSE_DATA_DIR}

echo "Output directories:"
echo "  Nature run: ${NATURE_RUN_DIR}"
echo "  OSSE data: ${OSSE_DATA_DIR}"
echo

# Change to CLIMBER-X directory
cd ${CLIMBER_X_DIR}

echo "=== Compiling CLIMBER-X ==="
make clean
make climber.x

if [ $? -eq 0 ]; then
    echo "✓ CLIMBER-X compilation successful!"
else
    echo "✗ CLIMBER-X compilation failed!"
    exit 1
fi

echo
echo "=== Running Nature Run ==="
echo "Configuration:"
echo "  Duration: 1000 years"
echo "  Output frequency: Yearly"
echo "  Variables: tas, pr"
echo "  Output format: NetCDF"
echo

# Create namelist for nature run
cat > nature_run.nml << EOF
&climber_nml
    run_length = 1000
    output_frequency = 1
    output_variables = 'tas,pr'
    output_format = 'netcdf'
    output_dir = '${NATURE_RUN_DIR}'
/
EOF

echo "Created namelist: nature_run.nml"
echo

# Run CLIMBER-X nature run
echo "Starting CLIMBER-X nature run..."
./climber.x nature_run.nml

if [ $? -eq 0 ]; then
    echo "✓ Nature run completed successfully!"
else
    echo "✗ Nature run failed!"
    exit 1
fi

echo
echo "=== Nature Run Results ==="
echo "Generated files:"
ls -la ${NATURE_RUN_DIR}/*.nc 2>/dev/null || echo "No NetCDF files found"

echo
echo "=== Next Steps ==="
echo "1. Generate synthetic observations:"
echo "   python generate_synthetic_obs.py --nature_run ${NATURE_RUN_DIR}/climber_nature_run.nc"
echo "2. Run ensemble experiments with different ensemble sizes"
echo "3. Perform data assimilation with PDAF"

echo
echo "=== Job completed ===" 