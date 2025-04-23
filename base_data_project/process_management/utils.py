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