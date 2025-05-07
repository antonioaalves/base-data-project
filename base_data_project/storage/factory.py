"""Factory for creating data container instances."""

import logging
from typing import Any, Dict, Optional

from base_data_project.storage.containers import (
    BaseDataContainer,
    MemoryDataContainer,
    CSVDataContainer,
    DBDataContainer,
    HybridDataContainer
)

class DataContainerFactory:
    """
    Factory for creating data container instances based on configuration.
    
    This class provides a central point for instantiating different types 
    of data containers while ensuring proper configuration.
    """
    
    @staticmethod
    def create_data_container(config: Dict[str, Any]) -> BaseDataContainer:
        """
        Create a data container based on configuration.
        
        Args:
            config: Configuration dictionary with storage strategy settings
            
        Returns:
            Configured data container instance
        """
        # Get project name for logging
        project_name = config.get('PROJECT_NAME', 'base_data_project')
        logger = logging.getLogger(project_name)
        
        # Get storage strategy from config
        storage_strategy = config.get('storage_strategy', {'mode': 'memory'})
        mode = storage_strategy.get('mode', 'memory')
        
        # Create container based on mode
        if mode == 'memory':
            logger.info("Creating memory data container")
            return MemoryDataContainer(storage_strategy)
            
        elif mode == 'persist':
            persist_format = storage_strategy.get('persist_format', 'csv')
            
            if persist_format == 'csv':
                logger.info("Creating CSV data container")
                return CSVDataContainer(storage_strategy)
            else:
                logger.info("Creating database data container")
                return DBDataContainer(storage_strategy)
                
        elif mode == 'hybrid':
            logger.info("Creating hybrid data container")
            return HybridDataContainer(storage_strategy)
            
        else:
            # Default to memory if mode is unknown
            logger.warning(f"Unknown storage mode '{mode}', defaulting to memory storage")
            return MemoryDataContainer(storage_strategy)
    
    @staticmethod
    def get_default_config() -> Dict[str, Any]:
        """
        Get default storage configuration.
        
        Returns:
            Dictionary with default storage configuration
        """
        return {
            'mode': 'memory',
            'persist_intermediate_results': False,
            'stages_to_persist': [],
            'cleanup_policy': 'keep_latest',
            'persist_format': 'csv',
            'storage_dir': 'data/intermediate'
        }