# tests/unit/test_with_mocking.py
import pytest
from unittest.mock import Mock, patch
from base_data_project.service import BaseService

class TestServiceWithMocking:
    
    @patch('base_data_project.process_management.stage_handler.ProcessStageHandler')
    @patch('base_data_project.data_manager.managers.base.BaseDataManager')
    def test_service_initialization(self, mock_data_manager, mock_stage_handler):
        """Test service initialization with mocked dependencies"""
        # Configure mocks
        mock_data_manager.connect.return_value = None
        
        # Create a properly configured mock process manager
        mock_process_manager = Mock()
        mock_process_manager.config = {"PROJECT_NAME": "test_project"}
        
        # Create service with mocked components
        service = BaseService(
            data_manager=mock_data_manager,
            process_manager=mock_process_manager
        )
        
        # Verify service was initialized correctly
        assert service.data_manager == mock_data_manager

    @patch('base_data_project.process_management.stage_handler.ProcessStageHandler')
    @patch('base_data_project.data_manager.managers.base.BaseDataManager')
    def test_execute_stage(self, mock_data_manager, mock_stage_handler):
        """Test stage execution with mocked dependencies"""
        # Create properly configured mocks
        mock_process_manager = Mock()
        mock_process_manager.config = {"PROJECT_NAME": "test_project"}
        mock_stage_handler.return_value = Mock()
        
        # Create service
        service = BaseService(
            data_manager=mock_data_manager,
            process_manager=mock_process_manager
        )
        service.stage_handler = mock_stage_handler.return_value
        
        # Execute stage
        service.execute_stage("test_stage", "test_algorithm", {"param": "value"})
        
        # Verify expected methods were called
        mock_stage_handler.return_value.start_stage.assert_called_once_with(
            "test_stage", "test_algorithm"
        )
        mock_stage_handler.return_value.record_stage_decision.assert_called_once()
        mock_stage_handler.return_value.complete_stage.assert_called_once()