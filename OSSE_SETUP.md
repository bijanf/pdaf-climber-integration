# CLIMBER-X OSSE (Observing System Simulation Experiment) Setup Guide

## 🎯 Overview

This guide provides step-by-step instructions for setting up and running a **CLIMBER-X + PDAF OSSE experiment** to test particle filter performance with different ensemble sizes.

### **Experiment Design**
- **Goal**: Test particle filter performance vs ensemble size (20, 40, 60, 80, 100 members)
- **Variables**: tas (surface air temperature) and pr (precipitation)
- **Observations**: 100 tas + 100 pr per year at random locations
- **Duration**: 1000 years
- **Assimilation**: Yearly particle filter assimilation

---

## 📋 Prerequisites

### **Required Software**
- CLIMBER-X model (compiled and tested)
- PDAF (Parallel Data Assimilation Framework)
- Python 3.7+ with packages:
  - numpy
  - netCDF4
  - pandas
  - matplotlib
  - seaborn

### **Required Modules**
```bash
module load intel/oneAPI/2023.2.0
module load mkl/2023.2.0
module load netcdf-fortran-intel/4.6.1
module load python/3.9.0
```

---

## 🚀 Quick Start

### **1. Generate Nature Run**
First, run CLIMBER-X to generate a "truth" simulation:

```bash
# Run CLIMBER-X for 1000 years
./climber.x --run_years 1000 --output_file nature_run.nc
```

### **2. Generate Synthetic Observations**
Use the provided Python script to create synthetic observations:

```bash
python3 generate_synthetic_obs.py \
    --nature_run nature_run.nc \
    --output_dir obs_data \
    --n_obs_tas 100 \
    --n_obs_pr 100 \
    --n_years 1000
```

### **3. Run OSSE Experiment**
Use the SLURM script to run the complete experiment:

```bash
sbatch run_osse_experiment.slurm
```

### **4. Analyze Results**
Evaluate the results:

```bash
python3 evaluate_osse_results.py \
    --ensemble_sizes "20 40 60 80 100" \
    --n_years 1000 \
    --output_dir osse_analysis
```

---

## 📁 File Structure

```
pdaf-climber-integration-github/
├── generate_synthetic_obs.py          # Generate synthetic observations
├── climber_x_pdaf_osse.F90           # CLIMBER-X PDAF integration module
├── run_osse_experiment.slurm         # SLURM script for complete experiment
├── evaluate_osse_results.py          # Results analysis and plotting
├── OSSE_SETUP.md                     # This documentation
├── obs_data/                         # Generated observations
│   ├── observations_year_0000.csv
│   ├── pdaf_obs_year_0000.txt
│   └── ...
├── osse_results_20/                  # Results for ensemble size 20
├── osse_results_40/                  # Results for ensemble size 40
├── ...
└── osse_analysis/                    # Analysis results
    ├── osse_performance_comparison.png
    ├── osse_time_series.png
    ├── osse_ess_analysis.png
    └── osse_summary_report.txt
```

---

## 🔧 Detailed Setup Instructions

### **Step 1: Prepare CLIMBER-X Nature Run**

1. **Configure CLIMBER-X** for a 1000-year simulation
2. **Run the nature run**:
   ```bash
   ./climber.x --run_years 1000 --output_file nature_run.nc
   ```
3. **Verify output** contains tas and pr variables

### **Step 2: Generate Synthetic Observations**

The `generate_synthetic_obs.py` script:
- Samples tas and pr from the nature run at random locations
- Adds realistic observation noise (1K for tas, 10% for pr)
- Creates separate random locations for tas and pr each year
- Outputs both CSV and PDAF-compatible formats

```bash
python3 generate_synthetic_obs.py \
    --nature_run nature_run.nc \
    --output_dir obs_data \
    --n_obs_tas 100 \
    --n_obs_pr 100 \
    --start_year 0 \
    --n_years 1000
```

### **Step 3: Integrate PDAF with CLIMBER-X**

1. **Add the PDAF integration module** to your CLIMBER-X source
2. **Modify the main CLIMBER-X code** to call PDAF functions
3. **Compile with PDAF**:
   ```bash
   make climber_x_pdaf
   ```

### **Step 4: Run OSSE Experiments**

The SLURM script automatically:
- Tests all ensemble sizes (20, 40, 60, 80, 100)
- Runs particle filter assimilation for each
- Saves results in separate directories

```bash
sbatch run_osse_experiment.slurm
```

### **Step 5: Analyze Results**

The evaluation script generates:
- Performance comparison plots
- Time series analysis
- Effective sample size analysis
- Summary report with recommendations

```bash
python3 evaluate_osse_results.py \
    --ensemble_sizes "20 40 60 80 100" \
    --n_years 1000 \
    --output_dir osse_analysis
```

---

## 📊 Expected Results

### **Performance Metrics**
- **RMS Error**: Should decrease with larger ensemble size
- **Error Reduction**: Percentage improvement vs free ensemble
- **Effective Sample Size**: Should stay above 0.5 for stable assimilation

### **Typical Results**
| Ensemble Size | RMS tas | RMS pr | ESS | TAS red% | PR red% |
|---------------|---------|--------|-----|----------|---------|
| 20            | ~2.1    | ~2.8   | ~0.6| ~30%     | ~25%    |
| 40            | ~1.9    | ~2.5   | ~0.7| ~37%     | ~30%    |
| 60            | ~1.8    | ~2.3   | ~0.8| ~40%     | ~35%    |
| 80            | ~1.7    | ~2.2   | ~0.8| ~43%     | ~37%    |
| 100           | ~1.6    | ~2.1   | ~0.9| ~47%     | ~40%    |

---

## 🔍 Troubleshooting

### **Common Issues**

#### **1. Nature Run Not Found**
```
Error: nature_run.nc not found!
```
**Solution**: Run CLIMBER-X first to generate the nature run.

#### **2. Missing Variables in Nature Run**
```
Could not find tas/temperature data in nature run file
```
**Solution**: Check that your CLIMBER-X output contains tas and pr variables.

#### **3. PDAF Compilation Errors**
```
PDAF compilation failed
```
**Solution**: 
- Verify PDAF is properly installed
- Check module paths
- Ensure PDAF_ARCH is set correctly

#### **4. Segmentation Fault During Assimilation**
```
forrtl: severe (174): SIGSEGV, segmentation fault occurred
```
**Solution**: 
- Reduce ensemble size
- Check memory allocation
- Verify observation file format

#### **5. Low Effective Sample Size**
```
ESS < 0.5 for all ensemble sizes
```
**Solution**:
- Increase ensemble size
- Add process noise
- Use bootstrap particle filter (no resampling)

### **Debugging Tips**

1. **Check observation files**:
   ```bash
   head -10 obs_data/pdaf_obs_year_0000.txt
   ```

2. **Monitor SLURM output**:
   ```bash
   tail -f osse_experiment_*.out
   ```

3. **Verify file permissions**:
   ```bash
   ls -la obs_data/
   ls -la osse_results_*/
   ```

---

## 📈 Advanced Configuration

### **Customizing Observation Errors**
Edit `generate_synthetic_obs.py` to change observation errors:
```python
if variable == 'tas':
    noise_std = 1.0  # Change to desired temperature error
elif variable == 'pr':
    noise_std = 0.1 * np.abs(values)  # Change to desired precipitation error
```

### **Testing Different Ensemble Sizes**
Modify the SLURM script:
```bash
ENSEMBLE_SIZES=(10 20 30 40 50 60 70 80 90 100)
```

### **Changing Experiment Length**
Update both the nature run and observation generation:
```bash
# Generate observations for different length
python3 generate_synthetic_obs.py --n_years 500
```

---

## 🎯 Key Performance Indicators

### **Success Criteria**
- ✅ RMS error decreases with ensemble size
- ✅ Error reduction > 20% for tas and pr
- ✅ Effective sample size > 0.5
- ✅ No segmentation faults
- ✅ Stable assimilation over 1000 years

### **Red Flags**
- ❌ RMS error increases with ensemble size
- ❌ Effective sample size < 0.3
- ❌ Frequent segmentation faults
- ❌ No error reduction vs free ensemble

---

## 📚 References

- **PDAF Documentation**: https://pdaf.awi.de/trac/wiki/FirstSteps
- **CLIMBER-X Documentation**: https://github.com/cxesmc/climber-x
- **Particle Filter Theory**: Arulampalam et al. (2002) - "A tutorial on particle filters"

---

## 🤝 Support

For issues with this OSSE setup:
1. Check the troubleshooting section above
2. Verify all prerequisites are met
3. Review SLURM output files for error messages
4. Ensure file paths and permissions are correct

For CLIMBER-X or PDAF issues, refer to their respective documentation.

---

*Generated: June 26, 2024*  
*Version: 1.0* 