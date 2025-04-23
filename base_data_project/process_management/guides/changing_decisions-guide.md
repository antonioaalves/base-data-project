# Complete Guide to Altering ProcessManager Decisions

This guide provides detailed instructions for modifying the decision structure in your ProcessManager system, covering all possible modifications and their implications.

## Table of Contents

1. [Understanding the Decision System](#understanding-the-decision-system)
2. [Types of Decision Alterations](#types-of-decision-alterations)
3. [Modifying Decision Fields](#modifying-decision-fields)
4. [Adding or Removing Decision Points](#adding-or-removing-decision-points)
5. [Changing Decision Validation](#changing-decision-validation)
6. [Updating the Default Value System](#updating-the-default-value-system)
7. [Impact on Caching](#impact-on-caching)
8. [Handling Backward Compatibility](#handling-backward-compatibility)
9. [Testing Decision Changes](#testing-decision-changes)
10. [Real-World Examples](#real-world-examples)

## Understanding the Decision System

Before making changes, ensure you understand how decisions work in the ProcessManager:

- **Decision Points**: Located between process stages (e.g., between Stage 1 and Stage 2)
- **Schema Definitions**: Defined in `schemas.py` using TypedDict or similar structures
- **Validation Process**: Checks for required fields, type correctness, and custom rules
- **Default Values**: Managed by DefaultValueManager to fill in missing fields
- **Impact on Processing**: Decisions affect how subsequent stages transform data

## Types of Decision Alterations

### Field-Level Changes

- **Adding Fields**: Introducing new parameters to existing decisions
- **Removing Fields**: Eliminating parameters from decisions
- **Modifying Fields**: Changing data types, constraints, or semantics
- **Renaming Fields**: Changing field names while preserving functionality

### Structural Changes

- **Adding Decision Points**: Creating new decision stages in the process
- **Removing Decision Points**: Eliminating decision stages
- **Reordering Decision Points**: Changing the sequence of decisions
- **Merging Decision Points**: Combining multiple decision points
- **Splitting Decision Points**: Breaking a decision point into multiple ones

## Modifying Decision Fields

### Adding New Fields

1. **Update Schema Definition**:
   ```python
   # Before
   class Decision1(TypedDict, total=True):
       x: float
       y: float
   
   # After
   class Decision1(TypedDict, total=True):
       x: float
       y: float
       priority: int  # New field
   ```

2. **Update Default Values**:
   ```python
   # Add default for the new field
   default_manager.update_defaults(1, {"priority": 1})
   ```

3. **Update Transformation Logic**:
   ```python
   def _apply_transformation(self, stage, data, decisions):
       if stage == 2:  # Stage affected by Decision1
           priority = decisions.get("priority", 1)
           # Use priority in your transformations
   ```

4. **Consider Backward Compatibility**:
   ```python
   # When loading old scenarios
   def _load_legacy_scenario(self, scenario_data):
       # Add missing fields with defaults
       if "priority" not in scenario_data["decisions"][1]:
           scenario_data["decisions"][1]["priority"] = 1
   ```

### Removing Fields

1. **Update Schema Definition**:
   ```python
   # Before
   class Decision1(TypedDict, total=True):
       x: float
       y: float
       legacy_field: str
   
   # After
   class Decision1(TypedDict, total=True):
       x: float
       y: float
       # legacy_field removed
   ```

2. **Update Default Values**:
   ```python
   # Remove default for the field
   defaults = default_manager.get_defaults(1)
   if "legacy_field" in defaults:
       del defaults["legacy_field"]
       default_manager.update_defaults(1, defaults)
   ```

3. **Update Transformation Logic**:
   ```python
   def _apply_transformation(self, stage, data, decisions):
       # Remove references to the removed field
       # Ensure code doesn't depend on the field
   ```

4. **Clean Up Old Scenarios**:
   ```python
   def _clean_legacy_scenarios(self):
       for scenario in self.saved_scenarios:
           if "legacy_field" in scenario["decisions"][1]:
               del scenario["decisions"][1]["legacy_field"]
   ```

### Modifying Field Types

1. **Update Schema Definition**:
   ```python
   # Before
   class Decision2(TypedDict, total=True):
       z: float
   
   # After
   class Decision2(TypedDict, total=True):
       z: int  # Changed from float to int
   ```

2. **Update Validation Logic**:
   ```python
   def validate_decision(decision, schema):
       # Update custom validations if needed
       if "z" in decision and isinstance(decision["z"], float):
           # Convert float to int for backward compatibility
           decision["z"] = int(decision["z"])
   ```

3. **Update Transformation Logic**:
   ```python
   def _apply_transformation(self, stage, data, decisions):
       # Ensure transformations handle the new type
       if stage == 3 and "z" in decisions:
           z_value = decisions["z"]
           # z_value is now an int, handle accordingly
   ```

### Renaming Fields

1. **Update Schema Definition**:
   ```python
   # Before
   class Decision3(TypedDict, total=True):
       old_name: float
   
   # After
   class Decision3(TypedDict, total=True):
       new_name: float  # Renamed from old_name
   ```

2. **Update Default Values**:
   ```python
   # Update defaults with new field name
   old_defaults = default_manager.get_defaults(3)
   if "old_name" in old_defaults:
       new_defaults = {k: v for k, v in old_defaults.items() if k != "old_name"}
       new_defaults["new_name"] = old_defaults["old_name"]
       default_manager.update_defaults(3, new_defaults)
   ```

3. **Add Migration Logic**:
   ```python
   def _migrate_field_names(self, decisions):
       if 3 in decisions and "old_name" in decisions[3]:
           decisions[3]["new_name"] = decisions[3].pop("old_name")
   ```

## Adding or Removing Decision Points

### Adding a New Decision Point

1. **Update Enum Definitions**:
   ```python
   # Add to enum if you use enums
   class DecisionPoint(Enum):
       DECISION_1 = 1
       DECISION_2 = 2
       DECISION_3 = 3
       DECISION_4 = 4
       DECISION_5 = 5  # New decision point
   ```

2. **Create Schema Definition**:
   ```python
   class Decision5(TypedDict, total=True):
       """Decision between Stage 5 and 6"""
       new_param1: float
       new_param2: str
   ```

3. **Update Schema Mappings**:
   ```python
   # Map decision points to schemas
   DECISION_SCHEMAS = {
       DecisionPoint.DECISION_1: Decision1,
       # ...existing mappings...
       DecisionPoint.DECISION_5: Decision5,
   }
   
   # Update stage mapping
   STAGE_TO_SCHEMA = {
       1: Decision1,
       # ...existing mappings...
       5: Decision5,
   }
   ```

4. **Configure Default Values**:
   ```python
   default_manager.update_defaults(5, {
       "new_param1": 1.0,
       "new_param2": "default"
   })
   ```

5. **Update Process Flow**:
   ```python
   # Ensure your process manager knows about the new stage
   def _compute_stage(self, stage: int) -> Any:
       # Handle the new stage
       if stage == 6:  # Stage after new decision
           # Implement Stage 6 computation
   ```

### Removing a Decision Point

1. **Update Enum Definitions** (if used):
   ```python
   # Remove from enum if you use enums
   class DecisionPoint(Enum):
       DECISION_1 = 1
       DECISION_2 = 2
       DECISION_3 = 3
       # DECISION_4 removed
   ```

2. **Update Schema Mappings**:
   ```python
   # Remove from mappings
   DECISION_SCHEMAS = {
       DecisionPoint.DECISION_1: Decision1,
       DecisionPoint.DECISION_2: Decision2,
       DecisionPoint.DECISION_3: Decision3,
       # Decision4 removed
   }
   
   # Update stage mapping
   STAGE_TO_SCHEMA = {
       1: Decision1,
       2: Decision2,
       3: Decision3,
       # 4 removed
   }
   ```

3. **Update Process Flow**:
   ```python
   # Adjust the process flow
   def _compute_stage(self, stage: int) -> Any:
       # Skip the removed decision
       if stage == 4:  # This used to depend on Decision4
           # Now depends on Decision3 instead
           stage_decisions = self.current_decisions.get(3, {})
   ```

4. **Clean Up Old Scenarios**:
   ```python
   def _clean_removed_decision(self):
       for scenario in self.saved_scenarios:
           if 4 in scenario["decisions"]:
               del scenario["decisions"][4]
   ```

## Changing Decision Validation

### Adding Custom Validation Rules

1. **Extend the Validation Function**:
   ```python
   def validate_decision(decision, schema, stage=None):
       # Existing basic validation
       is_valid, error_message = basic_validation(decision, schema)
       if not is_valid:
           return False, error_message
       
       # Custom validation rules
       if stage == 1 and "x" in decision and "y" in decision:
           if decision["x"] < 0 and decision["y"] < 0:
               return False, "x and y cannot both be negative"
       
       return True, None
   ```

2. **Add Domain-Specific Validation**:
   ```python
   def _validate_business_rules(self, stage, decision):
       """Validate business rules beyond schema validation"""
       if stage == 2 and "z" in decision:
           # Business rule: z must be within operating range
           if not (1.0 <= decision["z"] <= 10.0):
               raise InvalidDataError(f"z must be between 1.0 and 10.0, got {decision['z']}")
   ```

3. **Implement Inter-Field Validations**:
   ```python
   def _validate_inter_field_constraints(self, decision):
       """Validate relationships between fields"""
       if "min_value" in decision and "max_value" in decision:
           if decision["min_value"] > decision["max_value"]:
               raise InvalidDataError("min_value cannot be greater than max_value")
   ```

### Relaxing Validation Rules

1. **Update Type Checking**:
   ```python
   # Before - Strict type checking
   if expected_type == float:
       if not isinstance(value, float):
           return False, f"Expected float for '{key}', got {type(value).__name__}"
   
   # After - More flexible checking
   if expected_type == float:
       if not isinstance(value, (int, float)):  # Accept integers too
           return False, f"Expected numeric value for '{key}', got {type(value).__name__}"
       # Convert int to float if needed
       if isinstance(value, int):
           decision[key] = float(value)
   ```

2. **Make Fields Optional**:
   ```python
   # Change from total=True to partial definitions
   class Decision1(TypedDict, total=False):  # total=False makes all fields optional
       x: float
       y: float
   ```

## Updating the Default Value System

### Creating Field-Specific Defaults

1. **Set Up Complex Default Structure**:
   ```python
   # More structured default system
   self.defaults = {
       1: {
           "fields": {
               "x": {"value": 10.0, "min": 0.0, "max": 100.0},
               "y": {"value": 1.0, "min": 0.0, "max": 10.0}
           },
           "metadata": {
               "importance": "high",
               "description": "Critical process parameters"
           }
       }
   }
   ```

2. **Enhance the Default Value Manager**:
   ```python
   def get_default_value(self, stage, field):
       """Get a specific field default"""
       stage_defaults = self.defaults.get(stage, {})
       field_defaults = stage_defaults.get("fields", {}).get(field, {})
       return field_defaults.get("value")
   
   def get_field_constraints(self, stage, field):
       """Get constraints for a field"""
       stage_defaults = self.defaults.get(stage, {})
       field_defaults = stage_defaults.get("fields", {}).get(field, {})
       return {
           "min": field_defaults.get("min"),
           "max": field_defaults.get("max")
       }
   ```

### Implementing Contextual Defaults

1. **Context-Aware Default System**:
   ```python
   def apply_defaults(self, stage, decision, context=None):
       """Apply defaults based on context"""
       defaults = self.get_defaults(stage)
       
       # Apply context-specific logic
       if context and "mode" in context:
           if context["mode"] == "high_precision":
               # Adjust defaults for high precision mode
               defaults["x"] = 15.0  # Override standard default
       
       # Apply defaults to decision
       complete_decision = defaults.copy()
       complete_decision.update(decision)
       return complete_decision
   ```

2. **Example Usage**:
   ```python
   # Using contextual defaults
   process_manager.make_decisions(
       1, 
       {"y": 2.0},  # Provide y but not x
       context={"mode": "high_precision"}  # Context affects defaults
   )
   ```

## Impact on Caching

### Updating Cache Key Generation

1. **Modify Cache Key Generation**:
   ```python
   def _generate_cache_key(self, stage):
       """Generate cache key for a stage"""
       # Get relevant decisions for this stage
       relevant_decisions = {
           k: v for k, v in self.current_decisions.items()
           if k < stage
       }
       
       # Filter to only include fields that affect computation
       filtered_decisions = {}
       for stage_num, decision in relevant_decisions.items():
           filtered_decision = {}
           # Only include fields that affect computation
           for field, value in decision.items():
               if self._field_affects_computation(stage_num, field, stage):
                   filtered_decision[field] = value
           filtered_decisions[stage_num] = filtered_decision
       
       # Generate cache key from filtered decisions
       return generate_cache_key(filtered_decisions)
   ```

2. **Define Computation Dependencies**:
   ```python
   def _field_affects_computation(self, decision_stage, field, target_stage):
       """Determine if a decision field affects a target stage"""
       # Define dependencies
       dependencies = {
           # Format: {target_stage: {decision_stage: [fields]}}
           3: {
               1: ["x", "priority"],  # Stage 3 depends on x and priority from Decision 1
               2: ["z"]  # And z from Decision 2
           },
           4: {
               1: ["y"],  # Stage 4 depends on y from Decision 1
               3: ["w"]  # And w from Decision 3
           }
       }
       
       # Check if the field is in the dependency list
       stage_deps = dependencies.get(target_stage, {})
       field_deps = stage_deps.get(decision_stage, [])
       
       return field in field_deps
   ```

### Invalidating Caches on Schema Changes

1. **Version Your Schemas**:
   ```python
   # Add version information to schemas
   SCHEMA_VERSION = {
       1: 2,  # Decision 1 schema, version 2
       2: 1,  # Decision 2 schema, version 1
       3: 3,  # Decision 3 schema, version 3
   }
   ```

2. **Include Version in Cache Keys**:
   ```python
   def _generate_cache_key(self, stage):
       # Include schema versions in the cache key
       relevant_decisions = {
           k: v for k, v in self.current_decisions.items()
           if k < stage
       }
       
       # Add version information
       version_info = {
           f"schema_v_{k}": SCHEMA_VERSION.get(k, 1)
           for k in relevant_decisions.keys()
       }
       
       # Combine decisions with version info
       cache_data = {
           "decisions": relevant_decisions,
           "versions": version_info
       }
       
       return generate_cache_key(cache_data)
   ```

## Handling Backward Compatibility

### Creating Migration Functions

1. **Define Schema Migration Functions**:
   ```python
   def _migrate_decision_schema(self, stage, old_decision):
       """Migrate a decision from old schema to new schema"""
       if stage == 1:
           # Migrate Decision 1 schema
           if "old_field" in old_decision:
               # Handle removed field
               new_decision = {k: v for k, v in old_decision.items() if k != "old_field"}
               
               # Handle renamed field
               if "renamed_from" in old_decision:
                   new_decision["renamed_to"] = old_decision["renamed_from"]
               
               # Handle changed type
               if "int_field" in old_decision:
                   new_decision["int_field"] = int(old_decision["int_field"])
               
               return new_decision
       
       # No migration needed
       return old_decision
   ```

2. **Apply Migrations When Loading Scenarios**:
   ```python
   def load_scenario(self, scenario_id):
       """Load a saved scenario with migration"""
       scenario = self.saved_scenarios[scenario_id]
       
       # Migrate all decisions in the scenario
       migrated_decisions = {}
       for stage, decision in scenario["decisions"].items():
           migrated_decisions[stage] = self._migrate_decision_schema(stage, decision)
       
       # Update current decisions with migrated ones
       self.current_decisions = migrated_decisions
       
       # Clear cache since we have new decisions
       self.computation_cache = {}
   ```

### Adding Version Detection and Handling

1. **Add Version Information to Scenarios**:
   ```python
   def save_current_scenario(self, name):
       """Save the current scenario with version info"""
       scenario = {
           "name": name,
           "decisions": copy.deepcopy(self.current_decisions),
           "schema_versions": copy.deepcopy(SCHEMA_VERSION),
           "timestamp": datetime.now()
       }
       self.saved_scenarios.append(scenario)
       return len(self.saved_scenarios) - 1
   ```

2. **Version Compatibility Check**:
   ```python
   def _check_schema_compatibility(self, scenario):
       """Check if a scenario is compatible with current schemas"""
       scenario_versions = scenario.get("schema_versions", {})
       
       for stage, current_version in SCHEMA_VERSION.items():
           scenario_version = scenario_versions.get(stage, 1)
           
           if scenario_version > current_version:
               # Scenario uses newer schema than current code
               raise VersionError(f"Scenario uses schema version {scenario_version} for stage {stage}, but code only supports up to version {current_version}")
           
           if scenario_version < current_version:
               # Needs migration
               logger.info(f"Migrating stage {stage} schema from v{scenario_version} to v{current_version}")
   ```

## Testing Decision Changes

### Creating Test Suite for Decision Changes

1. **Test Basic Functionality**:
   ```python
   def test_decision_fields(self):
       """Test that all fields are handled correctly"""
       # Test valid fields
       self.process_manager.make_decisions(1, {"x": 10.5, "y": 2.0, "priority": 3})
       self.assertEqual(self.process_manager.current_decisions[1]["priority"], 3)
       
       # Test defaults
       self.process_manager.make_decisions(1, {"x": 10.5})
       self.assertEqual(self.process_manager.current_decisions[1]["y"], 1.0)
       self.assertEqual(self.process_manager.current_decisions[1]["priority"], 1)
   ```

2. **Test Validation Rules**:
   ```python
   def test_decision_validation(self):
       """Test validation of decisions"""
       # Test type validation
       with self.assertRaises(InvalidDataError):
           self.process_manager.make_decisions(1, {"x": "not a number", "y": 2.0})
       
       # Test custom business rules
       with self.assertRaises(InvalidDataError):
           self.process_manager.make_decisions(1, {"x": -1.0, "y": -2.0})
   ```

3. **Test Backward Compatibility**:
   ```python
   def test_legacy_scenario_loading(self):
       """Test loading of legacy scenarios"""
       # Create a legacy scenario format
       legacy_scenario = {
           "name": "Legacy Test",
           "decisions": {
               1: {"x": 10.5, "y": 2.0, "old_field": "value"},
               2: {"z": 5.0}
           },
           "schema_versions": {1: 1, 2: 1},
           "timestamp": datetime.now()
       }
       
       # Add to saved scenarios
       self.process_manager.saved_scenarios.append(legacy_scenario)
       
       # Try to load it
       self.process_manager.load_scenario(0)
       
       # Check migration worked
       self.assertNotIn("old_field", self.process_manager.current_decisions[1])
   ```

### Regression Testing Framework

1. **Create Standard Test Cases**:
   ```python
   class RegressionTests:
       """Standard test cases to run when schema changes"""
       
       @staticmethod
       def get_test_cases():
           """Get standard test cases"""
           return [
               # Format: (stage, decision_values, expected_result)
               (1, {"x": 10.5, "y": 2.0}, {"is_valid": True}),
               (1, {"x": -1.0, "y": -1.0}, {"is_valid": False, "error": "x and y cannot both be negative"}),
               # Add more standard cases
           ]
       
       @staticmethod
       def run_regression(process_manager):
           """Run regression tests on a process manager"""
           results = []
           for stage, decision, expected in RegressionTests.get_test_cases():
               try:
                   process_manager.make_decisions(stage, decision)
                   result = {"is_valid": True}
               except InvalidDataError as e:
                   result = {"is_valid": False, "error": str(e)}
               
               # Compare with expected
               test_passed = result["is_valid"] == expected["is_valid"]
               if not result["is_valid"] and not expected["is_valid"]:
                   test_passed = expected["error"] in result["error"]
               
               results.append({
                   "stage": stage,
                   "decision": decision,
                   "expected": expected,
                   "actual": result,
                   "passed": test_passed
               })
           
           return results
   ```

2. **Automating Regression Tests**:
   ```python
   def test_decision_regression(self):
       """Run regression tests after schema changes"""
       results = RegressionTests.run_regression(self.process_manager)
       
       # Check all tests passed
       failed_tests = [r for r in results if not r["passed"]]
       if failed_tests:
           self.fail(f"Regression tests failed: {failed_tests}")
   ```

## Real-World Examples

### Example 1: Adding a Priority Parameter

```python
# 1. Update schema
class Decision1(TypedDict, total=True):
    x: float
    y: float
    priority: int  # New field

# 2. Update default values
default_manager.update_defaults(1, {"priority": 1})

# 3. Update transformation logic
def _apply_transformation(self, stage, data, decisions):
    if stage == 2:  # Stage that uses Decision1
        priority = decisions.get(1, {}).get("priority", 1)
        
        # Use priority to weight calculations
        if priority > 2:
            # High priority processing
            result = self._compute_high_priority(data, decisions)
        else:
            # Normal processing
            result = self._compute_normal(data, decisions)
        
        return result
```

### Example 2: Changing Field Types for Better Performance

```python
# 1. Update schema
class Decision2(TypedDict, total=True):
    z: int  # Changed from float to int for performance

# 2. Update validation with migration
def validate_decision(decision, schema, stage=None):
    # Basic validation...
    
    # Type conversion for backward compatibility
    if stage == 2 and "z" in decision and isinstance(decision["z"], float):
        # Convert float to int
        decision["z"] = int(decision["z"])
    
    # Continue with validation...

# 3. Update processing logic
def _process_stage_3(self, data, z_value):
    # z_value is now an int, optimize calculations
    if z_value > 10:
        # Use fast path for large integers
        return self._fast_calculation(data, z_value)
    else:
        # Use regular path
        return self._regular_calculation(data, z_value)
```

### Example 3: Adding a New Decision Point for Fine-Grained Control

```python
# 1. Define new schema
class Decision5(TypedDict, total=True):
    """Fine-grained control parameters"""
    tolerance: float
    iterations: int
    use_approximation: bool

# 2. Update schema mappings
STAGE_TO_SCHEMA[5] = Decision5

# 3. Add defaults
default_manager.update_defaults(5, {
    "tolerance": 0.001,
    "iterations": 1000,
    "use_approximation": False
})

# 4. Implement new processing stage
def _compute_stage(self, stage: int) -> Any:
    if stage == 6:  # New stage after Decision5
        # Get parameters from decision 5
        params = self.current_decisions.get(5, {})
        tolerance = params.get("tolerance", 0.001)
        iterations = params.get("iterations", 1000)
        use_approximation = params.get("use_approximation", False)
        
        # Get previous stage result
        previous_data = self.get_stage_data(5)
        
        # Perform calculation with fine-grained control
        result = self._advanced_calculation(
            previous_data,
            tolerance=tolerance,
            max_iterations=iterations,
            approximate=use_approximation
        )
        
        return result
```

By following this comprehensive guide, you should be able to make any type of alteration to your ProcessManager decision system with confidence, ensuring backward compatibility and maintaining system integrity.