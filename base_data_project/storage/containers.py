"""Data container implementations for intermediate data storage."""

# Dependencies
import os
import copy
import json
import logging
import pandas as pd
from typing import Any, Dict, List, Optional, Union
from datetime import datetime
from pathlib import Path
import uuid

# Local stuff
from base_data_project.log_config import get_logger

class BaseDataContainer:
    """
    Abstract base class for intermediate data storage.
    
    Provides a consistent interface for storing and retrieving
    intermediate data from processing stages.
    """
    
    def __init__(self, config: Dict[str, Any], project_name: str = 'base_data_project'):
        """
        Initialize the data container with configuration.
        
        Args:
            config: Configuration dictionary with storage settings
            project_name: Name of the project for logging
        """
        self.config = config
        self.logger = get_logger(project_name)
        
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
    
    def __init__(self, config: Dict[str, Any], project_name: str = 'base_data_project'):
        """
        Initialize the memory data container.
        
        Args:
            config: Configuration dictionary with storage settings
        """
        super().__init__(config=config, project_name=project_name)
        self.logger.info(f"Initialized {self.__class__.__name__} with project name: {project_name}")
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
        
        metadata = self.metadata_store[latest_key]
        
        # Check if this is inlined data
        if metadata.get('storage_mode') == 'inlined' and 'inlined_result_data' in metadata:
            self.logger.info(f"Retrieved inlined data for stage '{stage_name}' with key: {latest_key}")
            return metadata['inlined_result_data']
        else:
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
    
    def __init__(self, config: Dict[str, Any], project_name: str = 'base_data_project'):
        """
        Initialize the CSV data container.
        
        Args:
            config: Configuration dictionary with storage settings
        """
        super().__init__(config=config, project_name=project_name)
        
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
        Store data as CSV file or inline within metadata.
        
        Args:
            stage_name: Name of the stage
            data: The data to store (can be None if inlined in metadata)
            metadata: Additional context information
            
        Returns:
            Storage key (identifier) for the data
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
        metadata_path = os.path.join(process_dir, f"{storage_key}_metadata.json")
        
        # Check if this is inlined data
        if metadata.get('storage_mode') == 'inlined':
            # For inlined data, we only store the metadata
            complete_metadata = {
                'timestamp': timestamp.isoformat(),
                'stage_name': stage_name,
                'process_id': process_id,
                'data_path': None,  # No separate data file
                'file_type': 'inlined',
                **metadata
            }
            
            with open(metadata_path, 'w') as f:
                json.dump(complete_metadata, f, indent=2)
            
            # Update metadata index
            self.metadata_index[storage_key] = complete_metadata
            self._save_metadata_index()
            
            self.logger.info(f"Stored inlined data for stage '{stage_name}' with key: {storage_key}")
            return storage_key
        
        # Handle regular data storage if not inlined
        data_path = os.path.join(process_dir, f"{storage_key}.csv")
        
        # Store data based on type
        if data is None:
            # No actual data to store
            file_type = 'none'
        elif isinstance(data, pd.DataFrame):
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
                # If conversion fails, store as JSON
                try:
                    with open(data_path + '.json', 'w') as f:
                        json.dump(data, f, cls=self._get_json_encoder())
                    data_path = data_path + '.json'
                    file_type = 'json'
                except Exception as e2:
                    raise ValueError(f"Cannot store data: {str(e2)}")
        
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

    def retrieve_stage_data(self, stage_name: str, process_id: Optional[str] = None) -> Any:
        """
        Retrieve data from CSV storage or inlined metadata.
        
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
        
        # Check if this is inlined data
        if metadata.get('file_type') == 'inlined' or metadata.get('storage_mode') == 'inlined':
            if 'inlined_result_data' in metadata:
                self.logger.info(f"Retrieved inlined data for stage '{stage_name}' with key: {latest_key}")
                return metadata['inlined_result_data']
            else:
                self.logger.warning(f"Inlined data format indicated but no data found for key {latest_key}")
                return metadata
        
        # Handle regular data retrieval
        data_path = metadata.get('data_path')
        file_type = metadata.get('file_type', 'dataframe')
        
        if file_type == 'none' or not data_path or not os.path.exists(data_path):
            # No data or path doesn't exist
            self.logger.warning(f"No data file found for key {latest_key}, returning metadata only")
            return metadata
        
        if file_type == 'dataframe':
            # Load single DataFrame
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
        elif file_type == 'json':
            # Load JSON data
            with open(data_path, 'r') as f:
                return json.load(f)
        
        # Fall back to returning metadata if data couldn't be loaded
        self.logger.warning(f"Could not load data for key {latest_key}, returning metadata only")
        return metadata

    def _get_json_encoder(self):
        """
        Get a custom JSON encoder that handles various data types.
        """
        import json
        import pandas as pd
        import numpy as np
        from datetime import datetime, date
        
        class CustomJSONEncoder(json.JSONEncoder):
            def default(self, obj):
                if isinstance(obj, (datetime, date)):
                    return obj.isoformat()
                elif isinstance(obj, pd.DataFrame):
                    return {
                        "_type": "DataFrame",
                        "data": obj.to_dict(orient='records'),
                        "columns": obj.columns.tolist(),
                        "index": obj.index.tolist() if not obj.index.equals(pd.RangeIndex(len(obj))) else None
                    }
                elif isinstance(obj, pd.Series):
                    return {
                        "_type": "Series",
                        "data": obj.tolist(),
                        "name": obj.name
                    }
                elif isinstance(obj, np.ndarray):
                    return obj.tolist()
                elif isinstance(obj, np.integer):
                    return int(obj)
                elif isinstance(obj, np.floating):
                    return float(obj)
                elif isinstance(obj, set):
                    return list(obj)
                return super().default(obj)
        
        return CustomJSONEncoder
        
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
    """
    
    def __init__(self, config: Dict[str, Any], project_name: str = 'base_data_project'):
        """
        Initialize the database data container.
        
        Args:
            config: Configuration dictionary with storage settings
        """
        super().__init__(config=config, project_name=project_name)
        
        # Extract database configuration
        self.db_url = config.get('db_url')
        
        if not self.db_url:
            # Default to SQLite if no URL provided
            import os
            storage_dir = config.get('storage_dir', 'data/intermediate')
            os.makedirs(storage_dir, exist_ok=True)
            self.db_url = f"sqlite:///{os.path.join(storage_dir, 'intermediate_data.db')}"
        
        self.logger.info(f"Initializing database data container with URL: {self.db_url}")
        
        # Initialize database
        self._initialize_database()
    
    def _initialize_database(self):
        """Initialize the database connection and tables."""
        try:
            from sqlalchemy import create_engine, Column, Integer, String, LargeBinary, DateTime, Text
            from sqlalchemy.ext.declarative import declarative_base
            from sqlalchemy.orm import sessionmaker
            import datetime
            
            # Create engine
            self.engine = create_engine(self.db_url)
            
            # Import base and intermediate_data models (very important for db creation)            
            from base_data_project.storage.models import Base, IntermediateData
                
            # Create tables
            Base.metadata.create_all(self.engine)
            
            # Create session
            Session = sessionmaker(bind=self.engine)
            self.session = Session()
            
            # Store model class for later use
            self.IntermediateData = IntermediateData
            
            self.logger.info("Database initialized successfully")
            
        except Exception as e:
            self.logger.error(f"Failed to initialize database: {str(e)}")
            raise            
    
    def store_stage_data(self, stage_name: str, data: Any, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Store data in the database or inline within metadata.
        
        Args:
            stage_name: Name of the stage
            data: The data to store (can be None if inlined in metadata)
            metadata: Additional context information
            
        Returns:
            Storage key (identifier) for the data
        """
        try:
            import pickle
            import json
            import uuid
            from datetime import datetime
            
            metadata = metadata or {}
            process_id = metadata.get('process_id', 'default')
            timestamp = datetime.now()
            
            # Generate a unique storage key
            storage_key = f"{process_id}_{stage_name}_{timestamp.strftime('%Y%m%d%H%M%S')}"
            
            # Check if this is inlined data
            if metadata.get('storage_mode') == 'inlined':
                # For inlined data, we store null in the data field
                intermediate_data = self.IntermediateData(
                    storage_key=storage_key,
                    process_id=process_id,
                    stage_name=stage_name,
                    timestamp=timestamp,
                    data=None,  # No binary data
                    metadata=json.dumps(metadata)
                )
                
                # Save to database
                self.session.add(intermediate_data)
                self.session.commit()
                
                self.logger.info(f"Stored inlined data for stage '{stage_name}' with key: {storage_key}")
                return storage_key
            
            # Regular data storage
            # Serialize data if not None
            data_pickle = pickle.dumps(data) if data is not None else None
            
            # Create database record
            intermediate_data = self.IntermediateData(
                storage_key=storage_key,
                process_id=process_id,
                stage_name=stage_name,
                timestamp=timestamp,
                data=data_pickle,
                metadata=json.dumps(metadata)
            )
            
            # Save to database
            self.session.add(intermediate_data)
            self.session.commit()
            
            self.logger.info(f"Stored data for stage '{stage_name}' with key: {storage_key}")
            return storage_key
            
        except Exception as e:
            self.session.rollback()
            self.logger.error(f"Error storing data in database: {str(e)}")
            raise
        
    def retrieve_stage_data(self, stage_name: str, process_id: Optional[str] = None) -> Any:
        """
        Retrieve data from the database or inlined metadata.
        
        Args:
            stage_name: Name of the stage
            process_id: Optional process identifier (defaults to 'default')
            
        Returns:
            The stored data or None if not found
            
        Raises:
            KeyError: If no data is found for the stage and process
        """
        try:
            import pickle
            import json
            
            process_id = process_id or 'default'
            
            # Query database for the latest record matching stage and process
            query = self.session.query(self.IntermediateData)\
                .filter_by(stage_name=stage_name, process_id=process_id)\
                .order_by(self.IntermediateData.timestamp.desc())
            
            record = query.first()
            
            if not record:
                raise KeyError(f"No data found for stage '{stage_name}' in process '{process_id}'")
            
            # Parse metadata
            try:
                metadata = json.loads(record.metadata) if record.metadata else {}
            except Exception as e:
                self.logger.error(f"Error parsing metadata: {str(e)}")
                metadata = {}
            
            # Check if this is inlined data
            if metadata.get('storage_mode') == 'inlined':
                if 'inlined_result_data' in metadata:
                    self.logger.info(f"Retrieved inlined data for stage '{stage_name}' with key: {record.storage_key}")
                    return metadata['inlined_result_data']
                else:
                    self.logger.warning(f"Inlined data format indicated but no data found")
                    return metadata
            
            # If not inlined, deserialize data from binary
            if record.data:
                data = pickle.loads(record.data)
                self.logger.info(f"Retrieved data for stage '{stage_name}' with key: {record.storage_key}")
                return data
            else:
                self.logger.warning(f"No binary data stored for key {record.storage_key}")
                return metadata
            
        except Exception as e:
            self.logger.error(f"Error retrieving data from database: {str(e)}")
            if isinstance(e, KeyError):
                raise  # Re-raise KeyError for consistent behavior
            # For other errors, return None
            return None
        
    def list_available_data(self, filters: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """
        List available data in the database.
        
        Args:
            filters: Optional filters for data selection (stage_name, process_id, etc.)
            
        Returns:
            List of dictionaries with data summaries
        """
        try:
            import json
            
            filters = filters or {}
            
            # Start with base query
            query = self.session.query(self.IntermediateData)
            
            # Apply filters if provided
            if 'stage_name' in filters:
                query = query.filter_by(stage_name=filters['stage_name'])
            if 'process_id' in filters:
                query = query.filter_by(process_id=filters['process_id'])
            
            # Execute query
            records = query.all()
            
            # Format results
            result = []
            for record in records:
                # Parse metadata
                try:
                    metadata = json.loads(record.metadata) if record.metadata else {}
                except:
                    metadata = {}
                
                # Create summary
                summary = {
                    'storage_key': record.storage_key,
                    'process_id': record.process_id,
                    'stage_name': record.stage_name,
                    'timestamp': record.timestamp.isoformat() if record.timestamp else None,
                    'metadata': metadata
                }
                
                result.append(summary)
            
            return result
            
        except Exception as e:
            self.logger.error(f"Error listing data from database: {str(e)}")
            # Return empty list on error
            return []
        
    def cleanup(self, policy: Optional[str] = None) -> None:
        """
        Clean up stored data based on policy.
        
        Args:
            policy: Cleanup policy to apply ('keep_none', 'keep_latest', 'keep_all')
        """
        try:
            policy = policy or self.config.get('cleanup_policy', 'keep_latest')
            
            if policy == 'keep_none':
                # Delete all records
                self.session.query(self.IntermediateData).delete()
                self.session.commit()
                self.logger.info("Cleaned up all stored data (policy: keep_none)")
                
            elif policy == 'keep_latest':
                # For each stage_name and process_id combination, keep only the latest record
                
                # Get unique combinations of stage_name and process_id
                combinations = self.session.query(
                    self.IntermediateData.stage_name,
                    self.IntermediateData.process_id
                ).distinct().all()
                
                # For each combination, find the latest record ID
                latest_ids = []
                for stage_name, process_id in combinations:
                    latest = self.session.query(self.IntermediateData.id)\
                        .filter_by(stage_name=stage_name, process_id=process_id)\
                        .order_by(self.IntermediateData.timestamp.desc())\
                        .first()
                    
                    if latest:
                        latest_ids.append(latest[0])
                
                # Delete all records except the latest ones
                if latest_ids:
                    deleted = self.session.query(self.IntermediateData)\
                        .filter(~self.IntermediateData.id.in_(latest_ids))\
                        .delete(synchronize_session=False)
                    
                    self.session.commit()
                    self.logger.info(f"Cleaned up {deleted} records, keeping latest for each stage (policy: keep_latest)")
            
            elif policy != 'keep_all':
                self.logger.warning(f"Unknown cleanup policy: {policy}, no cleanup performed")
            
        except Exception as e:
            self.session.rollback()
            self.logger.error(f"Error during cleanup: {str(e)}")
    
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
        try:
            import json
            
            # Query for the record
            record = self.session.query(self.IntermediateData)\
                .filter_by(storage_key=storage_key)\
                .first()
            
            if not record:
                raise KeyError(f"No data found for storage key: {storage_key}")
            
            # Parse metadata
            try:
                metadata = json.loads(record.metadata) if record.metadata else {}
            except:
                metadata = {}
            
            # Create summary
            summary = {
                'storage_key': record.storage_key,
                'process_id': record.process_id,
                'stage_name': record.stage_name,
                'timestamp': record.timestamp.isoformat() if record.timestamp else None,
                'data_size': len(record.data) if record.data else 0,
                'metadata': metadata
            }
            
            return summary
            
        except Exception as e:
            self.logger.error(f"Error getting data summary: {str(e)}")
            if isinstance(e, KeyError):
                raise  # Re-raise KeyError for consistent behavior
            # For other errors, return an error message
            return {'error': str(e)}
        
    def disconnect(self) -> None:
        """
        Close the database connection.
        """
        if hasattr(self, 'session') and self.session:
            self.session.close()
        
        if hasattr(self, 'engine') and self.engine:
            self.engine.dispose()
            
        self.logger.info("Database connection closed")


class HybridDataContainer(BaseDataContainer):
    """
    Data container that selectively stores data in memory or persistent storage
    based on configuration and data characteristics.
    (Placeholder for future implementation)
    """
    
    def __init__(self, config: Dict[str, Any], project_name: str = 'base_data_project'):
        super().__init__(config=config, project_name=project_name)
        self.logger.warning("HybridDataContainer is not fully implemented yet. Falling back to memory storage.")
        
        # For now, just delegate to MemoryDataContainer
        raise NotImplementedError("Hybrid approach not implemented yet")
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