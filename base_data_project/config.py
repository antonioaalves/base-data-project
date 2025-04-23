"""File containing basic project configurations"""

# Dependencies
import os
from pathlib import Path

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
                    'excluded_employees': '', # to create defaults, try using a list, and make sure the decision handling is not convertng it to a string
                    'excluded_lines': '', # to create defaults, try using a list, and make sure the decision handling is not convertng it to a string
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