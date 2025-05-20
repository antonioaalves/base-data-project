"""
Fixed version of the flexible process manager addressing logger initialization issue.
"""

# Import dependencies
import logging
import json
import copy
from datetime import datetime
from typing import Dict, List, Any, Optional, Union, Type

# Local stuff
from base_data_project.process_management.exceptions import InvalidDataError
from base_data_project.process_management.utils import generate_cache_key, validate_decision

# Initialize logger with a default name - will be updated in __init__
logger = logging.getLogger('base_data_project')

class ProcessManager:
    """
    Base class for managing processes with flexible decision points.
    Provides infrastructure for decision management, caching, and scenario comparison.
    
    Specific processes should inherit from this class and register their decision points.
    """

    def __init__(self, core_data: Any, project_name: str = None):
        """
        Initialize the ProcessManager with core data.

        Args:
            core_data: The initial data for the process
            project_name: Optional project name for logging
        """
        self.core_data = core_data            # Initial data for the process
        self.current_decisions = {}           # Current set of decisions made by the user at each stage
        self.computation_cache = {}           # Cache of computed results to avoid recalculation
        self.saved_scenarios = []             # Saved scenarios for comparison
        self.decision_points = {}             # Registered decision points
        self.decision_schemas = {}            # Schemas for each decision point
        self.default_values = {}              # Default values for each decision point
        
        # Get project name from core_data config if available, otherwise use provided or default
        if isinstance(core_data, dict) and 'config' in core_data and 'PROJECT_NAME' in core_data['config']:
            self.project_name = core_data['config']['PROJECT_NAME']
        else:
            self.project_name = project_name or 'base_data_project'
        
        # Get project-specific logger
        self.logger = logging.getLogger(self.project_name)
        
        self.logger.info("Flexible ProcessManager initialized with core data")

    @property
    def config(self):
        return self.core_data.get('config', {})

    def register_decision_point(self, stage: int, schema: Type, required: bool = True, 
                               defaults: Optional[Dict[str, Any]] = None) -> None:
        """
        Register a decision point for the process.
        
        Args:
            stage: The stage number where the decision point occurs
            schema: The schema class for validating decisions
            required: Whether this decision is required for subsequent stages
            defaults: Default values for fields in this decision
        """
        self.decision_points[stage] = {
            "required": required,
            "defaults": defaults or {}
        }
        self.decision_schemas[stage] = schema
        self.default_values[stage] = defaults or {}
        
        self.logger.info(f"Registered decision point for stage {stage}, required={required}")

    def make_decisions(self, stage: int, decision_values: Dict[str, Any], 
                    apply_defaults: bool = True) -> None:
        """
        User makes or changes a decision at a specific stage with validation.
        
        Args:
            stage: The stage number where the decision is made
            decision_values: Dictionary of decision values
            apply_defaults: Whether to apply default values for missing fields
            
        Raises:
            InvalidDataError: If the stage has no registered decision point or validation fails
        """
        if stage not in self.decision_points:
            error_msg = f"No decision point registered for stage {stage}"
            self.logger.error(error_msg)
            raise InvalidDataError(error_msg)
        
        schema = self.decision_schemas[stage]
        
        # Apply defaults if requested
        if apply_defaults:
            defaults = self.default_values.get(stage, {})
            if isinstance(defaults, dict):
                complete_decision = defaults.copy()
                complete_decision.update(decision_values)
            else:
                complete_decision = decision_values
            complete_decision.update(decision_values)
        else:
            complete_decision = decision_values
        
        # Validate the decision against its schema
        is_valid, error_message = validate_decision(complete_decision, schema)
        if not is_valid:
            error_msg = f"Invalid decision for stage {stage}: {error_message}"
            self.logger.error(error_msg)
            raise InvalidDataError(error_msg)
        
        # Merge with existing decisions for this stage if they exist
        if stage in self.current_decisions:
            # Get existing decisions
            existing_decisions = self.current_decisions[stage]
            
            # Create a deep copy to avoid modifying the original
            merged_decisions = copy.deepcopy(existing_decisions)
            
            # Log the existing and new decisions before merging
            self.logger.info(f"Existing decisions for stage {stage}: {existing_decisions}")
            self.logger.info(f"New decisions for stage {stage}: {complete_decision}")
            
            # Recursively merge the dictionaries
            self._deep_merge_dicts(merged_decisions, complete_decision)
            
            # Store the merged decisions
            self.current_decisions[stage] = merged_decisions
            self.logger.info(f"Merged decisions for stage {stage}: {merged_decisions}")
        else:
            # Store the valid decision as-is if no existing decisions
            self.current_decisions[stage] = complete_decision
            self.logger.info(f"Decision for stage {stage} stored successfully")
        
        # Invalidate cached results for this stage and beyond
        self._invalidate_cache(stage)

    def _deep_merge_dicts(self, dict1: Dict[str, Any], dict2: Dict[str, Any]) -> None:
        """
        Recursively merge dict2 into dict1. This modifies dict1 in place.
        
        Args:
            dict1: Base dictionary to be updated
            dict2: Dictionary with values to add/update
        """
        for k, v in dict2.items():
            if k in dict1 and isinstance(dict1[k], dict) and isinstance(v, dict):
                # Recursively merge nested dictionaries
                self._deep_merge_dicts(dict1[k], v)
            else:
                # For simple values or non-matching types, just overwrite
                dict1[k] = v

    def _invalidate_cache(self, from_stage: int) -> None:
        """
        Invalidate cached results for a stage and all subsequent stages.
        
        Args:
            from_stage: The stage to start invalidation from
        """
        keys_to_remove = []
        for key in self.computation_cache:
            if isinstance(key, tuple) and key[0] >= from_stage:
                keys_to_remove.append(key)
        
        for key in keys_to_remove:
            del self.computation_cache[key]
            
        self.logger.info(f"Invalidated cache for stage {from_stage} and beyond")

    def get_stage_data(self, stage: int) -> Any:
        """
        Get the computed data for a specific stage.
        
        Args:
            stage: The stage number to get data for
            
        Returns:
            The computed result for the stage
            
        Raises:
            InvalidDataError: If a required decision is missing
        """
        self.logger.info(f"Getting data for stage {stage}")
        
        # Stage 0 is special, just returns core data
        if stage == 0:
            return self.core_data
        
        # Check if required decisions are made
        self._check_required_decisions(stage)
        
        # Generate cache key based on relevant decisions
        cache_key = self._generate_cache_key(stage)
        
        # Check if result is already cached
        if cache_key in self.computation_cache:
            self.logger.info(f"Cache hit for stage {stage}")
            return self.computation_cache[cache_key]
        
        # Compute the result if not cached
        self.logger.info(f"Cache miss for stage {stage}, computing result")
        result = self._compute_stage(stage)
        
        # Cache the result
        self.computation_cache[cache_key] = result
        return result
    
    def _check_required_decisions(self, stage: int, substage: Optional[str] = None) -> None:
        """
        Check if all required decisions for this stage and substages are made.
        
        Args:
            stage: The stage to check required decisions for
            substage: Optional substage to chek required decisions for
            
        Raises:
            InvalidDataError: If a required decision is missing
        """
        for prior_stage in range(1, stage):
            if (prior_stage in self.decision_points and 
                self.decision_points[prior_stage]["required"] and
                prior_stage not in self.current_decisions):
                error_msg = f"Required decision for stage {prior_stage} is missing"
                self.logger.error(error_msg)
                raise InvalidDataError(error_msg)
            
        # If a substage is specified, also check required decisions for previous substages within the current stage            
        if substage is not None:
            # Get substages configuration for the current stage
            stage_config = self.config.get('stages', {}).get(stage, {})
            substages = stage_config.get('substages', {})

            # Get the sequence of the current substage
            current_stage_seq = substages.get(substage, {}).get('sequence', 0)

            # Check required decisions for revious substages
            for substage_name, substage_config in substages.items():
                substage_seq = substage_config.get('sequence', 0)
                # Only check previous substages
                if substage_seq < current_stage_seq:
                    # Get decision oints for this substage
                    decision_key = f"{stage}_{substage_name}"

                    if (decision_key in self.decision_points and
                        self.decision_points[decision_key]['required'] and
                        decision_key not in self.current_decisions):
                        error_msg = f"Required decision for substage {substage_name} in stage {stage} is missing"
                        self.logger.error(error_msg)
                        raise InvalidDataError(error_msg)
    
    def _generate_cache_key(self, stage: int) -> Union[int, str]:
        """
        Generate a unique key for caching based on relevant decisions.
        
        Args:
            stage: The stage number to generate a key for
            
        Returns:
            A hash value or string to use as cache key
        """
        # Only include decisions that affect this stage (decisions from previous stages)
        relevant_decisions = {
            k: v for k, v in self.current_decisions.items()
            if k < stage
        }
        
        # Include the stage number in the cache key
        return (stage, generate_cache_key(relevant_decisions))
    
    def _compute_stage(self, stage: int) -> Any:
        """
        Compute the result for a specific stage.
        
        This method should be overridden by specific process implementations.
        
        Args:
            stage: The stage number to compute
            
        Returns:
            The computed result for the stage
        """
        self.logger.warning(f"Using default _compute_stage for stage {stage} - this should be overridden")
        
        # Get data from previous stage
        previous_data = self.get_stage_data(stage - 1)
        
        # Get relevant decisions
        relevant_decisions = {
            k: v for k, v in self.current_decisions.items()
            if k < stage
        }
        
        # Default implementation just returns a summary of inputs
        result = {
            "stage": stage,
            "previous_data_summary": str(previous_data)[:100] + "..." if isinstance(previous_data, (str, dict, list)) else str(previous_data),
            "decisions_applied": relevant_decisions,
            "timestamp": datetime.now().isoformat()
        }
        
        return result
    
    def save_current_scenario(self, name: str) -> int:
        """
        Save the current state as a named scenario for future comparison.
        
        Args:
            name: Name to identify the saved scenario
            
        Returns:
            Index of the saved scenario
        """
        self.logger.info(f"Saving current scenario as '{name}'")
        
        # Create a deep copy of current decisions to save
        saved_scenario = {
            "name": name,
            "decisions": copy.deepcopy(self.current_decisions),
            "timestamp": datetime.now()
        }
        
        self.saved_scenarios.append(saved_scenario)
        return len(self.saved_scenarios) - 1
    
    def get_saved_scenarios(self) -> List[Dict[str, Any]]:
        """
        Get a list of saved scenarios for reference.
        
        Returns:
            List of scenario summary information
        """
        self.logger.info("Getting list of saved scenarios")
        
        return [
            {
                "name": scenario["name"], 
                "id": i, 
                "timestamp": scenario["timestamp"]
            }
            for i, scenario in enumerate(self.saved_scenarios)
        ]
    
    def compare_scenarios(self, scenario_ids: List[int]) -> List[Dict[str, Any]]:
        """
        Get comparison data for selected saved scenarios.
        
        Args:
            scenario_ids: List of scenario IDs to compare
            
        Returns:
            List of complete scenario data
        """
        self.logger.info(f"Comparing scenarios: {scenario_ids}")
        
        return [self.saved_scenarios[i] for i in scenario_ids]
    
    def load_scenario(self, scenario_id: int) -> None:
        """
        Load a saved scenario as the current scenario.
        
        Args:
            scenario_id: ID of the scenario to load
            
        Raises:
            IndexError: If the scenario ID is invalid
        """
        if scenario_id < 0 or scenario_id >= len(self.saved_scenarios):
            error_msg = f"Invalid scenario ID: {scenario_id}"
            self.logger.error(error_msg)
            raise IndexError(error_msg)
        
        scenario = self.saved_scenarios[scenario_id]
        self.current_decisions = copy.deepcopy(scenario["decisions"])
        
        # Clear cache since we loaded new decisions
        self.computation_cache = {}
        
        self.logger.info(f"Loaded scenario: {scenario['name']}")
    
    def update_default_values(self, stage: int, values: Dict[str, Any]) -> None:
        """
        Update default values for a decision point.
        
        Args:
            stage: Stage number
            values: Dictionary of default values to update
            
        Raises:
            InvalidDataError: If the stage has no registered decision point
        """
        if stage not in self.decision_points:
            error_msg = f"No decision point registered for stage {stage}"
            self.logger.error(error_msg)
            raise InvalidDataError(error_msg)
        
        # Update default values
        if stage not in self.default_values:
            self.default_values[stage] = {}
        
        self.default_values[stage].update(values)
        self.logger.info(f"Updated default values for stage {stage}")
    
    def get_default_values(self, stage: int) -> Dict[str, Any]:
        """
        Get default values for a decision point.
        
        Args:
            stage: Stage number
            
        Returns:
            Dictionary of default values
            
        Raises:
            InvalidDataError: If the stage has no registered decision point
        """
        if stage not in self.decision_points:
            error_msg = f"No decision point registered for stage {stage}"
            self.logger.error(error_msg)
            raise InvalidDataError(error_msg)
        
        return self.default_values.get(stage, {}).copy()
        
    def store_generated_data(self, stage, data_type, entity_type, entity_id, value, metadata=None):
        """
        Store generated data during process execution.
        
        Args:
            stage: The stage object or ID where the data was generated
            data_type: Type of data being stored (e.g., 'progress_update', 'stage_execution')
            entity_type: Type of entity the data relates to (e.g., 'stage', 'algorithm')
            entity_id: ID of the entity
            value: Numeric value to store
            metadata: Additional context information as a dictionary
        """
        # Extract stage ID if a stage object was passed
        stage_id = stage.get('id') if isinstance(stage, dict) else stage
        
        # Create a record of the generated data
        data_record = {
            'timestamp': datetime.now().isoformat(),
            'stage_id': stage_id,
            'data_type': data_type,
            'entity_type': entity_type,
            'entity_id': entity_id,
            'value': value,
            'metadata': metadata or {}
        }
        
        # Initialize the generated_data attribute if it doesn't exist
        if not hasattr(self, 'generated_data'):
            self.generated_data = []
        
        # Store the record
        self.generated_data.append(data_record)
        
        self.logger.info(f"Stored generated data: {data_type} for {entity_type}:{entity_id}")
        
        # Return the data record ID (simple index for now)
        return len(self.generated_data) - 1