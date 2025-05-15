# tests/unit/test_utils.py
import pytest
import os
from pathlib import Path
from base_data_project.utils import (
    create_components, 
    get_config_value, 
    merge_configs, 
    validate_config
)
from base_data_project.path_helpers import (
    get_project_root,
    get_data_path,
    get_output_path,
    get_log_path
)

class TestUtilFunctions:
    
    def test_create_components(self):
        """Test component creation with different configurations"""
        # Test with minimal config
        config = {'PROJECT_NAME': 'test_project'}
        data_manager, process_manager = create_components(
            use_db=False, 
            no_tracking=False,
            config=config
        )
        
        # Verify components were created
        assert data_manager is not None
        assert process_manager is not None
        
        # Test with no tracking
        data_manager, process_manager = create_components(
            use_db=False, 
            no_tracking=True,
            config=config
        )
        
        assert data_manager is not None
        assert process_manager is None
    
    def test_get_config_value(self):
        """Test retrieving values from nested configuration"""
        config = {
            'top_level': 'value',
            'nested': {
                'level1': {
                    'level2': 'nested_value'
                }
            },
            'list_value': [1, 2, 3]
        }
        
        # Test simple key
        assert get_config_value(config, 'top_level') == 'value'
        
        # Test nested key
        assert get_config_value(config, 'nested.level1.level2') == 'nested_value'
        
        # Test non-existent key
        assert get_config_value(config, 'does_not_exist', 'default') == 'default'
        
        # Test partially non-existent path
        assert get_config_value(config, 'nested.not_here', 'default') == 'default'
        
        # Test list value
        assert get_config_value(config, 'list_value') == [1, 2, 3]
    
    def test_merge_configs(self):
        """Test merging configuration dictionaries"""
        base_config = {
            'common': 'base_value',
            'base_only': 'only_in_base',
            'nested': {
                'key1': 'base_nested1',
                'key2': 'base_nested2'
            }
        }
        
        override_config = {
            'common': 'override_value',
            'override_only': 'only_in_override',
            'nested': {
                'key1': 'override_nested1',
                'key3': 'override_nested3'
            }
        }
        
        result = merge_configs(base_config, override_config)
        
        # Verify merged result
        assert result['common'] == 'override_value'  # Overridden
        assert result['base_only'] == 'only_in_base'  # Preserved from base
        assert result['override_only'] == 'only_in_override'  # Added from override
        
        # Verify nested merging
        assert result['nested']['key1'] == 'override_nested1'  # Overridden
        assert result['nested']['key2'] == 'base_nested2'  # Preserved from base
        assert result['nested']['key3'] == 'override_nested3'  # Added from override
    
    def test_validate_config(self):
        """Test configuration validation"""
        required_keys = {
            'name': str,
            'version': str,
            'count': int,
            'nested.key': str,
            'validation_func': lambda x: x > 0
        }
        
        # Valid config
        valid_config = {
            'name': 'test',
            'version': '1.0.0',
            'count': 42,
            'nested': {'key': 'value'},
            'validation_func': 10
        }
        
        is_valid, errors = validate_config(valid_config, required_keys)
        assert is_valid
        assert not errors
        
        # Invalid config
        invalid_config = {
            'name': 'test',
            'version': 1.0,  # Wrong type
            'count': '42',  # Wrong type
            'nested': {'wrong_key': 'value'},  # Missing required nested key
            'validation_func': -5  # Fails validation function
        }
        
        is_valid, errors = validate_config(invalid_config, required_keys)
        assert not is_valid
        assert 'version' in errors
        assert 'count' in errors
        assert 'nested.key' in errors
        assert 'validation_func' in errors

class TestPathHelpers:
    
    def test_get_project_root(self, monkeypatch):
        """Test project root detection with mocked paths"""
        # Create a mock path that will exist in the test environment
        test_path = os.path.join(os.getcwd(), 'main.py')
        
        # Mock the path.exists function to return True for our test path
        original_exists = os.path.exists
        def mock_exists(path):
            if str(path) == str(test_path):
                return True
            return original_exists(path)
        
        # Apply our mock
        monkeypatch.setattr(os.path, 'exists', mock_exists)
        monkeypatch.setattr('pathlib.Path.cwd', lambda: Path(os.getcwd()))
        
        # Test function
        root = get_project_root()
        assert str(root) == os.getcwd()
    
    def test_get_data_path(self, monkeypatch, tmp_path):
        """Test data path construction"""
        # Setup
        monkeypatch.setattr('base_data_project.path_helpers.get_project_root', 
                          lambda: tmp_path)
        
        # Test without filename
        data_dir = get_data_path()
        assert os.path.exists(data_dir)
        
        # Test with filename
        file_path = get_data_path('test.csv')
        assert os.path.basename(file_path) == 'test.csv'
        assert os.path.dirname(file_path).endswith('data')