"""Factory for creating data manager instances."""

import logging
import importlib
from typing import Dict, Any, Optional, Type

from base_data_project.data_manager.managers.base import BaseDataManager
from base_data_project.log_config import get_logger
from src.configuration_manager.manager import ConfigurationManager

class DataManagerFactory:
    """
    Factory class for creating data manager instances.
    
    This class centralizes the creation logic for different data manager types
    and provides a consistent interface for instantiating them.
    """
    
    # Dictionary to store registered data manager classes
    _registered_managers = {}
    
    @classmethod
    def register_data_manager(cls, data_source_type: str, manager_class: Type[BaseDataManager]) -> None:
        """
        Register a new data manager class.
        
        Args:
            data_source_type: Type identifier for the data source
            manager_class: The data manager class (must inherit from BaseDataManager)
        """
        if not issubclass(manager_class, BaseDataManager):
            raise TypeError(f"Data manager class must inherit from BaseDataManager")
            
        cls._registered_managers[data_source_type.lower()] = manager_class

    @classmethod
    def create_data_manager(cls, 
                          data_source_type: str, 
                          config: Optional[ConfigurationManager] = None,
                          project_name: str = 'base_data_project') -> BaseDataManager:
        """
        Create and return a data manager instance.
        
        Args:
            data_source_type: Type of data source ('csv', 'db', etc.)
            config: Configuration for the data manager
            project_name: Name of the project for logging
            
        Returns:
            Initialized data manager instance
            
        Raises:
            ValueError: If the data source type is unsupported
        """
        # Use the framework logger
        logger = get_logger(project_name)
        
        # Default empty configuration
        if config is None:
            config = ConfigurationManager()
        
        # Normalize data source type
        data_source_type_lower = data_source_type.lower()
        
        # Check if data manager type is registered
        if data_source_type_lower in cls._registered_managers:
            logger.info(f"Creating data manager for source type: {data_source_type}")
            
            # Get the data manager class
            manager_class = cls._registered_managers[data_source_type_lower]
            
            # Create instance
            return manager_class(config=config, project_name=project_name)
        
        # Try to import built-in managers
        try:
            logger.info(f"Data manager for '{data_source_type}' not registered, trying built-in managers")
            
            # Import built-in managers module
            from base_data_project.data_manager.managers import managers
            
            # Check for CSV manager
            if data_source_type_lower == 'csv':
                if hasattr(managers, 'CSVDataManager'):
                    manager_class = getattr(managers, 'CSVDataManager')
                    cls.register_data_manager('csv', manager_class)
                    return manager_class(config=config, project_name=project_name)
            
            # Check for database manager
            if data_source_type_lower in ['db', 'database', 'sql']:
                if hasattr(managers, 'DBDataManager'):
                    manager_class = getattr(managers, 'DBDataManager')
                    cls.register_data_manager('db', manager_class)
                    return manager_class(config=config, project_name=project_name)
            
        except ImportError:
            logger.warning("Could not import built-in data managers")
            
        # Try importing from project data managers
        try:
            logger.info(f"Trying to import custom data manager for '{data_source_type}'")
            
            # Try different import paths
            module_paths = [
                f"src.data_manager.managers.{data_source_type_lower}",  # Project-specific managers
                f"data_manager.managers.{data_source_type_lower}"       # Alternative project structure
            ]
            
            for module_path in module_paths:
                try:
                    # Try to import module
                    module = importlib.import_module(module_path)
                    
                    # Look for data manager class in module
                    # Convention: CamelCase data source type as class name + "DataManager"
                    class_name = ''.join(word.capitalize() for word in data_source_type.split('_'))
                    if not class_name.endswith('DataManager'):
                        class_name += 'DataManager'
                        
                    # Check if class exists in module
                    if hasattr(module, class_name):
                        manager_class = getattr(module, class_name)
                        
                        # Validate it's a proper data manager class
                        if issubclass(manager_class, BaseDataManager):
                            # Register for future use
                            cls.register_data_manager(data_source_type, manager_class)
                            
                            # Create instance
                            logger.info(f"Successfully imported data manager '{class_name}' from {module_path}")
                            return manager_class(config=config, project_name=project_name)
                    
                except ImportError:
                    # Try next path
                    continue
                    
            # If we get here, we couldn't find a suitable data manager
            error_msg = f"Unsupported data source type: {data_source_type}"
            logger.error(error_msg)
            raise ValueError(error_msg)
            
        except Exception as e:
            logger.error(f"Error creating data manager for type '{data_source_type}': {str(e)}")
            raise ValueError(f"Failed to create data manager: {str(e)}")
    
    @classmethod
    def list_available_managers(cls) -> Dict[str, str]:
        """
        List all available registered data managers.
        
        Returns:
            Dictionary mapping data source types to manager class names
        """
        return {source_type: manager_class.__name__ 
                for source_type, manager_class in cls._registered_managers.items()}