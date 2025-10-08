"""Base service class for process orchestration."""

import logging
from typing import Dict, Any, Optional, Tuple, Type, List
from datetime import datetime

from base_data_project.data_manager.managers.base import BaseDataManager
from base_data_project.process_management.manager import ProcessManager
from base_data_project.process_management.stage_handler import ProcessStageHandler
from base_data_project.storage.models import BaseDataModel
from base_data_project.log_config import get_logger

class BaseService:
    """
    Base class for services that orchestrate data processing.
    
    Services coordinate process tracking, data management, and 
    algorithm execution throughout a multi-stage workflow.
    """
    
    def __init__(self, data_manager: BaseDataManager, process_manager: Optional[ProcessManager] = None, 
                project_name: str = 'base_data_project', data_model_class: Optional[Type[BaseDataModel]] = None):
        """
        Initialize the service with data and process managers.
        
        Args:
            data_manager: Data manager for data operations
            process_manager: Optional process manager for tracking
            project_name: Project name for logging
        """
        self.data_manager = data_manager
        self.process_manager = process_manager
        self.current_process_id = None
        
        # Process tracking
        self.stage_handler = ProcessStageHandler(process_manager=process_manager, 
                                               config=process_manager.config if process_manager else {},
                                               project_name=project_name
                                            ) if process_manager else None
        
        # Data container and model initialization
        self.data_container = None
        self.data_model = None

        # Create data container if process manager has a stage handler
        if self.stage_handler:
            # Use the data container from the stage handler if available
            if hasattr(self.stage_handler, 'data_container'):
                self.data_container = self.stage_handler.data_container

        # Create data model if a class was provided 
        if data_model_class:
            self.data_model = data_model_class(self.data_container, project_name=project_name)
        
        # Get logger
        self.logger = get_logger(project_name)
        self.logger.info(f"Initialized {self.__class__.__name__}")

    def initialize_process(self, name: str, description: str) -> str:
        """
        Initialize a new process with the given name and description.
        
        Args:
            name: Process name
            description: Process description
            
        Returns:
            Process ID
        """
        self.logger.info(f"Initializing process: {name}")
        
        if self.stage_handler:
            # Initialize the process with the process manager
            self.current_process_id = self.stage_handler.initialize_process(name, description)
            self.logger.info(f"Process initialized with ID: {self.current_process_id}")
            return self.current_process_id
        else:
            # If no stage handler, just log and use a placeholder ID
            self.logger.info("Process tracking disabled (no process manager)")
            self.current_process_id = f"no_tracking_{datetime.now().strftime('%Y%m%d%H%M%S')}"
            return self.current_process_id

    def execute_stage(self, stage_name: str, algorithm_name: Optional[str] = None, 
                     algorithm_params: Optional[Dict[str, Any]] = None) -> bool:
        """
        Execute a specific stage in the process.
        
        Args:
            stage_name: Stage name to execute
            algorithm_name: Optional algorithm name for the processing stage
            algorithm_params: Optional parameters for the algorithm
            
        Returns:
            True if the stage executed successfully, False otherwise
        """
        try:
            self.logger.info(f"Executing process stage: {stage_name}")
            
            # Start stage in process manager if available
            if self.stage_handler:
                self.stage_handler.start_stage(stage_name, algorithm_name)

                if algorithm_name and algorithm_params:
                    self.stage_handler.record_stage_decision(stage_name, algorithm_name, algorithm_params)
            
            # Execute the appropriate stage method based on name
            success = self._dispatch_stage(stage_name, algorithm_name, algorithm_params)
            
            # Complete stage in stage handler if available
            if self.stage_handler:
                result_data = {
                    "success": success,
                    "timestamp": datetime.now().isoformat()
                }
                
                if not success:
                    result_data["error"] = f"Stage {stage_name} failed"
                    
                self.stage_handler.complete_stage(stage_name, success, result_data)
            
            return success
            
        except Exception as e:
            self.logger.error(f"Error executing stage {stage_name}: {str(e)}", exc_info=True)
            
            # Complete stage with failure in process manager if available
            if self.stage_handler:
                self.stage_handler.complete_stage(
                    stage_name, 
                    False, 
                    {"error": str(e), "timestamp": datetime.now().isoformat()}
                )
            
            return False
    
    def _dispatch_stage(self, stage_name: str, algorithm_name: Optional[str] = None,
                      algorithm_params: Optional[Dict[str, Any]] = None) -> bool:
        """
        Dispatch execution to the appropriate stage method.
        
        This method should be overridden by subclasses to implement
        stage-specific logic.
        
        Args:
            stage_name: Stage name to execute
            algorithm_name: Optional algorithm name
            algorithm_params: Optional algorithm parameters
            
        Returns:
            True if successful, False otherwise
            
        Raises:
            NotImplementedError: If the stage is not implemented
        """
        raise NotImplementedError(f"Stage '{stage_name}' not implemented")
    
    def finalize_process(self) -> None:
        """Finalize the process and clean up any resources."""
        self.logger.info("Finalizing process")
        
        # Nothing to do if no process manager
        if not self.stage_handler:
            return
        
        # Log completion
        self.logger.info(f"Process {self.current_process_id} completed")

    def get_process_summary(self) -> Dict[str, Any]:
        """
        Get a summary of the current process.
        
        Returns:
            Dictionary with process summary information
        """
        if self.stage_handler:
            return self.stage_handler.get_process_summary()
        else:
            return {
                "status": "no_tracking",
                "process_id": self.current_process_id
            }

    def get_stage_decision(self, stage: int, decision_name: str) -> Optional[Dict[str, Any]]:
        """
        Get a specific decision for a stage from the process manager.
        
        Args:
            stage: Stage number
            decision_name: Name of the decision
            
        Returns:
            Decision dictionary or None if not available
        """
        if self.process_manager:
            return self.process_manager.get_stage_decision(stage, decision_name)
        return None
    
    def get_decisions_for_stage(self, stage_name: str) -> Tuple[List[str], Dict[str, Any]]:
        """
        Get all decisions for a specific stage by stage name.
        
        Args:
            stage_name: Name of the stage to get decisions for
            
        Returns:
            Tuple of (list of decision names, dictionary of decisions)
        """
        if not self.stage_handler or not self.process_manager:
            return [], {}
            
        stage = self.stage_handler.stages.get(stage_name)
        if not stage:
            self.logger.warning(f"Stage '{stage_name}' not found in stage handler")
            return [], {}
            
        stage_sequence = stage.get('sequence')
        if stage_sequence is None:
            self.logger.warning(f"No sequence found for stage '{stage_name}'")
            return [], {}
            
        return stage_sequence, self.process_manager.current_decisions.get(stage_sequence, {})