#!/bin/bash

# Backup script for PDAF-CLIMBER-X integration
# This script creates a backup of all important files

echo "Creating backup of PDAF-CLIMBER-X integration..."

# Create backup directory
BACKUP_DIR="pdaf_integration_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Copy important files
echo "Backing up key files..."

# PDAF files
cp -r ../software/PDAF/make.arch/linux_intel.h $BACKUP_DIR/
cp -r ../software/PDAF/lib $BACKUP_DIR/pdaf_lib
cp -r ../software/PDAF/include $BACKUP_DIR/pdaf_include

# CLIMBER-X files
cp Makefile $BACKUP_DIR/
cp compile_with_pdaf.slurm $BACKUP_DIR/
cp PDAF_INTEGRATION_GUIDE.md $BACKUP_DIR/

# FESM-UTILS libraries
cp -r src/utils/fesm-utils/utils/include-omp $BACKUP_DIR/fesm_utils_omp
cp -r src/utils/fesm-utils/utils/include-serial $BACKUP_DIR/fesm_utils_serial

# Compiled executable
cp climber.x $BACKUP_DIR/

# Create environment setup script
cat > $BACKUP_DIR/setup_environment.sh << 'EOF'
#!/bin/bash
# Environment setup script for PDAF-CLIMBER-X

echo "Setting up PDAF-CLIMBER-X environment..."

# Load modules
module purge
module use /p/system/modulefiles/compiler \
           /p/system/modulefiles/gpu \
           /p/system/modulefiles/libraries \
           /p/system/modulefiles/parallel \
           /p/system/modulefiles/tools

module load intel/oneAPI/2024.0.0
module load netcdf-c/4.9.2
module load netcdf-fortran-intel/4.6.1
module load udunits/2.2.28
module load ncview/2.1.10
module load cdo/2.4.2

# Set PDAF environment variables
export PDAF_ROOT=/home/fallah/scripts/POEM/TESTS/software/PDAF
export PDAF_ARCH=linux_intel
export PDAF_INC=${PDAF_ROOT}/include
export PDAF_LIB=${PDAF_ROOT}/lib

echo "Environment setup complete!"
echo "PDAF_ROOT: $PDAF_ROOT"
echo "PDAF_ARCH: $PDAF_ARCH"
EOF

chmod +x $BACKUP_DIR/setup_environment.sh

# Create restore script
cat > $BACKUP_DIR/restore_integration.sh << 'EOF'
#!/bin/bash
# Restore script for PDAF-CLIMBER-X integration

echo "Restoring PDAF-CLIMBER-X integration..."

# Restore PDAF configuration
cp linux_intel.h ../software/PDAF/make.arch/

# Restore CLIMBER-X files
cp Makefile ../
cp compile_with_pdaf.slurm ../

# Restore FESM-UTILS
cp -r fesm_utils_omp/* ../src/utils/fesm-utils/utils/include-omp/
cp -r fesm_utils_serial/* ../src/utils/fesm-utils/utils/include-serial/

# Restore executable
cp climber.x ../

echo "Restoration complete!"
EOF

chmod +x $BACKUP_DIR/restore_integration.sh

# Create summary
cat > $BACKUP_DIR/README.txt << 'EOF'
PDAF-CLIMBER-X Integration Backup
================================

This backup contains all files needed to restore the PDAF integration with CLIMBER-X.

Contents:
- PDAF Intel configuration (linux_intel.h)
- PDAF libraries and include files
- Modified CLIMBER-X Makefile with PDAF integration
- Compilation SLURM script
- FESM-UTILS libraries (OpenMP and serial versions)
- Compiled climber.x executable
- Environment setup script
- Integration guide

To restore:
1. Run: ./restore_integration.sh
2. Run: ./setup_environment.sh

To recompile:
sbatch compile_with_pdaf.slurm

Created: $(date)
EOF

echo "Backup created in: $BACKUP_DIR"
echo "Files backed up:"
ls -la $BACKUP_DIR/

echo ""
echo "To restore this integration later, run:"
echo "cd $BACKUP_DIR && ./restore_integration.sh" 