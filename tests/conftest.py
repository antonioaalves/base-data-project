# tests/conftest.py
import pytest
import os
import tempfile
import pandas as pd
from typing import Dict, Any

@pytest.fixture(scope="session")
def global_mock_config() -> Dict[str, Any]:
    """Global configuration for all tests"""
    return {
        'PROJECT_NAME': 'test_project',
        'log_level': 'INFO'
    }

@pytest.fixture
def temp_data_dir():
    """Create a temporary directory for test data"""
    with tempfile.TemporaryDirectory() as temp_dir:
        # Create subdirectories
        os.makedirs(os.path.join(temp_dir, "data", "csvs"), exist_ok=True)
        os.makedirs(os.path.join(temp_dir, "output"), exist_ok=True)
        os.makedirs(os.path.join(temp_dir, "logs"), exist_ok=True)
        
        yield temp_dir

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
def create_csv_files(temp_data_dir, sample_dataframes):
    """Create CSV files from sample DataFrames"""
    created_files = {}
    
    for name, df in sample_dataframes.items():
        file_path = os.path.join(temp_data_dir, "data", "csvs", f"{name}.csv")
        df.to_csv(file_path, index=False)
        created_files[name] = file_path
    
    return created_files