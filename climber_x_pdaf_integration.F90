! CLIMBER-X PDAF Integration Module
! This module provides the interface between CLIMBER-X and PDAF

MODULE climber_x_pdaf_integration
  USE mod_obs_pdafomi, ONLY: init_obs_pdafomi, obs_pdafomi
  IMPLICIT NONE
  
  ! PDAF configuration
  INTEGER :: pdaf_filter_type = 12  ! Particle filter
  INTEGER :: pdaf_ensemble_size = 20
  INTEGER :: pdaf_resampling_type = 2  ! Stochastic universal resampling
  INTEGER :: pdaf_noise_type = 2  ! Relative noise scaling
  REAL(8) :: pdaf_noise_amplitude = 0.3
  
  ! State vector information
  INTEGER :: state_dim = 0
  REAL(8), ALLOCATABLE :: state_vector(:)
  REAL(8), ALLOCATABLE :: ensemble_states(:,:)
  
  ! Observation information
  INTEGER :: obs_dim = 0
  REAL(8), ALLOCATABLE :: obs_vector(:)
  REAL(8), ALLOCATABLE :: obs_error(:)
  
  CONTAINS
  
  SUBROUTINE init_pdaf_integration()
    ! Initialize PDAF integration
    IMPLICIT NONE
    
    PRINT *, "Initializing PDAF integration for CLIMBER-X..."
    
    ! Initialize observation module
    CALL init_obs_pdafomi()
    
    PRINT *, "PDAF integration initialized successfully"
  END SUBROUTINE init_pdaf_integration
  
  SUBROUTINE setup_state_vector(climber_state, nx, ny)
    ! Setup state vector from CLIMBER-X state
    IMPLICIT NONE
    REAL(8), INTENT(IN) :: climber_state(:,:)
    INTEGER, INTENT(IN) :: nx, ny
    
    state_dim = nx * ny
    
    IF (ALLOCATED(state_vector)) DEALLOCATE(state_vector)
    ALLOCATE(state_vector(state_dim))
    
    ! Convert 2D state to 1D vector
    state_vector = RESHAPE(climber_state, (/state_dim/))
    
    PRINT *, "State vector setup: dimension =", state_dim
  END SUBROUTINE setup_state_vector
  
  SUBROUTINE setup_ensemble(ensemble_data, nx, ny, nens)
    ! Setup ensemble from CLIMBER-X ensemble data
    IMPLICIT NONE
    REAL(8), INTENT(IN) :: ensemble_data(:,:,:)
    INTEGER, INTENT(IN) :: nx, ny, nens
    
    INTEGER :: i
    
    IF (ALLOCATED(ensemble_states)) DEALLOCATE(ensemble_states)
    ALLOCATE(ensemble_states(state_dim, nens))
    
    ! Convert 3D ensemble data to 2D matrix
    DO i = 1, nens
      ensemble_states(:,i) = RESHAPE(ensemble_data(:,:,i), (/state_dim/))
    END DO
    
    pdaf_ensemble_size = nens
    PRINT *, "Ensemble setup: size =", nens, "x", state_dim
  END SUBROUTINE setup_ensemble
  
  SUBROUTINE setup_observations(obs_data, obs_errors, nobs)
    ! Setup observations for assimilation
    IMPLICIT NONE
    REAL(8), INTENT(IN) :: obs_data(:), obs_errors(:)
    INTEGER, INTENT(IN) :: nobs
    
    obs_dim = nobs
    
    IF (ALLOCATED(obs_vector)) DEALLOCATE(obs_vector)
    IF (ALLOCATED(obs_error)) DEALLOCATE(obs_error)
    
    ALLOCATE(obs_vector(obs_dim))
    ALLOCATE(obs_error(obs_dim))
    
    obs_vector = obs_data
    obs_error = obs_errors
    
    PRINT *, "Observations setup: dimension =", obs_dim
  END SUBROUTINE setup_observations
  
  SUBROUTINE run_particle_filter()
    ! Run particle filter assimilation
    IMPLICIT NONE
    
    PRINT *, "Running particle filter assimilation..."
    PRINT *, "  Filter type:", pdaf_filter_type
    PRINT *, "  Ensemble size:", pdaf_ensemble_size
    PRINT *, "  Resampling type:", pdaf_resampling_type
    PRINT *, "  Noise type:", pdaf_noise_type
    PRINT *, "  Noise amplitude:", pdaf_noise_amplitude
    
    ! Call PDAF assimilation
    CALL obs_pdafomi(state_vector, ensemble_states, obs_vector, obs_error, &
                     pdaf_filter_type, pdaf_ensemble_size, &
                     pdaf_resampling_type, pdaf_noise_type, pdaf_noise_amplitude)
    
    PRINT *, "Particle filter assimilation completed"
  END SUBROUTINE run_particle_filter
  
  SUBROUTINE get_analysis_state(analysis_state, nx, ny)
    ! Get analysis state back to CLIMBER-X
    IMPLICIT NONE
    REAL(8), INTENT(OUT) :: analysis_state(:,:)
    INTEGER, INTENT(IN) :: nx, ny
    
    ! Convert 1D state vector back to 2D
    analysis_state = RESHAPE(state_vector, (/nx, ny/))
  END SUBROUTINE get_analysis_state
  
  SUBROUTINE get_analysis_ensemble(analysis_ensemble, nx, ny, nens)
    ! Get analysis ensemble back to CLIMBER-X
    IMPLICIT NONE
    REAL(8), INTENT(OUT) :: analysis_ensemble(:,:,:)
    INTEGER, INTENT(IN) :: nx, ny, nens
    
    INTEGER :: i
    
    ! Convert 2D ensemble matrix back to 3D
    DO i = 1, nens
      analysis_ensemble(:,:,i) = RESHAPE(ensemble_states(:,i), (/nx, ny/))
    END DO
  END SUBROUTINE get_analysis_ensemble
  
END MODULE climber_x_pdaf_integration 