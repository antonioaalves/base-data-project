"""Path helper functions for the base data project framework."""

import os
from pathlib import Path
from typing import Optional, Union, List

def get_project_root() -> Path:
    """
    Get the project root directory.
    
    The project root is determined in the following order:
    1. The directory containing a main.py file
    2. The current working directory
    
    Returns:
        Path object representing the project root
    """
    # Start with current directory
    current_dir = Path.cwd()
    
    # Look for main.py or config.py in parent directories
    for parent in [current_dir] + list(current_dir.parents):
        if (parent / 'main.py').exists() or (parent / 'src' / 'config.py').exists():
            return parent
    
    # If not found, return current directory
    return current_dir

def get_data_path(filename: Optional[str] = None) -> Union[str, Path]:
    """
    Get path to the data directory or a specific file within it.
    
    Args:
        filename: Optional filename to append to the data path
        
    Returns:
        Path to the data directory or file
    """
    root_dir = get_project_root()
    data_dir = root_dir / 'data'
    
    # Create directory if it doesn't exist
    os.makedirs(data_dir, exist_ok=True)
    
    if filename:
        return os.path.join(data_dir, filename)
    return data_dir

def get_output_path(filename: Optional[str] = None) -> Union[str, Path]:
    """
    Get path to the output directory or a specific file within it.
    
    Args:
        filename: Optional filename to append to the output path
        
    Returns:
        Path to the output directory or file
    """
    root_dir = get_project_root()
    output_dir = root_dir / 'data' / 'output'
    
    # Create directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    if filename:
        return os.path.join(output_dir, filename)
    return output_dir

def get_log_path(filename: Optional[str] = None) -> Union[str, Path]:
    """
    Get path to the logs directory or a specific log file.
    
    Args:
        filename: Optional filename to append to the logs path
        
    Returns:
        Path to the logs directory or file
    """
    root_dir = get_project_root()
    log_dir = root_dir / 'logs'
    
    # Create directory if it doesn't exist
    os.makedirs(log_dir, exist_ok=True)
    
    if filename:
        return os.path.join(log_dir, filename)
    return log_dir

def get_config_path() -> Path:
    """
    Get path to the config.py file.
    
    Returns:
        Path to the config.py file
    """
    root_dir = get_project_root()
    
    # Check for config.py in src directory
    config_path = root_dir / 'src' / 'config.py'
    if config_path.exists():
        return config_path
    
    # Check for config.py in root directory
    config_path = root_dir / 'config.py'
    if config_path.exists():
        return config_path
    
    # Default to src/config.py even if it doesn't exist yet
    return root_dir / 'src' / 'config.py'

def get_csv_path(csv_name: str, config: Optional[dict] = None) -> Union[str, Path]:
    """
    Get path to a specific CSV file.
    
    Args:
        csv_name: Name of the CSV file (without extension)
        config: Optional configuration dictionary
        
    Returns:
        Path to the CSV file
    """
    if config and 'dummy_data_filepaths' in config and csv_name in config['dummy_data_filepaths']:
        return config['dummy_data_filepaths'][csv_name]
    
    root_dir = get_project_root()
    return os.path.join(root_dir, 'data', 'csvs', f"{csv_name}.csv")

def ensure_directories(directories: List[str]) -> None:
    """
    Ensure that multiple directories exist, creating them if necessary.
    
    Args:
        directories: List of directory paths
    """
    for directory in directories:
        os.makedirs(directory, exist_ok=True)

def get_template_path(template_name: Optional[str] = None) -> Path:
    """
    Get path to a template directory or file.
    
    Args:
        template_name: Optional template name
        
    Returns:
        Path to the template directory or file
    """
    import pkg_resources
    
    templates_dir = pkg_resources.resource_filename('base_data_project', 'templates')
    
    if template_name:
        return Path(os.path.join(templates_dir, template_name))
    return Path(templates_dir)