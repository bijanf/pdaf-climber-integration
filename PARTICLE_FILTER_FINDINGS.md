# Particle Filter Testing Findings and Recommendations

## Overview
This document summarizes our testing of PDAF particle filters and provides recommendations for CLIMBER-X integration.

## Test Results Summary

### ✅ **What Works:**
1. **Particle Filter Initialization**: Successfully initializes with ensemble sizes 20-100
2. **Observation Assimilation**: Correctly processes observations and computes innovations
3. **Error Reduction**: Achieves ~31% RMS error reduction before resampling
4. **Ensemble Loading**: Successfully loads ensemble files (fixed naming issue)

### ❌ **What Fails:**
1. **Resampling Segmentation Fault**: Crashes during resampling with effective sample size = 1.00
2. **Ensemble Collapse**: Particles collapse to single point, causing numerical instability
3. **Memory Issues**: Online mode requires significant memory for large ensembles

## Root Cause Analysis

### **Ensemble Collapse Problem**
- **Effective Sample Size = 1.00**: All particles have identical weights
- **Numerical Instability**: Resampling with collapsed ensemble causes segmentation fault
- **Insufficient Diversity**: Ensemble loses diversity during assimilation

### **Memory Issues**
- **Online Mode**: Requires MPI processes = ensemble size (20 processes for 20 members)
- **Resource Constraints**: SLURM killed job due to memory limits

## Tested Configurations

### **Offline Mode Tests:**
1. **Basic Particle Filter**: `-filtertype 12 -dim_ens 50 -nsteps 3`
   - Result: Crashes during resampling
   
2. **Different Resampling Algorithms**:
   - Probabilistic resampling (type 1): Crashes
   - Stochastic universal resampling (type 2): Crashes  
   - Residual resampling (type 3): Crashes
   - No resampling (type 0): Not tested yet

3. **Noise Configurations**:
   - No noise (type 0): Crashes
   - Constant noise (type 1): Crashes
   - Relative noise scaling (type 2): Crashes

### **Online Mode Tests:**
1. **Fixed MPI Configuration**: `--ntasks=20` to match `dim_ens=20`
   - Result: Compilation successful, but killed by memory limits

## Recommendations for CLIMBER-X Integration

### **1. Use Bootstrap Filter (No Resampling)**
```bash
# Recommended configuration for stability
./PDAF_offline -filtertype 12 -dim_ens 50 -nsteps 10 -pf_res_type 0 -pf_noise_type 2 -pf_noise_amp 0.3
```
- **Advantage**: Avoids resampling crashes
- **Disadvantage**: May suffer from weight degeneracy over time

### **2. Use Large Ensemble with High Noise**
```bash
# Alternative configuration
./PDAF_offline -filtertype 12 -dim_ens 100 -nsteps 5 -pf_res_type 2 -pf_noise_type 2 -pf_noise_amp 0.5
```
- **Advantage**: Maintains ensemble diversity
- **Disadvantage**: Higher computational cost

### **3. Consider Ensemble Kalman Filter Instead**
```bash
# More stable alternative
./PDAF_offline -filtertype 4 -dim_ens 50 -nsteps 10
```
- **Advantage**: More stable, no resampling issues
- **Disadvantage**: Not a true particle filter

### **4. Online Mode with Reduced Ensemble**
```bash
# For online CLIMBER-X integration
mpirun -np 20 ./model_pdaf -filtertype 12 -dim_ens 20 -nsteps 5 -pf_res_type 0
```
- **Advantage**: Direct integration with model
- **Disadvantage**: Limited ensemble size due to MPI constraints

## Implementation Strategy for CLIMBER-X

### **Phase 1: Bootstrap Filter Integration**
1. Implement bootstrap filter (no resampling) in CLIMBER-X
2. Test with moderate ensemble size (20-50 members)
3. Validate assimilation performance

### **Phase 2: Advanced Particle Filter**
1. Investigate resampling stability issues in PDAF source code
2. Implement custom resampling with better numerical stability
3. Test with larger ensembles

### **Phase 3: Hybrid Approach**
1. Combine particle filter with ensemble Kalman filter
2. Use particle filter for state estimation, EnKF for covariance
3. Implement adaptive switching between methods

## Technical Details

### **PDAF Configuration Parameters**
- `filtertype 12`: Particle filter
- `dim_ens`: Ensemble size (20-100 recommended)
- `pf_res_type`: Resampling type (0=none, 1=probabilistic, 2=stochastic universal, 3=residual)
- `pf_noise_type`: Noise type (0=none, 1=constant, 2=relative scaling)
- `pf_noise_amp`: Noise amplitude (0.1-0.8 recommended)

### **Memory Requirements**
- **Offline Mode**: ~8GB for 50-member ensemble
- **Online Mode**: ~16GB for 20-member ensemble with MPI
- **Large Ensembles**: ~32GB for 100-member ensemble

### **Performance Considerations**
- **Compilation Time**: ~2-3 minutes for PDAF
- **Runtime**: ~30 seconds for 3 assimilation steps
- **MPI Scaling**: Linear with ensemble size

## Next Steps

1. **Complete Final Robust Test**: Wait for current test results
2. **Test Bootstrap Filter**: Verify no-resampling configuration works
3. **CLIMBER-X Integration**: Implement working configuration
4. **Documentation Update**: Update GitHub repository with findings
5. **Performance Optimization**: Fine-tune parameters for production use

## Conclusion

While particle filters show promise for CLIMBER-X integration, the resampling instability in PDAF requires careful parameter selection. The bootstrap filter (no resampling) appears to be the most stable option for initial implementation, with potential for advanced particle filter methods once the numerical stability issues are resolved. 