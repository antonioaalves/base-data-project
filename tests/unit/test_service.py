# tests/unit/test_service.py
import pytest
from unittest.mock import Mock, patch
from base_data_project.service import BaseService
from base_data_project.data_manager.managers.base import BaseDataManager
from base_data_project.process_management.manager import ProcessManager

class TestBaseService:
    
    @pytest.fixture
    def mock_data_manager(self):
        """Create mock data manager"""
        dm = Mock(spec=BaseDataManager)
        dm.connect.return_value = None
        return dm
        
    @pytest.fixture
    def mock_process_manager(self):
        """Create mock process manager"""
        pm = Mock(spec=ProcessManager)
        pm.config = {"PROJECT_NAME": "test_project"}
        return pm
        
    @pytest.fixture
    def service(self, mock_data_manager, mock_process_manager):
        """Create service instance"""
        return BaseService(
            data_manager=mock_data_manager,
            process_manager=mock_process_manager
        )
    
    def test_initialize_process(self, service):
        """Test process initialization"""
        # Configure the stage handler mock
        service.stage_handler = Mock()
        service.stage_handler.initialize_process.return_value = "test_process_id"
        
        # Call the method
        process_id = service.initialize_process("Test Process", "Test Description")
        
        # Verify correct method was called
        service.stage_handler.initialize_process.assert_called_once_with(
            "Test Process", "Test Description"
        )
        assert process_id == "test_process_id"
    
    def test_execute_stage(self, service):
        """Test stage execution"""
        # Configure the stage handler mock
        service.stage_handler = Mock()
        
        # Configure _dispatch_stage to return success
        service._dispatch_stage = Mock(return_value=True)
        
        # Call the method
        result = service.execute_stage("test_stage", "test_algorithm", {"param": "value"})
        
        # Verify
        service.stage_handler.start_stage.assert_called_once_with("test_stage", "test_algorithm")
        service.stage_handler.record_stage_decision.assert_called_once()
        service._dispatch_stage.assert_called_once()
        service.stage_handler.complete_stage.assert_called_once()
        assert result is True
    
    def test_execute_stage_failure(self, service):
        """Test stage execution failure handling"""
        # Configure the stage handler mock
        service.stage_handler = Mock()
        
        # Configure _dispatch_stage to return failure
        service._dispatch_stage = Mock(return_value=False)
        
        # Call the method
        result = service.execute_stage("test_stage", "test_algorithm", {"param": "value"})
        
        # Verify failure is properly handled
        assert result is False
        service.stage_handler.complete_stage.assert_called_once()
        
    def test_no_tracking_execution(self, mock_data_manager):
        """Test execution without process tracking"""
        # Create service without process manager
        service = BaseService(data_manager=mock_data_manager, process_manager=None)
        
        # Ensure service still works without tracking
        assert service.current_process_id is None
        assert service.stage_handler is None
        
        # Mock _dispatch_stage to verify it's called
        service._dispatch_stage = Mock(return_value=True)
        
        # Execute should work without stage_handler
        result = service.execute_stage("test_stage")
        assert result is True
        service._dispatch_stage.assert_called_once()