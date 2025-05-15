# tests/unit/test_stage_handler.py
import pytest
from datetime import datetime
from unittest.mock import Mock, patch
from base_data_project.process_management.stage_handler import ProcessStageHandler
from base_data_project.process_management.exceptions import InvalidStageSequenceError

class TestProcessStageHandler:
    
    @pytest.fixture
    def mock_process_manager(self):
        """Create a mock process manager"""
        return Mock()
    
    @pytest.fixture
    def sample_config(self):
        """Create a sample configuration for the stage handler"""
        return {
            'PROJECT_NAME': 'test_project',
            'stages': {
                'stage1': {
                    'sequence': 1,
                    'requires_previous': False,
                    'validation_required': True,
                    'decisions': {
                        'decision1': {
                            'param1': 'default'
                        }
                    }
                },
                'stage2': {
                    'sequence': 2,
                    'requires_previous': True,
                    'validation_required': True,
                    'decisions': {
                        'decision2': {
                            'param2': 10
                        }
                    },
                    'substages': {
                        'substage1': {
                            'sequence': 1,
                            'description': 'First substage',
                            'optional': False,
                            'auto_start': True
                        },
                        'substage2': {
                            'sequence': 2,
                            'description': 'Second substage',
                            'optional': True,
                            'dependencies': ['substage1']
                        }
                    },
                    'auto_complete_on_substages': True
                }
            },
            'storage_strategy': {
                'mode': 'memory'
            }
        }
    
    @pytest.fixture
    def stage_handler(self, mock_process_manager, sample_config):
        """Create a stage handler for testing"""
        return ProcessStageHandler(mock_process_manager, sample_config)
    
    def test_initialize_process(self, stage_handler):
        """Test process initialization"""
        process_id = stage_handler.initialize_process(
            "Test Process", 
            "Process description"
        )
        
        # Verify process was initialized
        assert stage_handler.initialized
        assert stage_handler.current_process_id == process_id
        assert len(stage_handler.stages) == 2
        assert 'stage1' in stage_handler.stages
        assert 'stage2' in stage_handler.stages
        
        # Verify substages were initialized
        assert 'substages' in stage_handler.stages['stage2']
        assert 'substage1' in stage_handler.stages['stage2']['substages']
        assert 'substage2' in stage_handler.stages['stage2']['substages']
    
    def test_start_stage(self, stage_handler):
        """Test starting a stage"""
        # Initialize process first
        stage_handler.initialize_process("Test Process", "Process description")
        
        # Start stage1
        stage = stage_handler.start_stage('stage1')
        
        # Verify stage was started correctly
        assert stage['status'] == 'in_progress'
        assert stage['started_at'] is not None
        assert stage_handler.stages['stage1']['status'] == 'in_progress'
    
    def test_start_stage_with_dependencies(self, stage_handler):
        """Test starting a stage that requires previous stages"""
        # Initialize process
        stage_handler.initialize_process("Test Process", "Process description")
        
        # Try to start stage2 without completing stage1
        with pytest.raises(InvalidStageSequenceError):
            stage_handler.start_stage('stage2')
        
        # Start and complete stage1
        stage_handler.start_stage('stage1')
        stage_handler.complete_stage('stage1', True, {'result': 'success'})
        
        # Now stage2 should start successfully
        stage2 = stage_handler.start_stage('stage2')
        assert stage2['status'] == 'in_progress'
    
    def test_start_substage(self, stage_handler):
        """Test starting a substage"""
        # Initialize process and complete required stages
        stage_handler.initialize_process("Test Process", "Process description")
        stage_handler.start_stage('stage1')
        stage_handler.complete_stage('stage1', True, {'result': 'success'})
        stage_handler.start_stage('stage2')
        
        # Start substage1
        substage = stage_handler.start_substage('stage2', 'substage1')
        
        # Verify substage was started
        assert substage['status'] == 'in_progress'
        assert substage['started_at'] is not None
        assert stage_handler.stages['stage2']['substages']['substage1']['status'] == 'in_progress'
    
    def test_track_progress(self, stage_handler):
        """Test tracking progress within a stage"""
        # Initialize and start stage
        stage_handler.initialize_process("Test Process", "Process description")
        stage_handler.start_stage('stage1')
        
        # Track progress
        stage_handler.track_progress(
            'stage1', 
            0.5, 
            "Half complete", 
            {'detail': 'processing item 50/100'}
        )
        
        # Verify tracking data was recorded
        tracking_data = stage_handler.stages['stage1']['tracking_data']
        assert len(tracking_data) == 1
        assert tracking_data[0]['progress'] == 0.5
        assert tracking_data[0]['message'] == "Half complete"
        assert tracking_data[0]['metadata']['detail'] == 'processing item 50/100'
    
    def test_complete_stage(self, stage_handler):
        """Test completing a stage"""
        # Initialize and start stage
        stage_handler.initialize_process("Test Process", "Process description")
        stage_handler.start_stage('stage1')
        
        # Complete stage
        result_data = {'output': 'test_output', 'metrics': {'accuracy': 0.95}}
        stage = stage_handler.complete_stage('stage1', True, result_data)
        
        # Verify stage was completed
        assert stage['status'] == 'completed'
        assert stage['completed_at'] is not None
        assert stage['result_data'] == result_data
        
        # Verify stage status in handler
        assert stage_handler.stages['stage1']['status'] == 'completed'
    
    def test_get_stage_status(self, stage_handler):
        """Test getting stage status"""
        # Initialize and start stage
        stage_handler.initialize_process("Test Process", "Process description")
        stage_handler.start_stage('stage1')
        
        # Get status
        status = stage_handler.get_stage_status('stage1')
        
        # Verify status information
        assert status['name'] == 'stage1'
        assert status['status'] == 'in_progress'
        assert status['started_at'] is not None
        assert status['completed_at'] is None
    
    def test_get_process_summary(self, stage_handler):
        """Test getting process summary"""
        # Initialize process with multiple stages
        stage_handler.initialize_process("Test Process", "Process description")
        
        # Start and complete stage1
        stage_handler.start_stage('stage1')
        stage_handler.complete_stage('stage1', True, {'result': 'success'})
        
        # Start stage2
        stage_handler.start_stage('stage2')
        
        # Get summary
        summary = stage_handler.get_process_summary()
        
        # Verify summary information
        assert summary['active_stage'] == 'stage2'
        assert 'status_counts' in summary
        assert summary['status_counts']['completed'] == 1
        assert summary['status_counts']['in_progress'] == 1
        assert 'stages' in summary
        assert len(summary['stages']) == 2