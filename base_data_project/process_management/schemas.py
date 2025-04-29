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

# NEW: Substage Status Enum (same as StageStatus for consistency)
class SubstageStatus(str, Enum):
    """Enum for process substage status"""
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

# NEW: Substage Configuration Schema
class SubstageConfig(TypedDict, total=False):
    """Configuration for a substage within a process stage"""
    sequence: int
    description: str
    optional: bool
    auto_start: bool
    weight: float
    validation_required: bool
    timeout_seconds: Optional[int]
    retry_on_failure: bool
    max_retries: int
    dependencies: List[str]  # List of other substage names this depends on

# NEW: Substage Information Schema
class SubstageInfo(TypedDict):
    """Information about a substage's current state"""
    name: str
    sequence: int
    status: SubstageStatus
    progress: float
    started_at: Optional[Any]
    completed_at: Optional[Any]
    error_message: Optional[str]
    optional: bool
    description: str
    tracking_data: List[Dict[str, Any]]
    result_data: Dict[str, Any]

# NEW: Substage Summary Schema
class SubstageSummary(TypedDict):
    """Summary information for substages"""
    info: Dict[str, SubstageInfo]
    active_substage: Optional[str]
    status_counts: Dict[str, int]
    total: int
    completed: int
    progress: float

# Update Stage Configuration to include substages
class StageConfig(TypedDict, total=False):
    """Configuration for a process stage"""
    sequence: int
    requires_previous: bool
    validation_required: bool
    decisions: Dict[str, Dict[str, Any]]
    algorithms: List[str]
    substages: Dict[str, SubstageConfig]  # NEW: Added substages configuration
    auto_complete_on_substages: bool      # NEW: Option to auto-complete when substages finish

# Process Configuration
class ProcessConfig(TypedDict):
    """Configuration for a process"""
    name: str
    description: str
    stages: Dict[int, Dict[str, Any]]
    decision_points: Dict[int, DecisionPointInfo]