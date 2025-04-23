"""Factory for creating algorithm instances."""

import logging
import importlib
from typing import Dict, Any, Optional, List, Type, Union

from base_data_project.algorithms.base import BaseAlgorithm

class AlgorithmFactory:
    """
    Factory class for creating algorithm instances.
    
    This class provides a central point for instantiating algorithm 
    objects, either from built-in algorithms or custom ones.
    """
    
    # Dictionary to store registered algorithm classes
    _registered_algorithms = {}
    
    @classmethod
    def register_algorithm(cls, name: str, algorithm_class: Type[BaseAlgorithm]) -> None:
        """
        Register a new algorithm class.
        
        Args:
            name: Name to register the algorithm under
            algorithm_class: The algorithm class (must inherit from BaseAlgorithm)
        """
        if not issubclass(algorithm_class, BaseAlgorithm):
            raise TypeError(f"Algorithm class must inherit from BaseAlgorithm")
            
        cls._registered_algorithms[name.lower()] = algorithm_class
        
    @classmethod
    def create_algorithm(cls, 
                       algorithm_name: str, 
                       data: Any = None,
                       parameters: Optional[Dict[str, Any]] = None) -> BaseAlgorithm:
        """
        Create and return an algorithm instance.
        
        Args:
            algorithm_name: Name of the algorithm to create
            data: Optional data to pass to the algorithm
            parameters: Optional parameters for the algorithm
            
        Returns:
            Initialized algorithm instance
            
        Raises:
            ValueError: If the algorithm is not registered
        """
        logger = logging.getLogger(parameters.get('project_name', 'base_data_project') 
                                if parameters else 'base_data_project')
        
        # Normalize algorithm name
        algorithm_name_lower = algorithm_name.lower()
        
        # Check if algorithm is registered
        if algorithm_name_lower in cls._registered_algorithms:
            logger.info(f"Creating algorithm: {algorithm_name}")
            
            # Get the algorithm class
            algorithm_class = cls._registered_algorithms[algorithm_name_lower]
            
            # Create instance
            return algorithm_class(
                algo_name=algorithm_name,
                parameters=parameters or {}
            )
            
        # Try importing from project algorithms
        try:
            logger.info(f"Algorithm '{algorithm_name}' not registered, trying to import")
            
            # Try different import paths
            module_paths = [
                f"src.algorithms.{algorithm_name_lower}",  # Project-specific algorithms
                f"algorithms.{algorithm_name_lower}",      # Alternative project structure
                f"base_data_project.algorithms.examples.{algorithm_name_lower}"  # Example algorithms
            ]
            
            for module_path in module_paths:
                try:
                    # Try to import module
                    module = importlib.import_module(module_path)
                    
                    # Look for algorithm class in module
                    # Convention: CamelCase algorithm name as class name
                    class_name = ''.join(word.capitalize() for word in algorithm_name.split('_'))
                    if not class_name.endswith('Algorithm'):
                        class_name += 'Algorithm'
                        
                    # Check if class exists in module
                    if hasattr(module, class_name):
                        algorithm_class = getattr(module, class_name)
                        
                        # Validate it's a proper algorithm class
                        if issubclass(algorithm_class, BaseAlgorithm):
                            # Register for future use
                            cls.register_algorithm(algorithm_name, algorithm_class)
                            
                            # Create instance
                            logger.info(f"Successfully imported algorithm '{algorithm_name}' from {module_path}")
                            return algorithm_class(
                                algo_name=algorithm_name,
                                parameters=parameters or {}
                            )
                    
                except ImportError:
                    # Try next path
                    continue
                        
            # If we get here, we couldn't find the algorithm
            raise ValueError(f"Algorithm '{algorithm_name}' not found")
            
        except Exception as e:
            logger.error(f"Error creating algorithm '{algorithm_name}': {str(e)}")
            raise ValueError(f"Failed to create algorithm '{algorithm_name}': {str(e)}")
    
    @classmethod
    def list_available_algorithms(cls) -> List[str]:
        """
        List all available registered algorithms.
        
        Returns:
            List of algorithm names
        """
        return list(cls._registered_algorithms.keys())