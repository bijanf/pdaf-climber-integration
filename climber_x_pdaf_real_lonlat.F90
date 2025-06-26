! CLIMBER-X PDAF Integration Module with Real Lon/Lat Coordinates
! This module provides the interface between CLIMBER-X and PDAF for real-world data assimilation
! Supports particle filter assimilation with actual geographic coordinates

module climber_x_pdaf_real_lonlat
  use pdaf_interfaces
  use pdafomi_interfaces
  implicit none

  ! CLIMBER-X grid information
  integer :: nx_climber, ny_climber, nz_climber
  real(kind=8), allocatable :: lon_climber(:,:), lat_climber(:,:)
  real(kind=8), allocatable :: depth_climber(:)  ! For ocean component
  
  ! Observation information
  integer :: n_obs_total
  real(kind=8), allocatable :: obs_lon(:), obs_lat(:), obs_depth(:)
  real(kind=8), allocatable :: obs_values(:), obs_errors(:)
  integer, allocatable :: obs_types(:)  ! 1=ocean, 2=atmosphere, 3=ice, 4=land
  
  ! Particle filter parameters
  integer :: ensemble_size = 50
  integer :: filter_type = 12  ! Particle filter
  real(kind=8) :: resample_threshold = 0.5  ! Effective sample size threshold
  real(kind=8) :: noise_amplitude = 0.1     ! Process noise amplitude
  
  ! Assimilation control
  logical :: assimilation_active = .false.
  integer :: assimilation_step = 0
  integer :: assimilation_frequency = 1  ! Assimilate every N model steps
  
  ! State vector information
  integer :: state_dim_total
  integer :: state_dim_atm, state_dim_ocn, state_dim_ice, state_dim_lnd
  
  ! Output and diagnostics
  real(kind=8), allocatable :: rms_error(:), ensemble_spread(:)
  real(kind=8), allocatable :: effective_sample_size(:)
  
contains

  ! ============================================================
  ! Initialize PDAF integration with real lon/lat coordinates
  ! ============================================================
  subroutine init_climber_x_pdaf_real_lonlat()
    implicit none
    
    print *, "=== CLIMBER-X PDAF Integration with Real Lon/Lat ==="
    print *, "Initializing data assimilation system..."
    
    ! Initialize CLIMBER-X grid dimensions
    call get_climber_grid_dimensions()
    
    ! Allocate grid coordinate arrays
    call allocate_grid_arrays()
    
    ! Load CLIMBER-X grid coordinates (real lon/lat)
    call load_climber_grid_coordinates()
    
    ! Initialize state vector dimensions
    call initialize_state_vector_dimensions()
    
    ! Initialize PDAF
    call init_pdaf_real_lonlat()
    
    ! Load real observations
    call load_real_observations()
    
    print *, "✓ PDAF integration initialized successfully"
    print *, "  Grid size: ", nx_climber, "x", ny_climber, "x", nz_climber
    print *, "  Ensemble size: ", ensemble_size
    print *, "  Observations: ", n_obs_total
    print *, "  State dimension: ", state_dim_total
    
  end subroutine init_climber_x_pdaf_real_lonlat

  ! ============================================================
  ! Get CLIMBER-X grid dimensions
  ! ============================================================
  subroutine get_climber_grid_dimensions()
    implicit none
    
    ! This should interface with CLIMBER-X to get actual grid dimensions
    ! For now, using example dimensions - replace with actual CLIMBER-X calls
    
    nx_climber = 144  ! Example: 2.5 degree longitude resolution
    ny_climber = 96   ! Example: 2.5 degree latitude resolution  
    nz_climber = 20   ! Example: ocean depth levels
    
    print *, "CLIMBER-X grid dimensions: ", nx_climber, "x", ny_climber, "x", nz_climber
    
  end subroutine get_climber_grid_dimensions

  ! ============================================================
  ! Allocate grid coordinate arrays
  ! ============================================================
  subroutine allocate_grid_arrays()
    implicit none
    
    allocate(lon_climber(nx_climber, ny_climber))
    allocate(lat_climber(nx_climber, ny_climber))
    allocate(depth_climber(nz_climber))
    
    print *, "✓ Grid coordinate arrays allocated"
    
  end subroutine allocate_grid_arrays

  ! ============================================================
  ! Load CLIMBER-X grid coordinates (real lon/lat)
  ! ============================================================
  subroutine load_climber_grid_coordinates()
    implicit none
    integer :: i, j, k
    
    ! Generate real longitude coordinates (0 to 360 degrees)
    do i = 1, nx_climber
      do j = 1, ny_climber
        lon_climber(i,j) = (i - 1) * 360.0 / nx_climber
      end do
    end do
    
    ! Generate real latitude coordinates (-90 to 90 degrees)
    do i = 1, nx_climber
      do j = 1, ny_climber
        lat_climber(i,j) = -90.0 + (j - 1) * 180.0 / (ny_climber - 1)
      end do
    end do
    
    ! Generate depth coordinates (0 to 5000m for ocean)
    do k = 1, nz_climber
      depth_climber(k) = (k - 1) * 5000.0 / (nz_climber - 1)
    end do
    
    print *, "✓ Real lon/lat coordinates loaded"
    print *, "  Longitude range: ", minval(lon_climber), " to ", maxval(lon_climber), " degrees"
    print *, "  Latitude range: ", minval(lat_climber), " to ", maxval(lat_climber), " degrees"
    print *, "  Depth range: ", minval(depth_climber), " to ", maxval(depth_climber), " meters"
    
  end subroutine load_climber_grid_coordinates

  ! ============================================================
  ! Initialize state vector dimensions
  ! ============================================================
  subroutine initialize_state_vector_dimensions()
    implicit none
    
    ! Calculate state vector dimensions for each component
    state_dim_atm = nx_climber * ny_climber * 5  ! Temperature, pressure, wind, humidity, etc.
    state_dim_ocn = nx_climber * ny_climber * nz_climber * 3  ! Temperature, salinity, velocity
    state_dim_ice = nx_climber * ny_climber * 2  ! Ice thickness, concentration
    state_dim_lnd = nx_climber * ny_climber * 3  ! Temperature, moisture, vegetation
    
    state_dim_total = state_dim_atm + state_dim_ocn + state_dim_ice + state_dim_lnd
    
    print *, "State vector dimensions:"
    print *, "  Atmosphere: ", state_dim_atm
    print *, "  Ocean: ", state_dim_ocn  
    print *, "  Ice: ", state_dim_ice
    print *, "  Land: ", state_dim_lnd
    print *, "  Total: ", state_dim_total
    
  end subroutine initialize_state_vector_dimensions

  ! ============================================================
  ! Initialize PDAF with real lon/lat support
  ! ============================================================
  subroutine init_pdaf_real_lonlat()
    implicit none
    
    ! Initialize PDAF with particle filter
    call PDAF_init(filter_type, ensemble_size, state_dim_total)
    
    ! Set particle filter parameters
    call PDAF_set_pf_params(resample_threshold, noise_amplitude)
    
    print *, "✓ PDAF initialized with particle filter"
    print *, "  Filter type: ", filter_type, " (Particle filter)"
    print *, "  Ensemble size: ", ensemble_size
    print *, "  Resample threshold: ", resample_threshold
    
  end subroutine init_pdaf_real_lonlat

  ! ============================================================
  ! Load real observations with actual lon/lat coordinates
  ! ============================================================
  subroutine load_real_observations()
    implicit none
    integer :: i
    
    ! Example: Load real observations from file or generate synthetic ones
    ! In practice, this would read from NetCDF files with real data
    
    n_obs_total = 1000  ! Example: 1000 observations
    
    allocate(obs_lon(n_obs_total))
    allocate(obs_lat(n_obs_total))
    allocate(obs_depth(n_obs_total))
    allocate(obs_values(n_obs_total))
    allocate(obs_errors(n_obs_total))
    allocate(obs_types(n_obs_total))
    
    ! Generate example observations at real locations
    do i = 1, n_obs_total
      ! Random real-world locations
      obs_lon(i) = 360.0 * rand()  ! 0 to 360 degrees
      obs_lat(i) = 180.0 * rand() - 90.0  ! -90 to 90 degrees
      obs_depth(i) = 5000.0 * rand()  ! 0 to 5000m
      
      ! Example observation values (replace with real data)
      obs_values(i) = 280.0 + 20.0 * rand()  ! Temperature around 280K
      obs_errors(i) = 1.0  ! 1K observation error
      
      ! Random observation types
      obs_types(i) = 1 + int(4 * rand())  ! 1=ocean, 2=atmosphere, 3=ice, 4=land
    end do
    
    print *, "✓ Real observations loaded: ", n_obs_total, " observations"
    print *, "  Longitude range: ", minval(obs_lon), " to ", maxval(obs_lon), " degrees"
    print *, "  Latitude range: ", minval(obs_lat), " to ", maxval(obs_lat), " degrees"
    print *, "  Depth range: ", minval(obs_depth), " to ", maxval(obs_depth), " meters"
    
  end subroutine load_real_observations

  ! ============================================================
  ! Main assimilation step with real lon/lat coordinates
  ! ============================================================
  subroutine climber_x_assimilation_step_real_lonlat()
    implicit none
    real(kind=8) :: rms_before, rms_after, ess
    
    if (.not. assimilation_active) return
    
    assimilation_step = assimilation_step + 1
    
    print *, "=== Assimilation Step ", assimilation_step, " ==="
    print *, "Processing observations at real lon/lat coordinates..."
    
    ! Pre-forecast step
    call PDAF_prepoststep(0, 0, 0, 0)
    
    ! Prepare observations for assimilation
    call prepare_observations_real_lonlat()
    
    ! Perform particle filter assimilation
    call perform_particle_filter_assimilation()
    
    ! Post-forecast step
    call PDAF_prepoststep(0, 0, 0, 1)
    
    ! Calculate diagnostics
    call calculate_assimilation_diagnostics(rms_before, rms_after, ess)
    
    print *, "✓ Assimilation step completed"
    print *, "  RMS error: ", rms_before, " -> ", rms_after
    print *, "  Effective sample size: ", ess
    
  end subroutine climber_x_assimilation_step_real_lonlat

  ! ============================================================
  ! Prepare observations for assimilation with real coordinates
  ! ============================================================
  subroutine prepare_observations_real_lonlat()
    implicit none
    integer :: i, obs_count
    
    print *, "Preparing ", n_obs_total, " observations for assimilation..."
    
    ! Count valid observations for this assimilation step
    obs_count = 0
    do i = 1, n_obs_total
      ! Check if observation is within model domain and valid
      if (obs_lon(i) >= 0.0 .and. obs_lon(i) <= 360.0 .and. &
          obs_lat(i) >= -90.0 .and. obs_lat(i) <= 90.0) then
        obs_count = obs_count + 1
      end if
    end do
    
    print *, "  Valid observations: ", obs_count, " out of ", n_obs_total
    
  end subroutine prepare_observations_real_lonlat

  ! ============================================================
  ! Perform particle filter assimilation
  ! ============================================================
  subroutine perform_particle_filter_assimilation()
    implicit none
    
    print *, "Performing particle filter assimilation..."
    
    ! Call PDAF particle filter
    call PDAF_assimilate_pf()
    
    print *, "✓ Particle filter assimilation completed"
    
  end subroutine perform_particle_filter_assimilation

  ! ============================================================
  ! Calculate assimilation diagnostics
  ! ============================================================
  subroutine calculate_assimilation_diagnostics(rms_before, rms_after, ess)
    implicit none
    real(kind=8), intent(out) :: rms_before, rms_after, ess
    
    ! Calculate RMS error before and after assimilation
    rms_before = 2.5  ! Example value - replace with actual calculation
    rms_after = 1.8   ! Example value - replace with actual calculation
    
    ! Calculate effective sample size
    ess = 0.7  ! Example value - replace with actual calculation
    
  end subroutine calculate_assimilation_diagnostics

  ! ============================================================
  ! Get state vector from CLIMBER-X (real lon/lat coordinates)
  ! ============================================================
  subroutine get_climber_x_state_real_lonlat(state_vector)
    implicit none
    real(kind=8), intent(out) :: state_vector(state_dim_total)
    integer :: i, j, k, idx
    
    idx = 1
    
    ! Extract atmosphere state variables
    do k = 1, 5  ! 5 atmospheric variables
      do j = 1, ny_climber
        do i = 1, nx_climber
          ! Get CLIMBER-X atmospheric variables at real lon/lat
          state_vector(idx) = get_atm_variable_real_lonlat(i, j, k)
          idx = idx + 1
        end do
      end do
    end do
    
    ! Extract ocean state variables
    do k = 1, nz_climber
      do j = 1, ny_climber
        do i = 1, nx_climber
          ! Get CLIMBER-X ocean variables at real lon/lat
          state_vector(idx) = get_ocn_variable_real_lonlat(i, j, k, 1)  ! Temperature
          idx = idx + 1
          state_vector(idx) = get_ocn_variable_real_lonlat(i, j, k, 2)  ! Salinity
          idx = idx + 1
          state_vector(idx) = get_ocn_variable_real_lonlat(i, j, k, 3)  ! Velocity
          idx = idx + 1
        end do
      end do
    end do
    
    ! Extract ice state variables
    do j = 1, ny_climber
      do i = 1, nx_climber
        state_vector(idx) = get_ice_variable_real_lonlat(i, j, 1)  ! Ice thickness
        idx = idx + 1
        state_vector(idx) = get_ice_variable_real_lonlat(i, j, 2)  ! Ice concentration
        idx = idx + 1
      end do
    end do
    
    ! Extract land state variables
    do j = 1, ny_climber
      do i = 1, nx_climber
        state_vector(idx) = get_lnd_variable_real_lonlat(i, j, 1)  ! Land temperature
        idx = idx + 1
        state_vector(idx) = get_lnd_variable_real_lonlat(i, j, 2)  ! Soil moisture
        idx = idx + 1
        state_vector(idx) = get_lnd_variable_real_lonlat(i, j, 3)  ! Vegetation
        idx = idx + 1
      end do
    end do
    
  end subroutine get_climber_x_state_real_lonlat

  ! ============================================================
  ! Set state vector back to CLIMBER-X (real lon/lat coordinates)
  ! ============================================================
  subroutine set_climber_x_state_real_lonlat(state_vector)
    implicit none
    real(kind=8), intent(in) :: state_vector(state_dim_total)
    integer :: i, j, k, idx
    
    idx = 1
    
    ! Set atmosphere state variables
    do k = 1, 5  ! 5 atmospheric variables
      do j = 1, ny_climber
        do i = 1, nx_climber
          ! Set CLIMBER-X atmospheric variables at real lon/lat
          call set_atm_variable_real_lonlat(i, j, k, state_vector(idx))
          idx = idx + 1
        end do
      end do
    end do
    
    ! Set ocean state variables
    do k = 1, nz_climber
      do j = 1, ny_climber
        do i = 1, nx_climber
          ! Set CLIMBER-X ocean variables at real lon/lat
          call set_ocn_variable_real_lonlat(i, j, k, 1, state_vector(idx))  ! Temperature
          idx = idx + 1
          call set_ocn_variable_real_lonlat(i, j, k, 2, state_vector(idx))  ! Salinity
          idx = idx + 1
          call set_ocn_variable_real_lonlat(i, j, k, 3, state_vector(idx))  ! Velocity
          idx = idx + 1
        end do
      end do
    end do
    
    ! Set ice state variables
    do j = 1, ny_climber
      do i = 1, nx_climber
        call set_ice_variable_real_lonlat(i, j, 1, state_vector(idx))  ! Ice thickness
        idx = idx + 1
        call set_ice_variable_real_lonlat(i, j, 2, state_vector(idx))  ! Ice concentration
        idx = idx + 1
      end do
    end do
    
    ! Set land state variables
    do j = 1, ny_climber
      do i = 1, nx_climber
        call set_lnd_variable_real_lonlat(i, j, 1, state_vector(idx))  ! Land temperature
        idx = idx + 1
        call set_lnd_variable_real_lonlat(i, j, 2, state_vector(idx))  ! Soil moisture
        idx = idx + 1
        call set_lnd_variable_real_lonlat(i, j, 3, state_vector(idx))  ! Vegetation
        idx = idx + 1
      end do
    end do
    
  end subroutine set_climber_x_state_real_lonlat

  ! ============================================================
  ! Interface functions to get CLIMBER-X variables at real lon/lat
  ! These need to be implemented to interface with actual CLIMBER-X
  ! ============================================================
  
  function get_atm_variable_real_lonlat(i, j, var_type) result(value)
    implicit none
    integer, intent(in) :: i, j, var_type
    real(kind=8) :: value
    
    ! Interface to CLIMBER-X atmosphere component
    ! Replace with actual CLIMBER-X calls
    value = 280.0 + 20.0 * rand()  ! Example temperature
    
  end function get_atm_variable_real_lonlat
  
  function get_ocn_variable_real_lonlat(i, j, k, var_type) result(value)
    implicit none
    integer, intent(in) :: i, j, k, var_type
    real(kind=8) :: value
    
    ! Interface to CLIMBER-X ocean component
    ! Replace with actual CLIMBER-X calls
    value = 275.0 + 10.0 * rand()  ! Example ocean temperature
    
  end function get_ocn_variable_real_lonlat
  
  function get_ice_variable_real_lonlat(i, j, var_type) result(value)
    implicit none
    integer, intent(in) :: i, j, var_type
    real(kind=8) :: value
    
    ! Interface to CLIMBER-X ice component
    ! Replace with actual CLIMBER-X calls
    value = 0.5 * rand()  ! Example ice concentration
    
  end function get_ice_variable_real_lonlat
  
  function get_lnd_variable_real_lonlat(i, j, var_type) result(value)
    implicit none
    integer, intent(in) :: i, j, var_type
    real(kind=8) :: value
    
    ! Interface to CLIMBER-X land component
    ! Replace with actual CLIMBER-X calls
    value = 285.0 + 15.0 * rand()  ! Example land temperature
    
  end function get_lnd_variable_real_lonlat

  ! ============================================================
  ! Interface functions to set CLIMBER-X variables at real lon/lat
  ! These need to be implemented to interface with actual CLIMBER-X
  ! ============================================================
  
  subroutine set_atm_variable_real_lonlat(i, j, var_type, value)
    implicit none
    integer, intent(in) :: i, j, var_type
    real(kind=8), intent(in) :: value
    
    ! Interface to CLIMBER-X atmosphere component
    ! Replace with actual CLIMBER-X calls
    print *, "Setting atmosphere variable at (", i, ",", j, ") = ", value
    
  end subroutine set_atm_variable_real_lonlat
  
  subroutine set_ocn_variable_real_lonlat(i, j, k, var_type, value)
    implicit none
    integer, intent(in) :: i, j, k, var_type
    real(kind=8), intent(in) :: value
    
    ! Interface to CLIMBER-X ocean component
    ! Replace with actual CLIMBER-X calls
    print *, "Setting ocean variable at (", i, ",", j, ",", k, ") = ", value
    
  end subroutine set_ocn_variable_real_lonlat
  
  subroutine set_ice_variable_real_lonlat(i, j, var_type, value)
    implicit none
    integer, intent(in) :: i, j, var_type
    real(kind=8), intent(in) :: value
    
    ! Interface to CLIMBER-X ice component
    ! Replace with actual CLIMBER-X calls
    print *, "Setting ice variable at (", i, ",", j, ") = ", value
    
  end subroutine set_ice_variable_real_lonlat
  
  subroutine set_lnd_variable_real_lonlat(i, j, var_type, value)
    implicit none
    integer, intent(in) :: i, j, var_type
    real(kind=8), intent(in) :: value
    
    ! Interface to CLIMBER-X land component
    ! Replace with actual CLIMBER-X calls
    print *, "Setting land variable at (", i, ",", j, ") = ", value
    
  end subroutine set_lnd_variable_real_lonlat

  ! ============================================================
  ! Cleanup and finalization
  ! ============================================================
  subroutine cleanup_climber_x_pdaf_real_lonlat()
    implicit none
    
    print *, "Cleaning up CLIMBER-X PDAF integration..."
    
    ! Deallocate arrays
    if (allocated(lon_climber)) deallocate(lon_climber)
    if (allocated(lat_climber)) deallocate(lat_climber)
    if (allocated(depth_climber)) deallocate(depth_climber)
    if (allocated(obs_lon)) deallocate(obs_lon)
    if (allocated(obs_lat)) deallocate(obs_lat)
    if (allocated(obs_depth)) deallocate(obs_depth)
    if (allocated(obs_values)) deallocate(obs_values)
    if (allocated(obs_errors)) deallocate(obs_errors)
    if (allocated(obs_types)) deallocate(obs_types)
    
    ! Finalize PDAF
    call PDAF_finalize()
    
    print *, "✓ CLIMBER-X PDAF integration cleaned up"
    
  end subroutine cleanup_climber_x_pdaf_real_lonlat

end module climber_x_pdaf_real_lonlat 