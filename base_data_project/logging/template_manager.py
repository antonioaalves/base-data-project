"""Message template manager for CSV-based template loading and rendering."""

import os
import pandas as pd
import logging
from typing import Dict, Any, List, Optional
import re

from base_data_project.log_config import get_logger

class MessageTemplateManager:
    """
    Manages message templates loaded from CSV files with parameter substitution.
    
    Handles Spanish language templates with {1}, {2}, {3} parameter format.
    """
    
    def __init__(self, config: Dict[str, Any], project_name: str = 'base_data_project'):
        """
        Initialize template manager with project configuration.
        
        Args:
            config: Project configuration dictionary
            project_name: Project name for logging
        """
        self.config = config
        self.project_name = project_name
        self.logger = get_logger(project_name)
        
        # Template storage
        self.templates: Dict[str, str] = {}
        self.templates_loaded = False
        
        # Load templates on initialization
        self._load_templates()
    
    def _load_templates(self) -> None:
        """
        Load templates from CSV file using pandas.
        
        CSV Format:
        - Separator: semicolon (;)
        - Columns: VAR, ES
        - Example: iniProc;"Iniciar proceso {1} - reintentar: {2}"
        
        Error Handling:
        - File not found → log warning, continue with empty templates
        - Parse errors → log warning, skip malformed rows
        - Missing columns → log error, disable template functionality
        """
        try:
            # Get template file path from config
            template_path = self.config.get('logging', {}).get('df_messages_path', 'data/csvs/messages.csv')
            
            # Check if file exists
            if not os.path.exists(template_path):
                self.logger.warning(f"Template file not found: {template_path}. Continuing with empty templates.")
                return
            
            # Load CSV with semicolon separator
            self.logger.info(f"Loading message templates from: {template_path}")
            df = pd.read_csv(template_path, sep=';', dtype=str)
            
            # Validate required columns
            required_columns = ['VAR', 'ES']
            missing_columns = [col for col in required_columns if col not in df.columns]
            
            if missing_columns:
                self.logger.error(f"Missing required columns in template file: {missing_columns}. Template functionality disabled.")
                return
            
            # Process templates
            template_count = 0
            error_count = 0
            
            for index, row in df.iterrows():
                try:
                    var_key = row['VAR']
                    es_template = row['ES']
                    
                    # Skip rows with missing data
                    if pd.isna(var_key) or pd.isna(es_template):
                        self.logger.warning(f"Skipping row {index + 1}: missing VAR or ES value")
                        error_count += 1
                        continue
                    
                    # Clean and store template
                    var_key = str(var_key).strip()
                    es_template = str(es_template).strip()
                    
                    if var_key and es_template:
                        self.templates[var_key] = es_template
                        template_count += 1
                    else:
                        self.logger.warning(f"Skipping row {index + 1}: empty VAR or ES after cleaning")
                        error_count += 1
                        
                except Exception as e:
                    self.logger.warning(f"Error processing row {index + 1}: {str(e)}")
                    error_count += 1
                    continue
            
            self.templates_loaded = True
            self.logger.info(f"Successfully loaded {template_count} templates ({error_count} errors)")
            
            # Log some examples for debugging
            if template_count > 0:
                sample_keys = list(self.templates.keys())[:3]  # First 3 templates
                self.logger.debug(f"Sample templates loaded: {sample_keys}")
            
        except Exception as e:
            self.logger.error(f"Failed to load templates from {template_path}: {str(e)}")
            self.templates_loaded = False
    
    def render(self, message_key: str, params: Optional[List[Any]] = None) -> str:
        """
        Render template with parameter substitution.
        
        Parameter Format: {1}, {2}, {3}, etc.
        
        Args:
            message_key: Template key (e.g., 'iniProc', 'errCallSubProc')
            params: List of parameters for substitution
        
        Returns:
            Rendered message string
        
        Error Handling:
        - Missing template → return "[MISSING_TEMPLATE:{key}]"
        - Parameter mismatch → use template as-is, log warning
        - Render exceptions → return "[RENDER_ERROR:{key}] {template}"
        """
        params = params or []
        
        # Check if template exists
        if message_key not in self.templates:
            error_msg = f"[MISSING_TEMPLATE:{message_key}]"
            self.logger.warning(f"Template not found: {message_key}")
            return error_msg
        
        template = self.templates[message_key]
        
        try:
            # Find all parameter placeholders in template
            placeholders = re.findall(r'\{(\d+)\}', template)
            
            if placeholders:
                # Get the highest parameter number
                max_param_num = max(int(p) for p in placeholders)
                
                # Check if we have enough parameters
                if len(params) < max_param_num:
                    self.logger.warning(
                        f"Template '{message_key}' expects {max_param_num} parameters, "
                        f"but only {len(params)} provided. Using template as-is."
                    )
                    return template
                
                # Replace parameters {1}, {2}, {3}, etc.
                rendered = template
                for i, param in enumerate(params, 1):
                    placeholder = f"{{{i}}}"
                    if placeholder in rendered:
                        rendered = rendered.replace(placeholder, str(param))
                
                return rendered
            else:
                # No parameters in template, return as-is
                return template
                
        except Exception as e:
            error_msg = f"[RENDER_ERROR:{message_key}] {template}"
            self.logger.error(f"Error rendering template '{message_key}': {str(e)}")
            return error_msg
    
    def validate_templates(self) -> Dict[str, List[str]]:
        """
        Validate loaded templates for debugging and health checking.
        
        Returns:
            Dictionary with validation results:
            - 'valid': List of valid template keys
            - 'invalid': List of invalid template keys with reasons
            - 'warnings': List of warnings about templates
        """
        result = {
            'valid': [],
            'invalid': [],
            'warnings': []
        }
        
        if not self.templates_loaded:
            result['warnings'].append("Templates not loaded successfully")
            return result
        
        for key, template in self.templates.items():
            try:
                # Check for basic template validity
                if not template or template.isspace():
                    result['invalid'].append(f"{key}: Empty template")
                    continue
                
                # Check for parameter syntax
                placeholders = re.findall(r'\{(\d+)\}', template)
                
                if placeholders:
                    # Check for sequential numbering
                    param_numbers = sorted([int(p) for p in placeholders])
                    expected_sequence = list(range(1, len(param_numbers) + 1))
                    
                    if param_numbers != expected_sequence:
                        result['warnings'].append(
                            f"{key}: Non-sequential parameters {param_numbers}, "
                            f"expected {expected_sequence}"
                        )
                
                result['valid'].append(key)
                
            except Exception as e:
                result['invalid'].append(f"{key}: Validation error - {str(e)}")
        
        return result
    
    def get_template(self, message_key: str) -> Optional[str]:
        """
        Get raw template without rendering.
        
        Args:
            message_key: Template key
            
        Returns:
            Raw template string or None if not found
        """
        return self.templates.get(message_key)
    
    def get_all_templates(self) -> Dict[str, str]:
        """
        Get all loaded templates.
        
        Returns:
            Dictionary of all templates
        """
        return self.templates.copy()
    
    def is_loaded(self) -> bool:
        """
        Check if templates were loaded successfully.
        
        Returns:
            True if templates are loaded, False otherwise
        """
        return self.templates_loaded
    
    def reload_templates(self) -> None:
        """
        Reload templates from the CSV file.
        
        Useful for runtime template updates.
        """
        self.templates.clear()
        self.templates_loaded = False
        self._load_templates()