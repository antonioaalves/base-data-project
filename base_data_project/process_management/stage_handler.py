"""Implementation of the process stage management."""

# Dependencies
from typing import Dict, Any, List, Optional, Union
import logging
from datetime import datetime
import uuid

# Local imports
from base_data_project.process_management.exceptions import (
    ProcessManagementError, 
    InvalidStageSequenceError,
    DependencyError
)
from base_data_project.storage.factory import DataContainerFactory

class ProcessStageHandler:
    """
    Handles the lifecycle and integration of process stages with ProcessManager.
    
    This class provides a consistent interface for tracking the execution of 
    process stages, recording decisions, and monitoring progress.
    """
    
    def __init__(self, process_manager, config: Dict[str, Any]):
        """
        Initialize the stage handler
        
        Args:
            process_manager: The process manager for tracking decisions and stages
            config: Configuration dictionary containing stage definitions
        """
        self.process_manager = process_manager
        self.config = config
        self.stages = {}
        self.current_process_id = None
        self.initialized = False
        
        # Get project name from config
        project_name = config.get('PROJECT_NAME', 'base_data_project')
        
        # Get logger
        self.logger = logging.getLogger(project_name)

        # Initialize data container based on configuration
        storage_strategy = config.get('storage_strategy', {'mode': 'memory'})
        
        if storage_strategy.get('mode') == 'memory':
            from base_data_project.storage.containers import MemoryDataContainer
            self.data_container = MemoryDataContainer(storage_strategy)
        elif storage_strategy.get('mode') == 'persist':
            # We'll implement these later
            if storage_strategy.get('persist_format') == 'csv':
                from base_data_project.storage.containers import CSVDataContainer
                self.data_container = CSVDataContainer(storage_strategy)
            else:
                from base_data_project.storage.containers import DBDataContainer
                self.data_container = DBDataContainer(storage_strategy)
        elif storage_strategy.get('mode') == 'hybrid':
            from base_data_project.storage.containers import HybridDataContainer
            self.data_container = HybridDataContainer(storage_strategy)
        else:
            # Default to memory
            from base_data_project.storage.containers import MemoryDataContainer
            self.data_container = MemoryDataContainer(storage_strategy)
        
    def initialize_process(self, name: str, description: str) -> str:
        """
        Initialize a new process with stages and substages based on configuration
        
        Args:
            name: Process name
            description: Process description
            
        Returns:
            Process ID
        """
        try:
            self.logger.info(f"Initializing process with name: {name}")
            
            # Create process record
            self.current_process_id = f"proc_{datetime.now().strftime('%Y%m%d%H%M%S')}_{uuid.uuid4().hex[:8]}"
            
            # Initialize stages from config
            stages_config = self.config.get('stages', {})
            self.stages = {}
            
            # Setup tracking for each stage
            for stage_name, stage_config in stages_config.items():
                # Create stage record
                stage_id = f"{self.current_process_id}_{stage_name}"
                sequence = stage_config.get('sequence', 0)
                
                stage = {
                    'id': stage_id,
                    'name': stage_name,
                    'sequence': sequence,
                    'requires_previous': stage_config.get('requires_previous', True),
                    'validation_required': stage_config.get('validation_required', True),
                    'auto_complete_on_substages': stage_config.get('auto_complete_on_substages', False),
                    'status': 'pending',
                    'decisions': {},
                    'started_at': None,
                    'completed_at': None,
                    'error_message': None,
                    'tracking_data': []
                }

                # Initialize substages if defined
                if 'substages' in stage_config:
                    stage['substages'] = {}

                    for substage_name, substage_config in stage_config['substages'].items():
                        stage['substages'][substage_name] = {
                            'name': substage_name,
                            'sequence': substage_config.get('sequence', 0),
                            'description': substage_config.get('description', ''),
                            'optional': substage_config.get('optional', False),
                            'weight': substage_config.get('weight', 1.0),
                            'dependencies': substage_config.get('dependencies', []),
                            'timeout_seconds': substage_config.get('timeout_seconds'),
                            'retry_on_failure': substage_config.get('retry_on_failure', False),
                            'max_retries': substage_config.get('max_retries', 1),
                            'status': 'pending',
                            'progress': 0.0,
                            'started_at': None,
                            'completed_at': None,
                            'error_message': None,
                            'tracking_data': []
                        }

                if self.process_manager:                
                    # Register decision points if applicable
                    if 'algorithms' in stage_config:
                        stage['algorithms'] = stage_config['algorithms']
                        
                        # Register with process manager for decision tracking
                        if self.process_manager:
                            # For each algorithm, register a decision point
                            for algorithm in stage_config['algorithms']:
                                # Register with default parameters
                                self.process_manager.register_decision_point(
                                    stage=sequence,
                                    schema=dict,  # Simple dict schema for now
                                    required=True,
                                    defaults=self.config.get('algorithm_defaults', {}).get(algorithm, {})
                                )
                
                    if 'decisions' in stage_config:
                        for decision_name, defaults in stage_config['decisions'].items():
                            decision_id = f"{stage_name}_{decision_name}"
                            self.process_manager.register_decision_point(
                                stage=sequence,
                                schema=dict,
                                required=True,
                                defaults=defaults
                            )

                            # Store decision point reference in stage
                            if 'decision_points' not in stage:
                                stage['decision_points'] = []
                            stage['decision_points'].append(decision_id)

                self.stages[stage_name] = stage
            
            self.initialized = True
            self.logger.info(f"Process initialized with ID: {self.current_process_id}")
            return self.current_process_id
            
        except Exception as e:
            self.logger.error(f"Error initializing process: {str(e)}", exc_info=True)
            raise
        
    def start_stage(self, stage_name: str, algorithm_name: Optional[str] = None) -> Dict[str, Any]:
        """
        Start execution of a stage and record the start event
        
        Args:
            stage_name: Name of the stage to start
            algorithm_name: Optional algorithm name for stages with multiple algorithms
            
        Returns:
            Stage tracking information dictionary
        """
        if not self.initialized:
            raise ProcessManagementError("Process not initialized")
            
        if stage_name not in self.stages:
            raise InvalidStageSequenceError(f"Unknown stage: {stage_name}")
            
        stage = self.stages[stage_name]
        self.logger.info(f"Starting stage: {stage_name} (sequence: {stage['sequence']})")
        
        # Check if previous stages completed if required
        if stage['requires_previous']:
            for s_name, s_info in self.stages.items():
                # Skip optional stages when checking dependencies
                if s_info.get('optional', False):
                    continue
                    
                if (s_info['sequence'] < stage['sequence'] and 
                    s_info['status'] != 'completed' and
                    s_name != stage_name):  # Don't check the current stage
                    error_msg = f"Cannot start stage {stage_name}: previous stage {s_name} not completed"
                    self.logger.error(error_msg)
                    stage['status'] = 'failed'
                    stage['error_message'] = error_msg
                    raise InvalidStageSequenceError(error_msg)
        
        # Update stage status
        stage['status'] = 'in_progress'
        stage['started_at'] = datetime.now()
        
        # Create a tracking record for the process manager
        tracking_id = f"{stage['id']}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        # If algorithm specified, add to tracking
        if algorithm_name:
            tracking_id += f"_{algorithm_name}"
            stage['current_algorithm'] = algorithm_name
        
        stage['tracking_id'] = tracking_id
        
        # Track stage start in process manager if available
        if self.process_manager:
            try:
                self.process_manager.store_generated_data(
                    stage=stage,
                    data_type="stage_execution",
                    entity_type="stage",
                    entity_id=stage['id'],
                    value=1.0,
                    metadata={
                        "action": "start",
                        "stage_name": stage_name,
                        "algorithm": algorithm_name,
                        "timestamp": datetime.now().isoformat()
                    }
                )
            except Exception as e:
                # Log but don't fail if tracking fails
                self.logger.warning(f"Error tracking stage start: {str(e)}")

        # After stage is successfully started, auto-start first substage if available
        if 'substages' in stage and stage['substages']:
            # Find the first substage by sequence
            first_substage = None
            first_sequence = float('inf')
            
            for substage_name, substage in stage['substages'].items():
                if substage.get('sequence', 0) < first_sequence and not substage.get('dependencies'):
                    first_sequence = substage.get('sequence', 0)
                    first_substage = substage_name
            
            # Auto-start the first substage if found
            if first_substage and stage['substages'][first_substage].get('auto_start', True):
                try:
                    self.logger.info(f"Auto-starting first substage {first_substage} of stage {stage_name}")
                    self.start_substage(stage_name, first_substage)
                except Exception as e:
                    self.logger.warning(f"Failed to auto-start first substage: {str(e)}")
        
        return stage
    
    def complete_stage(self, stage_name: str, success: bool, result_data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Complete a stage and record the completion event
        
        Args:
            stage_name: Name of the stage to complete
            success: Whether the stage completed successfully
            result_data: Optional result data to store
            
        Returns:
            Updated stage tracking information
        """
        if stage_name not in self.stages:
            raise InvalidStageSequenceError(f"Unknown stage: {stage_name}")
            
        stage = self.stages[stage_name]
        
        if stage['status'] != 'in_progress':
            raise ProcessManagementError(f"Cannot complete stage {stage_name} with status {stage['status']}")
        
        # Update stage status
        if success:
            stage['status'] = 'completed'
        else:
            stage['status'] = 'failed'
            
        stage['completed_at'] = datetime.now()
        stage['result_data'] = result_data or {}
        
        self.logger.info(f"Completed stage {stage_name} with status: {stage['status']}")
        
        # Track stage completion in process manager if available
        if self.process_manager:
            try:
                execution_time = (stage['completed_at'] - stage['started_at']).total_seconds()
                
                # Create a simplified result summary for tracking
                result_summary = {}
                if result_data:
                    # Extract scalar values for the summary, avoiding large objects
                    for k, v in result_data.items():
                        if not isinstance(v, (list, dict)) or (isinstance(v, (list, dict)) and len(v) < 10):
                            result_summary[k] = v
                
                self.process_manager.store_generated_data(
                    stage=stage,
                    data_type="stage_execution",
                    entity_type="stage",
                    entity_id=stage['id'],
                    value=1.0 if success else 0.0,
                    metadata={
                        "action": "complete",
                        "stage_name": stage_name,
                        "status": stage['status'],
                        "algorithm": stage.get('current_algorithm'),
                        "execution_time": execution_time,
                        "timestamp": datetime.now().isoformat(),
                        "result_summary": result_summary
                    }
                )
            except Exception as e:
                # Log but don't fail if tracking fails
                self.logger.warning(f"Error tracking stage completion: {str(e)}")
            
        if success and result_data and hasattr(self, 'data_container'):
            try:
                metadata = {
                    'process_id': self.current_process_id,
                    'timestamp': datetime.now().isoformat(),
                    'stage_name': stage_name,
                    'status': 'completed'
                }
                
                self.data_container.store_stage_data(
                    stage_name=stage_name,
                    data=result_data,
                    metadata=metadata
                )
                
                self.logger.info(f"Stored intermediate data for stage {stage_name}")
            except Exception as e:
                self.logger.warning(f"Failed to store intermediate data: {str(e)}")
        
        return stage
    
    def start_substage(self, stage_name: str, substage_name: str) -> Dict[str, Any]:
        """
        Start executing a substage within a stage and record the start event.
        Args:
            stage_name: Name of the parent stage.
            substage_name: Name of the substage to start
        Returns: 
            Substage tracking information dictionary
        Raises:
            ProcessManagementError: If process not initialized or stage not found
            InvalidStageSequenceError: If substage not found or previous substages not completed
        """
        # Check if process is initialized
        if not self.initialized:
            raise ProcessManagementError("Process not initialized")
        
        # Check if stages exists
        if stage_name not in self.stages:
            raise InvalidStageSequenceError(f"Unknown stage: {stage_name}")
        
        # Get stage information
        stage = self.stages[stage_name]

        # Check if the stage is in progress
        if stage['status'] != 'in_progress':
            raise ProcessManagementError(f"Cannot start substage {substage_name}: stage {stage_name} is not in progress")
        
        # Get substages configuration
        substages_config = self.config.get('stages', {}).get(stage_name, {}).get('substages', {})
        if substage_name not in substages_config:
            raise InvalidStageSequenceError(f"Unknown substage: {substage_name} in stage {stage_name}")
        
        # Get substage configuration
        substage_config = substages_config[substage_name]
        substage_sequence = substage_config.get('sequence', 0)

        if 'substages' not in stage:
            stage['substages'] = {}

        # Check if previous substages that are required 
        for other_substage_name, other_substage_config in substages_config.items():
            other_sequence = other_substage_config.get('sequence', 0)
            is_required = other_substage_config.get('required', True)

            # Only check previous substages that are not required 
            if other_sequence < substage_sequence and is_required:
                # Check if the substage exists in tracking
                if other_substage_name not in stage['substages']:
                    error_msg = f"Cannot start substage {substage_name}: previous substage {other_substage_name} not started"
                    self.logger.error(error_msg)
                    raise InvalidStageSequenceError(error_msg)
                
                # Check if previous substage is completed
                if stage['substages'][other_substage_name]['status'] != 'completed':
                    error_msg = f"Cannot start substage {substage_name}: previous substage {other_substage_name} not completed"
                    self.logger.error(error_msg)
                    raise InvalidStageSequenceError(error_msg)
                
        substage_id = f"{stage['id']}_{substage_name}"
        substage = {
            'id': substage_id,
            'name': substage_name,
            'sequence': substage_sequence,
            'status': 'in_progress',
            'started_at': datetime.now(),
            'completed_at': None,
            'error_message': None,
            'progress': 0.0,
            'tracking_data': []
        }

        # Store the substage in stage
        stage['substages'][substage_name] = substage

        # Update the current substage in stage
        stage['current_substage'] = substage_name

        self.logger.info(f"Started substage {substage_name} in stage {stage_name}")

        # Track substage start in process manager if available
        if self.process_manager:
            try:
                self.process_manager.store_generated_data(
                    stage=stage,
                    data_type="substage_execution",
                    entity_type="substage",
                    entity_id=substage_id,
                    value=1.0,
                    metadata={
                        "action": "start",
                        "stage_name": stage_name,
                        "substage_name": substage_name,
                        "timestamp": datetime.now().isoformat()
                    }
                )
            except Exception as e:
                # Log but dont fail if tracking fails
                self.logger.warning(f"Error tracking substage start: {str(e)}")

        return substage
    
    def skip_substage(self, stage_name: str, substage_name: str, reason: str) -> Dict[str, Any]:
        """
        Mark a substage as skipped
        
        Args:
            stage_name: Name of the parent stage
            substage_name: Name of the substage to skip
            reason: Reason for skipping
            
        Returns:
            Updated stage tracking information
            
        Raises:
            InvalidStageSequenceError: If the stage or substage does not exist
            ProcessManagementError: If the substage cannot be skipped
        """
        if stage_name not in self.stages:
            raise InvalidStageSequenceError(f"Unknown stage: {stage_name}")
            
        stage = self.stages[stage_name]
        
        # Check if substages are defined for this stage
        if 'substages' not in stage:
            raise ProcessManagementError(f"Stage {stage_name} does not have substages defined")
            
        # Check if this substage exists
        if substage_name not in stage['substages']:
            raise InvalidStageSequenceError(f"Unknown substage: {substage_name} in stage {stage_name}")
            
        substage = stage['substages'][substage_name]
        
        # Check if substage can be skipped
        if not substage.get('optional', False):
            raise ProcessManagementError(f"Cannot skip non-optional substage {substage_name}")
        
        # Update substage status
        substage['status'] = 'skipped'
        substage['completed_at'] = datetime.now()
        substage['error_message'] = f"Skipped: {reason}"
        
        self.logger.info(f"Skipped substage {substage_name} of stage {stage_name}: {reason}")
        
        # Update overall stage progress based on substages
        self._update_stage_progress_from_substages(stage_name)
        
        # Track substage skip in process manager if available
        if self.process_manager:
            try:
                self.process_manager.store_generated_data(
                    stage=stage,
                    data_type="substage_execution",
                    entity_type="substage",
                    entity_id=f"{stage['id']}_{substage_name}",
                    value=0.0,
                    metadata={
                        "action": "skip",
                        "stage_name": stage_name,
                        "substage_name": substage_name,
                        "reason": reason,
                        "timestamp": datetime.now().isoformat()
                    }
                )
            except Exception as e:
                # Log but don't fail if tracking fails
                self.logger.warning(f"Error tracking substage skip: {str(e)}")
        
        return stage

    def complete_substage(self, stage_name: str, substage_name: str, success: bool, result_data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Complete a substage and record the completion event
        Args:
            stage_name: Name of the parent stage
            substage_name: Name of the substage to complete
            success: Whether the substage completed successfully
            result_data:  Optional result data to store
        Returns:
            Updated stage tracking information including substage status
        Raises:
            InvalidStageSequenceError: If the stage or substage does not exist
            ProcessManagementError: If the substage is not in progress
        """
        if stage_name not in self.stages:
            raise InvalidStageSequenceError(f"Unknown stage: {stage_name}")
        
        stage = self.stages[stage_name]

        # Check if substages are defined for this stage
        if 'substages' not in stage:
            raise ProcessManagementError(f"Stage {stage_name} does not have substages defined")
        
        # Check if substage exists
        if substage_name not in stage['substages']:
            raise InvalidStageSequenceError(f"Unknown substage: {substage_name} in stage {stage_name}")
        
        substage = stage['substages'][substage_name]

        # Check if substage is in progress
        if substage.get('status') != 'in_progress':
            raise ProcessManagementError(f"Cannot complete substage {substage_name} with status {substage.get('status')}")
        
        if success:
            substage['status'] = 'completed'
        else:
            substage['status'] = 'failed'

        substage['completed_at'] = datetime.now()
        substage['result_data'] = result_data or {}

        self.logger.info(f"Comleted subtage {substage_name} of stage {stage_name} with status: {substage['status']}")

        # Update overall stage progress based on substages
        self._update_stage_progress_from_substages(stage_name)

        # Track substage completition in process manager if available
        if self.process_manager:
            try:
                execution_time = (substage['completed_at'] - substage['started_at']).total_seconds()
                
                # Create a simplified result summary for tracking
                result_summary = {}
                if result_data:
                    # Extract scalar values for the summary, avoiding large objects
                    for k, v in result_data.items():
                        if not isinstance(v, (list, dict)) or (isinstance(v, (list, dict)) and len(v) < 10):
                            result_summary[k] = v
                
                self.process_manager.store_generated_data(
                    stage=stage,
                    data_type="substage_execution",
                    entity_type="substage",
                    entity_id=f"{stage['id']}_{substage_name}",
                    value=1.0 if success else 0.0,
                    metadata={
                        "action": "complete",
                        "stage_name": stage_name,
                        "substage_name": substage_name,
                        "status": substage['status'],
                        "execution_time": execution_time,
                        "timestamp": datetime.now().isoformat(),
                        "result_summary": result_summary
                    }
                )
            except Exception as e:
                # Log but don't fail if tracking fails
                self.logger.warning(f"Error tracking substage completion: {str(e)}")

        # Check if all required substages are comleted to potentially auto-complete the stage
        all_completed = True
        has_failures = False

        for sub_name, sub_info in stage['substages'].items():
            if not sub_info.get('optional', False): # Only check required substages
                if sub_info.get('status') != 'completed':
                    all_completed = False
                if sub_info.get('status') == 'failed':
                    has_failures = True

        # IF all tthe required substages are completedm update the stage status
        if all_completed and stage['status'] == 'in_progress':
            # Only autocomplete if configured to do so and no failures in required substages
            auto_complete = stage.get('auto_complete_on_substages', False)
            if auto_complete and not has_failures:
                self.logger.info(f"Auto-completing stage {stage_name} as all substages are complete")
                self.complete_stage(stage_name, True, {
                    "auto_completed": True,
                    "substage_results": {name: info.get('result_data', {}) 
                                        for name, info in stage['substages'].items()}
                })

            return stage

    def _update_stage_progress_from_substages(self, stage_name: str) -> None:
        """
        Update the overall stage progress based on substage completion status
        
        Args:
            stage_name: Name of the stage to update
        """
        stage = self.stages[stage_name]
        substages = stage.get('substages', {})
        
        if not substages:
            return
        
        # Count substages and their weights
        total_weight = 0
        completed_weight = 0
        
        for substage_name, substage in substages.items():
            weight = substage.get('weight', 1.0)
            total_weight += weight
            
            if substage.get('status') == 'completed':
                completed_weight += weight
            elif substage.get('status') == 'in_progress':
                # Add partial progress for in-progress substages
                progress = substage.get('progress', 0.0)
                completed_weight += weight * progress
        
        # Calculate overall progress (avoid division by zero)
        if total_weight > 0:
            overall_progress = completed_weight / total_weight
        else:
            overall_progress = 0.0
        
        # Track this progress for the overall stage
        self.track_progress(
            stage_name,
            min(overall_progress, 1.0),  # Ensure progress doesn't exceed 100%
            f"Stage progress based on substages: {overall_progress:.1%}",
            {"substage_progress": {name: sub.get('progress', 0.0) for name, sub in substages.items()}}
        )

    def record_stage_decision(self, stage_name: str, decision_name: str, parameters: Dict[str, Any]) -> None:
        """
        Record a decision made for a stage
        
        Args:
            stage_name: Name of the stage
            decision_name: Name of the decision point
            parameters: Decision parameters
        """
        if stage_name not in self.stages:
            raise InvalidStageSequenceError(f"Unknown stage: {stage_name}")
            
        stage = self.stages[stage_name]
        
        # Record the decision
        stage['decisions'][decision_name] = parameters
        
        # Record in process manager if available
        if self.process_manager:
            # Get stage sequence number
            sequence = stage['sequence']
            
            try:
                # Make the decision in the process manager
                self.process_manager.make_decisions(
                    stage=sequence,
                    decision_values={
                        decision_name: parameters
                    }
                )
                
                self.logger.info(f"Recorded decision for stage {stage_name}, decision {decision_name}")
                
            except Exception as e:
                self.logger.error(f"Error recording decision: {str(e)}")
                # Continue execution even if decision recording fails
    
    def track_progress(self, stage_name: str, progress: float, message: str, metadata: Optional[Dict[str, Any]] = None) -> None:
        """
        Track progress within a stage
        
        Args:
            stage_name: Name of the stage
            progress: Progress value between 0.0 and 1.0
            message: Progress message
            metadata: Additional metadata to store
        """
        if stage_name not in self.stages:
            raise InvalidStageSequenceError(f"Unknown stage: {stage_name}")
            
        stage = self.stages[stage_name]
        
        if stage['status'] != 'in_progress':
            self.logger.warning(f"Tracking progress for non-active stage {stage_name}")
            return
            
        # Add to stage tracking data
        tracking_entry = {
            'timestamp': datetime.now(),
            'progress': progress,
            'message': message,
            'metadata': metadata or {}
        }
        
        stage['tracking_data'].append(tracking_entry)
        
        # Track in process manager if available
        if self.process_manager:
            try:
                self.process_manager.store_generated_data(
                    stage=stage,
                    data_type="progress_update",
                    entity_type="stage",
                    entity_id=stage['id'],
                    value=progress,
                    metadata={
                        "message": message,
                        "timestamp": tracking_entry['timestamp'].isoformat(),
                        **(metadata or {})
                    }
                )
            except Exception as e:
                # Log but don't fail if tracking fails
                self.logger.warning(f"Error tracking progress: {str(e)}")

    def track_substage_progress(self, stage_name: str, substage_name: str, progress: float, message: str, metadata: Optional[Dict[str, Any]] = None) -> None:
        """
        Tracks progress within a substage
        Args: 
            stage_name: Name of the arent stage
            substage_name: Name of the substage
            progress: Progress value between 0.0 and 1.0
            message: Progress message
            metadata: Additional metadata to store
        Raises:
            InvalidStageSequenceError: If the stage or substage does not exist
            ProcessManagementError: If the substage is not in progress
        """
        if stage_name not in self.stages:
            raise InvalidStageSequenceError(f"Unknown stage: {stage_name}")
        
        stage = self.stages[stage_name]

        # Check if substages are defined for this stage
        if 'substages' not in stage:
            raise ProcessManagementError(f"Stage {stage_name} does not have substages defined")
        
        # Check if this substage exists
        if substage_name not in stage['substages']:
            raise InvalidStageSequenceError(f"Unknown substage: {substage_name} in stage {stage_name}")
        
        substage = stage['substages'][substage_name]

        # Check if substage is in progress
        if substage.get('status') != 'in_progress':
            self.logger.warning(f"Tracking progress for non-active substage {substage_name} of stage {stage_name}")
            return
        
        # Validate progress value
        progress = max(0.0, min(1.0, progress)) # Clamp between 0 and 1

        # Update substage progress 
        substage['progress'] = progress

        # Add to substage tracking data 
        tracking_entry = {
            'timestamp': datetime.now(),
            'progress': progress,
            'message': message,
            'metadata': metadata or {}
        }

        if 'tracking_data' not in substage:
            substage['tracking_data'] = []

        substage['tracking_data'].append(tracking_entry)

        self.logger.info(f"Substage {substage_name} of stage {stage_name} progress: {progress:.1%} - {message}")

        # Update overall stage progress based on substages
        self._update_stage_progress_from_substages(stage_name)

        # Track in process manager if available
        if self.process_manager:
            try:
                self.process_manager.store_generated_data(
                    stage=stage,
                    data_type="substage_progress",
                    entity_type="substage",
                    entity_id=f"{stage['id']}_{substage_name}",
                    value=progress,
                    metadata={
                        "message": message,
                        "stage_name": stage_name,
                        "substage_name": substage_name,
                        "timestamp": tracking_entry['timestamp'].isoformat(),
                        **(metadata or {})
                    }
                )
            except Exception as e:
                # Log but don't fail if tracking fails
                self.logger.warning(f"Error tracking substage progress: {str(e)}")

    def get_stage_status(self, stage_name: str, include_substages: bool = True) -> Dict[str, Any]:
        """
        Get current status of a stage including substages
        
        Args:
            stage_name: Name of the stage
            include_substages: Whether to include detailed substage information
        Returns:
            Stage status dictionary with substage details
        Raises:
            InvalidStageSequenceError: If the stage does not exist
        """
        if stage_name not in self.stages:
            raise InvalidStageSequenceError(f"Unknown stage: {stage_name}")
            
        stage = self.stages[stage_name]
        
        # Return a simplified status dictionary
        status_dict = {
            'name': stage_name,
            'id': stage['id'],
            'status': stage['status'],
            'sequence': stage['sequence'],
            'started_at': stage['started_at'],
            'completed_at': stage['completed_at'],
            'error_message': stage['error_message'],
            'current_algorithm': stage.get('current_algorithm'),
            'decision_count': len(stage.get('decisions', {})),
            'progress': stage.get('progress', 0.0)
        }

        # Add substage information if available and requested 
        if include_substages and 'substages' in stage:
            substages_info = {}

            # Count substages by status
            substage_status_counts = {}
            for substage_name, substage in stage['substages'].items():
                substage_status = substage.get('status', 'pending')
                substage_status_counts[substage_status] = substage_status_counts.get(substage_status, 0) + 1

                # Add detailed substage information
                substages_info[substage_name] = {
                    'sequence': substage.get('sequence', 0),
                    'status': substage_status,
                    'progress': substage.get('progress', 0.0),
                    'started_at': substage.get('started_at'),
                    'completed_at': substage.get('completed_at'),
                    'error_message': substage.get('error_message'),
                    'optional': substage.get('optional', False),
                    'description': substage.get('description', '')
                }

            # Add active substage if any
            active_substage = None
            for substage_name, substage in stage['substages'].items():
                if substage.get('status') == 'in_progress':
                    active_substage = substage_name
                    break

            # Calculate overall substage progress 
            total_substages = len(stage['substages'])
            completed_substages = substage_status_counts.get('comleted', 0)
            substage_progress = completed_substages / total_substages if total_substages > 0 else 0.0

            # Add substage summary to status dictionary
            status_dict['substages'] = {
                'info': substages_info,
                'active_substage': active_substage,
                'status_counts': substage_status_counts,
                'total': total_substages,
                'completed': completed_substages,
                'progress': substage_progress
            }

        return status_dict
    
    def get_process_summary(self) -> Dict[str, Any]:
        """
        Get a summary of the entire process
        
        Returns:
            Process summary dictionary with substage details
        """
        if not self.initialized:
            return {'status': 'not_initialized'}
            
        # Count stages by status
        status_counts = {}
        for stage in self.stages.values():
            status_counts[stage['status']] = status_counts.get(stage['status'], 0) + 1
        
        # Find current active stage
        active_stage = None
        for stage_name, stage in self.stages.items():
            if stage['status'] == 'in_progress':
                active_stage = stage_name
                break
                
        # Calculate process progress
        total_stages = len(self.stages)
        completed_stages = status_counts.get('completed', 0)
        progress = completed_stages / total_stages if total_stages > 0 else 0.0
        
        # Count substages across all stages
        total_substages = 0
        completed_substages = 0
        substage_status_counts = {}

        for stage_name, stage in self.stages.items():
            if 'substages' in stage:
                for substage_name, substage in stage['substages'].items():
                    total_substages += 1
                    substage_status = substage.get('status', 'pending')
                    substage_status_counts[substage_status] = substage_status_counts.get(substage_status, 0) + 1
                    
                    if substage_status == 'completed':
                        completed_substages += 1
        
        # Calculate substage progress
        substage_progress = completed_substages / total_substages if total_substages > 0 else 0.0
        
        # Create summary dictionary
        summary = {
            'id': self.current_process_id,
            'status_counts': status_counts,
            'active_stage': active_stage,
            'progress': progress,
            'stages': {name: self.get_stage_status(name) for name in self.stages}
        }
        
        # Add substage summary if any substages exist
        if total_substages > 0:
            summary['substages'] = {
                'status_counts': substage_status_counts,
                'total': total_substages,
                'completed': completed_substages,
                'progress': substage_progress
            }
        
        return summary