"""Factory functions and module initialization for hybrid logging system."""

# base_data_project/logging/__init__.py

"""
Hybrid logging system for base_data_project framework.

Provides template-based structured logging with database integration
and backward-compatible file logging.
"""

from typing import Optional
import logging

from base_data_project.data_manager.managers.base import BaseDataManager
from base_data_project.logging.hybrid_manager import HybridLogManager
from base_data_project.logging.template_manager import MessageTemplateManager
from base_data_project.log_config import get_logger as get_file_logger

def get_hybrid_logger(project_name: str, data_manager: BaseDataManager) -> HybridLogManager:
    """
    Factory function for easy hybrid logger creation.
    
    This is the main entry point for creating hybrid loggers in projects.
    
    Args:
        project_name: Name of the project (e.g., 'algorithm_GD')
        data_manager: Data manager instance (should support database operations)
        
    Returns:
        Configured HybridLogManager instance
        
    Example:
        ```python
        from base_data_project.data_manager.factory import DataManagerFactory
        from base_data_project.logging import get_hybrid_logger
        
        # Create data manager
        data_manager = DataManagerFactory.create_data_manager('db', config)
        
        # Create hybrid logger
        logger = get_hybrid_logger('algorithm_GD', data_manager)
        
        # Use template-based logging
        logger.log_template('iniProc', [123, 2])
        
        # Use traditional logging (backward compatibility)
        logger.info("Traditional log message")
        ```
    """
    return HybridLogManager(data_manager, project_name)

def get_logger(project_name: str) -> logging.Logger:
    """
    Get traditional file logger - maintains backward compatibility.
    
    This function preserves the existing interface for projects that
    don't need hybrid logging functionality.
    
    Args:
        project_name: Name of the project for the logger
        
    Returns:
        Standard Python Logger instance
    """
    return get_file_logger(project_name)

def create_template_manager(config: dict, project_name: str = 'base_data_project') -> MessageTemplateManager:
    """
    Factory function for creating standalone template managers.
    
    Useful for projects that only need template rendering without database logging.
    
    Args:
        config: Project configuration dictionary
        project_name: Project name for logging
        
    Returns:
        Configured MessageTemplateManager instance
    """
    return MessageTemplateManager(config, project_name)

# Quick setup function for algorithm_GD
def setup_algorithm_gd_logging(config: dict, environment: str = 'local') -> HybridLogManager:
    """
    Quick setup function specifically for algorithm_GD project.
    
    Args:
        config: Project configuration with external_call_data
        environment: 'local' or 'server'
        
    Returns:
        Configured HybridLogManager for algorithm_GD
        
    Example:
        ```python
        from base_data_project.logging import setup_algorithm_gd_logging
        
        # Quick setup for development
        logger = setup_algorithm_gd_logging(config, 'local')
        logger.log_template('iniProc', [process_id, retry_count])
        ```
    """
    from base_data_project.data_manager.factory import DataManagerFactory
    from base_data_project.utils import merge_configs
    
    # Create environment-specific config
    env_config = {
        'logging': {
            'environment': environment,
            'db_logging_enabled': environment == 'server',
            'df_messages_path': 'data/csvs/messages.csv'
        }
    }
    
    # Merge configurations
    merged_config = merge_configs(config, env_config)
    
    # Create appropriate data manager
    data_source_type = 'db' if environment == 'server' else 'csv'
    data_manager = DataManagerFactory.create_data_manager(
        data_source_type=data_source_type,
        config=merged_config,
        project_name='algorithm_GD'
    )
    
    # Create hybrid logger
    return HybridLogManager(data_manager, 'algorithm_GD')

# Validation helper
def validate_logging_config(config: dict) -> tuple[bool, list[str]]:
    """
    Validate logging configuration for common issues.
    
    Args:
        config: Configuration dictionary to validate
        
    Returns:
        Tuple of (is_valid, list_of_errors)
    """
    errors = []
    
    # Check basic logging config
    logging_config = config.get('logging', {})
    
    if not logging_config:
        errors.append("Missing 'logging' section in configuration")
        return False, errors
    
    # Check environment
    environment = logging_config.get('environment')
    if environment not in ['local', 'server']:
        errors.append(f"Invalid environment '{environment}', must be 'local' or 'server'")
    
    # Check template path
    template_path = logging_config.get('df_messages_path')
    if not template_path:
        errors.append("Missing 'df_messages_path' in logging configuration")
    
    # Check database logging config for server environment
    if environment == 'server':
        db_enabled = logging_config.get('db_logging_enabled', True)
        
        if db_enabled:
            external_data = config.get('external_call_data', {})
            
            if not external_data:
                errors.append("Missing 'external_call_data' for server environment")
            else:
                required_fields = ['current_process_id', 'wfm_user']
                for field in required_fields:
                    if not external_data.get(field):
                        errors.append(f"Missing required field '{field}' in external_call_data")
    
    return len(errors) == 0, errors

# Export main classes and functions
__all__ = [
    'HybridLogManager',
    'MessageTemplateManager', 
    'get_hybrid_logger',
    'get_logger',
    'create_template_manager',
    'setup_algorithm_gd_logging',
    'validate_logging_config'
]