# Simple Substages Implementation Requirements

## Overview
This document outlines the requirements and changes needed to implement a "simple substages" feature for the Base Data Project framework. The substages feature will allow process stages to be divided into smaller, predefined components, providing more granular tracking and control over process execution.

## Requirements

### 1. Configuration Support
- Extend the stage configuration in `CONFIG` to include a `substages` property
- Allow specification of substage names, sequence, and optional properties
- Support default values for substage configuration

### 2. Process Management
- Add tracking of current substage within a stage
- Ensure proper state transitions between substages
- Allow substages to be marked as optional or required

### 3. Progress Tracking
- Track progress at the substage level
- Roll up substage progress into overall stage progress
- Support percentage completion for individual substages

### 4. Error Handling
- Handle errors at the substage level
- Allow for recovery or skip options for failed substages
- Propagate substage errors to the parent stage appropriately

### 5. Logging and Reporting
- Log entry/exit of substages
- Include substage information in process summaries
- Add substage status to process reports

## Changes Required

### In `process_management/manager.py`:
- Modify `_check_required_decisions` to understand substage requirements
- Update cache key generation to account for substage state
- Add methods for getting substage status

### In `process_management/stage_handler.py`:
- Add methods `start_substage`, `complete_substage`, and `track_substage_progress`
- Extend `get_stage_status` to include substage information
- Update `get_process_summary` to include substage status

### In `process_management/schemas.py`:
- Add substage-related schemas for configuration

### In Configuration (`config.py`):
- Add example substage configuration to the default CONFIG

### Example Configuration

```python
'stages': {
    'data_loading': {
        'sequence': 1,
        'requires_previous': False,
        'validation_required': True,
        'substages': {
            'connection': {
                'sequence': 1,
                'description': 'Establishing connection to data source'
            },
            'schema_validation': {
                'sequence': 2,
                'description': 'Validating data schema'
            },
            'data_extraction': {
                'sequence': 3,
                'description': 'Extracting data from source'
            }
        },
        'decisions': {
            'selections': {
                'apply_selection': True,
                'parameters': []
            }
        }
    },
    # Other stages...
}
```

## Usage Example

```python
# Start a stage
stage = stage_handler.start_stage("data_loading")

# Start a substage
stage_handler.start_substage("data_loading", "connection")

# Track progress within a substage
stage_handler.track_substage_progress(
    "data_loading", 
    "connection",
    0.5,  # 50% progress
    "Connecting to database"
)

# Complete a substage
stage_handler.complete_substage("data_loading", "connection", success=True)

# Complete the entire stage when all substages are done
stage_handler.complete_stage("data_loading", success=True)
```

## Implementation Strategy

1. First, extend the configuration model to support substages
2. Add the core substage tracking methods to the stage handler
3. Update the process manager to understand substage state
4. Enhance reporting and summary features
5. Add example implementation in the template project
6. Update documentation with substage usage examples
