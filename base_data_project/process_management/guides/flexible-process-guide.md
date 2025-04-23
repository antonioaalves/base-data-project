# Flexible Process Manager Developer Guide

## Introduction

The Flexible Process Manager is a redesigned version of our process management system that allows for greater customization and adaptability. Rather than enforcing a rigid decision structure, it enables each process to define its own decision points, schemas, and validation rules.

This guide will help you understand how to use the flexible process manager to create custom processes.

## Core Concepts

The flexible process manager is built around these key concepts:

1. **Base Process Manager**: Provides the core infrastructure for decision management, caching, and scenario comparison.

2. **Process-Specific Extensions**: Each specific process inherits from the base manager and defines its own decision points and flow.

3. **Decision Registration**: Processes register their decision points with schemas and default values.

4. **Optional Decisions**: Not all stages require decisions, and some decisions can be optional.

5. **Flexible Stage Computation**: Each process implements its own stage computation logic.

## Creating a Custom Process

### 1. Define your Process-Specific Schemas

First, define the schemas for your process's decision points:

```python
from typing import Dict, Any, TypedDict

class MyProcessDecision1(TypedDict, total=True):
    """Decision schema for first decision point"""
    parameter1: str
    parameter2: int

class MyProcessDecision2(TypedDict, total=False):  # total=False makes all fields optional
    """Decision schema for second decision point (optional fields)"""
    optional_param1: float
    optional_param2: bool
```

### 2. Create your Process Class

Create a class that inherits from the base `ProcessManager` and registers its decision points:

```python
from src.process_management.flexible_process_manager import ProcessManager

class MyCustomProcess(ProcessManager):
    def __init__(self, core_data: Any):
        super().__init__(core_data)
        
        # Register decision points
        self.register_decision_point(
            stage=1,
            schema=MyProcessDecision1,
            required=True,
            defaults={
                "parameter1": "default",
                "parameter2": 10
            }
        )
        
        self.register_decision_point(
            stage=2,
            schema=MyProcessDecision2,
            required=False,  # This decision is optional
            defaults={
                "optional_param1": 1.0
                # Not providing a default for optional_param2
            }
        )
        
        # Initialize process-specific state
        self.my_data = None
        self.results = None
```

### 3. Implement Stage Computation Logic

Override the `_compute_stage` method to implement your process-specific logic:

```python
def _compute_stage(self, stage: int) -> Any:
    """Compute the result for a specific stage"""
    if stage == 1:
        return self._handle_stage1()
    elif stage == 2:
        return self._handle_stage2()
    elif stage == 3:
        return self._handle_stage3()
    else:
        raise InvalidDataError(f"Invalid stage: {stage}")

def _handle_stage1(self) -> Dict[str, Any]:
    """Implementation for stage 1"""
    # Get core data
    core_data = self.core_data
    
    # No decisions needed for this stage
    # Process the core data...
    
    return {"stage1_result": "processed data"}

def _handle_stage2(self) -> Dict[str, Any]:
    """Implementation for stage 2"""
    # Get previous stage result
    prev_data = self.get_stage_data(1)
    
    # Get decision for stage 1
    decision1 = self.current_decisions.get(1, {})
    param1 = decision1.get("parameter1")
    param2 = decision1.get("parameter2")
    
    # Process based on decision...
    
    return {"stage2_result": "processed with decision"}

def _handle_stage3(self) -> Dict[str, Any]:
    """Implementation for stage 3"""
    # Get previous stage result
    prev_data = self.get_stage_data(2)
    
    # Get optional decision for stage 2 (if provided)
    decision2 = self.current_decisions.get(2, {})
    opt_param1 = decision2.get("optional_param1", 1.0)  # Default if not provided
    opt_param2 = decision2.get("optional_param2", False)  # Default if not provided
    
    # Process based on decision...
    
    return {"stage3_result": "final result"}
```

### 4. Implement the Run Method

Provide a convenient `run` method that executes the entire process:

```python
def run(self) -> Dict[str, Any]:
    """Run the entire process"""
    # Get the final stage result
    final_result = self.get_stage_data(3)
    
    # You can do additional post-processing here
    
    return final_result
```

## Using Your Custom Process

Here's how to use your custom process:

```python
# Create the process with initial data
process = MyCustomProcess(core_data={"initial_data": "value"})

# Make decisions
process.make_decisions(1, {
    "parameter1": "custom_value",
    "parameter2": 20
})

# Optional decisions can be skipped or provided
if need_custom_settings:
    process.make_decisions(2, {
        "optional_param1": 2.5,
        "optional_param2": True
    })

# Run the process
result = process.run()

# Save scenario for later comparison
scenario_id = process.save_current_scenario("My Custom Settings")

# Try different settings
process.make_decisions(1, {
    "parameter1": "alternative",
    "parameter2": 15
})

# Run with new settings
new_result = process.run()

# Compare scenarios
comparison = process.compare_scenarios([scenario_id, process.save_current_scenario("Alternative")])
```

## Advanced Features

### Updating Default Values

You can update the default values for decision points:

```python
process.update_default_values(1, {
    "parameter1": "new_default"
})
```

### Loading Saved Scenarios

You can load previously saved scenarios:

```python
process.load_scenario(scenario_id)
```

### Customizing Validation

The flexible process manager uses TypedDict for basic validation, but you can extend this by overriding the `make_decisions` method:

```python
def make_decisions(self, stage: int, decision_values: Dict[str, Any], apply_defaults: bool = True) -> None:
    """Override to add custom validation"""
    # First, perform standard validation
    super().make_decisions(stage, decision_values, apply_defaults)
    
    # Then add custom validation
    if stage == 1:
        # Get the complete decision after defaults applied
        decision = self.current_decisions[stage]
        
        # Custom business rule validation
        if decision["parameter1"] == "special" and decision["parameter2"] < 10:
            raise InvalidDataError("When parameter1 is 'special', parameter2 must be at least 10")
```

## Best Practices

1. **Define Clear Schemas**: Use TypedDict with descriptive docstrings to make decision schemas clear.

2. **Use Meaningful Defaults**: Provide sensible default values for all parameters.

3. **Document Dependencies**: Clearly document which stages depend on which decisions.

4. **Handle Missing Decisions**: Use `get` with defaults when accessing decision values to handle cases where decisions are optional or not yet made.

5. **Maintain Backward Compatibility**: When updating schemas, ensure they remain compatible with saved scenarios.

6. **Cache Management**: Be aware of when cache invalidation happens and optimize accordingly.

7. **Error Handling**: Provide meaningful error messages when validation fails.

## Common Patterns

### Conditional Decisions

Some decisions may only be relevant based on other decisions:

```python
# Decision 1: Algorithm selection
process.make_decisions(1, {"algorithm": "advanced"})

# Decision 2: Only needed for "advanced" algorithm
if process.current_decisions[1]["algorithm"] == "advanced":
    process.make_decisions(2, {"advanced_parameter": 10})
```

### Parameter Presets

You can define presets for common parameter combinations:

```python
def apply_preset(self, preset_name: str) -> None:
    """Apply a predefined preset of decision values"""
    if preset_name == "high_precision":
        self.make_decisions(1, {"parameter1": "precise", "parameter2": 100})
        self.make_decisions(2, {"optional_param1": 0.001, "optional_param2": True})
    elif preset_name == "balanced":
        self.make_decisions(1, {"parameter1": "balanced", "parameter2": 50})
    elif preset_name == "fast":
        self.make_decisions(1, {"parameter1": "fast", "parameter2": 10})
        self.make_decisions(2, {"optional_param1": 1.0, "optional_param2": False})
```

### Progressive Refinement

Enable users to refine decisions progressively:

```python
# Start with basic settings
process.make_decisions(1, {"parameter1": "basic"})

# Run a preliminary analysis
prelim_result = process.get_stage_data(2)

# Refine settings based on preliminary results
if prelim_result["quality_indicator"] < 0.8:
    process.make_decisions(2, {"optional_param1": 0.5})

# Run the final stage
final_result = process.get_stage_data(3)
```

## Migration Guide

If you're migrating from the old process manager, follow these steps:

1. Identify all existing decision points and their schemas
2. Create TypedDict classes for each schema
3. Create a new process class that inherits from `ProcessManager`
4. Register the decision points with appropriate schemas and defaults
5. Implement stage computation methods
6. Update code that uses the process manager to use the new interface

## Conclusion

The flexible process manager provides a powerful framework for creating custom processes with varying decision structures. By allowing each process to define its own decision points, it enables a more adaptable and maintainable system while preserving the core functionality of decision management, caching, and scenario comparison.
