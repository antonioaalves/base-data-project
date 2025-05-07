""""""
# Dependencies
from typing import Any, Dict, List, Optional
from datetime import datetime

# Local stuff

class BaseDataContainer:
    """
    Abstract base class for intermediate data storage.
    
    Provides a consistent interface for storing and retrieving
    intermediate data from processing stages.
    """
    
    def __init__(self, config: Dict[str, Any]):
        """Initialize the data container with configuration."""
        self.config = config
        
    def store_stage_data(self, stage_name: str, data: Any, metadata: Dict[str, Any] = None) -> str:
        """
        Store data from a processing stage.
        
        Args:
            stage_name: Name of the stage
            data: The data to store
            metadata: Additional context information
            
        Returns:
            Storage identifier for the data
        """
        raise NotImplementedError("Subclasses must implement store_stage_data")
        
    def retrieve_stage_data(self, stage_name: str, process_id: Optional[str] = None) -> Any:
        """
        Retrieve data for a specific stage.
        
        Args:
            stage_name: Name of the stage
            process_id: Optional process identifier
            
        Returns:
            The stored data
        """
        raise NotImplementedError("Subclasses must implement retrieve_stage_data")
        
    def list_available_data(self, filters: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        """
        List available intermediate data.
        
        Args:
            filters: Optional filters for data selection
            
        Returns:
            List of available data summaries
        """
        raise NotImplementedError("Subclasses must implement list_available_data")
        
    def cleanup(self, policy: str = None) -> None:
        """
        Clean up stored data based on policy.
        
        Args:
            policy: Cleanup policy to apply
        """
        raise NotImplementedError("Subclasses must implement cleanup")
    

class MemoryDataContainer(BaseDataContainer):
    """
    Data container that stores intermediate data in memory.
    """
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__(config)
        self.data_store = {}  # Stage data indexed by process_id and stage_name
        self.metadata_store = {}  # Metadata for each stored item
        
    def store_stage_data(self, stage_name: str, data: Any, metadata: Dict[str, Any] = None) -> str:
        """Store data in memory."""
        process_id = metadata.get('process_id', 'default')
        storage_key = f"{process_id}_{stage_name}"
        
        # Store a deep copy to prevent modification
        self.data_store[storage_key] = copy.deepcopy(data)
        
        # Store metadata with timestamp
        self.metadata_store[storage_key] = {
            'timestamp': datetime.now().isoformat(),
            'stage_name': stage_name,
            'process_id': process_id,
            **(metadata or {})
        }
        
        return storage_key
        
    def retrieve_stage_data(self, stage_name: str, process_id: Optional[str] = None) -> Any:
        """Retrieve data from memory."""
        process_id = process_id or 'default'
        storage_key = f"{process_id}_{stage_name}"
        
        if storage_key not in self.data_store:
            raise KeyError(f"No data found for stage {stage_name} in process {process_id}")
            
        # Return a deep copy to prevent modification of stored data
        return copy.deepcopy(self.data_store[storage_key])
        
    def list_available_data(self, filters: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        """List available data in memory."""
        filters = filters or {}
        
        result = []
        for key, metadata in self.metadata_store.items():
            # Apply filters if provided
            if filters:
                if 'stage_name' in filters and metadata['stage_name'] != filters['stage_name']:
                    continue
                if 'process_id' in filters and metadata['process_id'] != filters['process_id']:
                    continue
                    
            # Add to result
            result.append({
                'storage_key': key,
                'metadata': metadata
            })
            
        return result
        
    def cleanup(self, policy: str = None) -> None:
        """Clean up stored data based on policy."""
        policy = policy or self.config.get('cleanup_policy', 'keep_latest')
        
        if policy == 'keep_none':
            # Clear all data
            self.data_store.clear()
            self.metadata_store.clear()
            
        elif policy == 'keep_latest':
            # Group by stage_name and keep only the latest for each
            latest_keys = {}
            
            for key, metadata in self.metadata_store.items():
                stage_name = metadata['stage_name']
                timestamp = metadata['timestamp']
                
                if stage_name not in latest_keys or timestamp > latest_keys[stage_name][1]:
                    latest_keys[stage_name] = (key, timestamp)
            
            # Keep only the latest keys
            keys_to_keep = set(info[0] for info in latest_keys.values())
            
            # Remove others
            self.data_store = {k: v for k, v in self.data_store.items() if k in keys_to_keep}
            self.metadata_store = {k: v for k, v in self.metadata_store.items() if k in keys_to_keep}   