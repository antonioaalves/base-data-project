# tests/unit/test_process_manager.py
import pytest
from base_data_project.process_management.manager import ProcessManager
from base_data_project.process_management.exceptions import InvalidDataError

class TestProcessManager:
    
    @pytest.fixture
    def core_data(self):
        """Sample core data for process manager"""
        return {
            "version": "1.0.0",
            "config": {"PROJECT_NAME": "test_project"}
        }
    
    @pytest.fixture
    def process_manager(self, core_data):
        """Create a process manager instance"""
        pm = ProcessManager(core_data)
        
        # Register a simple decision point with dict schema
        pm.register_decision_point(
            stage=1,
            schema=dict,  # Using dict allows any values
            required=True,
            defaults={"x": 10.0, "y": 1.0}
        )
        
        # Register a second decision point
        pm.register_decision_point(
            stage=2,
            schema=dict,
            required=False,
            defaults={"z": 5}
        )
        
        return pm
    
    def test_make_decisions(self, process_manager):
        """Test making decisions"""
        # Make a valid decision
        process_manager.make_decisions(1, {"x": 20.0, "y": 2.0})
        assert process_manager.current_decisions[1]["x"] == 20.0
        assert process_manager.current_decisions[1]["y"] == 2.0
        
        # Make a decision with defaults applied
        process_manager.make_decisions(1, {"x": 30.0})
        assert process_manager.current_decisions[1]["x"] == 30.0
        assert process_manager.current_decisions[1]["y"] == 1.0  # Default value
    
    def test_get_stage_data(self, process_manager):
        """Test retrieving stage data"""
        # Make decisions
        process_manager.make_decisions(1, {"x": 20.0, "y": 2.0})
        
        # Get stage data
        result = process_manager.get_stage_data(1)
        assert result is not None
        
        # Check stage 0 returns core data
        core_data = process_manager.get_stage_data(0)
        assert core_data == process_manager.core_data
    
    def test_save_and_load_scenario(self, process_manager):
        """Test saving and loading scenarios"""
        # Make some decisions
        process_manager.make_decisions(1, {"x": 20.0, "y": 2.0})
        process_manager.make_decisions(2, {"z": 10})
        
        # Save the scenario
        scenario_id = process_manager.save_current_scenario("Test Scenario")
        
        # Change decisions
        process_manager.make_decisions(1, {"x": 30.0, "y": 3.0})
        
        # Load the saved scenario
        process_manager.load_scenario(scenario_id)
        
        # Verify decisions were restored
        assert process_manager.current_decisions[1]["x"] == 20.0
        assert process_manager.current_decisions[2]["z"] == 10