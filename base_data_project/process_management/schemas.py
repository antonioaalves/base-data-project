"""
Flexible Process Schema Definitions

This module defines the base schemas and utilities for the flexible process manager.
"""

# Note: change for what is the specific projects business logic.

from typing import Dict, List, Any, TypedDict, Type, Optional, Union
from enum import Enum

# Base class for all decision schemas
class DecisionSchema(TypedDict, total=True):
    """Base type for decision values"""
    pass

# Base class for all stage result schemas
class StageResultSchema(TypedDict, total=True):
    """Base type for stage results"""
    pass

# Scenario related schemas
class ScenarioSummary(TypedDict):
    """Summary information for a saved scenario"""
    name: str
    id: int
    timestamp: Any
    
class SavedScenario(TypedDict):
    """Complete saved scenario"""
    name: str
    decisions: Dict[int, Dict[str, Any]]
    timestamp: Any

# Process Stage Status Enum
class StageStatus(str, Enum):
    """Enum for process stage status"""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    SKIPPED = "skipped"
    
# Decision Point Registration Information
class DecisionPointInfo(TypedDict):
    """Information about a registered decision point"""
    required: bool
    schema: Type[DecisionSchema]
    defaults: Dict[str, Any]
    description: str

# Process Configuration
class ProcessConfig(TypedDict):
    """Configuration for a process"""
    name: str
    description: str
    stages: Dict[int, Dict[str, Any]]
    decision_points: Dict[int, DecisionPointInfo]