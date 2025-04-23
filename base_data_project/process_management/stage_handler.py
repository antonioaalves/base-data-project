"""Implementation of the process stage management."""

# Dependencies
from typing import Dict, Any, List, Optional, Union
import logging
from datetime import datetime
import uuid

# Local imports
from base_data_project.process_management.exceptions import (
    ProcessManagementError, 
    InvalidStageSequenceError
)

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
        
        # Get logger
        self.logger = logging.getLogger(config.get('PROJECT_NAME', 'base_data_project'))
        
    def initialize_process(self, name: str, description: str) -> str:
        """
        Initialize a new process with stages based on configuration
        
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
                    'status': 'pending',
                    'decisions': {},
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
                    "execution_time": (stage['completed_at'] - stage['started_at']).total_seconds(),
                    "timestamp": datetime.now().isoformat(),
                    "result_summary": {k: v for k, v in (result_data or {}).items() if not isinstance(v, (list, dict))}
                }
            )
        
        return stage
    
    def record_stage_decision(self, stage_name: str, algorithm_name: str, parameters: Dict[str, Any]) -> None:
        """
        Record a decision made for a stage
        
        Args:
            stage_name: Name of the stage
            algorithm_name: Name of the algorithm
            parameters: Decision parameters
        """
        if stage_name not in self.stages:
            raise InvalidStageSequenceError(f"Unknown stage: {stage_name}")
            
        stage = self.stages[stage_name]
        
        # Record the decision
        stage['decisions'][algorithm_name] = parameters
        
        # Record in process manager if available
        if self.process_manager:
            # Get stage sequence number
            sequence = stage['sequence']
            
            try:
                # Make the decision in the process manager
                self.process_manager.make_decisions(
                    stage=sequence,
                    decision_values={
                        'algorithm': algorithm_name,
                        'parameters': parameters
                    }
                )
                
                self.logger.info(f"Recorded decision for stage {stage_name}, algorithm {algorithm_name}")
                
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
    
    def get_stage_status(self, stage_name: str) -> Dict[str, Any]:
        """
        Get current status of a stage
        
        Args:
            stage_name: Name of the stage
            
        Returns:
            Stage status dictionary
        """
        if stage_name not in self.stages:
            raise InvalidStageSequenceError(f"Unknown stage: {stage_name}")
            
        stage = self.stages[stage_name]
        
        # Return a simplified status dictionary
        return {
            'name': stage_name,
            'id': stage['id'],
            'status': stage['status'],
            'sequence': stage['sequence'],
            'started_at': stage['started_at'],
            'completed_at': stage['completed_at'],
            'error_message': stage['error_message'],
            'current_algorithm': stage.get('current_algorithm'),
            'decision_count': len(stage['decisions'])
        }
    
    def get_process_summary(self) -> Dict[str, Any]:
        """
        Get a summary of the entire process
        
        Returns:
            Process summary dictionary
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
        
        return {
            'id': self.current_process_id,
            'status_counts': status_counts,
            'active_stage': active_stage,
            'progress': progress,
            'stages': {name: self.get_stage_status(name) for name in self.stages}
        }