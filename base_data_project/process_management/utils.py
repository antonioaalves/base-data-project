"""Utility functions for process management."""

import json
import hashlib
from typing import Dict, List, Any, Optional, Tuple, Union, Type

def generate_cache_key(decisions: Dict[int, Dict[str, Any]]) -> str:
    """
    Generate a unique cache key from a set of decisions.
    
    Args:
        decisions: Dictionary of stage decisions
        
    Returns:
        String hash to use as cache key
    """
    try:
        # Convert to sorted JSON string for consistent hashing
        json_str = json.dumps(decisions, sort_keys=True)
        # Create a hash of the JSON string
        return hashlib.md5(json_str.encode()).hexdigest()
    except Exception as e:
        # Fallback to string representation
        return str(sorted(decisions.items()))

def validate_decision(decision: Dict[str, Any], schema: Type) -> Tuple[bool, Optional[str]]:
    """
    Validate a decision against its schema.
    
    Args:
        decision: Decision values to validate
        schema: Schema type to validate against
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    # Special case for dict schema - accept any keys
    if schema == dict:
        return True, None
        
    # Get required fields from schema
    annotations = getattr(schema, '__annotations__', {})
    
    # Check if schema is marked as total=False (optional fields)
    is_total = getattr(schema, '__total__', True)
    
    if is_total:
        # All fields are required
        required_keys = set(annotations.keys())
        
        # Check for missing required keys
        missing_keys = required_keys - set(decision.keys())
        if missing_keys:
            return False, f"Missing required keys: {', '.join(missing_keys)}"
    
    # Check for unexpected keys - skip this check if schema is dict
    unexpected_keys = set(decision.keys()) - set(annotations.keys())
    if unexpected_keys:
        return False, f"Unexpected keys: {', '.join(unexpected_keys)}"
    
    # Type validation - basic checks for primitive types
    for key, value in decision.items():
        if key not in annotations:
            continue
            
        expected_type = annotations[key]
        
        # Handling basic Python types
        if expected_type == float:
            if not isinstance(value, (int, float)):
                return False, f"Expected float for '{key}', got {type(value).__name__}"
            # Convert int to float if needed
            if isinstance(value, int):
                decision[key] = float(value)
        elif expected_type == int:
            if not isinstance(value, int):
                return False, f"Expected int for '{key}', got {type(value).__name__}"
        elif expected_type == str:
            if not isinstance(value, str):
                return False, f"Expected str for '{key}', got {type(value).__name__}"
        elif expected_type == bool:
            if not isinstance(value, bool):
                return False, f"Expected bool for '{key}', got {type(value).__name__}"
        elif expected_type == list or getattr(expected_type, '__origin__', None) == list:
            if not isinstance(value, list):
                return False, f"Expected list for '{key}', got {type(value).__name__}"
        elif expected_type == dict or getattr(expected_type, '__origin__', None) == dict:
            if not isinstance(value, dict):
                return False, f"Expected dict for '{key}', got {type(value).__name__}"
    
    return True, None

def get_relevant_decisions(all_decisions: Dict[int, Dict[str, Any]], stage: int) -> Dict[int, Dict[str, Any]]:
    """
    Get only the decisions that are relevant for a specific stage.
    
    Args:
        all_decisions: Dictionary of all decisions
        stage: The stage to get relevant decisions for
        
    Returns:
        Dictionary with only the decisions that affect the given stage
    """
    return {
        k: v for k, v in all_decisions.items()
        if k < stage  # Only decisions for earlier stages matter
    }

def summarize_decisions(decisions: Dict[int, Dict[str, Any]]) -> Dict[str, str]:
    """
    Create a human-readable summary of decisions.
    
    Args:
        decisions: Dictionary of decisions
        
    Returns:
        Dictionary with summarized decision information
    """
    summary = {}
    for stage, decision in decisions.items():
        summary[f"Stage {stage}"] = ", ".join([f"{k}={v}" for k, v in decision.items()])
    
    return summary

def format_scenario_summary(scenario: Dict[str, Any], index: int) -> Dict[str, Any]:
    """
    Format a scenario summary for display.
    
    Args:
        scenario: Complete scenario data
        index: Index of the scenario
        
    Returns:
        Dictionary with formatted summary information
    """
    return {
        "name": scenario["name"],
        "id": index,
        "timestamp": scenario["timestamp"],
        "decision_summary": summarize_decisions(scenario["decisions"])
    }

def decision_diff(decisions1: Dict[int, Dict[str, Any]], 
                 decisions2: Dict[int, Dict[str, Any]]) -> Dict[int, Dict[str, Any]]:
    """
    Find differences between two sets of decisions.
    Args:
        decisions1: First set of decisions
        decisions2: Second set of decisions
    Returns:
        Dictionary with differences
    """
    diff = {}
    all_stages = set(decisions1.keys()) | set(decisions2.keys())
    
    for stage in all_stages:
        stage_diff = {}
        
        # Get decisions for this stage from both sets
        d1 = decisions1.get(stage, {})
        d2 = decisions2.get(stage, {})
        
        # Find all keys from both
        all_keys = set(d1.keys()) | set(d2.keys())
        
        for key in all_keys:
            # If key exists in both and values differ
            if key in d1 and key in d2 and d1[key] != d2[key]:
                stage_diff[key] = {
                    "from": d1[key],
                    "to": d2[key]
                }
            # If key exists only in first set
            elif key in d1 and key not in d2:
                stage_diff[key] = {
                    "from": d1[key],
                    "to": None
                }
            # If key exists only in second set
            elif key not in d1 and key in d2:
                stage_diff[key] = {
                    "from": None,
                    "to": d2[key]
                }
        
        # Add to diff if there are differences at this stage
        if stage_diff:
            diff[stage] = stage_diff
    
    return diff

"""
Utility functions for working with intermediate data storage.
These can be added to base_data_project/utils.py
"""

def get_stored_stage_data(process_manager, stage_name: str, process_id: Optional[str] = None):
    """
    Retrieve stored data for a specific stage.
    
    Args:
        process_manager: The process manager instance
        stage_name: Name of the stage to retrieve data for
        process_id: Optional process ID (defaults to current process)
        
    Returns:
        The stored stage data or None if not found
    """
    if not hasattr(process_manager, 'stage_handler') or not process_manager.stage_handler:
        process_manager.logger.warning("No stage handler available, cannot retrieve stored data")
        return None
        
    stage_handler = process_manager.stage_handler
    
    if not hasattr(stage_handler, 'data_container') or not stage_handler.data_container:
        process_manager.logger.warning("No data container available, cannot retrieve stored data")
        return None
    
    # Use current process ID if not specified
    if not process_id and hasattr(stage_handler, 'current_process_id'):
        process_id = stage_handler.current_process_id
    
    try:
        return stage_handler.data_container.retrieve_stage_data(stage_name, process_id)
    except KeyError as e:
        process_manager.logger.warning(f"No data found for stage {stage_name}: {str(e)}")
        return None
    except Exception as e:
        process_manager.logger.error(f"Error retrieving stage data: {str(e)}")
        return None

def list_stored_data(process_manager, stage_name: Optional[str] = None, process_id: Optional[str] = None):
    """
    List available stored data.
    
    Args:
        process_manager: The process manager instance
        stage_name: Optional stage name to filter by
        process_id: Optional process ID to filter by
        
    Returns:
        List of available data summaries
    """
    if not hasattr(process_manager, 'stage_handler') or not process_manager.stage_handler:
        process_manager.logger.warning("No stage handler available, cannot list stored data")
        return []
        
    stage_handler = process_manager.stage_handler
    
    if not hasattr(stage_handler, 'data_container') or not stage_handler.data_container:
        process_manager.logger.warning("No data container available, cannot list stored data")
        return []
    
    # Build filters
    filters = {}
    if stage_name:
        filters['stage_name'] = stage_name
    if process_id:
        filters['process_id'] = process_id
    
    try:
        return stage_handler.data_container.list_available_data(filters)
    except Exception as e:
        process_manager.logger.error(f"Error listing stored data: {str(e)}")
        return []

def cleanup_stored_data(process_manager, policy: Optional[str] = None):
    """
    Clean up stored data based on policy.
    
    Args:
        process_manager: The process manager instance
        policy: Cleanup policy to apply ('keep_none', 'keep_latest', 'keep_all')
        
    Returns:
        True if cleanup was successful, False otherwise
    """
    if not hasattr(process_manager, 'stage_handler') or not process_manager.stage_handler:
        process_manager.logger.warning("No stage handler available, cannot clean up stored data")
        return False
        
    stage_handler = process_manager.stage_handler
    
    if not hasattr(stage_handler, 'data_container') or not stage_handler.data_container:
        process_manager.logger.warning("No data container available, cannot clean up stored data")
        return False
    
    try:
        stage_handler.data_container.cleanup(policy)
        return True
    except Exception as e:
        process_manager.logger.error(f"Error cleaning up stored data: {str(e)}")
        return False