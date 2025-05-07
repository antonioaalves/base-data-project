""""""

# Dependencies
from typing import Any, Dict

# Local stuff
from base_data_project.storage.containers import BaseDataContainer

class DataContainerFactory:
    """
    Factory for creating data container instances.
    """
    
    @staticmethod
    def create_data_container(config: Dict[str, Any]) -> BaseDataContainer:
        """
        Create a data container based on configuration.
        
        Args:
            config: Configuration dictionary
            
        Returns:
            Initialized data container
        """
        storage_strategy = config.get('storage_strategy', {'mode': 'memory'})
        mode = storage_strategy.get('mode', 'memory')
        
        if mode == 'memory':
            from base_data_project.storage.containers import MemoryDataContainer
            return MemoryDataContainer(storage_strategy)
        elif mode == 'persist':
            persist_format = storage_strategy.get('persist_format', 'csv')
            if persist_format == 'csv':
                from base_data_project.storage.containers import CSVDataContainer
                return CSVDataContainer(storage_strategy)
            else:
                from base_data_project.storage.containers import DBDataContainer
                return DBDataContainer(storage_strategy)
        elif mode == 'hybrid':
            from base_data_project.storage.containers import HybridDataContainer
            return HybridDataContainer(storage_strategy)
        else:
            # Default to memory
            from base_data_project.storage.containers import MemoryDataContainer
            return MemoryDataContainer(storage_strategy)