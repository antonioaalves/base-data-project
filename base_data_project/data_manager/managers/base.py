"""Base data manager class to define the interface for all data managers."""

import os
import pandas as pd
import logging
from typing import Dict, Any, List, Optional, Union
from abc import ABC, abstractmethod

class BaseDataManager(ABC):
    """
    Abstract base class for data management operations.
    
    This class defines the interface that all data managers must implement,
    with concrete implementations for common functionality like validation
    and context management.
    """

    def __init__(self, config: Dict[str, Any]) -> None:
        """
        Initialize the data manager.
        
        Args:
            config: Configuration dictionary with connection and path information
        """
        self.config = config
        
        # Get project name from config or use default
        project_name = config.get('PROJECT_NAME', 'base_data_project')
        self.logger = logging.getLogger(project_name)
        
        self.logger.info("Initialized BaseDataManager")

    @abstractmethod
    def connect(self) -> None:
        """
        Establish connection to the data source.
        
        Must be implemented by concrete classes.
        """
        pass

    @abstractmethod 
    def disconnect(self) -> None:
        """
        Close connection to the data source.
        
        Must be implemented by concrete classes.
        """
        pass

    @abstractmethod
    def load_data(self, entity: str, **kwargs) -> pd.DataFrame:
        """
        Load data from a specific entity.
        
        Args:
            entity: The entity name/type to load
            **kwargs: Additional parameters for loading
            
        Returns: 
            DataFrame containing loaded data
        """
        pass

    @abstractmethod
    def save_data(self, entity: str, data: pd.DataFrame, **kwargs) -> None:
        """
        Save data for a specific entity.
        
        Args:
            entity: The entity name/type to save
            data: DataFrame containing the data to save
            **kwargs: Additional parameters for saving
        """
        pass

    def validate_data(self, data: pd.DataFrame, validation_rules: Dict[str, Any]) -> Dict[str, bool]:
        """
        Validate data against specified rules.
        
        Args:
            data: DataFrame to validate
            validation_rules: Dictionary of validation rules
            
        Returns:
            Dictionary with validation results
        """
        results = {}
        
        # Check for required columns
        if 'required_columns' in validation_rules:
            required_cols = validation_rules['required_columns']
            results['has_required_columns'] = all(col in data.columns for col in required_cols)
        
        # Check for non-empty data
        if 'non_empty' in validation_rules and validation_rules['non_empty']:
            results['non_empty'] = len(data) > 0
        
        # Check for unique identifiers
        if 'unique_columns' in validation_rules:
            for col in validation_rules['unique_columns']:
                if col in data.columns:
                    results[f'{col}_is_unique'] = data[col].is_unique
        
        # Check for no missing values in required fields
        if 'no_nulls_columns' in validation_rules:
            for col in validation_rules['no_nulls_columns']:
                if col in data.columns:
                    results[f'{col}_has_no_nulls'] = not data[col].isnull().any()
        
        # Check for value ranges
        if 'value_ranges' in validation_rules:
            for col, range_info in validation_rules['value_ranges'].items():
                if col in data.columns:
                    min_val = range_info.get('min')
                    max_val = range_info.get('max')
                    
                    if min_val is not None:
                        results[f'{col}_min_valid'] = (data[col] >= min_val).all()
                        
                    if max_val is not None:
                        results[f'{col}_max_valid'] = (data[col] <= max_val).all()
        
        # Check for allowed values
        if 'allowed_values' in validation_rules:
            for col, allowed in validation_rules['allowed_values'].items():
                if col in data.columns:
                    results[f'{col}_has_allowed_values'] = data[col].isin(allowed).all()
        
        # Overall validation result
        results['valid'] = all(result for result in results.values())
        
        return results
    
    def __enter__(self):
        """Context manager entry with connection"""
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit with disconnection"""
        self.disconnect()
        if exc_type is not None:
            self.logger.error(f"Error in data manager: {str(exc_val)}")
            return False  # re-raise the exception