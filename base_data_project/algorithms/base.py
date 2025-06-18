"""Base class for all algorithms used in this framework."""

from typing import Dict, Any, List, Optional
import logging
import time
from datetime import datetime
from abc import ABC, abstractmethod
import traceback

from base_data_project.log_config import get_logger

class BaseAlgorithm(ABC):
    """
    Abstract base class for defining algorithms.
    
    All algorithm implementations should inherit from this class and implement
    the required abstract methods.
    """

    def __init__(self, algo_name: str, parameters: Optional[Dict[str, Any]] = None):
        """
        Initialize algorithm with name and parameters.
        
        Args:
            algo_name: Name of the algorithm
            parameters: Optional dictionary of algorithm parameters
        """
        self.algo_name = algo_name
        self.parameters = parameters or {}
        self.execution_time = None
        self.status = "not_started"
        self.error = None
        
        # Get project name from parameters or config
        if isinstance(self.parameters, dict):
            if 'config' in self.parameters and 'project_name' in self.parameters['config']:
                self.project_name = self.parameters['config']['project_name']
            else:
                self.project_name = self.parameters.get('project_name', 'base_data_project')
        else:
            self.project_name = 'base_data_project'
            
        self.logger = get_logger(self.project_name)
        
        self.logger.info(f"Initialized algorithm: {algo_name}")

    @abstractmethod
    def adapt_data(self, data: Any = None) -> Any:
        """
        Transform input data into algorithm-specific format.
        
        This method should be implemented by subclasses to prepare 
        the data for processing by the algorithm.
        
        Args:
            data: Input data (optional if data was provided at initialization)
            
        Returns:
            Transformed data ready for algorithm processing
        """
        pass

    @abstractmethod
    def execute_algorithm(self, adapted_data: Any = None) -> Any:
        """
        Execute the core algorithm logic.
        
        This method should be implemented by subclasses to contain the
        actual algorithm implementation.
        
        Args:
            adapted_data: Data that has been prepared by adapt_data
            
        Returns:
            Raw algorithm results
        """
        pass

    @abstractmethod
    def format_results(self, algorithm_results: Any = None) -> Dict[str, Any]:
        """
        Format algorithm results into a standardized structure.
        
        This method should be implemented by subclasses to convert the
        raw algorithm output into a consistent format.
        
        Args:
            algorithm_results: The raw output from execute_algorithm
            
        Returns:
            Formatted results dictionary
        """
        pass

    def run(self, parameters: Optional[Dict[str, Any]] = None, data: Any = None) -> Dict[str, Any]:
        """
        Main execution flow with timing and error handling.
        
        This method orchestrates the algorithm execution process:
        1. Merge parameters
        2. Adapt data
        3. Execute algorithm
        4. Format results
        
        Args:
            parameters: Optional parameters to update existing ones
            data: Optional data to process
            
        Returns:
            Formatted algorithm results
        """
        # Update parameters if provided
        if parameters:
            self.parameters.update(parameters)
            
        self.logger.info(f"Starting execution of algorithm: {self.algo_name}")
        self.status = "running"
        start_time = time.time()
        
        try:
            # Stage 1: Adapt the data to algorithm format
            self.logger.info("Stage 1: Adapting data")
            adapted_data = self.adapt_data(data)
            
            # Stage 2: Execute the core algorithm logic
            self.logger.info("Stage 2: Executing algorithm")
            algorithm_results = self.execute_algorithm(adapted_data)
            
            # Stage 3: Format results to common structure
            self.logger.info("Stage 3: Formatting results")
            final_results = self.format_results(algorithm_results)
            
            # Calculate execution time
            self.execution_time = time.time() - start_time
            self.status = "completed"
            
            # Add metadata to results
            final_results.update({
                "algorithm_name": self.algo_name,
                "status": self.status,
                "execution_time": self.execution_time,
                "timestamp": datetime.now().isoformat()
            })
            
            self.logger.info(f"Algorithm {self.algo_name} completed successfully in {self.execution_time:.2f} seconds")
            return final_results
            
        except Exception as e:
            # Record error details
            self.execution_time = time.time() - start_time
            self.status = "failed"
            self.error = str(e)
            
            # Log the error with traceback
            self.logger.error(f"Error in algorithm {self.algo_name}: {str(e)}")
            self.logger.error(traceback.format_exc())
            
            # Return error information
            return {
                "algorithm_name": self.algo_name,
                "status": "failed",
                "execution_time": self.execution_time,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    def get_status(self) -> Dict[str, Any]:
        """
        Get the current status of the algorithm.
        
        Returns:
            Dictionary with status information
        """
        return {
            "algorithm_name": self.algo_name,
            "status": self.status,
            "execution_time": self.execution_time,
            "error": self.error,
            "parameters": self.parameters
        }