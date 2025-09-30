"""Logging configuration for the base data project framework."""

import logging
import sys
from datetime import datetime
import os
from typing import Optional, Dict

# Global logger registry
_loggers: Dict[str, logging.Logger] = {}

def setup_logger(project_name: str, 
                log_level: int = logging.INFO, 
                log_dir: Optional[str] = None,
                console_output: bool = True) -> logging.Logger:
    """
    Configure and return a logger instance with both file and console handlers.
    If a logger with the given project_name already exists, return that instead.
    
    Args:
        project_name: Name of the project for the logger
        log_level: Logging level (default: INFO)
        log_dir: Directory to store log files (default: 'logs')
        console_output: Whether to output logs to console (default: True)
        
    Returns:
        Configured logger instance
    """
    # Check if logger already exists
    if project_name in _loggers:
        return _loggers[project_name]
    
    # Use default log directory if not specified
    if log_dir is None:
        log_dir = 'logs'
    
    # Create logs directory if it doesn't exist
    if not os.path.exists(log_dir):
        os.makedirs(log_dir, exist_ok=True)

    datetime_str = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    # Generate log filename WITH timestamp to reuse the same file
    log_filename = os.path.join(log_dir, f'{project_name}_{datetime_str}.log')
    
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
    
    # Store in registry
    _loggers[project_name] = logger
    
    logger.info(f'Logger initialized for {project_name}')
    return logger

def get_logger(project_name: str, data_manager=None, config=None) -> logging.Logger:
    """
    Get logger instance - now supports enhanced logging when data_manager provided.
    
    Args:
        project_name: Name of the project for the logger
        data_manager: Optional data manager for database logging
        config: Optional configuration for enhanced features
        
    Returns:
        Enhanced logger if data_manager provided, regular logger otherwise
    """
    # Create regular file logger (existing functionality)
    file_logger = setup_logger(project_name)
    
    # If data_manager provided, wrap with enhanced logger
    if data_manager:
        return EnhancedLogger(file_logger, data_manager, config)
    
    # Otherwise return regular logger (existing behavior)
    return file_logger

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


class EnhancedLogger:
    """
    Enhanced logger that adds template-based database logging to existing file logger.
    Wraps the existing logger and adds new functionality without breaking existing code.
    """
    
    def __init__(self, file_logger, data_manager=None, config=None):
        """
        Initialize enhanced logger.
        
        Args:
            file_logger: Existing file logger instance
            data_manager: Optional data manager for database logging
            config: Configuration for template loading
        """
        self.file_logger = file_logger
        self.data_manager = data_manager
        self.config = config or {}
        self.templates = {}
        self.db_logging_enabled = False
        
        # Load templates and setup database logging if data_manager provided
        if data_manager and hasattr(data_manager, 'set_process_errors'):
            self._load_templates()
            self._setup_database_logging()
    
    def _load_templates(self):
        """Load message templates from CSV file."""
        try:
            import pandas as pd
            import os
            
            template_path = self.config.get('logging', {}).get('df_messages_path', 'data/csvs/messages.csv')
            
            if os.path.exists(template_path):
                df = pd.read_csv(template_path, sep=';', dtype=str)
                
                if 'VAR' in df.columns and 'ES' in df.columns:
                    for _, row in df.iterrows():
                        if pd.notna(row['VAR']) and pd.notna(row['ES']):
                            self.templates[str(row['VAR']).strip()] = str(row['ES']).strip()
                    
                    self.file_logger.info(f"Loaded {len(self.templates)} message templates")
                else:
                    self.file_logger.warning(f"Template file missing required columns: {template_path}")
            else:
                self.file_logger.info(f"Template file not found: {template_path}")
                
        except Exception as e:
            self.file_logger.error(f"Error loading templates: {str(e)}")
    
    def _setup_database_logging(self):
        """Setup database logging if configuration allows."""
        logging_config = self.config.get('logging', {})
        environment = logging_config.get('environment', 'local')
        db_enabled = logging_config.get('db_logging_enabled', True)
        external_data = self.config.get('external_call_data', {})
        
        self.db_logging_enabled = (
            environment == 'server' and 
            db_enabled and 
            external_data.get('current_process_id') is not None
        )
        
        self.file_logger.info(f"Database logging: {'enabled' if self.db_logging_enabled else 'disabled'}")
    
    def _render_template(self, message_key, params=None):
        """Render template with parameters."""
        if message_key not in self.templates:
            return f"[MISSING_TEMPLATE:{message_key}]"
        
        template = self.templates[message_key]
        if not params:
            return template
        
        try:
            import re
            rendered = template
            for i, param in enumerate(params, 1):
                placeholder = f"{{{i}}}"
                if placeholder in rendered:
                    rendered = rendered.replace(placeholder, str(param))
            return rendered
        except Exception as e:
            self.file_logger.error(f"Template rendering error: {str(e)}")
            return template
    
    def log_template(self, message_key, params=None, level='INFO'):
        """
        NEW METHOD: Template-based logging with database integration.
        
        Args:
            message_key: Template key (e.g., 'iniProc', 'errCallSubProc')
            params: List of parameters for template substitution
            level: Log level ('INFO', 'ERROR', 'WARNING')
        """
        # Render template
        rendered_message = self._render_template(message_key, params or [])
        
        # Try database logging if enabled
        db_success = False
        if self.db_logging_enabled and self.data_manager:
            try:
                db_success = self.data_manager.set_process_errors(
                    message_key=message_key,
                    rendered_message=rendered_message,
                    error_type=level.upper()
                )
            except Exception as e:
                self.file_logger.error(f"Database logging failed: {str(e)}")
        
        # File logging (always happens)
        file_message = f"[{message_key}] {rendered_message}"
        if self.db_logging_enabled and not db_success:
            file_message = f"[DB_FALLBACK] {file_message}"
        
        # Route to appropriate log level
        if level.upper() == 'ERROR':
            self.file_logger.error(file_message)
        elif level.upper() == 'WARNING':
            self.file_logger.warning(file_message)
        else:
            self.file_logger.info(file_message)
    
    # Delegate all existing logger methods (backward compatibility)
    def info(self, message):
        """Existing method - no change."""
        self.file_logger.info(message)
    
    def error(self, message):
        """Existing method - no change."""
        self.file_logger.error(message)
    
    def warning(self, message):
        """Existing method - no change."""
        self.file_logger.warning(message)
    
    def debug(self, message):
        """Existing method - no change."""
        self.file_logger.debug(message)
    
    def critical(self, message):
        """Existing method - no change."""
        self.file_logger.critical(message)