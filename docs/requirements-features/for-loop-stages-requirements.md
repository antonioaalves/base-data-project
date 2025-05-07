# For Loop Stages Implementation Requirements

## Overview
This document outlines the requirements and changes needed to implement a "for loop stages" feature for the Base Data Project framework. The for loop stages feature will allow the dynamic repetition of a stage or sequence of substages based on user decisions or data-driven criteria, with the number of iterations not known in advance.

## Requirements

### 1. Loop Configuration Support
- Extend the stage configuration in `CONFIG` to include loop properties
- Support loop condition specification (fixed count, data-driven, or decision-based)
- Allow per-iteration configuration and parameter changes
- Define how substages will be executed for each iteration

### 2. Loop State Management
- Track the current iteration number
- Maintain separate state for each iteration
- Support pausing, resuming, or terminating loops based on conditions
- Handle loop completion detection

### 3. Decision Integration
- Allow decisions to influence loop behavior (continue, break, modify)
- Support collection of decisions at each iteration
- Provide mechanisms for decisions in one iteration to affect subsequent iterations
- Enable loop initialization decisions (e.g., setting up iteration parameters)

### 4. Progress Tracking
- Track progress across all iterations
- Show both iteration-specific and overall loop progress
- Support estimated completion calculation based on completed iterations

### 5. Error Handling
- Provide strategies for handling errors in specific iterations
- Define retry policies for failed iterations
- Allow loop continuation even after iteration failures
- Support rollback of failed iterations

### 6. Results Management
- Collect and aggregate results from each iteration
- Provide summary statistics across all iterations
- Enable passing of intermediate results between iterations
- Support final result transformation/aggregation

## Changes Required

### In `process_management/manager.py`:
- Add loop state tracking to the process manager
- Implement iteration management logic
- Extend caching to handle iteration-specific data
- Add methods for managing loop execution

### In `process_management/stage_handler.py`:
- Add methods like `start_loop`, `start_iteration`, `complete_iteration`, and `complete_loop`
- Extend stage status tracking to include loop information
- Add functionality to track progress across iterations
- Implement loop condition evaluation

### In `process_management/schemas.py`:
- Add loop configuration schemas
- Define iteration state schema
- Create schemas for loop conditions and iteration parameters

### In Configuration (`config.py`):
- Add example loop stage configuration to the default CONFIG

### Example Configuration

```python
'stages': {
    'data_processing': {
        'sequence': 3,
        'requires_previous': True,
        'validation_required': True,
        'loop_config': {
            'enabled': True,
            'type': 'dynamic',  # 'fixed', 'dynamic', or 'condition-based'
            'init_decision': 'processing_initialization',
            'iteration_decision': 'iteration_parameters',
            'continue_condition': 'has_more_data',
            'max_iterations': 10,  # Safety limit
            'iteration_data_key': 'data_batch'
        },
        'substages': {
            'prepare_iteration': {
                'sequence': 1,
                'description': 'Prepare data for current iteration'
            },
            'process_batch': {
                'sequence': 2,
                'description': 'Process the current data batch'
            },
            'validate_results': {
                'sequence': 3,
                'description': 'Validate results from this iteration'
            },
            'store_iteration_results': {
                'sequence': 4,
                'description': 'Store results from this iteration'
            }
        },
        'decisions': {
            'processing_initialization': {
                'batch_size': 100,
                'processing_mode': 'standard'
            },
            'iteration_parameters': {
                'apply_filters': True,
                'threshold': 0.5
            }
        }
    },
    # Other stages...
}
```

## Usage Example

```python
# Start a loop stage
stage = stage_handler.start_stage("data_processing")

# Initialize the loop
loop_config = stage_handler.initialize_loop(
    "data_processing", 
    initial_data={"total_items": 500}
)

# Process each iteration
while stage_handler.has_next_iteration("data_processing"):
    # Start the next iteration
    iteration = stage_handler.start_iteration("data_processing")
    current_iteration = iteration['current']
    
    # Process this iteration's substages
    stage_handler.start_substage("data_processing", "prepare_iteration")
    # ... do preparation work ...
    stage_handler.complete_substage("data_processing", "prepare_iteration", success=True)
    
    stage_handler.start_substage("data_processing", "process_batch")
    # ... process the batch ...
    stage_handler.complete_substage("data_processing", "process_batch", success=True)
    
    stage_handler.start_substage("data_processing", "validate_results")
    # ... validate the results ...
    stage_handler.complete_substage("data_processing", "validate_results", success=True)
    
    stage_handler.start_substage("data_processing", "store_iteration_results")
    # ... store the results ...
    stage_handler.complete_substage("data_processing", "store_iteration_results", success=True)
    
    # Complete this iteration
    stage_handler.complete_iteration(
        "data_processing", 
        success=True, 
        iteration_results={"processed_items": 100, "success_rate": 0.98}
    )
    
    # Update loop condition if needed
    if some_condition:
        stage_handler.update_loop_condition("data_processing", continue_loop=False)

# Complete the loop stage
loop_summary = stage_handler.complete_loop("data_processing")
stage_handler.complete_stage("data_processing", success=True, result_data=loop_summary)
```

## Implementation Strategy

1. First implement the simpler substages feature as a foundation
2. Extend the process manager to track iteration state
3. Add loop configuration to the configuration schema
4. Implement the loop control methods in the stage handler
5. Add iteration tracking and results aggregation
6. Create example templates demonstrating loop usage
7. Update documentation with loop usage examples
8. Add visualization support for loop progress

## Dependencies

- Simple substages feature should be implemented first
- Requires extended decision management to handle per-iteration decisions
- May need enhanced caching mechanisms to handle iteration-specific state
