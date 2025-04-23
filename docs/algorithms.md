# Algorithms Framework

The algorithms framework in the Base Data Project provides a standardized approach to implementing data processing algorithms. This ensures consistency across implementations while providing flexibility for custom logic.

## Core Concepts

The algorithm framework is built around these key concepts:

1. **BaseAlgorithm**: Abstract base class for all algorithms
2. **AlgorithmFactory**: Factory for creating algorithm instances
3. **Execution Flow**: Standard three-stage execution pattern
4. **Result Formatting**: Consistent structure for algorithm outputs

## Main Components

### BaseAlgorithm

The `BaseAlgorithm` class defines the interface and common functionality for all algorithms:

- Initialization with parameters
- Standard execution flow
- Logging and error handling
- Status and execution time tracking

### AlgorithmFactory

The `AlgorithmFactory` centralizes algorithm creation:

- Registration of algorithm classes
- Dynamic algorithm loading
- Parameter management
- Name normalization

## Algorithm Structure

Every algorithm implements three main methods:

1. **adapt_data**: Transform input data into algorithm-specific format
2. **execute_algorithm**: Core algorithm logic
3. **format_results**: Convert raw results to a standardized structure

```python
from base_data_project.algorithms.base import BaseAlgorithm

class MyAlgorithm(BaseAlgorithm):
    def adapt_data(self, data=None):
        """Transform input data into algorithm-specific format"""
        # Implementation
        return transformed_data
        
    def execute_algorithm(self, adapted_data=None):
        """Execute the core algorithm logic"""
        # Implementation
        return results
        
    def format_results(self, algorithm_results=None):
        """Format results into a standardized structure"""
        # Implementation
        return formatted_results
```

## Using Algorithms

### Creating Algorithm Instances

The recommended way to create algorithm instances is through the `AlgorithmFactory`:

```python
from base_data_project.algorithms.factory import AlgorithmFactory

# Create an algorithm instance
algorithm = AlgorithmFactory.create_algorithm(
    algorithm_name="example_algorithm",
    parameters={
        "threshold": 0.75,
        "max_iterations": 100
    }
)
```

### Running Algorithms

Once you have an algorithm instance, you can run it with the `run` method:

```python
# Run the algorithm with data
result = algorithm.run(data)

# Check for successful execution
if result["status"] == "completed":
    # Access the results
    output = result["data"]
    metrics = result["metrics"]
    
    # Use the results
    print(f"Algorithm completed in {result['execution_time']:.2f} seconds")
    print(f"Accuracy: {metrics.get('accuracy', 'N/A')}")
else:
    # Handle failure
    print(f"Algorithm failed: {result['error']}")
```

### Getting Algorithm Status

You can check the status of an algorithm after execution:

```python
status = algorithm.get_status()

print(f"Algorithm: {status['algorithm_name']}")
print(f"Status: {status['status']}")
print(f"Execution time: {status['execution_time']} seconds")

if status['error']:
    print(f"Error: {status['error']}")
```

## Implementing Custom Algorithms

### Basic Implementation

To create a custom algorithm, inherit from `BaseAlgorithm` and implement the required methods:

```python
from base_data_project.algorithms.base import BaseAlgorithm
import pandas as pd

class MyCustomAlgorithm(BaseAlgorithm):
    def __init__(self, algo_name="MyCustomAlgorithm", parameters=None):
        super().__init__(algo_name=algo_name, parameters=parameters or {})
        # Add algorithm-specific initialization

    def adapt_data(self, data=None):
        """Adapt data to algorithm format"""
        self.logger.info("Adapting data for MyCustomAlgorithm")
        
        if data is None:
            return None
            
        # Example: Extract specific columns from DataFrame
        if isinstance(data, pd.DataFrame):
            required_columns = ['feature1', 'feature2', 'target']
            
            # Check for required columns
            for column in required_columns:
                if column not in data.columns:
                    self.logger.warning(f"Missing required column: {column}")
            
            # Select and transform columns
            adapted_data = data[required_columns].copy()
            
            # Perform any necessary preprocessing
            adapted_data['feature1'] = adapted_data['feature1'].fillna(0)
            adapted_data['feature2'] = adapted_data['feature2'].fillna(0)
            
            return adapted_data
        else:
            self.logger.warning("Expected DataFrame, got different data type")
            return data

    def execute_algorithm(self, adapted_data=None):
        """Execute the core algorithm logic"""
        self.logger.info("Executing MyCustomAlgorithm")
        
        # Get algorithm parameters
        threshold = self.parameters.get('threshold', 0.5)
        max_iterations = self.parameters.get('max_iterations', 100)
        
        try:
            # Example algorithm implementation
            results = {
                'predictions': [],
                'metrics': {},
                'intermediate_steps': []
            }
            
            if adapted_data is not None and isinstance(adapted_data, pd.DataFrame):
                # Simple example: classify based on threshold
                feature_sum = adapted_data['feature1'] + adapted_data['feature2']
                predictions = (feature_sum > threshold).astype(int)
                
                # Calculate metrics
                if 'target' in adapted_data.columns:
                    accuracy = (predictions == adapted_data['target']).mean()
                    true_positives = ((predictions == 1) & (adapted_data['target'] == 1)).sum()
                    false_positives = ((predictions == 1) & (adapted_data['target'] == 0)).sum()
                    
                    results['metrics'] = {
                        'accuracy': accuracy,
                        'true_positives': true_positives,
                        'false_positives': false_positives
                    }
                
                results['predictions'] = predictions.tolist()
            
            return results
            
        except Exception as e:
            self.logger.error(f"Error executing algorithm: {str(e)}")
            raise

    def format_results(self, algorithm_results=None):
        """Format the results into a standardized structure"""
        self.logger.info("Formatting results for MyCustomAlgorithm")
        
        if algorithm_results is None:
            self.logger.warning("No algorithm results to format")
            return {
                "algorithm_name": self.algo_name,
                "status": "failed",
                "error": "No results to format"
            }
            
        # Create standardized result structure
        formatted_results = {
            "algorithm_name": self.algo_name,
            "status": "completed",
            "execution_time": self.execution_time,
            "metrics": algorithm_results.get('metrics', {}),
            "data": {
                "predictions": algorithm_results.get('predictions', []),
                "count": len(algorithm_results.get('predictions', [])),
                "parameters_used": self.parameters
            }
        }
        
        return formatted_results
```

### Registering Custom Algorithms

Once you've implemented your algorithm, you need to register it with the `AlgorithmFactory`:

```python
from base_data_project.algorithms.factory import AlgorithmFactory

# Register the algorithm
AlgorithmFactory.register_algorithm('my_custom_algorithm', MyCustomAlgorithm)

# Now you can create instances using the factory
algorithm = AlgorithmFactory.create_algorithm('my_custom_algorithm', parameters={
    'threshold': 0.75,
    'max_iterations': 50
})
```

Alternatively, if your algorithm is in a module that follows the naming convention, it will be automatically discovered:

```python
# In src/algorithms/my_custom_algorithm.py
from base_data_project.algorithms.base import BaseAlgorithm

class MyCustomAlgorithm(BaseAlgorithm):
    # Implementation
    pass
```

Then in `src/algorithms/__init__.py`:

```python
from src.algorithms.my_custom_algorithm import MyCustomAlgorithm

__all__ = ['MyCustomAlgorithm']
```

And in `src/config.py`:

```python
CONFIG = {
    # ...
    'available_algorithms': [
        'my_custom_algorithm',
        # ...
    ]
}
```

## Example Algorithms

The framework comes with example algorithm implementations that you can use as reference:

### ExampleAlgorithm

A basic example showing the standard algorithm structure:

```python
from base_data_project.algorithms.examples.example_algorithm import ExampleAlgorithm

algorithm = ExampleAlgorithm(parameters={
    'threshold': 0.5,
    'max_iterations': 100
})
```

### FillBagsAlgorithm

An example implementing a bag filling algorithm:

```python
from base_data_project.algorithms.examples.fill_bags import FillBagsAlgorithm

algorithm = FillBagsAlgorithm(data=data_manager, parameters={
    'sort_strategy': 'capacity',
    'prioritize_high_capacity': True
})
```

### LpAlgo

An example implementing a linear programming optimization algorithm:

```python
from base_data_project.algorithms.examples.lp_algo import LpAlgo

algorithm = LpAlgo(data=data_manager, parameters={
    'temporal_space': 1,
    'objective_weights': {
        'understaffing': 1.0,
        'overstaffing': 1.0
    }
})
```

## Best Practices

1. **Follow the three-stage execution pattern** (adapt, execute, format) to maintain consistency

2. **Use descriptive parameter names** with sensible defaults:
   ```python
   def __init__(self, algo_name=None, parameters=None):
       # Use default parameter values
       params = {
           'threshold': 0.5,
           'max_iterations': 100,
           'tolerance': 0.001
       }
       # Update with provided parameters
       if parameters:
           params.update(parameters)
       
       super().__init__(algo_name=algo_name or "MyAlgorithm", parameters=params)
   ```

3. **Implement robust data validation** in `adapt_data`:
   ```python
   def adapt_data(self, data=None):
       # Validate input data
       if data is None:
           self.logger.warning("No data provided")
           return None
           
       if not isinstance(data, pd.DataFrame):
           self.logger.warning(f"Expected DataFrame, got {type(data)}")
           # Try conversion or raise error
   ```

4. **Include comprehensive logging** at each step:
   ```python
   self.logger.info(f"Starting data adaptation with {len(data)} records")
   self.logger.debug(f"Parameters: {self.parameters}")
   self.logger.warning(f"Missing values detected in column X: {data['X'].isnull().sum()}")
   ```

5. **Handle errors gracefully** within the algorithm:
   ```python
   try:
       result = complex_calculation(data)
   except Exception as e:
       self.logger.error(f"Calculation failed: {str(e)}")
       # Provide fallback or partial result
       result = fallback_calculation(data)
   ```

6. **Provide rich metadata** in the results:
   ```python
   def format_results(self, algorithm_results=None):
       # Include detailed metrics and metadata
       return {
           "algorithm_name": self.algo_name,
           "status": "completed",
           "execution_time": self.execution_time,
           "metrics": {
               "accuracy": 0.95,
               "precision": 0.92,
               "recall": 0.89,
               "f1_score": 0.90
           },
           "parameters_used": self.parameters,
           "data_summary": {
               "input_shape": self.input_shape,
               "output_shape": self.output_shape,
               "timestamp": datetime.now().isoformat()
           }
       }
   ```

## Common Issues and Solutions

### Issue: Algorithm Not Found

```
ValueError: Algorithm 'my_algorithm' not found
```

**Solution:**
1. Check that the algorithm name is registered with the factory
2. Verify the spelling and capitalization of the algorithm name
3. Ensure that the algorithm module is importable

### Issue: Parameter Type Errors

```
TypeError: unsupported operand type(s) for +: 'int' and 'str'
```

**Solution:**
1. Validate parameter types in `__init__` or `adapt_data`
2. Convert parameters to the expected type where possible
3. Provide clear error messages for invalid parameters

### Issue: Memory Issues with Large Datasets

**Solution:**
1. Process data in chunks instead of all at once
2. Use generators to yield results incrementally
3. Consider out-of-core processing libraries like Dask

### Issue: Algorithm Taking Too Long

**Solution:**
1. Add progress logging within the algorithm
2. Implement early stopping based on convergence or max iterations
3. Consider using more efficient data structures or algorithms
4. Add optimization parameters to control computational complexity