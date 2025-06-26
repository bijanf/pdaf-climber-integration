#!/usr/bin/env python3
"""
Evaluate CLIMBER-X OSSE Results

This script analyzes the results of OSSE experiments with different ensemble sizes
and generates plots comparing particle filter performance.

Usage:
    python evaluate_osse_results.py --ensemble_sizes "20 40 60 80 100" --n_years 1000
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import argparse
import os
import glob
from datetime import datetime

def load_osse_diagnostics(ensemble_size, n_years):
    """
    Load diagnostics for a specific ensemble size.
    
    Args:
        ensemble_size (int): Ensemble size
        n_years (int): Number of years
        
    Returns:
        dict: Dictionary containing diagnostic data
    """
    results_dir = f"osse_results_{ensemble_size}/osse_output/diagnostics"
    
    # Load final diagnostics
    final_diag_file = os.path.join(results_dir, "final_diagnostics.txt")
    
    if not os.path.exists(final_diag_file):
        print(f"Warning: No diagnostics found for ensemble size {ensemble_size}")
        return None
    
    # Parse final diagnostics
    diagnostics = {
        'ensemble_size': ensemble_size,
        'years': [],
        'rms_tas': [],
        'rms_pr': [],
        'ess': []
    }
    
    with open(final_diag_file, 'r') as f:
        lines = f.readlines()
        
    # Find the data section
    data_started = False
    for line in lines:
        line = line.strip()
        if 'Year  RMS_TAS  RMS_PR  ESS' in line:
            data_started = True
            continue
        if data_started and line and not line.startswith('---'):
            try:
                parts = line.split()
                if len(parts) >= 4:
                    diagnostics['years'].append(int(parts[0]))
                    diagnostics['rms_tas'].append(float(parts[1]))
                    diagnostics['rms_pr'].append(float(parts[2]))
                    diagnostics['ess'].append(float(parts[3]))
            except (ValueError, IndexError):
                continue
    
    return diagnostics

def load_all_osse_results(ensemble_sizes, n_years):
    """
    Load diagnostics for all ensemble sizes.
    
    Args:
        ensemble_sizes (list): List of ensemble sizes
        n_years (int): Number of years
        
    Returns:
        dict: Dictionary containing all diagnostic data
    """
    all_results = {}
    
    for ens_size in ensemble_sizes:
        print(f"Loading results for ensemble size {ens_size}...")
        results = load_osse_diagnostics(ens_size, n_years)
        if results is not None:
            all_results[ens_size] = results
    
    return all_results

def calculate_performance_metrics(all_results):
    """
    Calculate performance metrics for each ensemble size.
    
    Args:
        all_results (dict): All diagnostic data
        
    Returns:
        DataFrame: Performance metrics
    """
    metrics = []
    
    for ens_size, results in all_results.items():
        if not results['rms_tas'] or not results['rms_pr']:
            continue
            
        # Calculate mean RMS errors
        mean_rms_tas = np.mean(results['rms_tas'])
        mean_rms_pr = np.mean(results['rms_pr'])
        mean_ess = np.mean(results['ess'])
        
        # Calculate error reduction (assuming free run RMS = 3.0)
        free_run_rms = 3.0
        tas_reduction = (free_run_rms - mean_rms_tas) / free_run_rms * 100
        pr_reduction = (free_run_rms - mean_rms_pr) / free_run_rms * 100
        
        metrics.append({
            'ensemble_size': ens_size,
            'mean_rms_tas': mean_rms_tas,
            'mean_rms_pr': mean_rms_pr,
            'mean_ess': mean_ess,
            'tas_error_reduction_pct': tas_reduction,
            'pr_error_reduction_pct': pr_reduction
        })
    
    return pd.DataFrame(metrics)

def create_performance_plots(metrics_df, output_dir):
    """
    Create performance comparison plots.
    
    Args:
        metrics_df (DataFrame): Performance metrics
        output_dir (str): Output directory
    """
    os.makedirs(output_dir, exist_ok=True)
    
    # Set up plotting style
    plt.style.use('seaborn-v0_8')
    sns.set_palette("husl")
    
    # Create figure with subplots
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    fig.suptitle('CLIMBER-X OSSE Particle Filter Performance vs Ensemble Size', fontsize=16)
    
    # Plot 1: RMS Error vs Ensemble Size
    ax1 = axes[0, 0]
    ax1.plot(metrics_df['ensemble_size'], metrics_df['mean_rms_tas'], 'o-', label='tas', linewidth=2, markersize=8)
    ax1.plot(metrics_df['ensemble_size'], metrics_df['mean_rms_pr'], 's-', label='pr', linewidth=2, markersize=8)
    ax1.set_xlabel('Ensemble Size')
    ax1.set_ylabel('Mean RMS Error')
    ax1.set_title('RMS Error vs Ensemble Size')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Error Reduction vs Ensemble Size
    ax2 = axes[0, 1]
    ax2.plot(metrics_df['ensemble_size'], metrics_df['tas_error_reduction_pct'], 'o-', 
             label='tas', linewidth=2, markersize=8, color='blue')
    ax2.plot(metrics_df['ensemble_size'], metrics_df['pr_error_reduction_pct'], 's-', 
             label='pr', linewidth=2, markersize=8, color='orange')
    ax2.set_xlabel('Ensemble Size')
    ax2.set_ylabel('Error Reduction (%)')
    ax2.set_title('Error Reduction vs Ensemble Size')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: Effective Sample Size vs Ensemble Size
    ax3 = axes[1, 0]
    ax3.plot(metrics_df['ensemble_size'], metrics_df['mean_ess'], 'o-', 
             color='green', linewidth=2, markersize=8)
    ax3.axhline(y=0.5, color='red', linestyle='--', alpha=0.7, label='ESS = 0.5 threshold')
    ax3.set_xlabel('Ensemble Size')
    ax3.set_ylabel('Mean Effective Sample Size')
    ax3.set_title('Effective Sample Size vs Ensemble Size')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Plot 4: Performance summary table
    ax4 = axes[1, 1]
    ax4.axis('off')
    
    # Create summary table
    table_data = []
    for _, row in metrics_df.iterrows():
        table_data.append([
            f"{row['ensemble_size']}",
            f"{row['mean_rms_tas']:.3f}",
            f"{row['mean_rms_pr']:.3f}",
            f"{row['mean_ess']:.3f}",
            f"{row['tas_error_reduction_pct']:.1f}%",
            f"{row['pr_error_reduction_pct']:.1f}%"
        ])
    
    table = ax4.table(cellText=table_data,
                     colLabels=['Ens', 'RMS_tas', 'RMS_pr', 'ESS', 'TAS_red%', 'PR_red%'],
                     cellLoc='center',
                     loc='center',
                     bbox=[0, 0, 1, 1])
    table.auto_set_font_size(False)
    table.set_fontsize(10)
    table.scale(1, 2)
    ax4.set_title('Performance Summary')
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'osse_performance_comparison.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"✓ Performance plots saved to: {output_dir}/osse_performance_comparison.png")

def create_time_series_plots(all_results, output_dir):
    """
    Create time series plots for each ensemble size.
    
    Args:
        all_results (dict): All diagnostic data
        output_dir (str): Output directory
    """
    os.makedirs(output_dir, exist_ok=True)
    
    # Create time series plots
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('OSSE Time Series - RMS Error Evolution', fontsize=16)
    
    # Plot positions
    plot_positions = [(0, 0), (0, 1), (1, 0), (1, 1)]
    
    for i, (ens_size, results) in enumerate(all_results.items()):
        if i >= 4:  # Only plot first 4 ensemble sizes
            break
            
        row, col = plot_positions[i]
        ax = axes[row, col]
        
        years = results['years']
        rms_tas = results['rms_tas']
        rms_pr = results['rms_pr']
        
        ax.plot(years, rms_tas, label='tas', linewidth=1.5)
        ax.plot(years, rms_pr, label='pr', linewidth=1.5)
        ax.set_xlabel('Year')
        ax.set_ylabel('RMS Error')
        ax.set_title(f'Ensemble Size: {ens_size}')
        ax.legend()
        ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'osse_time_series.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"✓ Time series plots saved to: {output_dir}/osse_time_series.png")

def create_ess_analysis(all_results, output_dir):
    """
    Create effective sample size analysis.
    
    Args:
        all_results (dict): All diagnostic data
        output_dir (str): Output directory
    """
    os.makedirs(output_dir, exist_ok=True)
    
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
    fig.suptitle('Effective Sample Size Analysis', fontsize=16)
    
    # Plot 1: ESS time series
    for ens_size, results in all_results.items():
        years = results['years']
        ess = results['ess']
        ax1.plot(years, ess, label=f'Ens={ens_size}', linewidth=1.5)
    
    ax1.axhline(y=0.5, color='red', linestyle='--', alpha=0.7, label='ESS = 0.5 threshold')
    ax1.set_xlabel('Year')
    ax1.set_ylabel('Effective Sample Size')
    ax1.set_title('ESS Evolution')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: ESS distribution
    ess_data = []
    ens_labels = []
    for ens_size, results in all_results.items():
        ess_data.extend(results['ess'])
        ens_labels.extend([f'Ens={ens_size}'] * len(results['ess']))
    
    ess_df = pd.DataFrame({'ESS': ess_data, 'Ensemble': ens_labels})
    
    sns.boxplot(data=ess_df, x='Ensemble', y='ESS', ax=ax2)
    ax2.axhline(y=0.5, color='red', linestyle='--', alpha=0.7, label='ESS = 0.5 threshold')
    ax2.set_title('ESS Distribution')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'osse_ess_analysis.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"✓ ESS analysis saved to: {output_dir}/osse_ess_analysis.png")

def generate_summary_report(metrics_df, all_results, output_dir):
    """
    Generate a comprehensive summary report.
    
    Args:
        metrics_df (DataFrame): Performance metrics
        all_results (dict): All diagnostic data
        output_dir (str): Output directory
    """
    report_file = os.path.join(output_dir, 'osse_summary_report.txt')
    
    with open(report_file, 'w') as f:
        f.write("CLIMBER-X OSSE Particle Filter Experiment Summary Report\n")
        f.write("=" * 60 + "\n\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        
        f.write("EXPERIMENT CONFIGURATION\n")
        f.write("-" * 30 + "\n")
        f.write(f"Ensemble sizes tested: {list(all_results.keys())}\n")
        f.write(f"Observations per year: 100 tas + 100 pr\n")
        f.write(f"Experiment length: {len(next(iter(all_results.values()))['years'])} years\n")
        f.write(f"Filter type: Particle filter (type 12)\n\n")
        
        f.write("PERFORMANCE SUMMARY\n")
        f.write("-" * 20 + "\n")
        f.write("Ensemble Size | Mean RMS tas | Mean RMS pr | Mean ESS | TAS red% | PR red%\n")
        f.write("-" * 80 + "\n")
        
        for _, row in metrics_df.iterrows():
            f.write(f"{row['ensemble_size']:13d} | {row['mean_rms_tas']:11.3f} | {row['mean_rms_pr']:10.3f} | "
                   f"{row['mean_ess']:8.3f} | {row['tas_error_reduction_pct']:7.1f}% | {row['pr_error_reduction_pct']:6.1f}%\n")
        
        f.write("\nKEY FINDINGS\n")
        f.write("-" * 12 + "\n")
        
        # Find best performing ensemble size
        best_tas = metrics_df.loc[metrics_df['mean_rms_tas'].idxmin()]
        best_pr = metrics_df.loc[metrics_df['mean_rms_pr'].idxmin()]
        best_ess = metrics_df.loc[metrics_df['mean_ess'].idxmax()]
        
        f.write(f"• Best tas performance: Ensemble size {best_tas['ensemble_size']} "
               f"(RMS: {best_tas['mean_rms_tas']:.3f}, reduction: {best_tas['tas_error_reduction_pct']:.1f}%)\n")
        f.write(f"• Best pr performance: Ensemble size {best_pr['ensemble_size']} "
               f"(RMS: {best_pr['mean_rms_pr']:.3f}, reduction: {best_pr['pr_error_reduction_pct']:.1f}%)\n")
        f.write(f"• Best ESS: Ensemble size {best_ess['ensemble_size']} (ESS: {best_ess['mean_ess']:.3f})\n")
        
        # Check for ensemble collapse
        low_ess_count = len(metrics_df[metrics_df['mean_ess'] < 0.5])
        if low_ess_count > 0:
            f.write(f"• Warning: {low_ess_count} ensemble sizes show signs of collapse (ESS < 0.5)\n")
        else:
            f.write("• All ensemble sizes maintain good diversity (ESS > 0.5)\n")
        
        f.write("\nRECOMMENDATIONS\n")
        f.write("-" * 15 + "\n")
        
        # Provide recommendations based on results
        optimal_ens = metrics_df.loc[metrics_df['tas_error_reduction_pct'].idxmax()]
        f.write(f"• Recommended ensemble size: {optimal_ens['ensemble_size']} "
               f"(best balance of performance and computational cost)\n")
        f.write("• Consider using bootstrap particle filter if ESS remains low\n")
        f.write("• Monitor ensemble diversity in longer experiments\n")
        
        f.write("\nFILES GENERATED\n")
        f.write("-" * 16 + "\n")
        f.write("• osse_performance_comparison.png - Performance vs ensemble size\n")
        f.write("• osse_time_series.png - Time evolution of RMS errors\n")
        f.write("• osse_ess_analysis.png - Effective sample size analysis\n")
        f.write("• osse_summary_report.txt - This report\n")
    
    print(f"✓ Summary report saved to: {report_file}")

def main():
    parser = argparse.ArgumentParser(description='Evaluate CLIMBER-X OSSE results')
    parser.add_argument('--ensemble_sizes', required=True, 
                       help='Space-separated list of ensemble sizes (e.g., "20 40 60 80 100")')
    parser.add_argument('--n_years', type=int, default=1000, help='Number of years in experiment')
    parser.add_argument('--output_dir', default='osse_analysis', help='Output directory for analysis')
    
    args = parser.parse_args()
    
    # Parse ensemble sizes
    ensemble_sizes = [int(x) for x in args.ensemble_sizes.split()]
    
    print("=== CLIMBER-X OSSE Results Evaluation ===")
    print(f"Ensemble sizes: {ensemble_sizes}")
    print(f"Number of years: {args.n_years}")
    print(f"Output directory: {args.output_dir}")
    print()
    
    # Load all results
    print("Loading OSSE results...")
    all_results = load_all_osse_results(ensemble_sizes, args.n_years)
    
    if not all_results:
        print("Error: No results found!")
        return
    
    print(f"✓ Loaded results for {len(all_results)} ensemble sizes")
    
    # Calculate performance metrics
    print("Calculating performance metrics...")
    metrics_df = calculate_performance_metrics(all_results)
    
    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)
    
    # Generate plots and analysis
    print("Generating performance plots...")
    create_performance_plots(metrics_df, args.output_dir)
    
    print("Generating time series plots...")
    create_time_series_plots(all_results, args.output_dir)
    
    print("Generating ESS analysis...")
    create_ess_analysis(all_results, args.output_dir)
    
    print("Generating summary report...")
    generate_summary_report(metrics_df, all_results, args.output_dir)
    
    # Save metrics to CSV
    metrics_file = os.path.join(args.output_dir, 'osse_performance_metrics.csv')
    metrics_df.to_csv(metrics_file, index=False)
    print(f"✓ Performance metrics saved to: {metrics_file}")
    
    print()
    print("=== Evaluation Complete ===")
    print(f"All results saved to: {args.output_dir}/")
    print("Check the summary report for key findings and recommendations.")

if __name__ == '__main__':
    main() 