# tests/unit/test_data_model.py
import pytest
from unittest.mock import Mock
from base_data_project.storage.models import BaseDataModel
from base_data_project.storage.containers import BaseDataContainer

class TestBaseDataModel:
    
    @pytest.fixture
    def mock_container(self):
        """Create mock data container"""
        container = Mock(spec=BaseDataContainer)
        return container
    
    @pytest.fixture
    def data_model(self, mock_container):
        """Create data model instance"""
        return BaseDataModel(data_container=mock_container, project_name="test_project")
    
    def test_initialization(self, data_model, mock_container):
        """Test data model initialization"""
        assert data_model.data_container == mock_container
        assert data_model.logger is not None
    
    def test_without_container(self):
        """Test initialization without container"""
        model = BaseDataModel(project_name="test_project")
        assert model.data_container is None
        assert model.logger is not None