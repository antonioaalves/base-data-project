"""Data container implementations for intermediate data storage."""

import os
import copy
import json
import logging
import pandas as pd
from typing import Any, Dict, List, Optional, Union
from datetime import datetime
from pathlib import Path
import uuid

class BaseDataContainer:
    """
    Abstract base class for intermediate data storage.
    
    Provides a consistent interface for storing and retrieving
    intermediate data from processing stages.
    """
    
    def __init__(self, config: Dict[str, Any]):
        """
        Initialize the data container with configuration.
        
        Args:
            config: Configuration dictionary with storage settings
        """
        self.config = config
        
        # Get project name if available in config
        project_name = config.get('project_name', 'base_data_project')
        self.logger = logging.getLogger(project_name)
        
        self.logger.info(f"Initialized {self.__class__.__name__}")
        
    def store_stage_data(self, stage_name: str, data: Any, metadata: Optional[Dict[str, Any]] = None) -> str:
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
        
    def list_available_data(self, filters: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """
        List available intermediate data.
        
        Args:
            filters: Optional filters for data selection
            
        Returns:
            List of available data summaries
        """
        raise NotImplementedError("Subclasses must implement list_available_data")
        
    def cleanup(self, policy: Optional[str] = None) -> None:
        """
        Clean up stored data based on policy.
        
        Args:
            policy: Cleanup policy to apply
        """
        raise NotImplementedError("Subclasses must implement cleanup")
    
    def get_data_summary(self, storage_key: str) -> Dict[str, Any]:
        """
        Get summary information about stored data.
        
        Args:
            storage_key: The storage identifier
            
        Returns:
            Dictionary with summary information
        """
        raise NotImplementedError("Subclasses must implement get_data_summary")


class MemoryDataContainer(BaseDataContainer):
    """
    Data container that stores intermediate data in memory.
    """
    
    def __init__(self, config: Dict[str, Any]):
        """
        Initialize the memory data container.
        
        Args:
            config: Configuration dictionary with storage settings
        """
        super().__init__(config)
        self.data_store = {}  # Stage data indexed by storage_key
        self.metadata_store = {}  # Metadata for each stored item
        
    def store_stage_data(self, stage_name: str, data: Any, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Store data in memory.
        
        Args:
            stage_name: Name of the stage
            data: The data to store
            metadata: Additional context information
            
        Returns:
            Storage key (identifier) for the data
        """
        metadata = metadata or {}
        process_id = metadata.get('process_id', 'default')
        timestamp = datetime.now()
        
        # Generate a unique storage key
        storage_key = f"{process_id}_{stage_name}_{timestamp.strftime('%Y%m%d%H%M%S')}_{uuid.uuid4().hex[:8]}"
        
        # Store a deep copy of the data to prevent modification
        self.data_store[storage_key] = copy.deepcopy(data)
        
        # Store metadata with timestamp
        self.metadata_store[storage_key] = {
            'timestamp': timestamp.isoformat(),
            'stage_name': stage_name,
            'process_id': process_id,
            'data_type': self._get_data_type(data),
            'size_estimate': self._estimate_size(data),
            **metadata
        }
        
        self.logger.info(f"Stored data for stage '{stage_name}' with key: {storage_key}")
        return storage_key
        
    def retrieve_stage_data(self, stage_name: str, process_id: Optional[str] = None) -> Any:
        """
        Retrieve data from memory.
        
        Args:
            stage_name: Name of the stage
            process_id: Optional process identifier (defaults to 'default')
            
        Returns:
            The stored data or None if not found
            
        Raises:
            KeyError: If no data is found for the stage and process
        """
        process_id = process_id or 'default'
        
        # Find the latest data for this stage and process
        matching_keys = []
        for key, metadata in self.metadata_store.items():
            if (metadata['stage_name'] == stage_name and 
                metadata['process_id'] == process_id):
                matching_keys.append((key, metadata['timestamp']))
        
        if not matching_keys:
            raise KeyError(f"No data found for stage '{stage_name}' in process '{process_id}'")
            
        # Sort by timestamp (descending) and get the most recent
        matching_keys.sort(key=lambda x: x[1], reverse=True)
        latest_key = matching_keys[0][0]
        
        # Return a deep copy to prevent modification of stored data
        self.logger.info(f"Retrieved data for stage '{stage_name}' with key: {latest_key}")
        return copy.deepcopy(self.data_store[latest_key])
        
    def list_available_data(self, filters: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """
        List available data in memory.
        
        Args:
            filters: Optional filters for data selection (stage_name, process_id, etc.)
            
        Returns:
            List of dictionaries with data summaries
        """
        filters = filters or {}
        
        result = []
        for key, metadata in self.metadata_store.items():
            # Apply filters if provided
            if filters:
                skip = False
                for filter_key, filter_value in filters.items():
                    if filter_key in metadata:
                        if metadata[filter_key] != filter_value:
                            skip = True
                            break
                if skip:
                    continue
                    
            # Add to result
            result.append({
                'storage_key': key,
                'metadata': metadata,
                'summary': self.get_data_summary(key)
            })
            
        return result
        
    def cleanup(self, policy: Optional[str] = None) -> None:
        """
        Clean up stored data based on policy.
        
        Args:
            policy: Cleanup policy to apply ('keep_none', 'keep_latest', 'keep_all')
        """
        policy = policy or self.config.get('cleanup_policy', 'keep_latest')
        
        if policy == 'keep_none':
            # Clear all data
            self.data_store.clear()
            self.metadata_store.clear()
            self.logger.info("Cleaned up all stored data (policy: keep_none)")
            
        elif policy == 'keep_latest':
            # Group by stage_name and process_id, keep only the latest for each
            latest_keys = {}
            
            for key, metadata in self.metadata_store.items():
                stage_name = metadata['stage_name']
                process_id = metadata['process_id']
                timestamp = metadata['timestamp']
                group_key = f"{process_id}_{stage_name}"
                
                if group_key not in latest_keys or timestamp > latest_keys[group_key][1]:
                    latest_keys[group_key] = (key, timestamp)
            
            # Keep only the latest keys
            keys_to_keep = set(info[0] for info in latest_keys.values())
            
            # Count before cleanup
            before_count = len(self.data_store)
            
            # Remove others
            self.data_store = {k: v for k, v in self.data_store.items() if k in keys_to_keep}
            self.metadata_store = {k: v for k, v in self.metadata_store.items() if k in keys_to_keep}
            
            # Count after cleanup
            after_count = len(self.data_store)
            removed_count = before_count - after_count
            
            self.logger.info(f"Cleaned up {removed_count} of {before_count} data items (policy: keep_latest)")
        
        elif policy != 'keep_all':
            self.logger.warning(f"Unknown cleanup policy: {policy}, no cleanup performed")
    
    def get_data_summary(self, storage_key: str) -> Dict[str, Any]:
        """
        Get summary information about stored data.
        
        Args:
            storage_key: The storage identifier
            
        Returns:
            Dictionary with summary information
            
        Raises:
            KeyError: If the storage key is not found
        """
        if storage_key not in self.data_store:
            raise KeyError(f"No data found for storage key: {storage_key}")
            
        data = self.data_store[storage_key]
        metadata = self.metadata_store[storage_key]
        
        summary = {
            'data_type': metadata.get('data_type', self._get_data_type(data)),
            'size_estimate': metadata.get('size_estimate', self._estimate_size(data)),
            'timestamp': metadata.get('timestamp'),
            'stage_name': metadata.get('stage_name'),
            'process_id': metadata.get('process_id')
        }
        
        # Add type-specific summary information
        if isinstance(data, pd.DataFrame):
            summary.update({
                'rows': len(data),
                'columns': len(data.columns),
                'column_names': data.columns.tolist()[:10],  # First 10 columns
                'memory_usage': data.memory_usage(deep=True).sum()
            })
        elif isinstance(data, dict):
            summary.update({
                'keys': list(data.keys())[:10],  # First 10 keys
                'nested_types': {k: type(v).__name__ for k, v in list(data.items())[:10]}
            })
        elif isinstance(data, list):
            summary.update({
                'length': len(data),
                'sample_types': [type(item).__name__ for item in data[:5]]  # Types of first 5 items
            })
            
        return summary
    
    def _get_data_type(self, data: Any) -> str:
        """
        Determine the type of data for metadata.
        
        Args:
            data: The data to analyze
            
        Returns:
            String representation of the data type
        """
        if isinstance(data, pd.DataFrame):
            return 'dataframe'
        elif isinstance(data, dict):
            return 'dictionary'
        elif isinstance(data, list):
            return 'list'
        elif isinstance(data, str):
            return 'string'
        elif isinstance(data, (int, float, bool)):
            return 'scalar'
        else:
            return type(data).__name__
    
    def _estimate_size(self, data: Any) -> int:
        """
        Estimate the size of the data in bytes.
        
        Args:
            data: The data to analyze
            
        Returns:
            Estimated size in bytes
        """
        try:
            if isinstance(data, pd.DataFrame):
                return data.memory_usage(deep=True).sum()
            elif isinstance(data, (dict, list)):
                # Use json serialization as a rough estimate
                try:
                    return len(json.dumps(data).encode('utf-8'))
                except (TypeError, OverflowError):
                    # Fall back to a simple length-based estimate
                    return len(str(data))
            else:
                return len(str(data))
        except Exception:
            # Fall back to a simple length-based estimate
            return len(str(data))


class CSVDataContainer(BaseDataContainer):
    """
    Data container that stores intermediate data as CSV files.
    """
    
    def __init__(self, config: Dict[str, Any]):
        """
        Initialize the CSV data container.
        
        Args:
            config: Configuration dictionary with storage settings
        """
        super().__init__(config)
        
        # Get storage directory from config
        self.storage_dir = config.get('storage_dir', 'data/intermediate')
        
        # Create storage directory if it doesn't exist
        os.makedirs(self.storage_dir, exist_ok=True)
        
        # Initialize metadata index
        self.metadata_index = {}
        self._load_metadata_index()
    
    def _load_metadata_index(self) -> None:
        """Load metadata index from disk if it exists."""
        index_path = os.path.join(self.storage_dir, 'metadata_index.json')
        if os.path.exists(index_path):
            try:
                with open(index_path, 'r') as f:
                    self.metadata_index = json.load(f)
                self.logger.info(f"Loaded metadata index with {len(self.metadata_index)} entries")
            except Exception as e:
                self.logger.warning(f"Error loading metadata index: {str(e)}")
    
    def _save_metadata_index(self) -> None:
        """Save metadata index to disk."""
        index_path = os.path.join(self.storage_dir, 'metadata_index.json')
        try:
            with open(index_path, 'w') as f:
                json.dump(self.metadata_index, f, indent=2)
        except Exception as e:
            self.logger.warning(f"Error saving metadata index: {str(e)}")
    
    def store_stage_data(self, stage_name: str, data: Any, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Store data as CSV file.
        
        Args:
            stage_name: Name of the stage
            data: The data to store (must be DataFrame or dict of DataFrames)
            metadata: Additional context information
            
        Returns:
            Storage key (identifier) for the data
            
        Raises:
            ValueError: If data is not a DataFrame or convertible to one
        """
        metadata = metadata or {}
        process_id = metadata.get('process_id', 'default')
        timestamp = datetime.now()
        
        # Generate a unique storage key
        storage_key = f"{process_id}_{stage_name}_{timestamp.strftime('%Y%m%d%H%M%S')}_{uuid.uuid4().hex[:8]}"
        
        # Create process directory if it doesn't exist
        process_dir = os.path.join(self.storage_dir, process_id)
        os.makedirs(process_dir, exist_ok=True)
        
        # File paths
        data_path = os.path.join(process_dir, f"{storage_key}.csv")
        metadata_path = os.path.join(process_dir, f"{storage_key}_metadata.json")
        
        # Store data based on type
        if isinstance(data, pd.DataFrame):
            # Store DataFrame directly
            data.to_csv(data_path, index=True)
            file_type = 'dataframe'
        elif isinstance(data, dict) and all(isinstance(v, pd.DataFrame) for v in data.values()):
            # Store dictionary of DataFrames as separate CSV files
            os.makedirs(os.path.join(process_dir, storage_key), exist_ok=True)
            for key, df in data.items():
                df_path = os.path.join(process_dir, storage_key, f"{key}.csv")
                df.to_csv(df_path, index=True)
            data_path = os.path.join(process_dir, storage_key)
            file_type = 'dataframe_dict'
        else:
            # Try to convert to DataFrame
            try:
                pd.DataFrame(data).to_csv(data_path, index=True)
                file_type = 'converted_to_dataframe'
            except Exception as e:
                raise ValueError(f"Cannot store data as CSV: {str(e)}")
        
        # Store metadata
        complete_metadata = {
            'timestamp': timestamp.isoformat(),
            'stage_name': stage_name,
            'process_id': process_id,
            'data_path': data_path,
            'file_type': file_type,
            **metadata
        }
        
        with open(metadata_path, 'w') as f:
            json.dump(complete_metadata, f, indent=2)
        
        # Update metadata index
        self.metadata_index[storage_key] = complete_metadata
        self._save_metadata_index()
        
        self.logger.info(f"Stored data for stage '{stage_name}' with key: {storage_key}")
        return storage_key
    
    # Other methods to be implemented later (retrieve_stage_data, list_available_data, cleanup, get_data_summary)
    def retrieve_stage_data(self, stage_name: str, process_id: Optional[str] = None) -> Any:
        """
        Retrieve data from CSV storage.
        
        Args:
            stage_name: Name of the stage
            process_id: Optional process identifier (defaults to 'default')
            
        Returns:
            The stored data or None if not found
            
        Raises:
            KeyError: If no data is found for the stage and process
        """
        process_id = process_id or 'default'
        
        # Find all matching entries
        matching_keys = []
        for key, metadata in self.metadata_index.items():
            if (metadata['stage_name'] == stage_name and 
                metadata['process_id'] == process_id):
                matching_keys.append((key, metadata['timestamp']))
        
        if not matching_keys:
            raise KeyError(f"No data found for stage '{stage_name}' in process '{process_id}'")
            
        # Sort by timestamp (descending) and get the most recent
        matching_keys.sort(key=lambda x: x[1], reverse=True)
        latest_key = matching_keys[0][0]
        
        # Load data based on type
        metadata = self.metadata_index[latest_key]
        data_path = metadata['data_path']
        file_type = metadata.get('file_type', 'dataframe')
        
        if file_type == 'dataframe':
            # Load single DataFrame
            if os.path.exists(data_path):
                return pd.read_csv(data_path, index_col=0)
        elif file_type == 'dataframe_dict':
            # Load dictionary of DataFrames
            if os.path.isdir(data_path):
                result = {}
                for file_name in os.listdir(data_path):
                    if file_name.endswith('.csv'):
                        key = file_name[:-4]  # Remove .csv extension
                        df_path = os.path.join(data_path, file_name)
                        result[key] = pd.read_csv(df_path, index_col=0)
                return result
        
        # Fall back to returning metadata if data couldn't be loaded
        self.logger.warning(f"Could not load data for key {latest_key}, returning metadata only")
        return metadata
        
    def list_available_data(self, filters: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """
        List available data in CSV storage.
        
        Args:
            filters: Optional filters for data selection (stage_name, process_id, etc.)
            
        Returns:
            List of dictionaries with data summaries
        """
        filters = filters or {}
        
        result = []
        for key, metadata in self.metadata_index.items():
            # Apply filters if provided
            if filters:
                skip = False
                for filter_key, filter_value in filters.items():
                    if filter_key in metadata:
                        if metadata[filter_key] != filter_value:
                            skip = True
                            break
                if skip:
                    continue
                    
            # Add to result
            result.append({
                'storage_key': key,
                'metadata': metadata,
                'summary': self.get_data_summary(key)
            })
            
        return result
        
    def cleanup(self, policy: Optional[str] = None) -> None:
        """
        Clean up stored data based on policy.
        
        Args:
            policy: Cleanup policy to apply ('keep_none', 'keep_latest', 'keep_all')
        """
        policy = policy or self.config.get('cleanup_policy', 'keep_latest')
        
        if policy == 'keep_none':
            # Delete all files and directories
            for key, metadata in self.metadata_index.items():
                data_path = metadata.get('data_path')
                if data_path and os.path.exists(data_path):
                    if os.path.isdir(data_path):
                        import shutil
                        shutil.rmtree(data_path)
                    else:
                        os.remove(data_path)
                        
                # Remove metadata file
                process_id = metadata.get('process_id', 'default')
                process_dir = os.path.join(self.storage_dir, process_id)
                metadata_path = os.path.join(process_dir, f"{key}_metadata.json")
                if os.path.exists(metadata_path):
                    os.remove(metadata_path)
            
            # Clear metadata index
            self.metadata_index = {}
            self._save_metadata_index()
            self.logger.info("Cleaned up all stored data (policy: keep_none)")
            
        elif policy == 'keep_latest':
            # Group by stage_name and process_id, keep only the latest for each
            latest_keys = {}
            
            for key, metadata in self.metadata_index.items():
                stage_name = metadata['stage_name']
                process_id = metadata['process_id']
                timestamp = metadata['timestamp']
                group_key = f"{process_id}_{stage_name}"
                
                if group_key not in latest_keys or timestamp > latest_keys[group_key][1]:
                    latest_keys[group_key] = (key, timestamp)
            
            # Keep only the latest keys
            keys_to_keep = set(info[0] for info in latest_keys.values())
            
            # Delete files for keys not in keys_to_keep
            for key, metadata in list(self.metadata_index.items()):
                if key not in keys_to_keep:
                    data_path = metadata.get('data_path')
                    if data_path and os.path.exists(data_path):
                        if os.path.isdir(data_path):
                            import shutil
                            shutil.rmtree(data_path)
                        else:
                            os.remove(data_path)
                            
                    # Remove metadata file
                    process_id = metadata.get('process_id', 'default')
                    process_dir = os.path.join(self.storage_dir, process_id)
                    metadata_path = os.path.join(process_dir, f"{key}_metadata.json")
                    if os.path.exists(metadata_path):
                        os.remove(metadata_path)
                    
                    # Remove from metadata index
                    del self.metadata_index[key]
            
            # Save updated metadata index
            self._save_metadata_index()
            self.logger.info(f"Cleaned up data items, keeping latest for each stage (policy: keep_latest)")
    
    def get_data_summary(self, storage_key: str) -> Dict[str, Any]:
        """
        Get summary information about stored data.
        
        Args:
            storage_key: The storage identifier
            
        Returns:
            Dictionary with summary information
            
        Raises:
            KeyError: If the storage key is not found
        """
        if storage_key not in self.metadata_index:
            raise KeyError(f"No data found for storage key: {storage_key}")
            
        metadata = self.metadata_index[storage_key]
        data_path = metadata.get('data_path')
        file_type = metadata.get('file_type', 'dataframe')
        
        summary = {
            'data_type': file_type,
            'timestamp': metadata.get('timestamp'),
            'stage_name': metadata.get('stage_name'),
            'process_id': metadata.get('process_id'),
            'storage_path': data_path
        }
        
        # Add file size
        if data_path and os.path.exists(data_path):
            if os.path.isdir(data_path):
                # Sum up sizes of all files in directory
                total_size = 0
                file_count = 0
                for root, dirs, files in os.walk(data_path):
                    for file in files:
                        file_path = os.path.join(root, file)
                        total_size += os.path.getsize(file_path)
                        file_count += 1
                summary['size_bytes'] = total_size
                summary['file_count'] = file_count
            else:
                summary['size_bytes'] = os.path.getsize(data_path)
        
        return summary


class DBDataContainer(BaseDataContainer):
    """
    Data container that stores intermediate data in a database.
    (Placeholder for future implementation)
    """
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__(config)
        self.logger.warning("DBDataContainer is not fully implemented yet. Falling back to memory storage.")
        
        # For now, just delegate to MemoryDataContainer
        self._memory_container = MemoryDataContainer(config)
    
    def store_stage_data(self, stage_name: str, data: Any, metadata: Optional[Dict[str, Any]] = None) -> str:
        return self._memory_container.store_stage_data(stage_name, data, metadata)
        
    def retrieve_stage_data(self, stage_name: str, process_id: Optional[str] = None) -> Any:
        return self._memory_container.retrieve_stage_data(stage_name, process_id)
        
    def list_available_data(self, filters: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        return self._memory_container.list_available_data(filters)
        
    def cleanup(self, policy: Optional[str] = None) -> None:
        self._memory_container.cleanup(policy)
    
    def get_data_summary(self, storage_key: str) -> Dict[str, Any]:
        return self._memory_container.get_data_summary(storage_key)


class HybridDataContainer(BaseDataContainer):
    """
    Data container that selectively stores data in memory or persistent storage
    based on configuration and data characteristics.
    (Placeholder for future implementation)
    """
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__(config)
        self.logger.warning("HybridDataContainer is not fully implemented yet. Falling back to memory storage.")
        
        # For now, just delegate to MemoryDataContainer
        self._memory_container = MemoryDataContainer(config)
    
    def store_stage_data(self, stage_name: str, data: Any, metadata: Optional[Dict[str, Any]] = None) -> str:
        return self._memory_container.store_stage_data(stage_name, data, metadata)
        
    def retrieve_stage_data(self, stage_name: str, process_id: Optional[str] = None) -> Any:
        return self._memory_container.retrieve_stage_data(stage_name, process_id)
        
    def list_available_data(self, filters: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        return self._memory_container.list_available_data(filters)
        
    def cleanup(self, policy: Optional[str] = None) -> None:
        self._memory_container.cleanup(policy)
    
    def get_data_summary(self, storage_key: str) -> Dict[str, Any]:
        return self._memory_container.get_data_summary(storage_key)