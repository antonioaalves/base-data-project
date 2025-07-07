"""Hybrid log manager for template-based database and file logging."""

import logging
from typing import Dict, Any, List, Optional

from base_data_project.data_manager.managers.base import BaseDataManager
from base_data_project.log_config import get_logger
from base_data_project.logging.template_manager import MessageTemplateManager

class HybridLogManager:
    """
    Hybrid logging manager that provides both template-based structured logging
    and backward-compatible file logging.
    
    Features:
    - Template-based logging with database storage
    - Environment-aware routing (server vs local)
    - Automatic fallback to file logging on database failures
    - Full backward compatibility with existing logging calls
    """
    
    def __init__(self, data_manager: BaseDataManager, project_name: str = 'base_data_project'):
        """
        Initialize hybrid logger with data manager and project context.
        
        Args:
            data_manager: Data manager instance for database logging
            project_name: Project name for logging context
        """
        self.data_manager = data_manager
        self.project_name = project_name
        
        # Get configuration from data manager
        self.config = getattr(data_manager, 'config', {})
        
        # Initialize components
        self.file_logger = get_logger(project_name)
        self.template_manager = MessageTemplateManager(self.config, project_name)
        
        # Get logging configuration
        self.logging_config = self.config.get('logging', {})
        self.environment = self.logging_config.get('environment', 'local')
        self.db_logging_enabled = self.logging_config.get('db_logging_enabled', True)
        self.server_file_logging = self.logging_config.get('server_file_logging', True)
        
        # Database logging availability
        self.db_logging_available = self._check_db_logging_availability()
        
        self.file_logger.info(f"HybridLogManager initialized for {project_name}")
        self.file_logger.info(f"Environment: {self.environment}, DB logging: {self.db_logging_available}")
        
        # Log template loading status
        if self.template_manager.is_loaded():
            template_count = len(self.template_manager.get_all_templates())
            self.file_logger.info(f"Loaded {template_count} message templates")
        else:
            self.file_logger.warning("No message templates loaded")
    
    def _check_db_logging_availability(self) -> bool:
        """
        Check if database logging is available and properly configured.
        
        Returns:
            True if database logging is available, False otherwise
        """
        if not self.db_logging_enabled:
            return False
        
        if self.environment == 'local':
            return False
        
        # Check if data manager supports database logging
        if not hasattr(self.data_manager, 'set_process_errors'):
            self.file_logger.warning("Data manager does not support set_process_errors method")
            return False
        
        # Check if external_call_data is configured
        external_data = self.config.get('external_call_data')
        if not external_data or not external_data.get('current_process_id'):
            self.file_logger.warning("external_call_data not properly configured for database logging")
            return False
        
        return True
    
    def log_template(self, message_key: str, params: Optional[List[Any]] = None, level: str = 'INFO') -> None:
        """
        Template-based structured logging with environment-aware routing.
        
        Args:
            message_key: Template key (e.g., 'iniProc', 'errCallSubProc')
            params: List of parameters for template substitution
            level: Log level ('INFO', 'ERROR', 'WARNING')
        
        Routing Logic:
        - Server environment: Database + File (if enabled)
        - Local environment: File only
        - Database failure: Automatic fallback to file with [DB_FALLBACK] prefix
        """
        params = params or []
        
        # Render the template
        rendered_message = self.template_manager.render(message_key, params)
        
        # Determine logging targets
        log_to_db = self.db_logging_available and self.environment == 'server'
        log_to_file = (self.environment == 'local' or 
                      (self.environment == 'server' and self.server_file_logging))
        
        # Database logging attempt
        db_success = False
        if log_to_db:
            try:
                db_success = self.data_manager.set_process_errors(
                    message_key=message_key,
                    rendered_message=rendered_message,
                    error_type=level.upper()
                )
                
                if db_success:
                    self.file_logger.debug(f"Successfully logged to database: {message_key}")
                else:
                    self.file_logger.warning(f"Database logging failed for: {message_key}")
                    
            except Exception as e:
                self.file_logger.error(f"Database logging exception for {message_key}: {str(e)}")
                db_success = False
        
        # File logging
        if log_to_file:
            # Add prefix if this is a database fallback
            if log_to_db and not db_success:
                file_message = f"[DB_FALLBACK] [{message_key}] {rendered_message}"
            else:
                file_message = f"[{message_key}] {rendered_message}"
            
            # Route to appropriate file log level
            self._log_to_file(file_message, level)
        
        # Fallback file logging if database failed and file logging was not enabled
        elif log_to_db and not db_success:
            fallback_message = f"[DB_FALLBACK] [{message_key}] {rendered_message}"
            self._log_to_file(fallback_message, level)
            self.file_logger.warning("Database logging failed, using file fallback")
    
    def _log_to_file(self, message: str, level: str) -> None:
        """
        Route message to appropriate file log level.
        
        Args:
            message: Message to log
            level: Log level ('INFO', 'ERROR', 'WARNING')
        """
        level_upper = level.upper()
        
        if level_upper == 'ERROR':
            self.file_logger.error(message)
        elif level_upper == 'WARNING':
            self.file_logger.warning(message)
        else:  # Default to INFO
            self.file_logger.info(message)
    
    # Backward Compatibility Methods
    def info(self, message: str) -> None:
        """
        Log info message to file logger.
        Maintains backward compatibility with existing code.
        
        Args:
            message: Message to log
        """
        self.file_logger.info(message)
    
    def error(self, message: str) -> None:
        """
        Log error message to file logger.
        Maintains backward compatibility with existing code.
        
        Args:
            message: Message to log
        """
        self.file_logger.error(message)
    
    def warning(self, message: str) -> None:
        """
        Log warning message to file logger.
        Maintains backward compatibility with existing code.
        
        Args:
            message: Message to log
        """
        self.file_logger.warning(message)
    
    def debug(self, message: str) -> None:
        """
        Log debug message to file logger.
        Maintains backward compatibility with existing code.
        
        Args:
            message: Message to log
        """
        self.file_logger.debug(message)
    
    # Utility Methods
    def get_template_status(self) -> Dict[str, Any]:
        """
        Get status information about loaded templates.
        
        Returns:
            Dictionary with template status information
        """
        validation_result = self.template_manager.validate_templates()
        
        return {
            'templates_loaded': self.template_manager.is_loaded(),
            'total_templates': len(self.template_manager.get_all_templates()),
            'valid_templates': len(validation_result['valid']),
            'invalid_templates': len(validation_result['invalid']),
            'warnings': len(validation_result['warnings']),
            'validation_details': validation_result
        }
    
    def get_logging_status(self) -> Dict[str, Any]:
        """
        Get current logging configuration and status.
        
        Returns:
            Dictionary with logging status information
        """
        return {
            'project_name': self.project_name,
            'environment': self.environment,
            'db_logging_enabled': self.db_logging_enabled,
            'db_logging_available': self.db_logging_available,
            'server_file_logging': self.server_file_logging,
            'template_manager_loaded': self.template_manager.is_loaded(),
            'external_call_data_configured': bool(self.config.get('external_call_data'))
        }
    
    def test_database_logging(self) -> bool:
        """
        Test database logging connectivity and functionality.
        
        Returns:
            True if database logging works, False otherwise
        """
        if not self.db_logging_available:
            self.file_logger.info("Database logging not available for testing")
            return False
        
        try:
            # Test with a simple message
            test_success = self.data_manager.set_process_errors(
                message_key='test_connectivity',
                rendered_message='Database logging connectivity test',
                error_type='INFO'
            )
            
            if test_success:
                self.file_logger.info("Database logging test successful")
                return True
            else:
                self.file_logger.warning("Database logging test failed")
                return False
                
        except Exception as e:
            self.file_logger.error(f"Database logging test exception: {str(e)}")
            return False
    
    def reload_templates(self) -> None:
        """
        Reload message templates from CSV file.
        
        Useful for runtime template updates.
        """
        self.file_logger.info("Reloading message templates")
        self.template_manager.reload_templates()
        
        if self.template_manager.is_loaded():
            template_count = len(self.template_manager.get_all_templates())
            self.file_logger.info(f"Reloaded {template_count} message templates")
        else:
            self.file_logger.warning("Template reload failed")
    
    def get_template(self, message_key: str) -> Optional[str]:
        """
        Get raw template without rendering.
        
        Args:
            message_key: Template key
            
        Returns:
            Raw template string or None if not found
        """
        return self.template_manager.get_template(message_key)
    
    def render_template(self, message_key: str, params: Optional[List[Any]] = None) -> str:
        """
        Render template without logging.
        
        Args:
            message_key: Template key
            params: Parameters for substitution
            
        Returns:
            Rendered message string
        """
        return self.template_manager.render(message_key, params or [])