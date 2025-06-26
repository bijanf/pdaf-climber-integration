# PDAF-CLIMBER-X Integration Guide

This repository contains scripts and documentation for integrating PDAF (Parallel Data Assimilation Framework) with the CLIMBER-X climate model.

## ⚠️ Important Notice

This repository contains **only integration scripts and documentation**. It does not include:
- CLIMBER-X source code (available at: https://github.com/cxesmc/climber-x)
- PDAF source code (available at: https://pdaf.awi.de/trac/wiki/FirstSteps)
- FESM-UTILS source code (available at: https://github.com/fesmc/fesm-utils)

## 📋 Prerequisites

You need to have the following software installed:
- CLIMBER-X (from https://github.com/cxesmc/climber-x)
- PDAF (from https://pdaf.awi.de/trac/wiki/FirstSteps)
- FESM-UTILS (from https://github.com/fesmc/fesm-utils)

## 🚀 Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/pdaf-climber-integration.git
   cd pdaf-climber-integration
   ```

2. **Follow the integration guide:**
   ```bash
   # Read the detailed guide
   cat PDAF_INTEGRATION_GUIDE.md
   ```

3. **Run the integration:**
   ```bash
   # Set up environment
   ./setup_environment.sh
   
   # Compile with PDAF
   sbatch compile_with_pdaf.slurm
   ```

## 📁 Repository Structure

```
pdaf-climber-integration/
├── PDAF_INTEGRATION_GUIDE.md    # Complete integration guide
├── compile_with_pdaf.slurm      # SLURM compilation script
├── setup_environment.sh         # Environment setup script
├── backup_pdaf_integration.sh   # Backup script
├── make.arch/
│   └── linux_intel.h           # PDAF Intel configuration
└── README.md                   # This file
```

## 🔧 Configuration Files

### PDAF Intel Configuration (`make.arch/linux_intel.h`)
Configuration for building PDAF with Intel OneAPI compiler.

### SLURM Script (`compile_with_pdaf.slurm`)
Batch script for compiling CLIMBER-X with PDAF support on HPC systems.

## 📖 Documentation

- **`PDAF_INTEGRATION_GUIDE.md`**: Complete step-by-step integration process
- **Troubleshooting**: Common issues and solutions
- **Environment Setup**: Module loading and environment variables

## 🤝 Contributing

This repository is for sharing integration scripts and documentation. Please:
- Do not include source code from other projects
- Follow the license terms of CLIMBER-X, PDAF, and FESM-UTILS
- Respect the intellectual property of the original authors

## 📄 License

This repository contains only integration scripts and documentation created by the author. The original software licenses apply to:
- CLIMBER-X: See https://github.com/cxesmc/climber-x
- PDAF: See https://pdaf.awi.de/trac/wiki/FirstSteps
- FESM-UTILS: See https://github.com/fesmc/fesm-utils

## 🙏 Acknowledgments

- CLIMBER-X development team
- PDAF development team at AWI
- FESM-UTILS development team

## 📞 Support

For issues with this integration:
- Check the troubleshooting section in `PDAF_INTEGRATION_GUIDE.md`
- Ensure you have the correct versions of all dependencies
- Verify your HPC environment matches the documented setup

For issues with the original software:
- CLIMBER-X: https://github.com/cxesmc/climber-x
- PDAF: https://pdaf.awi.de/trac/wiki/FirstSteps
- FESM-UTILS: https://github.com/fesmc/fesm-utils 