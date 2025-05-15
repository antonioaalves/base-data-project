"""Core utility functions for the base data project framework."""

import logging
from typing import Dict, Any, Tuple, Optional

def create_components(use_db: bool = False, 
                     no_tracking: bool = False, 
                     config: Optional[Dict[str, Any]] = None) -> Tuple[Any, Any]:
    """
    Create and configure system components based on arguments.
    
    Args:
        use_db: Whether to use database instead of CSV files
        no_tracking: Whether to disable process tracking
        config: Configuration dictionary
        
    Returns:
        Tuple of (data_manager, process_manager)
    """
    # Get logger
    logger = logging.getLogger(config.get('PROJECT_NAME', 'base_data_project') 
                              if config else 'base_data_project')
    
    # Import factories
    from base_data_project.data_manager.factory import DataManagerFactory
    
    # Use configuration if provided, otherwise use empty dict
    if config is None:
        config = {}
    
    # Determine data source type
    data_source_type = 'db' if use_db or config.get('use_db', False) else 'csv'

    # Create data manager through factory
    data_manager = DataManagerFactory.create_data_manager(
        data_source_type=data_source_type,
        config=config
    )

    # Create process manager if tracking is enabled
    process_manager = None
    if not no_tracking:
        try:
            # Import ProcessManager
            from base_data_project.process_management.manager import ProcessManager
            
            # Initialize with core data
            core_data = {
                "version": config.get("version", "1.0.0"),
                "config": config,
                "data_source_type": data_source_type,
                "use_db": use_db
            }
            process_manager = ProcessManager(core_data)
            
            # Log process manager creation
            logger.info("Process manager initialized.")
        except Exception as e:
            logger.error(f"Error initializing process manager: {str(e)}")
            logger.info("Continuing without process tracking")
            process_manager = None

    return data_manager, process_manager

def get_config_value(config: Dict[str, Any], key_path: str, default: Any = None) -> Any:
    """
    Get a value from a nested configuration dictionary using dot notation.
    
    Args:
        config: Configuration dictionary
        key_path: Path to the value using dot notation (e.g., 'database.connection.host')
        default: Default value to return if the key is not found
        
    Returns:
        The configuration value or the default
    """
    if not config:
        return default
        
    keys = key_path.split('.')
    value = config
    
    try:
        for key in keys:
            if isinstance(value, dict) and key in value:
                value = value[key]
            else:
                return default
        return value
    except Exception:
        return default

def merge_configs(base_config: Dict[str, Any], override_config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Recursively merge two configuration dictionaries.
    
    Args:
        base_config: Base configuration dictionary
        override_config: Override configuration dictionary
        
    Returns:
        Merged configuration dictionary
    """
    result = base_config.copy()
    
    for key, value in override_config.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            # Recursively merge nested dictionaries
            result[key] = merge_configs(result[key], value)
        else:
            # Override or add the value
            result[key] = value
            
    return result

def validate_config(config: Dict[str, Any], required_keys: Dict[str, Any]) -> Tuple[bool, Dict[str, str]]:
    """
    Validate a configuration dictionary against required keys and types.
    
    Args:
        config: Configuration dictionary to validate
        required_keys: Dictionary mapping required keys to expected types or validation functions
        
    Returns:
        Tuple of (is_valid, error_messages)
    """
    errors = {}
    
    for key_path, expected_type in required_keys.items():
        if '.' not in key_path:
            # Simple flat key
            if key_path not in config:
                errors[key_path] = f"Missing required key: {key_path}"
            else:
                value = config[key_path]
                
                # This is the critical fix:
                # Check if it's a validator function or a type
                if callable(expected_type) and not isinstance(expected_type, type):
                    # It's a custom validator function
                    if not expected_type(value):
                        errors[key_path] = f"Invalid value for key {key_path}: {value}"
                elif isinstance(expected_type, type) and not isinstance(value, expected_type):
                    # It's a type - use isinstance for type checking
                    errors[key_path] = f"Expected {expected_type.__name__} for key {key_path}, got {type(value).__name__}"
        else:
            # Nested key
            parts = key_path.split('.')
            current = config
            found = True
            
            for i, part in enumerate(parts):
                if not isinstance(current, dict) or part not in current:
                    errors[key_path] = f"Missing required key: {key_path}"
                    found = False
                    break
                
                if i == len(parts) - 1:
                    # Last part - validate the value
                    value = current[part]
                    
                    # Same fix for type checking:
                    if callable(expected_type) and not isinstance(expected_type, type):
                        # It's a custom validator function
                        if not expected_type(value):
                            errors[key_path] = f"Invalid value for key {key_path}: {value}"
                    elif isinstance(expected_type, type) and not isinstance(value, expected_type):
                        # It's a type - use isinstance for type checking
                        errors[key_path] = f"Expected {expected_type.__name__} for key {key_path}, got {type(value).__name__}"
                else:
                    # Not the last part - continue navigating
                    current = current[part]
    
    return len(errors) == 0, errors