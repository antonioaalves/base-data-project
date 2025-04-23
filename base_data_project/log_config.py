"""Logging configuration for the base data project framework."""

import logging
import sys
from datetime import datetime
import os
from typing import Optional

def setup_logger(project_name: str, 
                log_level: int = logging.INFO, 
                log_dir: Optional[str] = None,
                console_output: bool = True) -> logging.Logger:
    """
    Configure and return a logger instance with both file and console handlers.
    
    Args:
        project_name: Name of the project for the logger
        log_level: Logging level (default: INFO)
        log_dir: Directory to store log files (default: 'logs')
        console_output: Whether to output logs to console (default: True)
        
    Returns:
        Configured logger instance
    """
    # Use default log directory if not specified
    if log_dir is None:
        log_dir = 'logs'
    
    # Create logs directory if it doesn't exist
    if not os.path.exists(log_dir):
        os.makedirs(log_dir, exist_ok=True)
    
    # Generate log filename with timestamp
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_filename = os.path.join(log_dir, f'{project_name}_{timestamp}.log')
    
    # Create logger
    logger = logging.getLogger(project_name)
    logger.setLevel(log_level)
    
    # Remove existing handlers if any
    if logger.handlers:
        logger.handlers.clear()
    
    # Create formatters
    file_formatter = logging.Formatter(
        '%(asctime)s | %(levelname)8s | %(filename)s:%(lineno)d | %(message)s'
    )
    console_formatter = logging.Formatter(
        '%(asctime)s | %(levelname)8s | %(message)s'
    )
    
    # File handler
    file_handler = logging.FileHandler(log_filename)
    file_handler.setLevel(log_level)
    file_handler.setFormatter(file_formatter)
    logger.addHandler(file_handler)
    
    # Console handler
    if console_output:
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(log_level)
        console_handler.setFormatter(console_formatter)
        logger.addHandler(console_handler)
    
    logger.info(f'Logger initialized for {project_name}')
    return logger

def get_logger(project_name: str) -> logging.Logger:
    """
    Get an existing logger by project name or create a new one.
    
    Args:
        project_name: Name of the project for the logger
        
    Returns:
        Logger instance
    """
    logger = logging.getLogger(project_name)
    
    # If logger doesn't have handlers, set up a new one
    if not logger.handlers:
        return setup_logger(project_name)
        
    return logger

def configure_logging_from_config(config: dict) -> logging.Logger:
    """
    Configure logging based on configuration dictionary.
    
    Args:
        config: Configuration dictionary
        
    Returns:
        Configured logger instance
    """
    # Get project name from config
    project_name = config.get('PROJECT_NAME', 'base_data_project')
    
    # Get log configuration
    log_level_name = config.get('log_level', 'INFO')
    log_dir = config.get('log_dir', 'logs')
    log_format = config.get('log_format', '%(asctime)s | %(levelname)8s | %(filename)s:%(lineno)d | %(message)s')
    
    # Convert log level name to logging constant
    log_level = getattr(logging, log_level_name) if isinstance(log_level_name, str) else log_level_name
    
    # Configure logger
    logger = setup_logger(project_name, log_level, log_dir)
    
    # Update formatters if custom format specified
    if log_format:
        formatter = logging.Formatter(log_format)
        for handler in logger.handlers:
            handler.setFormatter(formatter)
    
    return logger