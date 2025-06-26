# Complete Setup Instructions for PDAF-CLIMBER-X Integration

## Overview
This repository contains integration scripts and documentation for PDAF-CLIMBER-X integration.
The actual CLIMBER-X and PDAF source code must be obtained separately due to licensing.

## Step 1: Clone Required Repositories

### 1.1 Clone CLIMBER-X
```bash
git clone https://github.com/cxesmc/climber-x.git
cd climber-x
# Check out the appropriate version/tag
git checkout <version_tag>
cd ..
```

### 1.2 Clone PDAF
```bash
# Download PDAF from the official website
wget https://pdaf.awi.de/trac/export/HEAD/pdaf/trunk/PDAF_V2.0.tar.gz
tar -xzf PDAF_V2.0.tar.gz
mv PDAF_V2.0 pdaf
cd pdaf
# Follow PDAF installation instructions
cd ..
```

### 1.3 Clone FESM-UTILS (if needed)
```bash
git clone https://github.com/fesmc/fesm-utils.git
cd fesm-utils
# Follow installation instructions
cd ..
```

## Step 2: Set Up Environment

### 2.1 Load Required Modules
```bash
module load intel/oneAPI/2023.2.0
module load mkl/2023.2.0
module load netcdf-fortran-intel/4.6.1
```

### 2.2 Set Environment Variables
```bash
export PDAF_ARCH=linux_intel
export CLIMBER_X_DIR=/path/to/climber-x
export PDAF_DIR=/path/to/pdaf
```

## Step 3: Build PDAF

### 3.1 Compile PDAF
```bash
cd pdaf
make clean
make
```

### 3.2 Test PDAF Installation
```bash
cd tutorial/offline_2D_serial
make PDAF_offline
./PDAF_offline -filtertype 12 -dim_ens 20 -nsteps 3
```

## Step 4: Build CLIMBER-X with PDAF

### 4.1 Copy Integration Files
```bash
# Copy PDAF integration module to CLIMBER-X
cp pdaf-climber-integration/climber_x_pdaf_integration.F90 climber-x/src/
cp pdaf-climber-integration/Makefile.climber_x_pdaf climber-x/
```

### 4.2 Modify CLIMBER-X Makefile
Follow the instructions in `CLIMBER_X_INTEGRATION_GUIDE.md`

### 4.3 Compile CLIMBER-X with PDAF
```bash
cd climber-x
make -f Makefile.climber_x_pdaf
```

## Step 5: Test Integration

### 5.1 Run Particle Filter Tests
```bash
cd pdaf-climber-integration
sbatch run_pf_different_resampling.slurm
sbatch run_online_pf.slurm
```

### 5.2 Run CLIMBER-X Integration Test
```bash
sbatch test_climber_x_integration.slurm
```

## Directory Structure After Setup
```
your_workspace/
├── pdaf-climber-integration/     # This repository
├── climber-x/                    # CLIMBER-X source
├── pdaf/                         # PDAF source
└── fesm-utils/                   # FESM-UTILS (optional)
```

## Troubleshooting

### Common Issues
1. **Module not found**: Ensure all required modules are available
2. **Compilation errors**: Check compiler flags and library paths
3. **Runtime crashes**: Verify ensemble size matches MPI processes
4. **Memory issues**: Adjust SLURM resource allocation

### Getting Help
- Check the troubleshooting section in `PDAF_INTEGRATION_GUIDE.md`
- Verify your HPC environment matches the documented setup
- Ensure you have the correct versions of all dependencies

## References
- CLIMBER-X: https://github.com/cxesmc/climber-x
- PDAF: https://pdaf.awi.de/trac/wiki/FirstSteps
- FESM-UTILS: https://github.com/fesmc/fesm-utils 