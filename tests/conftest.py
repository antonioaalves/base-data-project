# tests/conftest.py
import pytest
import os
import tempfile
import pandas as pd
import logging
from typing import Dict, Any
from pathlib import Path
import sys
from unittest.mock import patch, MagicMock

# Add project root to sys.path
sys.path.insert(0, str(Path(__file__).parent.parent))

# Suppress logging during tests
logging.basicConfig(level=logging.ERROR)

# Fix for the internal pytest error with bestrelpath
def pytest_configure(config):
    import _pytest.pathlib
    original_bestrelpath = _pytest.pathlib.bestrelpath
    
    def patched_bestrelpath(directory, path):
        try:
            return original_bestrelpath(directory, path)
        except AssertionError:
            return str(path)
    
    _pytest.pathlib.bestrelpath = patched_bestrelpath

@pytest.fixture
def mock_config():
    """Basic configuration for testing"""
    return {
        'PROJECT_NAME': 'test_project',
        'data_dir': 'test_data',
        'output_dir': 'test_output',
        'log_dir': 'test_logs',
        'log_level': 'ERROR',
        'use_db': False,
        'dummy_data_filepaths': {
            'test_entity': 'test_data/csvs/test_entity.csv'
        }
    }

@pytest.fixture
def temp_dir():
    """Create a temporary directory for test data"""
    with tempfile.TemporaryDirectory() as temp_dir:
        yield temp_dir

@pytest.fixture
def prepared_temp_dir(temp_dir):
    """Create a temporary directory with standard project structure"""
    os.makedirs(os.path.join(temp_dir, "data", "csvs"), exist_ok=True)
    os.makedirs(os.path.join(temp_dir, "output"), exist_ok=True)
    os.makedirs(os.path.join(temp_dir, "logs"), exist_ok=True)
    return temp_dir

@pytest.fixture
def sample_dataframe():
    """Create a sample DataFrame for testing"""
    return pd.DataFrame({
        'id': [1, 2, 3],
        'name': ['A', 'B', 'C'],
        'value': [10.5, 20.5, 30.5]
    })

@pytest.fixture
def sample_dataframes():
    """Create sample DataFrames for testing"""
    return {
        'employees': pd.DataFrame({
            'ID': [1, 2, 3],
            'NAME': ['John', 'Jane', 'Bob'],
            'CAPACITY_CONTRIBUTION': [1.0, 0.8, 1.2]
        }),
        'production_lines': pd.DataFrame({
            'ID': [101, 102, 103],
            'NAME': ['Line A', 'Line B', 'Line C'],
            'NECESSITY': [2, 1, 3]
        }),
        'employee_production_lines': pd.DataFrame({
            'EMPLOYEE_ID': [1, 1, 2, 3, 3],
            'PRODUCTION_LINE_ID': [101, 102, 102, 101, 103]
        })
    }

@pytest.fixture
def mock_csv_data_manager(mock_config):
    """Create a mocked CSVDataManager"""
    from base_data_project.data_manager.managers.managers import CSVDataManager
    
    with patch('os.path.exists', return_value=True), \
         patch('os.makedirs', return_value=None):
        
        manager = MagicMock(spec=CSVDataManager)
        manager.config = mock_config
        manager.connect.return_value = None
        manager.disconnect.return_value = None
        
        # Set up the load_data and save_data methods with reasonable defaults
        def mock_load_data(entity, **kwargs):
            if entity == 'test_entity':
                return pd.DataFrame({'id': [1, 2, 3], 'value': [10, 20, 30]})
            return pd.DataFrame()
            
        def mock_save_data(entity, data, **kwargs):
            return f"test_output/{entity}.csv"
            
        manager.load_data.side_effect = mock_load_data
        manager.save_data.side_effect = mock_save_data
        
        return manager

@pytest.fixture
def mock_process_manager():
    """Create a mocked ProcessManager"""
    from base_data_project.process_management.manager import ProcessManager
    
    manager = MagicMock(spec=ProcessManager)
    manager.current_decisions = {}
    
    # Set up behavior for make_decisions method
    def mock_make_decisions(stage, decision_values, apply_defaults=True):
        manager.current_decisions[stage] = decision_values
        
    manager.make_decisions.side_effect = mock_make_decisions
    
    return manager

# Reset the AlgorithmFactory between tests
@pytest.fixture(autouse=True)
def reset_algorithm_factory():
    """Reset the AlgorithmFactory between tests"""
    from base_data_project.algorithms.factory import AlgorithmFactory
    
    # Store the original state
    original_algorithms = AlgorithmFactory._registered_algorithms.copy()
    
    # Run the test
    yield
    
    # Restore the original state
    AlgorithmFactory._registered_algorithms = original_algorithms