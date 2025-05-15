import pytest
import logging
from typing import Dict, Any

class BaseTest:
    """Base class for all unit tests with common functionality"""
    
    @pytest.fixture
    def mock_config(self) -> Dict[str, Any]:
        """Basic configuration for testing"""
        return {
            'PROJECT_NAME': 'test_project',
            'data_dir': 'test_data',
            'output_dir': 'test_output',
            'log_level': 'INFO'
        }
    
    @pytest.fixture
    def setup_logging(self):
        """Configure logging for tests"""
        logging.basicConfig(level=logging.INFO)
        logger = logging.getLogger('test_project')
        return logger