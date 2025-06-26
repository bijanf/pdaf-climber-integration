#!/usr/bin/env python3
"""
Generate Synthetic Observations for CLIMBER-X OSSE Experiment

This script generates synthetic observations of tas (surface air temperature) 
and pr (precipitation) from a CLIMBER-X nature run for particle filter testing.

Usage:
    python generate_synthetic_obs.py --nature_run nature_run.nc --output_dir obs_data/
"""

import numpy as np
import netCDF4 as nc
import pandas as pd
import argparse
import os
from datetime import datetime, timedelta
import random

def load_nature_run_data(nature_run_file):
    """
    Load tas and pr data from CLIMBER-X nature run NetCDF file.
    
    Args:
        nature_run_file (str): Path to nature run NetCDF file
        
    Returns:
        dict: Dictionary containing tas, pr, lon, lat, time data
    """
    print(f"Loading nature run data from: {nature_run_file}")
    
    with nc.Dataset(nature_run_file, 'r') as ds:
        # Load coordinates
        lon = ds.variables['lon'][:] if 'lon' in ds.variables else ds.variables['longitude'][:]
        lat = ds.variables['lat'][:] if 'lat' in ds.variables else ds.variables['latitude'][:]
        time = ds.variables['time'][:] if 'time' in ds.variables else np.arange(1000)
        
        # Load variables (try different possible names)
        tas_names = ['tas', 'temp', 'temperature', 't2m', 't_ref']
        pr_names = ['pr', 'precip', 'precipitation', 'rain', 'prec']
        
        tas = None
        pr = None
        
        for name in tas_names:
            if name in ds.variables:
                tas = ds.variables[name][:]
                print(f"Found tas data with name: {name}")
                break
                
        for name in pr_names:
            if name in ds.variables:
                pr = ds.variables[name][:]
                print(f"Found pr data with name: {name}")
                break
        
        if tas is None:
            raise ValueError("Could not find tas/temperature data in nature run file")
        if pr is None:
            raise ValueError("Could not find pr/precipitation data in nature run file")
    
    return {
        'tas': tas,
        'pr': pr,
        'lon': lon,
        'lat': lat,
        'time': time
    }

def generate_random_locations(n_obs, lon_range, lat_range, seed=None):
    """
    Generate random observation locations.
    
    Args:
        n_obs (int): Number of observations
        lon_range (tuple): (min_lon, max_lon)
        lat_range (tuple): (min_lat, max_lat)
        seed (int): Random seed for reproducibility
        
    Returns:
        tuple: (lons, lats) arrays of random locations
    """
    if seed is not None:
        np.random.seed(seed)
    
    lons = np.random.uniform(lon_range[0], lon_range[1], n_obs)
    lats = np.random.uniform(lat_range[0], lat_range[1], n_obs)
    
    return lons, lats

def find_nearest_grid_point(obs_lon, obs_lat, model_lon, model_lat):
    """
    Find nearest grid point in model for given observation location.
    
    Args:
        obs_lon (float): Observation longitude
        obs_lat (float): Observation latitude
        model_lon (array): Model longitude grid
        model_lat (array): Model latitude grid
        
    Returns:
        tuple: (i, j) indices of nearest grid point
    """
    # Handle longitude wrapping
    if obs_lon < 0:
        obs_lon += 360.0
    
    # Find nearest grid point
    i = np.argmin(np.abs(model_lon - obs_lon))
    j = np.argmin(np.abs(model_lat - obs_lat))
    
    return i, j

def sample_nature_run(nature_data, obs_lons, obs_lats, variable, time_idx):
    """
    Sample nature run at given locations and time.
    
    Args:
        nature_data (dict): Nature run data
        obs_lons (array): Observation longitudes
        obs_lats (array): Observation latitudes
        variable (str): Variable name ('tas' or 'pr')
        time_idx (int): Time index
        
    Returns:
        array: Sampled values
    """
    model_lon = nature_data['lon']
    model_lat = nature_data['lat']
    var_data = nature_data[variable]
    
    sampled_values = []
    
    for obs_lon, obs_lat in zip(obs_lons, obs_lats):
        i, j = find_nearest_grid_point(obs_lon, obs_lat, model_lon, model_lat)
        
        # Extract value from nature run
        if len(var_data.shape) == 3:  # (time, lat, lon)
            value = var_data[time_idx, j, i]
        elif len(var_data.shape) == 4:  # (time, depth, lat, lon)
            value = var_data[time_idx, 0, j, i]  # Surface level
        else:
            raise ValueError(f"Unexpected data shape for {variable}: {var_data.shape}")
        
        sampled_values.append(float(value))
    
    return np.array(sampled_values)

def add_observation_noise(values, variable):
    """
    Add realistic observation noise to synthetic observations.
    
    Args:
        values (array): True values from nature run
        variable (str): Variable name ('tas' or 'pr')
        
    Returns:
        tuple: (noisy_values, errors)
    """
    if variable == 'tas':
        # Temperature: 1K standard deviation
        noise_std = 1.0
        errors = np.full_like(values, noise_std)
    elif variable == 'pr':
        # Precipitation: 10% relative error
        noise_std = 0.1 * np.abs(values)
        errors = noise_std
    else:
        raise ValueError(f"Unknown variable: {variable}")
    
    # Add Gaussian noise
    noise = np.random.normal(0, noise_std)
    noisy_values = values + noise
    
    return noisy_values, errors

def generate_synthetic_observations(nature_data, n_obs_tas=100, n_obs_pr=100, 
                                  start_year=0, n_years=1000, output_dir='obs_data'):
    """
    Generate synthetic observations for the entire experiment period.
    
    Args:
        nature_data (dict): Nature run data
        n_obs_tas (int): Number of tas observations per year
        n_obs_pr (int): Number of pr observations per year
        start_year (int): Starting year
        n_years (int): Number of years
        output_dir (str): Output directory for observation files
    """
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"Generating synthetic observations for {n_years} years...")
    print(f"  - {n_obs_tas} tas observations per year")
    print(f"  - {n_obs_pr} pr observations per year")
    
    # Get model grid bounds
    lon_min, lon_max = np.min(nature_data['lon']), np.max(nature_data['lon'])
    lat_min, lat_max = np.min(nature_data['lat']), np.max(nature_data['lat'])
    
    print(f"Model grid: lon [{lon_min:.1f}, {lon_max:.1f}], lat [{lat_min:.1f}, {lat_max:.1f}]")
    
    # Generate observations for each year
    for year in range(start_year, start_year + n_years):
        print(f"Processing year {year}...")
        
        # Use different seeds for tas and pr to get separate random locations
        tas_lons, tas_lats = generate_random_locations(n_obs_tas, (lon_min, lon_max), 
                                                      (lat_min, lat_max), seed=year*2)
        pr_lons, pr_lats = generate_random_locations(n_obs_pr, (lon_min, lon_max), 
                                                    (lat_min, lat_max), seed=year*2+1)
        
        # Sample nature run for this year
        time_idx = year  # Assuming yearly data
        tas_true = sample_nature_run(nature_data, tas_lons, tas_lats, 'tas', time_idx)
        pr_true = sample_nature_run(nature_data, pr_lons, pr_lats, 'pr', time_idx)
        
        # Add observation noise
        tas_obs, tas_errors = add_observation_noise(tas_true, 'tas')
        pr_obs, pr_errors = add_observation_noise(pr_true, 'pr')
        
        # Create observation dataframes
        tas_df = pd.DataFrame({
            'year': year,
            'lon': tas_lons,
            'lat': tas_lats,
            'variable': 'tas',
            'true_value': tas_true,
            'observed_value': tas_obs,
            'error': tas_errors
        })
        
        pr_df = pd.DataFrame({
            'year': year,
            'lon': pr_lons,
            'lat': pr_lats,
            'variable': 'pr',
            'true_value': pr_true,
            'observed_value': pr_obs,
            'error': pr_errors
        })
        
        # Combine and save
        obs_df = pd.concat([tas_df, pr_df], ignore_index=True)
        
        # Save to CSV
        output_file = os.path.join(output_dir, f'observations_year_{year:04d}.csv')
        obs_df.to_csv(output_file, index=False)
        
        # Also save in PDAF-compatible format
        pdaf_file = os.path.join(output_dir, f'pdaf_obs_year_{year:04d}.txt')
        save_pdaf_format(obs_df, pdaf_file)
    
    # Create summary file
    summary_file = os.path.join(output_dir, 'observation_summary.txt')
    create_summary_file(summary_file, n_years, n_obs_tas, n_obs_pr, lon_min, lon_max, lat_min, lat_max)
    
    print(f"✓ Synthetic observations generated in: {output_dir}")
    print(f"  - {n_years} yearly observation files")
    print(f"  - {n_obs_tas + n_obs_pr} observations per year")
    print(f"  - Separate random locations for tas and pr")

def save_pdaf_format(obs_df, filename):
    """
    Save observations in PDAF-compatible format.
    
    Args:
        obs_df (DataFrame): Observation dataframe
        filename (str): Output filename
    """
    with open(filename, 'w') as f:
        f.write(f"# PDAF Observation File\n")
        f.write(f"# Format: year lon lat variable observed_value error\n")
        f.write(f"# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"# Number of observations: {len(obs_df)}\n\n")
        
        for _, row in obs_df.iterrows():
            f.write(f"{row['year']:4d} {row['lon']:8.3f} {row['lat']:8.3f} "
                   f"{row['variable']:4s} {row['observed_value']:12.6f} {row['error']:8.3f}\n")

def create_summary_file(filename, n_years, n_obs_tas, n_obs_pr, lon_min, lon_max, lat_min, lat_max):
    """
    Create a summary file with experiment details.
    
    Args:
        filename (str): Summary filename
        n_years (int): Number of years
        n_obs_tas (int): Number of tas observations per year
        n_obs_pr (int): Number of pr observations per year
        lon_min, lon_max, lat_min, lat_max (float): Grid bounds
    """
    with open(filename, 'w') as f:
        f.write("CLIMBER-X OSSE Synthetic Observation Summary\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"Experiment period: {n_years} years\n")
        f.write(f"Observations per year:\n")
        f.write(f"  - tas (temperature): {n_obs_tas}\n")
        f.write(f"  - pr (precipitation): {n_obs_pr}\n")
        f.write(f"  - Total: {n_obs_tas + n_obs_pr}\n\n")
        f.write(f"Model grid bounds:\n")
        f.write(f"  - Longitude: [{lon_min:.1f}, {lon_max:.1f}] degrees\n")
        f.write(f"  - Latitude: [{lat_min:.1f}, {lat_max:.1f}] degrees\n\n")
        f.write(f"Observation errors:\n")
        f.write(f"  - tas: 1.0 K (Gaussian)\n")
        f.write(f"  - pr: 10% relative error (Gaussian)\n\n")
        f.write(f"File formats:\n")
        f.write(f"  - CSV: observations_year_YYYY.csv (detailed format)\n")
        f.write(f"  - PDAF: pdaf_obs_year_YYYY.txt (PDAF-compatible)\n\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

def main():
    parser = argparse.ArgumentParser(description='Generate synthetic observations for CLIMBER-X OSSE')
    parser.add_argument('--nature_run', required=True, help='Path to nature run NetCDF file')
    parser.add_argument('--output_dir', default='obs_data', help='Output directory for observations')
    parser.add_argument('--n_obs_tas', type=int, default=100, help='Number of tas observations per year')
    parser.add_argument('--n_obs_pr', type=int, default=100, help='Number of pr observations per year')
    parser.add_argument('--start_year', type=int, default=0, help='Starting year')
    parser.add_argument('--n_years', type=int, default=1000, help='Number of years')
    
    args = parser.parse_args()
    
    # Load nature run data
    nature_data = load_nature_run_data(args.nature_run)
    
    # Generate synthetic observations
    generate_synthetic_observations(
        nature_data,
        n_obs_tas=args.n_obs_tas,
        n_obs_pr=args.n_obs_pr,
        start_year=args.start_year,
        n_years=args.n_years,
        output_dir=args.output_dir
    )

if __name__ == '__main__':
    main() 