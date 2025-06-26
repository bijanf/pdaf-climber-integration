#!/bin/bash
# Get Started from GitHub Repository
# This script explains how to set up the complete environment
# starting from the pdaf-climber-integration repository

set -e

echo "=== Getting Started from GitHub Repository ==="
echo "Repository: https://github.com/bijanf/pdaf-climber-integration"
echo
echo "This script will guide you through setting up the complete environment"
echo "including CLIMBER-X and PDAF from scratch."
echo

# Check if we're in the right directory
if [ ! -f "README.md" ]; then
    echo "Error: Please run this script from the pdaf-climber-integration directory"
    echo "First, clone the repository:"
    echo "  git clone https://github.com/bijanf/pdaf-climber-integration.git"
    echo "  cd pdaf-climber-integration"
    exit 1
fi

echo "✓ Running from pdaf-climber-integration directory"
echo

# Create setup instructions
cat > SETUP_INSTRUCTIONS.md << 'EOF'
# Complete Setup Instructions

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
EOF

echo "✓ Created SETUP_INSTRUCTIONS.md"
echo

# Create a quick setup script
cat > quick_setup.sh << 'EOF'
#!/bin/bash
# Quick Setup Script
# This script automates the initial setup process

set -e

echo "=== Quick Setup for PDAF-CLIMBER-X Integration ==="
echo

# Configuration
WORKSPACE_DIR="/home/fallah/scripts/POEM/TESTS/software"
CLIMBER_X_REPO="https://github.com/cxesmc/climber-x.git"
PDAF_URL="https://pdaf.awi.de/trac/export/HEAD/pdaf/trunk/PDAF_V2.0.tar.gz"

echo "Setting up in: $WORKSPACE_DIR"
echo

# Create workspace directory
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# Clone CLIMBER-X
echo "Cloning CLIMBER-X..."
if [ ! -d "CLIMBER-X" ]; then
    git clone "$CLIMBER_X_REPO" CLIMBER-X
    echo "✓ CLIMBER-X cloned successfully"
else
    echo "✓ CLIMBER-X already exists"
fi

# Download PDAF
echo "Downloading PDAF..."
if [ ! -d "PDAF" ]; then
    wget "$PDAF_URL" -O PDAF_V2.0.tar.gz
    tar -xzf PDAF_V2.0.tar.gz
    mv PDAF_V2.0 PDAF
    rm PDAF_V2.0.tar.gz
    echo "✓ PDAF downloaded and extracted successfully"
else
    echo "✓ PDAF already exists"
fi

# Load modules
echo "Loading required modules..."
module load intel/oneAPI/2023.2.0
module load mkl/2023.2.0
module load netcdf-fortran-intel/4.6.1

# Set environment
export PDAF_ARCH=linux_intel

echo
echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Build PDAF: cd PDAF && make"
echo "2. Test PDAF: cd tutorial/offline_2D_serial && make PDAF_offline"
echo "3. Integrate with CLIMBER-X: Follow SETUP_INSTRUCTIONS.md"
echo
echo "Directories created:"
echo "- $WORKSPACE_DIR/CLIMBER-X"
echo "- $WORKSPACE_DIR/PDAF"
echo "- $WORKSPACE_DIR/pdaf-climber-integration (this repo)"
EOF

chmod +x quick_setup.sh

echo "✓ Created quick_setup.sh"
echo

# Update the main README
cat > README.md << 'EOF'
# PDAF-CLIMBER-X Integration Guide

This repository contains scripts and documentation for integrating PDAF (Parallel Data Assimilation Framework) with the CLIMBER-X climate model.

## ⚠️ Important Notice

This repository contains **only integration scripts and documentation**. It does not include:

* CLIMBER-X source code (available at: https://github.com/cxesmc/climber-x)
* PDAF source code (available at: https://pdaf.awi.de/trac/wiki/FirstSteps)
* FESM-UTILS source code (available at: https://github.com/fesmc/fesm-utils)

## 🚀 Quick Start

### Option 1: Automated Setup
```bash
# Clone this repository
git clone https://github.com/bijanf/pdaf-climber-integration.git
cd pdaf-climber-integration

# Run automated setup
./quick_setup.sh
```

### Option 2: Manual Setup
```bash
# Clone this repository
git clone https://github.com/bijanf/pdaf-climber-integration.git
cd pdaf-climber-integration

# Follow detailed instructions
cat SETUP_INSTRUCTIONS.md
```

## 📋 Prerequisites

You need to have the following software installed:

* CLIMBER-X (from https://github.com/cxesmc/climber-x)
* PDAF (from https://pdaf.awi.de/trac/wiki/FirstSteps)
* FESM-UTILS (from https://github.com/fesmc/fesm-utils)

## 📁 Repository Structure

```
pdaf-climber-integration/
├── SETUP_INSTRUCTIONS.md         # Complete setup guide
├── quick_setup.sh               # Automated setup script
├── run_pf_different_resampling.slurm  # Particle filter resampling tests
├── run_online_pf.slurm          # Online mode particle filter
├── integrate_with_climber_x.sh  # CLIMBER-X integration script
├── test_climber_x_integration.slurm  # CLIMBER-X integration test
├── CLIMBER_X_INTEGRATION_GUIDE.md    # Integration documentation
├── climber_x_pdaf_integration.F90    # CLIMBER-X PDAF interface
├── Makefile.climber_x_pdaf      # CLIMBER-X Makefile with PDAF
├── make.arch/
│   └── linux_intel.h           # PDAF Intel configuration
└── README.md                   # This file
```

## 🔧 Configuration Files

### PDAF Intel Configuration (`make.arch/linux_intel.h`)
Configuration for building PDAF with Intel OneAPI compiler.

### SLURM Scripts
* `run_pf_different_resampling.slurm`: Test different resampling algorithms
* `run_online_pf.slurm`: Test online mode particle filter
* `test_climber_x_integration.slurm`: Test CLIMBER-X integration

## 📖 Documentation

* **`SETUP_INSTRUCTIONS.md`**: Complete step-by-step setup process
* **`CLIMBER_X_INTEGRATION_GUIDE.md`**: Integration process and troubleshooting
* **Troubleshooting**: Common issues and solutions
* **Environment Setup**: Module loading and environment variables

## 🤝 Contributing

This repository is for sharing integration scripts and documentation. Please:

* Do not include source code from other projects
* Follow the license terms of CLIMBER-X, PDAF, and FESM-UTILS
* Respect the intellectual property of the original authors

## 📄 License

This repository contains only integration scripts and documentation created by the author. The original software licenses apply to:

* CLIMBER-X: See https://github.com/cxesmc/climber-x
* PDAF: See https://pdaf.awi.de/trac/wiki/FirstSteps
* FESM-UTILS: See https://github.com/fesmc/fesm-utils

## 🙏 Acknowledgments

* CLIMBER-X development team
* PDAF development team at AWI
* FESM-UTILS development team

## 📞 Support

For issues with this integration:

* Check the troubleshooting section in `CLIMBER_X_INTEGRATION_GUIDE.md`
* Ensure you have the correct versions of all dependencies
* Verify your HPC environment matches the documented setup

For issues with the original software:

* CLIMBER-X: https://github.com/cxesmc/climber-x
* PDAF: https://pdaf.awi.de/trac/wiki/FirstSteps
* FESM-UTILS: https://github.com/fesmc/fesm-utils
EOF

echo "✓ Updated README.md"
echo

echo "=== Setup Complete ==="
echo "Files created:"
echo "- SETUP_INSTRUCTIONS.md: Complete setup guide"
echo "- quick_setup.sh: Automated setup script"
echo "- Updated README.md: Enhanced documentation"
echo
echo "Now you can:"
echo "1. Run the fixed online mode test: sbatch run_online_pf.slurm"
echo "2. Update GitHub repository: ./update_github_repo.sh"
echo "3. Follow SETUP_INSTRUCTIONS.md for complete setup"
EOF 