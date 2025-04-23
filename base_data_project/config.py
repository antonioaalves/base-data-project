"""Configuration utilities for the base data project framework."""

import os
from pathlib import Path
from typing import Dict, Any, Optional

# Project name - This should be overridden by specific projects
PROJECT_NAME = 'base_data_project'

# Get application root directory (where main.py is located)
ROOT_DIR = Path(__file__).resolve().parents[1]

CONFIG = {
    # Database configuration
    'use_db': False,
    'db_url': f"sqlite:///{os.path.join(ROOT_DIR, 'data', 'production.db')}",

    'empty_dataframes': [],
    
    # Base directories
    'data_dir': os.path.join(ROOT_DIR, 'data'),
    'output_dir': os.path.join(ROOT_DIR, 'data', 'output'),
    'log_dir': os.path.join(ROOT_DIR, 'logs'),
    
    # File paths
    'dummy_data_filepaths': {
        #'contract_types': os.path.join(ROOT_DIR, 'data', 'csvs', 'contracttype_table.csv'),
        #'demands': os.path.join(ROOT_DIR, 'data', 'csvs', 'demand_table.csv'),
        #'days_numbers': os.path.join(ROOT_DIR, 'data', 'csvs', 'daysnumber_table.csv')
    },
    
    # Available algorithms (used by AlgorithmFactory)
    'available_algorithms': [],
    
    # Process configuration
    'stages': {
        'stage_name1': {
            'sequence': 1,
            'requires_previous': False,
            'validation_required': True,
            'decisions': {
                'selections': {
                    'apply_selection': True,
                    'months': [1],
                    'years': [2024]
                }
            }
        },
        'stage_name2': {
            'sequence': 2,
            'requires_previous': True,
            'validation_required': True,
            'decisions': {
                'filtering':{
                    'apply_filtering': False,
                    'excluded_employees': [], # to create defaults, try using a list, and make sure the decision handling is not convertng it to a string
                    'excluded_lines': [], # to create defaults, try using a list, and make sure the decision handling is not convertng it to a string
                },
                'time_periods': 1
            }
        },
        'stage_name3': {
            'sequence': 3,
            'requires_previous': True,
            'validation_required': True,
            'decisions': {
                'product_assignments': {
                    'product_id': [],
                    'production_line_id': [],
                    'quantity': []
                }
            }
        },
        'stage_name4': {
            'sequence': 4,  
            'requires_previous': True,
            'validation_required': True,
            'decisions': {
                'algorithms': [] # TODO: add 'decisions' hierarchy as the others stages
            }
        },
        'stage_name5': {
            'sequence': 5,
            'requires_previous': True,
            'validation_required': True,
            'decisions': {
                'changes': {
                    'add_changes': False,
                    'special_allocations': {}
                },
                'generate_report': False
            }
        }
    },
    
    # Algorithm parameters
    'algorithm_defaults': {
        'algorithm_name1': {
            'sort_strategy': '',
            'prioritize_high_capacity': True
        },
        'algorithm_name2': {
            'temporal_space': 1,
            'objective_weights': {
                'understaffing': 1.0,
                'overstaffing': 1.0
            }
        }
    },

    # Note: this is only needed if there is a logic in the project to save files
    # Output configuration
    'output': {
        'base_dir': 'data/output',
        'visualizations_dir': 'data/output/visualizations',
        'diagnostics_dir': 'data/diagnostics'
    },
    
    # Logging configuration
    'log_level': 'INFO',
    'log_format': '%(asctime)s | %(levelname)8s | %(filename)s:%(lineno)d | %(message)s',
    'log_dir': 'logs'
}

def get_config() -> Dict[str, Any]:
    """
    Get the configuration dictionary.
    
    Returns:
        Dictionary with configuration values
    """
    return CONFIG

def update_config(new_values: Dict[str, Any]) -> None:
    """
    Update the configuration with new values.
    
    Args:
        new_values: Dictionary with new configuration values
    """
    global CONFIG
    
    # Recursively update nested dictionaries
    def update_dict(d, u):
        for k, v in u.items():
            if isinstance(v, dict) and k in d and isinstance(d[k], dict):
                update_dict(d[k], v)
            else:
                d[k] = v
    
    update_dict(CONFIG, new_values)

def get_config_value(path: str, default: Any = None) -> Any:
    """
    Get a specific configuration value using dot notation.
    
    Args:
        path: Path to the configuration value using dot notation
              (e.g., 'database.connection.host')
        default: Default value to return if the path is not found
        
    Returns:
        Configuration value or default if not found
    """
    parts = path.split('.')
    value = CONFIG
    
    try:
        for part in parts:
            value = value[part]
        return value
    except (KeyError, TypeError):
        return default

def set_project_name(name: str) -> None:
    """
    Set the project name.
    
    Args:
        name: Project name
    """
    global PROJECT_NAME
    PROJECT_NAME = name
    # Also update in CONFIG
    CONFIG['PROJECT_NAME'] = name