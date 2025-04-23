"""Example algorithm implementation for project templates."""

import logging
from typing import Dict, Any, Optional
from datetime import datetime

# Import base algorithm class
from base_data_project.algorithms.base import BaseAlgorithm

class ExampleAlgorithm(BaseAlgorithm):
    """
    Example algorithm implementation to demonstrate how to create custom algorithms.
    
    Inherits from the BaseAlgorithm class in the base_data_project framework.
    This serves as a template for implementing your own algorithms.
    """

    def __init__(self, algo_name: str = "ExampleAlgorithm", parameters: Optional[Dict[str, Any]] = None):
        """
        Initialize the algorithm with parameters.
        
        Args:
            algo_name: Name of the algorithm (default: "ExampleAlgorithm")
            parameters: Optional dictionary of algorithm parameters
        """
        # Initialize the parent class first
        super().__init__(algo_name=algo_name, parameters=parameters or {})
        
        # Perform additional initialization
        self.results = None
        self.logger.info(f"Initialized {self.algo_name} algorithm")

    def adapt_data(self, data: Any = None) -> Any:
        """
        Transform the input data into algorithm-specific format.
        
        Args:
            data: Input data for the algorithm
            
        Returns:
            Transformed data in the format needed by the algorithm
        """
        try:
            self.logger.info(f"Adapting data for {self.algo_name}")
            
            # TODO: Implement your data transformation logic here
            # For demonstration purposes, we'll just do minimal processing
            if data is None:
                self.logger.warning("No data provided to adapt_data")
                return {}
                
            if isinstance(data, dict):
                # Example transformation: extract specific fields
                adapted_data = {
                    'values': data.get('values', []),
                    'metadata': data.get('metadata', {}),
                    'timestamp': datetime.now().isoformat()
                }
            elif hasattr(data, 'to_dict'):
                # Handle pandas DataFrame
                adapted_data = {
                    'records': data.to_dict('records'),
                    'shape': data.shape,
                    'columns': data.columns.tolist(),
                    'timestamp': datetime.now().isoformat()
                }
            else:
                # Pass through other data types
                adapted_data = data
            
            self.logger.info("Data adaptation completed successfully")
            return adapted_data
            
        except Exception as e:
            self.logger.error(f"Error during data adaptation: {str(e)}")
            raise

    def execute_algorithm(self, adapted_data: Any = None) -> Dict[str, Any]:
        """
        Execute the core algorithm logic.
        
        Args:
            adapted_data: Data that has been prepared by adapt_data
            
        Returns:
            Algorithm results
        """
        try:
            self.logger.info(f"Executing algorithm {self.algo_name}")
            
            # Default parameter values if not specified
            parameters = self.parameters
            threshold = parameters.get('threshold', 0.5)
            max_iterations = parameters.get('max_iterations', 100)
            
            # Simple example algorithm: Calculate statistics for numeric values
            result = {
                'status': 'success',
                'parameters_used': {
                    'threshold': threshold,
                    'max_iterations': max_iterations
                },
                'metrics': {},
                'timestamp': datetime.now().isoformat()
            }
            
            # Implement a simple analysis of the data
            if adapted_data and isinstance(adapted_data, dict):
                # If we have values to process
                values = adapted_data.get('values', [])
                if values and isinstance(values, list) and all(isinstance(x, (int, float)) for x in values):
                    # Calculate simple statistics on numeric values
                    result['metrics'] = {
                        'count': len(values),
                        'sum': sum(values),
                        'mean': sum(values) / len(values) if values else None,
                        'max': max(values) if values else None,
                        'min': min(values) if values else None,
                        'threshold_count': sum(1 for v in values if v > threshold)
                    }
            
            self.logger.info(f"Algorithm {self.algo_name} execution completed successfully")
            return result
            
        except Exception as e:
            self.logger.error(f"Error during algorithm execution: {str(e)}")
            raise

    def format_results(self, algorithm_results: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Format algorithm results into standardized structure.
        
        Args:
            algorithm_results: Raw results from execute_algorithm
            
        Returns:
            Formatted results
        """
        try:
            self.logger.info(f"Formatting results for {self.algo_name}")
            
            # Use provided results or empty dict if None
            results_to_format = algorithm_results if algorithm_results is not None else {}
            
            # Create a standardized result structure
            formatted_results = {
                "algorithm_name": self.algo_name,
                "status": results_to_format.get('status', 'completed'),
                "execution_time": self.execution_time,
                "timestamp": datetime.now().isoformat(),
                "metrics": results_to_format.get('metrics', {}),
                "parameters": self.parameters,
                "error": self.error,
                "data": results_to_format
            }
            
            # Store the formatted results for later access
            self.results = formatted_results
            
            self.logger.info("Results formatting completed successfully")
            return formatted_results
            
        except Exception as e:
            self.logger.error(f"Error formatting results: {str(e)}")
            raise

def create_example_algorithm(parameters: Optional[Dict[str, Any]] = None) -> ExampleAlgorithm:
    """
    Factory function to create an instance of ExampleAlgorithm.
    
    Args:
        parameters: Optional algorithm parameters
        
    Returns:
        Initialized ExampleAlgorithm instance
    """
    return ExampleAlgorithm(parameters=parameters)