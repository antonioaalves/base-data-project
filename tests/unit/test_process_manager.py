# tests/unit/test_process_manager.py
import pytest
from typing import Dict, Any, TypedDict, Type
from base_data_project.process_management.manager import ProcessManager
from base_data_project.process_management.exceptions import InvalidDataError

class TestDecision1(TypedDict, total=True):
    """Test decision schema for stage 1"""
    x: float
    y: float

class TestDecision2(TypedDict, total=False):
    """Test decision schema for stage 2 with optional fields"""
    z: int
    optional: bool

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
        """Create a process manager with registered decision points"""
        pm = ProcessManager(core_data)
        
        # Register decision points
        pm.register_decision_point(
            stage=1,
            schema=TestDecision1,
            required=True,
            defaults={"x": 10.0, "y": 1.0}
        )
        
        pm.register_decision_point(
            stage=2,
            schema=TestDecision2,
            required=False,
            defaults={"z": 5}
        )
        
        return pm
    
    def test_make_decisions(self, process_manager):
        """Test making decisions with validation"""
        # Make a valid decision
        process_manager.make_decisions(1, {"x": 20.0, "y": 2.0})
        assert process_manager.current_decisions[1]["x"] == 20.0
        assert process_manager.current_decisions[1]["y"] == 2.0
        
        # Make a decision with defaults applied
        process_manager.make_decisions(1, {"x": 30.0})
        assert process_manager.current_decisions[1]["x"] == 30.0
        assert process_manager.current_decisions[1]["y"] == 1.0  # Default value
    
    def test_make_invalid_decision(self, process_manager):
        """Test making an invalid decision"""
        # Missing required field
        with pytest.raises(InvalidDataError):
            process_manager.make_decisions(1, {}, apply_defaults=False)
        
        # Wrong type
        with pytest.raises(InvalidDataError):
            process_manager.make_decisions(1, {"x": "not-a-number", "y": 2.0})
    
    def test_get_stage_data(self, process_manager):
        """Test retrieving stage data with caching"""
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
        process_manager.make_decisions(2, {"z": 10, "optional": True})
        
        # Save the scenario
        scenario_id = process_manager.save_current_scenario("Test Scenario")
        
        # Change decisions
        process_manager.make_decisions(1, {"x": 30.0, "y": 3.0})
        
        # Load the saved scenario
        process_manager.load_scenario(scenario_id)
        
        # Verify decisions were restored
        assert process_manager.current_decisions[1]["x"] == 20.0
        assert process_manager.current_decisions[2]["z"] == 10
    
    def test_compare_scenarios(self, process_manager):
        """Test comparing scenarios"""
        # Create first scenario
        process_manager.make_decisions(1, {"x": 20.0, "y": 2.0})
        id1 = process_manager.save_current_scenario("Scenario 1")
        
        # Create second scenario
        process_manager.make_decisions(1, {"x": 30.0, "y": 3.0})
        id2 = process_manager.save_current_scenario("Scenario 2")
        
        # Compare scenarios
        comparison = process_manager.compare_scenarios([id1, id2])
        
        # Verify comparison data
        assert len(comparison) == 2
        assert comparison[0]["name"] == "Scenario 1"
        assert comparison[1]["name"] == "Scenario 2"
        assert comparison[0]["decisions"][1]["x"] == 20.0
        assert comparison[1]["decisions"][1]["x"] == 30.0