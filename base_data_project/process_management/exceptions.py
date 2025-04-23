"""Exceptions for the process management module."""

class ProcessManagementError(Exception):
    """Base exception for process management errors."""
    pass

class InvalidStageSequenceError(ProcessManagementError):
    """Raised when attempting to create an invalid stage sequence."""
    pass

class ScenarioStateError(ProcessManagementError):
    """Raised when attempting an invalid scenario state transition."""
    pass

class DependencyError(ProcessManagementError):
    """Raised when stage dependencies are not met."""
    pass

class InvalidDataError(ProcessManagementError):
    """Raised when trying to store invalid data."""
    pass

class StageExecutionError(ProcessManagementError):
    """Raised when a stage execution fails."""
    pass

class DecisionValidationError(ProcessManagementError):
    """Raised when a decision fails validation."""
    pass