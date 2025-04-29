"""Helper functions for the base data project framework."""

import logging
import pandas as pd
from typing import Dict, List, Any, Union

# only here to get the logger for this module
def setup_logger(project_name: str = 'base_data_project'):
    """
    Get a logger for the specified project.
    
    Args:
        project_name: The project name to use for logger
        
    Returns:
        Configured logger instance
    """
    logger = logging.getLogger(project_name)
    
    # Add a handler if none exists
    if not logger.handlers:
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s | %(levelname)8s | %(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
    
    return logger

# Get logger for this module
logger = setup_logger()

# TODO: contemplate on removing because it is not being used here (aligh with claude)
def validate_allocation_data(balls: List[Dict[str, Any]], bags: List[Dict[str, Any]]) -> bool:
    """
    Validate ball and bag data for allocation algorithm.
    
    Args:
        balls: List of ball dictionaries
        bags: List of bag dictionaries
        
    Returns:
        True if data is valid, False otherwise
    """
    logger.info("Validating allocation data")
    
    # Check for non-empty lists
    if not balls:
        logger.error("No balls provided for allocation")
        return False
    
    if not bags:
        logger.error("No bags provided for allocation")
        return False
    
    # Validate ball data
    for i, ball in enumerate(balls):
        if 'id' not in ball:
            logger.error(f"Ball at index {i} is missing 'id' field")
            return False
        if 'colors' not in ball:
            logger.error(f"Ball at index {i} is missing 'colors' field")
            return False
        if 'capacity_contribution' not in ball:
            logger.error(f"Ball at index {i} is missing 'capacity_contribution' field")
            return False
    
    # Validate bag data
    for i, bag in enumerate(bags):
        if 'capacity' not in bag:
            logger.error(f"Bag at index {i} is missing 'capacity' field")
            return False
        if 'color' not in bag:
            logger.error(f"Bag at index {i} is missing 'color' field")
            return False
    
    logger.info("Allocation data validation successful")
    return True

def generate_allocation_summary(
    bag_allocations: Dict[int, Dict[str, Any]], 
    unused_balls: List[int], 
    filled: bool
) -> Dict[str, Any]:
    """
    Generate a summary of an allocation result.
    
    Args:
        bag_allocations: Dictionary mapping bag indices to allocation information
        unused_balls: List of ball IDs that were not allocated
        filled: Whether all bags were filled to capacity
    
    Returns:
        Dictionary with allocation summary
    """
    total_bags = len(bag_allocations)
    total_allocated_balls = sum(len(bag['balls']) for bag in bag_allocations.values())
    total_unused_balls = len(unused_balls)
    
    # Calculate fill percentages
    total_capacity = sum(bag['objective_capacity'] for bag in bag_allocations.values())
    filled_capacity = sum(bag['filled_capacity'] for bag in bag_allocations.values())
    
    if total_capacity > 0:
        fill_percentage = (filled_capacity / total_capacity) * 100
    else:
        fill_percentage = 0
    
    # Count full bags
    full_bags = sum(1 for bag in bag_allocations.values() 
                   if bag['filled_capacity'] >= bag['objective_capacity'])
    
    # Create summary
    summary = {
        "status": "completed",
        "filled_completely": filled,
        "total_bags": total_bags,
        "full_bags": full_bags,
        "total_allocated_balls": total_allocated_balls,
        "total_unused_balls": total_unused_balls,
        "total_capacity": total_capacity,
        "filled_capacity": filled_capacity,
        "fill_percentage": fill_percentage
    }
    
    return summary