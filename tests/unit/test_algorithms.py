# tests/unit/test_algorithms.py
import pytest
import pandas as pd
from base_data_project.algorithms.base import BaseAlgorithm
from base_data_project.algorithms.factory import AlgorithmFactory
from base_data_project.algorithms.examples.example_algorithm import ExampleAlgorithm

class TestBaseAlgorithm:
    
    @pytest.fixture
    def sample_algorithm(self):
        """Create a sample algorithm instance"""
        return ExampleAlgorithm(parameters={"threshold": 0.7, "max_iterations": 50})
    
    @pytest.fixture
    def sample_data(self):
        """Create sample data for algorithm testing"""
        return {
            "values": [1.0, 2.0, 3.0, 4.0, 5.0],
            "metadata": {"source": "test"}
        }
    
    def test_adapt_data(self, sample_algorithm, sample_data):
        """Test the adapt_data method"""
        adapted_data = sample_algorithm.adapt_data(sample_data)
        
        # Verify data was properly adapted
        assert "values" in adapted_data
        assert adapted_data["values"] == sample_data["values"]
        assert "metadata" in adapted_data
        assert "timestamp" in adapted_data
    
    def test_execute_algorithm(self, sample_algorithm, sample_data):
        """Test the execute_algorithm method"""
        adapted_data = sample_algorithm.adapt_data(sample_data)
        results = sample_algorithm.execute_algorithm(adapted_data)
        
        # Verify algorithm execution
        assert results["status"] == "success"
        assert results["parameters_used"]["threshold"] == 0.7
        assert "metrics" in results
        assert results["metrics"]["count"] == 5
        assert results["metrics"]["sum"] == 15.0
        assert results["metrics"]["mean"] == 3.0
    
    def test_format_results(self, sample_algorithm, sample_data):
        """Test the format_results method"""
        adapted_data = sample_algorithm.adapt_data(sample_data)
        algorithm_results = sample_algorithm.execute_algorithm(adapted_data)
        formatted_results = sample_algorithm.format_results(algorithm_results)
        
        # Verify result formatting
        assert formatted_results["algorithm_name"] == "ExampleAlgorithm"
        assert formatted_results["status"] == "success"
        assert "execution_time" in formatted_results
        assert "metrics" in formatted_results
    
    def test_run(self, sample_algorithm, sample_data):
        """Test the complete run method"""
        result = sample_algorithm.run(data=sample_data)
        
        # Verify complete pipeline
        assert result["algorithm_name"] == "ExampleAlgorithm"
        assert result["status"] == "completed"
        assert "metrics" in result
        assert "execution_time" in result

class TestAlgorithmFactory:
    
    def test_register_and_create_algorithm(self):
        """Test registering and creating an algorithm via factory"""
        # Clear any previously registered algorithms first to avoid conflicts
        AlgorithmFactory._registered_algorithms = {}
        
        # Register algorithm
        AlgorithmFactory.register_algorithm("example", ExampleAlgorithm)
        
        # Create algorithm
        algorithm = AlgorithmFactory.create_algorithm(
            "example", 
            parameters={"threshold": 0.8}
        )
        
        # Verify algorithm was created correctly
        assert isinstance(algorithm, ExampleAlgorithm)
        assert algorithm.parameters["threshold"] == 0.8
        
    def test_create_unregistered_algorithm(self):
        """Test behavior when creating an unregistered algorithm"""
        with pytest.raises(ValueError):
            AlgorithmFactory.create_algorithm("non_existent_algorithm")
    
    def test_list_available_algorithms(self):
        """Test listing available algorithms"""
        # Register algorithms
        AlgorithmFactory.register_algorithm("algo1", ExampleAlgorithm)
        AlgorithmFactory.register_algorithm("algo2", ExampleAlgorithm)
        
        # List algorithms
        available = AlgorithmFactory.list_available_algorithms()
        
        # Verify list contains registered algorithms
        assert "algo1" in available
        assert "algo2" in available