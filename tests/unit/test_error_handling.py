# tests/unit/test_error_handling.py
import pytest
from base_data_project.process_management.exceptions import (
    ProcessManagementError,
    InvalidStageSequenceError,
    ScenarioStateError,
    DependencyError,
    InvalidDataError
)
from base_data_project.process_management.manager import ProcessManager

class TestErrorHandling:
    
    @pytest.fixture
    def process_manager(self):
        """Create a process manager for testing"""
        pm = ProcessManager({"version": "1.0.0"})
        pm.register_decision_point(
            stage=1,
            schema=dict,
            required=True,
            defaults={}
        )
        return pm
    
    def test_invalid_stage(self, process_manager):
        """Test behavior when accessing invalid stage"""
        with pytest.raises(InvalidDataError):
            process_manager.make_decisions(999, {"value": 1})
    
    def test_dependent_stage_access(self, process_manager):
        """Test accessing stage when required decisions are missing"""
        # Define custom method for testing
        def _compute_stage(self, stage):
            if stage == 2:
                # This should verify stage 1 decisions exist
                self._check_required_decisions(2)
                return {"message": "Stage 2 computed"}
            return {"message": f"Stage {stage} computed"}
        
        # Monkey patch the _compute_stage method
        process_manager._compute_stage = _compute_stage.__get__(
            process_manager, ProcessManager
        )
        
        # Register stage 2
        process_manager.register_decision_point(
            stage=2,
            schema=dict,
            required=True,
            defaults={}
        )
        
        # Try to get stage 2 data without making stage 1 decision
        with pytest.raises(InvalidDataError):
            process_manager.get_stage_data(2)
        
        # Make stage 1 decision and try again
        process_manager.make_decisions(1, {"value": 1})
        result = process_manager.get_stage_data(2)
        assert result["message"] == "Stage 2 computed"
    
    def test_scenario_management_errors(self, process_manager):
        """Test errors in scenario management"""
        # Try to load non-existent scenario
        with pytest.raises(IndexError):
            process_manager.load_scenario(999)
        
        # Create and load valid scenario
        process_manager.make_decisions(1, {"value": 42})
        scenario_id = process_manager.save_current_scenario("Test Scenario")
        
        # Change current decisions
        process_manager.make_decisions(1, {"value": 99})
        assert process_manager.current_decisions[1]["value"] == 99
        
        # Load scenario
        process_manager.load_scenario(scenario_id)
        assert process_manager.current_decisions[1]["value"] == 42