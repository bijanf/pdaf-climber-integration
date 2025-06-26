######################################################
# Include file with machine-specific definitions     #
# for building PDAF.                                 #
#                                                    #
# Variant for Linux with Intel ifx and OpenMPI       #
#                                                    #
# In the case of compilation without MPI, a dummy    #
# implementation of MPI, like provided in the        #
# directory nullmpi/ has to be linked when building  #
# an executable.                                     #
######################################################
# $Id: linux_intel.h 2024-06-26 $


# Compiler, Linker, and Archiver
FC = mpiifx
LD = $(FC)
AR = ar
RANLIB = ranlib

# C preprocessor
# (only required, if preprocessing is not performed via the compiler)
CPP = /usr/bin/cpp

# Definitions for CPP
# Define USE_PDAF to include PDAF
# Define BLOCKING_MPI_EXCHANGE to use blocking MPI commands to exchange data between model and PDAF
# Define PDAF_NO_UPDATE to deactivate the analysis step of the filter
# (if the compiler does not support get_command_argument()
# from Fortran 2003 you should define F77 here.)
CPP_DEFS = -DUSE_PDAF

# Optimization specs for compiler
# To use OpenMP parallelization in PDAF, specify it here (-qopenmp for Intel)
#   (You should explicitly define double precision for floating point
#   variables in the compilation)  
OPT = -O3 -cpp -qopenmp

# Optimization specifications for Linker
OPT_LNK = $(OPT)

# Linking libraries (BLAS, LAPACK, if required: MPI)
LINK_LIBS =-L/usr/lib -llapack  -lblas   -lm

# Specifications for the archiver
AR_SPEC = 

# Specifications for ranlib
RAN_SPEC =

# Specification for directory holding modules (-module for Intel, -J for GNU)
MODULEOPT = -module

# Include path for MPI header file
MPI_INC = 

# Object for nullMPI - if compiled without MPI library
OBJ_MPI =

# NetCDF (only required for Lorenz96)
NC_LIB   = 
NC_INC   = 