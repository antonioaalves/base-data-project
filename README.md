# Base Data Project
v1.1.0

A standardized framework for data processing projects that provides:

- Consistent data management interfaces
- Process tracking and management
- Algorithm implementation patterns
- Configuration and logging standards

## Installation

```bash
pip install base-data-project
```

## Quick Start

### Creating a new project

```bash
# Create a new project with the default template
base-data-project init my_new_project

# Create a new project with a specific template
base-data-project init my_new_project --template minimal_project

# List available templates
base-data-project list-templates
```

### Using the framework in your code

```python
# Import components from the framework
from base_data_project.data_manager.factory import DataManagerFactory
from base_data_project.process_management.manager import ProcessManager
from base_data_project.utils import create_components
from base_data_project.log_config import setup_logger

# Set up logger
logger = setup_logger('my_project')

# Create data and process managers
data_manager, process_manager = create_components(use_db=False, no_tracking=False)

# Use data manager to load and save data
with data_manager:
    data = data_manager.load_data('users')
    processed_data = process_data(data)
    data_manager.save_data('processed_users', processed_data)
```

## Core Components

### Data Management

The data management layer provides abstraction over different data sources:

- **BaseDataManager**: Abstract base class for all data managers
- **CSVDataManager**: Implementation for CSV files
- **DBDataManager**: Implementation for databases
- **DataManagerFactory**: Factory for creating data manager instances

### Process Management

The process management layer tracks execution stages, decisions, and progress:

- **ProcessManager**: Manages decisions and caching
- **ProcessStageHandler**: Handles process stage execution flow
- **Exceptions**: Custom exceptions for process management errors

### Algorithm Framework

The algorithm framework provides a structure for implementing processing algorithms consistently:

- **BaseAlgorithm**: Abstract base class for all algorithms
- **AlgorithmFactory**: Factory for creating algorithm instances

### Utilities

- **Path Helpers**: Functions for working with project paths
- **Logging**: Configurable logging setup
- **Utilities**: Miscellaneous utility functions

## Templates

Base Data Project comes with multiple project templates:

- **base_project**: Complete project structure with all components
- **minimal_project**: Minimal project structure for simple use cases

## Documentation

For more detailed documentation, see the [full documentation](https://base-data-project.readthedocs.io/en/latest/).

## License

MIT