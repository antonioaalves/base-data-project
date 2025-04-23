# Process Manager Guide

## Core Concepts

The ProcessManager implements a stage-based decision system for managing complex processes. It's designed around these key concepts:

1. **Stages**: The process is divided into sequential stages (typically 5 stages)
2. **Decisions**: Users make decisions between stages that affect subsequent processing
3. **Data Flow**: Data flows through stages, with each stage transforming data based on prior decisions
4. **Caching**: Results are cached to avoid redundant calculations 
5. **Scenarios**: Complete sets of decisions can be saved as scenarios for comparison

## Architecture Overview

```
Core Data → Stage 1 → Decision 1 → Stage 2 → Decision 2 → ... → Stage 5
                                     ↑
                         DefaultValueManager
                                     ↓
                        (provides default values)
```

## Key Components

### 1. ProcessManager

This is the main class that orchestrates the entire process:

```python
# Initialize with core data
process_manager = ProcessManager(core_data, use_defaults=True)
```

### 2. DefaultValueManager

Manages default values for decision points when a user doesn't provide complete decision data:

```python
# The DefaultValueManager stores defaults for each stage
defaults = {
    1: {"x": 10.0, "y": 1.0},
    2: {"z": 5.0},
    # etc.
}
```

### 3. Decision Schemas

Each decision point has a schema (defined in `schemas.py`) that specifies required fields and their types:

```python
class Decision1(Decision):
    """Decision between Stage 1 and 2"""
    x: float
    y: float
```

## Main Capabilities

### 1. Making Decisions

Users can make decisions at each stage, with validation against schemas:

```python
process_manager.make_decisions(1, {"x": 10.5, "y": 2.0})
```

- Validates decision against the schema for that stage
- Can apply default values for missing fields
- Decisions affect all subsequent stages

### 2. Getting Stage Results

The manager computes and retrieves data for each stage:

```python
result = process_manager.get_stage_data(3)  # Get results for stage 3
```

- Automatically handles dependencies between stages
- Uses caching to avoid recalculating unchanged stages
- Generates cache keys based on decisions that affect a stage

### 3. Saving and Comparing Scenarios

Users can save complete scenarios and compare different decision sets:

```python
# Save current decisions as a scenario
scenario_id = process_manager.save_current_scenario("Scenario A")

# Compare multiple scenarios
comparison = process_manager.compare_scenarios([id1, id2])
```

### 4. Managing Default Values

Default values can be updated to change the behavior:

```python
# Update defaults for stage 1
process_manager.update_default_values(1, {"x": 20.0})

# Get current defaults
defaults = process_manager.get_default_values(1)
```

## Implementation Details

### Data Flow

1. Core data is provided at initialization
2. Each stage transforms data based on previous stage's output and decisions
3. The `_compute_stage()` method calculates each stage's results
4. The `_apply_transformation()` method handles actual business logic (must be customized)

### Caching Mechanism

1. Each stage result is cached using a key derived from decisions
2. Only relevant decisions (those that affect a given stage) are used for caching
3. Making a new decision invalidates cached results for subsequent stages

### Validation Process

1. Decision values are checked against schemas for each stage
2. Required fields must be present (unless defaults are used)
3. Field types must match schema definitions
4. Unexpected fields are not allowed

## Limitations and Constraints

1. **Linear Process Only**: The system assumes a strictly linear process flow
2. **Fixed Number of Stages**: Typically designed for 5 stages
3. **Schema Dependency**: All decisions must conform to predefined schemas
4. **No Parallel Processing**: Stages execute sequentially
5. **Limited Stage Communication**: Stages can only access results from previous stages

## Customization Points

To adapt the ProcessManager for specific use cases:

1. **Override `_apply_transformation()`**: Implement business logic for each stage
2. **Define Custom Schemas**: Create appropriate schemas for your decision points
3. **Customize Default Values**: Set appropriate defaults for your process
4. **Extend Stage Processing**: Add specialized computation or validation

## Usage Example

```python
# Initialize with core data
process_manager = ProcessManager(initial_data, use_defaults=True)

# Make decisions for each stage
process_manager.make_decisions(1, {"x": 10.5, "y": 2.0})
process_manager.make_decisions(2, {"z": 5.0})
process_manager.make_decisions(3, {"w": 7.0})
process_manager.make_decisions(4, {"v": 3.0})

# Get final result
final_result = process_manager.get_stage_data(5)

# Save the scenario
scenario_id = process_manager.save_current_scenario("Baseline Scenario")

# Try different decisions
process_manager.make_decisions(1, {"x": 12.0, "y": 1.5})
alt_scenario_id = process_manager.save_current_scenario("Alternative Scenario")

# Compare the scenarios
comparison = process_manager.compare_scenarios([scenario_id, alt_scenario_id])
```

## Best Practices

1. **Always validate results**: Check stage outputs to ensure they make sense
2. **Cache selectively**: For very large datasets, consider customizing the caching
3. **Document schemas clearly**: Make it obvious what each decision field controls
4. **Log intermediate results**: Add detailed logging for troubleshooting
5. **Handle default values carefully**: Make sure defaults produce reasonable outcomes

## Common Issues and Solutions

### Missing Required Fields
**Issue**: `InvalidDataError: Missing required keys: y`
**Solution**: Either provide all required fields in the decision or enable defaults.

### Type Mismatch
**Issue**: `InvalidDataError: Expected float for 'x', got str`
**Solution**: Ensure field types match the schema definitions.

### Cache Key Generation
**Issue**: `TypeError: generate_cache_key() got an unexpected keyword argument`
**Solution**: Ensure the function is called with the right parameters (decisions dictionary, not stage number).

### Default Values Not Applied
**Issue**: Default values not being used
**Solution**: Check that `use_defaults=True` and the DefaultValueManager is initialized.

## Extending the Framework

To extend this framework for more complex use cases:

1. **Custom Stage Types**: Create specialized stage classes for different types of processing
2. **Advanced Validation**: Add more sophisticated validation rules for decisions
3. **Dynamic Schema Generation**: Generate schemas based on process configuration
4. **Result Visualization**: Add methods to visualize stage results and scenario comparisons
5. **Persistence**: Add database integration to store and retrieve scenarios