# Process Management

The process management layer of the Base Data Project framework provides a structured approach to managing multi-stage data processing flows with decision tracking, progress monitoring, and caching capabilities.

## Core Concepts

The process management system is built around these key concepts:

1. **Process**: A complete data processing flow, from raw data to final results
2. **Stages**: Sequential steps in the process (e.g., data loading, transformation, processing)
3. **Decisions**: User choices that affect how stages are executed
4. **Progress Tracking**: Monitoring and recording process execution
5. **Caching**: Avoiding redundant calculations when inputs haven't changed

## Main Components

### ProcessManager

The `ProcessManager` handles decision tracking, caching, and scenario management. It provides:

- Decision recording and validation
- Stage computation caching
- Scenario saving and comparison
- Default value management

### ProcessStageHandler

The `ProcessStageHandler` manages the execution flow of process stages:

- Stage initialization and execution
- Progress tracking
- Stage status recording
- Decision tracking

## Using Process Management

### Basic Usage

```python
from base_data_project.utils import create_components
from base_data_project.process_management.manager import ProcessManager
from base_data_project.process_management.stage_handler import ProcessStageHandler

# Create components
data_manager, process_manager = create_components(
    use_db=False,
    no_tracking=False,  # Enable process tracking
    config=CONFIG
)

# Use stage handler to manage execution flow
stage_handler = ProcessStageHandler(process_manager, CONFIG)

# Initialize a new process
process_id = stage_handler.initialize_process(
    "My Process",
    "Process description"
)

# Start a stage
stage = stage_handler.start_stage("data_loading")

# Record a decision
stage_handler.record_stage_decision(
    "data_loading",
    "selections",
    {"apply_selection": True, "filters": ["field1", "field2"]}
)

# Track progress during execution
stage_handler.track_progress(
    "data_loading",
    0.5,  # 50% progress
    "Loading data from source files",
    {"files_processed": 5, "total_files": 10}
)

# Complete a stage
stage_handler.complete_stage(
    "data_loading",
    success=True,
    result_data={"rows_loaded": 1000, "files_processed": 10}
)

# Get process summary
summary = stage_handler.get_process_summary()
```

### Making Decisions

Decisions are recorded at specific points in the process and affect how subsequent stages are executed:

```python
# Directly using the process manager
process_manager.make_decisions(
    1,  # Stage number
    {
        "parameter1": "value1",
        "parameter2": 42,
        "parameter3": True
    }
)

# Using the stage handler
stage_handler.record_stage_decision(
    "processing",  # Stage name
    "algorithm_selection",  # Decision name
    {
        "algorithm": "example_algorithm",
        "parameters": {
            "threshold": 0.75,
            "max_iterations": 100
        }
    }
)
```

### Getting Stage Results

The process manager caches stage results to avoid redundant calculations:

```python
# Get results for a specific stage
stage_data = process_manager.get_stage_data(3)  # Stage 3

# Use the results
if stage_data["status"] == "success":
    # Access result data
    results = stage_data["results"]
    
    # Do something with the results
    print(f"Found {len(results)} items")
```

### Saving and Comparing Scenarios

You can save the current set of decisions as a named scenario:

```python
# Make decisions
process_manager.make_decisions(1, {"parameter1": "value1"})
process_manager.make_decisions(2, {"parameter2": 42})

# Save the current scenario
scenario_id = process_manager.save_current_scenario("Baseline Scenario")

# Make different decisions
process_manager.make_decisions(1, {"parameter1": "alternative"})

# Save as another scenario
alt_scenario_id = process_manager.save_current_scenario("Alternative Scenario")

# Get list of saved scenarios
scenarios = process_manager.get_saved_scenarios()

# Compare scenarios
comparison = process_manager.compare_scenarios([scenario_id, alt_scenario_id])

# Load a saved scenario
process_manager.load_scenario(scenario_id)
```

## Process Flow and Caching

### How Caching Works

1. The process manager generates a unique cache key for each stage based on the decisions that affect it
2. When `get_stage_data()` is called, it checks if the result is already in the cache
3. If found, it returns the cached result; otherwise, it computes the result
4. When decisions change, the cache for affected stages is invalidated

```python
# This will compute the result for stage 2
result1 = process_manager.get_stage_data(2)

# This will use the cached result (same inputs)
result2 = process_manager.get_stage_data(2)

# Make a new decision that affects stage 2
process_manager.make_decisions(1, {"new_value": 10})

# This will compute a new result (inputs changed)
result3 = process_manager.get_stage_data(2)
```

## Advanced Usage

### Custom Process Implementation

For more complex processes, you can extend the base `ProcessManager`:

```python
from base_data_project.process_management.manager import ProcessManager

class MyCustomProcess(ProcessManager):
    def __init__(self, core_data):
        super().__init__(core_data)
        
        # Register decision points
        self.register_decision_point(
            stage=1,
            schema=dict,  # Use TypedDict for more structured validation
            required=True,
            defaults={"parameter1": "default", "parameter2": 10}
        )
        
    def _compute_stage(self, stage: int):
        """Override to implement custom stage computation logic"""
        if stage == 1:
            return self._handle_stage1()
        elif stage == 2:
            return self._handle_stage2()
        # etc.
        
    def _handle_stage1(self):
        """Custom implementation for stage 1"""
        # Get core data
        data = self.core_data
        
        # Process data
        result = process_data(data)
        
        return result
```

### Tracking Process Execution

For detailed execution tracking, you can use the `track_progress` method:

```python
def process_large_dataset(data, stage_handler):
    total_rows = len(data)
    
    for i, chunk in enumerate(chunks(data, 1000)):
        # Process chunk
        process_chunk(chunk)
        
        # Track progress
        progress = (i + 1) * 1000 / total_rows
        stage_handler.track_progress(
            "processing",
            min(progress, 1.0),  # Ensure progress is between 0 and 1
            f"Processed {(i + 1) * 1000} of {total_rows} rows",
            {"chunk": i + 1, "total_chunks": (total_rows // 1000) + 1}
        )
```

## Best Practices

1. **Organize complex processes into well-defined stages** with clear inputs and outputs

2. **Make decisions explicit** by using the decision-tracking mechanism rather than passing parameters directly

3. **Use scenarios** to compare different approaches to the same problem

4. **Track progress** during long-running operations to provide feedback to users

5. **Design for caching efficiency** by ensuring each stage only depends on necessary decisions

6. **Handle errors gracefully** and provide clear error messages:
   ```python
   try:
       stage_handler.start_stage("processing")
       # Process data
       stage_handler.complete_stage("processing", success=True, result_data=results)
   except Exception as e:
       logger.error(f"Processing failed: {str(e)}")
       stage_handler.complete_stage("processing", success=False, result_data={"error": str(e)})
   ```

## Common Issues and Solutions

### Issue: Invalid Decision Error

```
InvalidDataError: Missing required keys: parameter2
```

**Solution:**
1. Ensure all required fields are provided in the decision
2. Use default values for optional fields
3. Check schema definition for the decision point

### Issue: Cache Not Working as Expected

**Solution:**
1. Make sure all relevant information is captured in decisions
2. Check if caching is disabled
3. Verify that the stage depends on the correct decisions

### Issue: Process Flow Errors

```
InvalidStageSequenceError: Cannot start stage processing: previous stage data_loading not completed
```

**Solution:**
1. Ensure stages are executed in the correct order
2. Check stage dependencies in the configuration
3. Verify that required stages are completed successfully

### Issue: Memory Issues with Large Result Caching

**Solution:**
1. Ensure stage results are serializable
2. Consider implementing custom caching for very large results
3. Use references to large objects instead of storing complete copies

## Custom Process Extensions

For more complex applications, you can build a custom process on top of the base framework:

1. Create a subclass of `ProcessManager`
2. Define your decision schemas using `TypedDict`
3. Register decision points with schemas and defaults
4. Implement stage computation logic
5. Add domain-specific functionality

See the [Flexible Process Guide](process_management/guides/flexible-process-guide.md) for detailed information on creating custom processes.
