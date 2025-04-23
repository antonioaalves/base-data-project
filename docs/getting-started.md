# Getting Started with Base Data Project

This guide will help you quickly set up and begin working with the Base Data Project framework.

## Installation

Install the framework using pip:

```bash
pip install base-data-project
```

## Creating a New Project

The framework comes with a built-in CLI tool for creating new projects:

```bash
# Create a new project with the default template
base-data-project init my_new_project

# Create a new project with a specific template
base-data-project init my_new_project --template minimal_project

# List available templates
base-data-project list-templates
```

## Project Structure

After creating a new project, you'll have a directory structure like this:

```
my_new_project/
├── main.py                # Main entry point for interactive mode
├── batch_process.py       # Script for batch processing
├── routes.py              # API server (optional)
├── README.md              # Project documentation
├── requirements.txt       # Project dependencies
├── data/                  # Data directory
│   ├── csvs/              # Input CSV files
│   └── output/            # Output files
├── logs/                  # Log files
└── src/                   # Source code
    ├── __init__.py
    ├── config.py          # Project configuration
    ├── algorithms/        # Custom algorithms
    │   ├── __init__.py
    │   └── example_algorithm.py
    └── services/          # Business logic services
        ├── __init__.py
        └── example_service.py
```

## Configuration

The main configuration file is located at `src/config.py`. This file defines:

- Project name
- Available algorithms
- Process stages and decision points
- Default parameters
- File paths and directories

Here's an example of what you can customize in the config file:

```python
# Project name for logging and identification
PROJECT_NAME = "my_new_project"

CONFIG = {
    # Use database instead of CSV files
    'use_db': False,
    
    # Database connection (if use_db is True)
    'db_url': "sqlite:///data/production.db",
    
    # File paths for CSV data sources
    'dummy_data_filepaths': {
        'users': os.path.join(ROOT_DIR, 'data', 'csvs', 'users.csv'),
    },
    
    # Available algorithms
    'available_algorithms': [
        'my_custom_algorithm',
    ],
    
    # Process stages and decision points
    'stages': {
        'data_loading': {
            'sequence': 1,
            'requires_previous': False,
            'validation_required': True,
            'decisions': {
                'selections': {
                    'apply_selection': True,
                    'parameters': []
                }
            }
        },
        # Additional stages...
    }
}
```

## Running Your Project

### Interactive Mode

Interactive mode provides a step-by-step process with user prompts:

```bash
python main.py run-process
```

This will:
1. Initialize the data and process managers
2. Guide you through each stage of the process
3. Prompt for decisions where needed
4. Show progress and results

### Batch Mode

Batch mode runs the entire process non-interactively:

```bash
python batch_process.py --algorithm my_algorithm
```

Additional options:
- `--use-db`: Use database instead of CSV files
- `--no-tracking`: Disable process tracking

### API Server (Optional)

For HTTP access to functionality:

```bash
python routes.py
```

This starts a Flask server with endpoints for:
- `/health`: Health check endpoint
- `/process`: Start a new process
- `/data/<entity>`: Get data for a specific entity

## Expanding Your Project

### Adding a New Algorithm

1. Create a new file in `src/algorithms/` (e.g., `my_algorithm.py`)
2. Inherit from `base_data_project.algorithms.base.BaseAlgorithm`
3. Implement required methods: `adapt_data`, `execute_algorithm`, and `format_results`

Example:

```python
from base_data_project.algorithms.base import BaseAlgorithm

class MyAlgorithm(BaseAlgorithm):
    def adapt_data(self, data=None):
        # Transform data
        return transformed_data
        
    def execute_algorithm(self, adapted_data=None):
        # Execute algorithm
        return results
        
    def format_results(self, algorithm_results=None):
        # Format results
        return formatted_results
```

4. Register in `src/algorithms/__init__.py`
5. Add to available algorithms in `src/config.py`

## Next Steps

With your project set up, you can now:

1. **Customize the configuration** in `src/config.py`
2. **Add your data** to the `data/csvs` directory
3. **Implement custom algorithms** in `src/algorithms/`
4. **Develop business logic** in `src/services/`
5. **Run the process** using one of the execution methods

For more detailed information, refer to:
- [Data Management](data_management.md)
- [Process Management](process_management.md)
- [Algorithms](algorithms.md)
- [Examples](examples.md)
