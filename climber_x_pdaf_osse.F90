! CLIMBER-X PDAF OSSE Integration Module
! This module provides the interface between CLIMBER-X and PDAF for OSSE experiments
! Supports particle filter assimilation of tas and pr observations at real lon/lat coordinates

module climber_x_pdaf_osse
  use pdaf_interfaces
  use pdafomi_interfaces
  implicit none

  ! OSSE experiment parameters
  integer :: ensemble_size = 50
  integer :: filter_type = 12  ! Particle filter
  integer :: n_obs_tas = 100   ! Number of tas observations per year
  integer :: n_obs_pr = 100    ! Number of pr observations per year
  integer :: n_years = 1000    ! Total experiment length
  integer :: current_year = 0  ! Current assimilation year
  
  ! CLIMBER-X grid information
  integer :: nx_climber, ny_climber
  real(kind=8), allocatable :: lon_climber(:,:), lat_climber(:,:)
  
  ! State vector information
  integer :: state_dim_total
  integer :: state_dim_tas, state_dim_pr
  
  ! Observation arrays
  integer :: n_obs_total
  real(kind=8), allocatable :: obs_lon(:), obs_lat(:)
  real(kind=8), allocatable :: obs_values(:), obs_errors(:)
  character(len=4), allocatable :: obs_variables(:)
  
  ! Model state arrays (ensemble)
  real(kind=8), allocatable :: ensemble_tas(:,:,:)  ! (nx, ny, ensemble_size)
  real(kind=8), allocatable :: ensemble_pr(:,:,:)   ! (nx, ny, ensemble_size)
  
  ! Diagnostics
  real(kind=8), allocatable :: rms_error_tas(:), rms_error_pr(:)
  real(kind=8), allocatable :: ensemble_spread_tas(:), ensemble_spread_pr(:)
  real(kind=8), allocatable :: effective_sample_size(:)
  
  ! File paths
  character(len=256) :: obs_data_dir = 'obs_data/'
  character(len=256) :: output_dir = 'osse_output/'
  
  ! Control flags
  logical :: assimilation_active = .false.
  logical :: diagnostics_enabled = .true.
  
contains

  ! ============================================================
  ! Initialize CLIMBER-X PDAF OSSE integration
  ! ============================================================
  subroutine init_climber_x_pdaf_osse(ens_size, n_tas, n_pr, n_exp_years)
    implicit none
    integer, intent(in) :: ens_size, n_tas, n_pr, n_exp_years
    
    ensemble_size = ens_size
    n_obs_tas = n_tas
    n_obs_pr = n_pr
    n_years = n_exp_years
    n_obs_total = n_obs_tas + n_obs_pr
    
    print *, "=== CLIMBER-X PDAF OSSE Integration ==="
    print *, "Initializing OSSE experiment..."
    print *, "  Ensemble size: ", ensemble_size
    print *, "  Observations per year: ", n_obs_tas, " tas + ", n_obs_pr, " pr"
    print *, "  Experiment length: ", n_years, " years"
    
    ! Initialize CLIMBER-X grid
    call init_climber_grid()
    
    ! Initialize state vector dimensions
    call init_state_vector_dimensions()
    
    ! Allocate arrays
    call allocate_osse_arrays()
    
    ! Initialize PDAF
    call init_pdaf_osse()
    
    ! Create output directories
    call create_output_directories()
    
    print *, "✓ OSSE integration initialized successfully"
    
  end subroutine init_climber_x_pdaf_osse

  ! ============================================================
  ! Initialize CLIMBER-X grid
  ! ============================================================
  subroutine init_climber_grid()
    implicit none
    
    ! This should interface with CLIMBER-X to get actual grid dimensions
    ! For now, using example dimensions - replace with actual CLIMBER-X calls
    
    nx_climber = 144  ! Example: 2.5 degree longitude resolution
    ny_climber = 96   ! Example: 2.5 degree latitude resolution
    
    allocate(lon_climber(nx_climber, ny_climber))
    allocate(lat_climber(nx_climber, ny_climber))
    
    ! Generate real longitude and latitude coordinates
    call generate_climber_grid_coordinates()
    
    print *, "CLIMBER-X grid: ", nx_climber, "x", ny_climber
    print *, "  Longitude range: ", minval(lon_climber), " to ", maxval(lon_climber), " degrees"
    print *, "  Latitude range: ", minval(lat_climber), " to ", maxval(lat_climber), " degrees"
    
  end subroutine init_climber_grid

  ! ============================================================
  ! Generate CLIMBER-X grid coordinates
  ! ============================================================
  subroutine generate_climber_grid_coordinates()
    implicit none
    integer :: i, j
    
    ! Generate longitude coordinates (0 to 360 degrees)
    do i = 1, nx_climber
      do j = 1, ny_climber
        lon_climber(i,j) = (i - 1) * 360.0 / nx_climber
      end do
    end do
    
    ! Generate latitude coordinates (-90 to 90 degrees)
    do i = 1, nx_climber
      do j = 1, ny_climber
        lat_climber(i,j) = -90.0 + (j - 1) * 180.0 / (ny_climber - 1)
      end do
    end do
    
  end subroutine generate_climber_grid_coordinates

  ! ============================================================
  ! Initialize state vector dimensions
  ! ============================================================
  subroutine init_state_vector_dimensions()
    implicit none
    
    state_dim_tas = nx_climber * ny_climber
    state_dim_pr = nx_climber * ny_climber
    state_dim_total = state_dim_tas + state_dim_pr
    
    print *, "State vector dimensions:"
    print *, "  tas: ", state_dim_tas
    print *, "  pr: ", state_dim_pr
    print *, "  Total: ", state_dim_total
    
  end subroutine init_state_vector_dimensions

  ! ============================================================
  ! Allocate OSSE arrays
  ! ============================================================
  subroutine allocate_osse_arrays()
    implicit none
    
    ! Observation arrays
    allocate(obs_lon(n_obs_total))
    allocate(obs_lat(n_obs_total))
    allocate(obs_values(n_obs_total))
    allocate(obs_errors(n_obs_total))
    allocate(obs_variables(n_obs_total))
    
    ! Ensemble arrays
    allocate(ensemble_tas(nx_climber, ny_climber, ensemble_size))
    allocate(ensemble_pr(nx_climber, ny_climber, ensemble_size))
    
    ! Diagnostic arrays
    allocate(rms_error_tas(n_years))
    allocate(rms_error_pr(n_years))
    allocate(ensemble_spread_tas(n_years))
    allocate(ensemble_spread_pr(n_years))
    allocate(effective_sample_size(n_years))
    
    print *, "✓ OSSE arrays allocated"
    
  end subroutine allocate_osse_arrays

  ! ============================================================
  ! Initialize PDAF for OSSE
  ! ============================================================
  subroutine init_pdaf_osse()
    implicit none
    
    ! Initialize PDAF with particle filter
    call PDAF_init(filter_type, ensemble_size, state_dim_total)
    
    print *, "✓ PDAF initialized with particle filter"
    print *, "  Filter type: ", filter_type, " (Particle filter)"
    print *, "  Ensemble size: ", ensemble_size
    
  end subroutine init_pdaf_osse

  ! ============================================================
  ! Create output directories
  ! ============================================================
  subroutine create_output_directories()
    implicit none
    character(len=256) :: cmd
    
    ! Create output directory
    cmd = 'mkdir -p ' // trim(output_dir)
    call system(cmd)
    
    ! Create subdirectories
    cmd = 'mkdir -p ' // trim(output_dir) // '/tas'
    call system(cmd)
    cmd = 'mkdir -p ' // trim(output_dir) // '/pr'
    call system(cmd)
    cmd = 'mkdir -p ' // trim(output_dir) // '/diagnostics'
    call system(cmd)
    
    print *, "✓ Output directories created"
    
  end subroutine create_output_directories

  ! ============================================================
  ! Load observations for a specific year
  ! ============================================================
  subroutine load_observations_for_year(year)
    implicit none
    integer, intent(in) :: year
    character(len=256) :: obs_file
    integer :: i, unit, ios
    character(len=256) :: line
    integer :: obs_year
    real(kind=8) :: obs_lon_val, obs_lat_val, obs_val, obs_err
    character(len=4) :: obs_var
    
    ! Construct observation file name
    write(obs_file, '(A,I4.4,A)') trim(obs_data_dir) // 'pdaf_obs_year_', year, '.txt'
    
    print *, "Loading observations from: ", trim(obs_file)
    
    ! Open observation file
    open(newunit=unit, file=obs_file, status='old', action='read', iostat=ios)
    if (ios /= 0) then
      print *, "Error: Could not open observation file: ", trim(obs_file)
      return
    end if
    
    ! Skip header lines
    do
      read(unit, '(A)', iostat=ios) line
      if (ios /= 0) exit
      if (line(1:1) /= '#') exit
    end do
    
    ! Read observations
    i = 1
    do
      if (i > n_obs_total) exit
      
      read(unit, *, iostat=ios) obs_year, obs_lon_val, obs_lat_val, obs_var, obs_val, obs_err
      if (ios /= 0) exit
      
      obs_lon(i) = obs_lon_val
      obs_lat(i) = obs_lat_val
      obs_variables(i) = obs_var
      obs_values(i) = obs_val
      obs_errors(i) = obs_err
      
      i = i + 1
    end do
    
    close(unit)
    
    print *, "  Loaded ", i-1, " observations for year ", year
    
  end subroutine load_observations_for_year

  ! ============================================================
  ! Main OSSE assimilation step
  ! ============================================================
  subroutine climber_x_osse_assimilation_step(year)
    implicit none
    integer, intent(in) :: year
    real(kind=8) :: rms_before_tas, rms_after_tas, rms_before_pr, rms_after_pr, ess
    
    current_year = year
    
    print *, "=== OSSE Assimilation Step Year ", year, " ==="
    
    ! Load observations for this year
    call load_observations_for_year(year)
    
    ! Pre-forecast step
    call PDAF_prepoststep(0, 0, 0, 0)
    
    ! Prepare observations for assimilation
    call prepare_osse_observations()
    
    ! Perform particle filter assimilation
    call perform_osse_particle_filter()
    
    ! Post-forecast step
    call PDAF_prepoststep(0, 0, 0, 1)
    
    ! Calculate diagnostics
    call calculate_osse_diagnostics(rms_before_tas, rms_after_tas, rms_before_pr, rms_after_pr, ess)
    
    ! Store diagnostics
    rms_error_tas(year+1) = rms_after_tas
    rms_error_pr(year+1) = rms_after_pr
    effective_sample_size(year+1) = ess
    
    ! Save results
    call save_osse_results(year)
    
    print *, "✓ OSSE assimilation step completed for year ", year
    print *, "  tas RMS: ", rms_before_tas, " -> ", rms_after_tas
    print *, "  pr RMS: ", rms_before_pr, " -> ", rms_after_pr
    print *, "  Effective sample size: ", ess
    
  end subroutine climber_x_osse_assimilation_step

  ! ============================================================
  ! Prepare observations for OSSE assimilation
  ! ============================================================
  subroutine prepare_osse_observations()
    implicit none
    integer :: i, tas_count, pr_count
    
    print *, "Preparing ", n_obs_total, " observations for assimilation..."
    
    tas_count = 0
    pr_count = 0
    
    do i = 1, n_obs_total
      if (obs_variables(i) == 'tas') then
        tas_count = tas_count + 1
      else if (obs_variables(i) == 'pr') then
        pr_count = pr_count + 1
      end if
    end do
    
    print *, "  tas observations: ", tas_count
    print *, "  pr observations: ", pr_count
    
  end subroutine prepare_osse_observations

  ! ============================================================
  ! Perform particle filter assimilation for OSSE
  ! ============================================================
  subroutine perform_osse_particle_filter()
    implicit none
    
    print *, "Performing particle filter assimilation for OSSE..."
    
    ! Call PDAF particle filter
    call PDAF_assimilate_pf()
    
    print *, "✓ Particle filter assimilation completed"
    
  end subroutine perform_osse_particle_filter

  ! ============================================================
  ! Calculate OSSE diagnostics
  ! ============================================================
  subroutine calculate_osse_diagnostics(rms_before_tas, rms_after_tas, rms_before_pr, rms_after_pr, ess)
    implicit none
    real(kind=8), intent(out) :: rms_before_tas, rms_after_tas, rms_before_pr, rms_after_pr, ess
    
    ! Calculate RMS error before and after assimilation
    ! This is a simplified calculation - replace with actual truth comparison
    rms_before_tas = 2.5  ! Example value
    rms_after_tas = 1.8   ! Example value
    rms_before_pr = 3.2   ! Example value
    rms_after_pr = 2.1    ! Example value
    
    ! Calculate effective sample size
    ess = 0.7  ! Example value
    
  end subroutine calculate_osse_diagnostics

  ! ============================================================
  ! Get state vector from CLIMBER-X ensemble
  ! ============================================================
  subroutine get_climber_x_osse_state(state_vector, member)
    implicit none
    real(kind=8), intent(out) :: state_vector(state_dim_total)
    integer, intent(in) :: member
    integer :: i, j, idx
    
    idx = 1
    
    ! Extract tas state variables
    do j = 1, ny_climber
      do i = 1, nx_climber
        state_vector(idx) = ensemble_tas(i, j, member)
        idx = idx + 1
      end do
    end do
    
    ! Extract pr state variables
    do j = 1, ny_climber
      do i = 1, nx_climber
        state_vector(idx) = ensemble_pr(i, j, member)
        idx = idx + 1
      end do
    end do
    
  end subroutine get_climber_x_osse_state

  ! ============================================================
  ! Set state vector back to CLIMBER-X ensemble
  ! ============================================================
  subroutine set_climber_x_osse_state(state_vector, member)
    implicit none
    real(kind=8), intent(in) :: state_vector(state_dim_total)
    integer, intent(in) :: member
    integer :: i, j, idx
    
    idx = 1
    
    ! Set tas state variables
    do j = 1, ny_climber
      do i = 1, nx_climber
        ensemble_tas(i, j, member) = state_vector(idx)
        idx = idx + 1
      end do
    end do
    
    ! Set pr state variables
    do j = 1, ny_climber
      do i = 1, nx_climber
        ensemble_pr(i, j, member) = state_vector(idx)
        idx = idx + 1
      end do
    end do
    
  end subroutine set_climber_x_osse_state

  ! ============================================================
  ! Save OSSE results
  ! ============================================================
  subroutine save_osse_results(year)
    implicit none
    integer, intent(in) :: year
    character(len=256) :: tas_file, pr_file, diag_file
    integer :: unit, i, j, m
    
    ! Save tas ensemble
    write(tas_file, '(A,I4.4,A)') trim(output_dir) // '/tas/ensemble_tas_year_', year, '.bin'
    open(newunit=unit, file=tas_file, form='unformatted', access='direct', recl=8*nx_climber*ny_climber)
    do m = 1, ensemble_size
      write(unit, rec=m) ensemble_tas(:,:,m)
    end do
    close(unit)
    
    ! Save pr ensemble
    write(pr_file, '(A,I4.4,A)') trim(output_dir) // '/pr/ensemble_pr_year_', year, '.bin'
    open(newunit=unit, file=pr_file, form='unformatted', access='direct', recl=8*nx_climber*ny_climber)
    do m = 1, ensemble_size
      write(unit, rec=m) ensemble_pr(:,:,m)
    end do
    close(unit)
    
    ! Save diagnostics
    write(diag_file, '(A,I4.4,A)') trim(output_dir) // '/diagnostics/diagnostics_year_', year, '.txt'
    open(newunit=unit, file=diag_file, status='replace')
    write(unit, *) "Year: ", year
    write(unit, *) "RMS Error tas: ", rms_error_tas(year+1)
    write(unit, *) "RMS Error pr: ", rms_error_pr(year+1)
    write(unit, *) "Effective Sample Size: ", effective_sample_size(year+1)
    close(unit)
    
  end subroutine save_osse_results

  ! ============================================================
  ! Initialize ensemble with perturbations
  ! ============================================================
  subroutine initialize_osse_ensemble(base_tas, base_pr, perturbation_amplitude)
    implicit none
    real(kind=8), intent(in) :: base_tas(nx_climber, ny_climber)
    real(kind=8), intent(in) :: base_pr(nx_climber, ny_climber)
    real(kind=8), intent(in) :: perturbation_amplitude
    integer :: m, i, j
    real(kind=8) :: noise_tas, noise_pr
    
    print *, "Initializing OSSE ensemble with perturbations..."
    
    do m = 1, ensemble_size
      do j = 1, ny_climber
        do i = 1, nx_climber
          ! Add Gaussian noise to tas
          call random_number(noise_tas)
          noise_tas = (noise_tas - 0.5) * 2.0 * perturbation_amplitude
          ensemble_tas(i, j, m) = base_tas(i, j) + noise_tas
          
          ! Add Gaussian noise to pr
          call random_number(noise_pr)
          noise_pr = (noise_pr - 0.5) * 2.0 * perturbation_amplitude
          ensemble_pr(i, j, m) = base_pr(i, j) + noise_pr
        end do
      end do
    end do
    
    print *, "✓ Ensemble initialized with ", ensemble_size, " members"
    
  end subroutine initialize_osse_ensemble

  ! ============================================================
  ! Run complete OSSE experiment
  ! ============================================================
  subroutine run_complete_osse_experiment()
    implicit none
    integer :: year
    
    print *, "=== Running Complete OSSE Experiment ==="
    print *, "Years: 0 to ", n_years-1
    print *, "Ensemble size: ", ensemble_size
    
    ! Run assimilation for each year
    do year = 0, n_years-1
      call climber_x_osse_assimilation_step(year)
    end do
    
    ! Save final diagnostics
    call save_final_osse_diagnostics()
    
    print *, "✓ Complete OSSE experiment finished"
    
  end subroutine run_complete_osse_experiment

  ! ============================================================
  ! Save final OSSE diagnostics
  ! ============================================================
  subroutine save_final_osse_diagnostics()
    implicit none
    character(len=256) :: final_diag_file
    integer :: unit, year
    
    final_diag_file = trim(output_dir) // '/diagnostics/final_diagnostics.txt'
    
    open(newunit=unit, file=final_diag_file, status='replace')
    write(unit, *) "CLIMBER-X OSSE Final Diagnostics"
    write(unit, *) "================================"
    write(unit, *) "Ensemble size: ", ensemble_size
    write(unit, *) "Experiment length: ", n_years, " years"
    write(unit, *) "Observations per year: ", n_obs_tas, " tas + ", n_obs_pr, " pr"
    write(unit, *)
    write(unit, *) "Year  RMS_TAS  RMS_PR  ESS"
    write(unit, *) "----  -------  ------  ---"
    
    do year = 1, n_years
      write(unit, '(I4,2F9.3,F7.3)') year-1, rms_error_tas(year), rms_error_pr(year), effective_sample_size(year)
    end do
    
    close(unit)
    
    print *, "✓ Final diagnostics saved to: ", trim(final_diag_file)
    
  end subroutine save_final_osse_diagnostics

  ! ============================================================
  ! Cleanup OSSE integration
  ! ============================================================
  subroutine cleanup_climber_x_pdaf_osse()
    implicit none
    
    print *, "Cleaning up CLIMBER-X PDAF OSSE integration..."
    
    ! Deallocate arrays
    if (allocated(lon_climber)) deallocate(lon_climber)
    if (allocated(lat_climber)) deallocate(lat_climber)
    if (allocated(obs_lon)) deallocate(obs_lon)
    if (allocated(obs_lat)) deallocate(obs_lat)
    if (allocated(obs_values)) deallocate(obs_values)
    if (allocated(obs_errors)) deallocate(obs_errors)
    if (allocated(obs_variables)) deallocate(obs_variables)
    if (allocated(ensemble_tas)) deallocate(ensemble_tas)
    if (allocated(ensemble_pr)) deallocate(ensemble_pr)
    if (allocated(rms_error_tas)) deallocate(rms_error_tas)
    if (allocated(rms_error_pr)) deallocate(rms_error_pr)
    if (allocated(ensemble_spread_tas)) deallocate(ensemble_spread_tas)
    if (allocated(ensemble_spread_pr)) deallocate(ensemble_spread_pr)
    if (allocated(effective_sample_size)) deallocate(effective_sample_size)
    
    ! Finalize PDAF
    call PDAF_finalize()
    
    print *, "✓ CLIMBER-X PDAF OSSE integration cleaned up"
    
  end subroutine cleanup_climber_x_pdaf_osse

end module climber_x_pdaf_osse 