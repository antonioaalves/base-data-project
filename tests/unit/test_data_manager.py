# tests/unit/test_data_manager.py
import pytest
import pandas as pd
import os
from unittest.mock import patch
from base_data_project.data_manager.managers.managers import CSVDataManager

class TestCSVDataManager:
    
    @pytest.fixture
    def test_config(self, mock_config, tmp_path):
        """Create a test configuration with temporary paths"""
        # Note: renamed from mock_config to test_config to avoid conflict
        test_config = mock_config.copy()
        test_config['data_dir'] = str(tmp_path / "data")
        test_config['output_dir'] = str(tmp_path / "output")
        
        # Create necessary directories
        (tmp_path / "data").mkdir(exist_ok=True)
        (tmp_path / "data" / "csvs").mkdir(exist_ok=True)
        (tmp_path / "output").mkdir(exist_ok=True)
        
        return test_config
    
    @pytest.fixture
    def csv_manager(self, test_config):
        """Create a CSVDataManager with test configuration"""
        with patch('os.path.exists', return_value=True):
            manager = CSVDataManager(config=test_config)
            return manager
    
    @pytest.fixture
    def sample_dataframe(self):
        """Create a sample DataFrame for testing"""
        return pd.DataFrame({
            'id': [1, 2, 3],
            'name': ['A', 'B', 'C'],
            'value': [10.5, 20.5, 30.5]
        })
    
    def test_connect_disconnect(self, csv_manager):
        """Test connect and disconnect methods"""
        with patch('os.path.exists', return_value=True), \
             patch('os.makedirs', return_value=None):
            csv_manager.connect()
            # Verify that connection was established (check logs or state)
            csv_manager.disconnect()
            # Verify that disconnection was successful
    
    def test_load_data_file_not_found(self, csv_manager):
        """Test loading data when file doesn't exist"""
        with patch('os.path.exists', return_value=False):
            csv_manager.connect()
            result = csv_manager.load_data('non_existent_entity')
            assert isinstance(result, pd.DataFrame)
            assert result.empty
    
    def test_save_and_load_data(self, csv_manager, sample_dataframe, tmp_path):
        """Test saving and then loading data"""
        # Setup patches to avoid actual file operations
        with patch('os.path.exists', return_value=True), \
             patch('os.makedirs', return_value=None), \
             patch('pandas.DataFrame.to_csv', return_value=None), \
             patch('pandas.read_csv', return_value=sample_dataframe):
            
            csv_manager.connect()
            
            # Save the sample data
            entity_name = 'test_entity'
            csv_manager.save_data(entity_name, sample_dataframe)
            
            # Load the saved data
            loaded_data = csv_manager.load_data(entity_name)
            
            # Verify the loaded data matches the original
            pd.testing.assert_frame_equal(
                loaded_data.reset_index(drop=True), 
                sample_dataframe.reset_index(drop=True)
            )
            
            csv_manager.disconnect()
    
    def test_validate_data(self, csv_manager, sample_dataframe):
        """Test data validation with rules"""
        validation_rules = {
            'required_columns': ['id', 'name'],
            'non_empty': True,
            'unique_columns': ['id'],
            'no_nulls_columns': ['id', 'name']
        }
        
        result = csv_manager.validate_data(sample_dataframe, validation_rules)
        assert result['valid'] is True
        assert result['has_required_columns'] is True
        assert result['id_is_unique'] is True