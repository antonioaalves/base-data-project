# tests/unit/test_parameterized.py
import pytest
from base_data_project.utils import validate_config
from base_data_project.data_manager.factory import DataManagerFactory

class TestWithParameterization:
    
    @pytest.mark.parametrize("config,expected_valid", [
        ({"name": "test", "version": "1.0"}, True),
        ({"name": "test"}, False),  # Missing version
        ({"version": "1.0"}, False),  # Missing name
        ({}, False),  # Empty config
    ])
    def test_simple_validation(self, config, expected_valid):
        """Test simple config validation with different inputs"""
        required_keys = {
            "name": str,
            "version": str
        }
        
        is_valid, _ = validate_config(config, required_keys)
        assert is_valid == expected_valid
    
    @pytest.mark.parametrize("source_type,config,expected_class", [
        ("csv", {"PROJECT_NAME": "test"}, "CSVDataManager"),
        ("db", {"PROJECT_NAME": "test"}, "DBDataManager"),
        ("database", {"PROJECT_NAME": "test"}, "DBDataManager"),
        ("sql", {"PROJECT_NAME": "test"}, "DBDataManager"),
    ])
    def test_data_manager_factory(self, source_type, config, expected_class):
        """Test data manager factory with different source types"""
        data_manager = DataManagerFactory.create_data_manager(source_type, config)
        assert data_manager.__class__.__name__ == expected_class