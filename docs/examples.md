# Examples

This section provides detailed examples of how to use the Base Data Project Framework for common data processing tasks. These examples demonstrate the framework's capabilities and serve as templates for your own projects.

## Example 1: CSV Data Processing Pipeline

This example demonstrates a complete data processing pipeline using CSV files.

### Project Setup

First, create a new project:

```bash
base-data-project init csv_processing_example
cd csv_processing_example
pip install -r requirements.txt
```

### Data Preparation

Create sample CSV files in the `data/csvs` directory:

**users.csv**
```csv
id,name,email,age,status
1,John Doe,john@example.com,35,active
2,Jane Smith,jane@example.com,28,active
3,Bob Johnson,bob@example.com,42,inactive
4,Alice Brown,alice@example.com,31,active
5,Charlie Davis,charlie@example.com,45,pending
```

**transactions.csv**
```csv
id,user_id,amount,date,category
101,1,125.50,2023-01-15,shopping
102,2,75.20,2023-01-16,groceries
103,1,50.00,2023-01-18,entertainment
104,3,200.00,2023-01-20,travel
105,4,35.75,2023-01-22,groceries
```

### Configuration

Update the configuration in `src/config.py`:

```python
PROJECT_NAME = "csv_processing_example"

CONFIG = {
    'use_db': False,
    'data_dir': os.path.join(ROOT_DIR, 'data'),
    'output_dir': os.path.join(ROOT_DIR, 'data', 'output'),
    
    'dummy_data_filepaths': {
        'users': os.path.join(ROOT_DIR, 'data', 'csvs', 'users.csv'),
        'transactions': os.path.join(ROOT_DIR, 'data', 'csvs', 'transactions.csv')
    },
    
    'available_algorithms': [
        'user_activity_analysis'
    ],
    
    'stages': {
        'data_loading': {
            'sequence': 1,
            'requires_previous': False,
            'validation_required': True,
            'decisions': {
                'selections': {
                    'load_users': True,
                    'load_transactions': True
                }
            }
        },
        'data_transformation': {
            'sequence': 2,
            'requires_previous': True,
            'validation_required': True,
            'decisions': {
                'transformations': {
                    'filter_active_only': False,
                    'min_transaction_amount': 0
                }
            }
        },
        'processing': {
            'sequence': 3,
            'requires_previous': True,
            'validation_required': True,
            'algorithms': [
                'user_activity_analysis'
            ],
            'decisions': {
                'algorithm_selection': {
                    'algorithm': 'user_activity_analysis',
                    'parameters': {
                        'activity_threshold': 100
                    }
                }
            }
        },
        'result_analysis': {
            'sequence': 4,
            'requires_previous': True,
            'validation_required': True,
            'decisions': {
                'report_generation': {
                    'generate_report': True,
                    'report_format': 'csv'
                }
            }
        }
    }
}
```

### Create Custom Algorithm

Create a file at `src/algorithms/user_activity_analysis.py`:

```python
from base_data_project.algorithms.base import BaseAlgorithm
import pandas as pd

class UserActivityAnalysisAlgorithm(BaseAlgorithm):
    def __init__(self, algo_name="UserActivityAnalysis", parameters=None):
        default_params = {
            'activity_threshold': 100
        }
        if parameters:
            default_params.update(parameters)
        super().__init__(algo_name=algo_name, parameters=default_params)
    
    def adapt_data(self, data=None):
        """Transform input data into algorithm-specific format"""
        self.logger.info("Adapting data for user activity analysis")
        
        if data is None or not isinstance(data, dict):
            self.logger.warning("Expected dictionary with users and transactions")
            return None
        
        # Extract users and transactions DataFrames
        users = data.get('users')
        transactions = data.get('transactions')
        
        if users is None or transactions is None:
            self.logger.warning("Missing required data: users and transactions")
            return None
        
        # Ensure required columns exist
        user_cols = ['id', 'name', 'status']
        transaction_cols = ['id', 'user_id', 'amount', 'date']
        
        if not all(col in users.columns for col in user_cols):
            self.logger.warning(f"Users dataframe missing required columns: {user_cols}")
            return None
            
        if not all(col in transactions.columns for col in transaction_cols):
            self.logger.warning(f"Transactions dataframe missing required columns: {transaction_cols}")
            return None
        
        # Return adapted data
        return {
            'users': users.copy(),
            'transactions': transactions.copy()
        }
    
    def execute_algorithm(self, adapted_data=None):
        """Execute the core algorithm logic"""
        self.logger.info("Executing user activity analysis")
        
        if adapted_data is None:
            return None
        
        users = adapted_data['users']
        transactions = adapted_data['transactions']
        
        # Get algorithm parameters
        activity_threshold = self.parameters.get('activity_threshold', 100)
        
        # Calculate total amount per user
        user_totals = transactions.groupby('user_id')['amount'].sum().reset_index()
        user_totals.columns = ['id', 'total_amount']
        
        # Merge with users data
        user_activity = pd.merge(users, user_totals, on='id', how='left')
        user_activity['total_amount'] = user_activity['total_amount'].fillna(0)
        
        # Classify users based on activity
        user_activity['activity_level'] = 'low'
        user_activity.loc[user_activity['total_amount'] >= activity_threshold, 'activity_level'] = 'high'
        
        # Calculate some metrics
        active_users = user_activity[user_activity['status'] == 'active']
        metrics = {
            'total_users': len(users),
            'active_users': len(active_users),
            'high_activity_users': len(user_activity[user_activity['activity_level'] == 'high']),
            'average_transaction_amount': transactions['amount'].mean(),
            'total_transaction_amount': transactions['amount'].sum()
        }
        
        return {
            'user_activity': user_activity,
            'metrics': metrics
        }
    
    def format_results(self, algorithm_results=None):
        """Format the results into a standardized structure"""
        self.logger.info("Formatting user activity analysis results")
        
        if algorithm_results is None:
            return {
                "algorithm_name": self.algo_name,
                "status": "failed",
                "error": "No results to format"
            }
        
        # Format results for output
        formatted_results = {
            "algorithm_name": self.algo_name,
            "status": "completed",
            "execution_time": self.execution_time,
            "metrics": algorithm_results.get('metrics', {}),
            "data": {
                "user_activity": algorithm_results.get('user_activity', pd.DataFrame()).to_dict('records'),
                "parameters_used": self.parameters
            }
        }
        
        return formatted_results
```

Update `src/algorithms/__init__.py`:

```python
from src.algorithms.user_activity_analysis import UserActivityAnalysisAlgorithm

__all__ = ['UserActivityAnalysisAlgorithm']
```

### Create Custom Service

Update `src/services/example_service.py`:

```python
import logging
import pandas as pd
from typing import Dict, Any, Optional
from datetime import datetime

from src.config import PROJECT_NAME

logger = logging.getLogger(PROJECT_NAME)

class ExampleService:
    """Service for the CSV processing example."""
    
    def __init__(self, data_manager, process_manager=None):
        """Initialize with data and process managers."""
        self.data_manager = data_manager
        self.process_manager = process_manager
        self.current_process_id = None
        
    def initialize_process(self, name: str, description: str) -> str:
        """Initialize a new process."""
        if not self.process_manager:
            logger.warning("Process manager not available, tracking disabled")
            return "no_tracking"
            
        # Initialize process
        self.current_process_id = self.process_manager.initialize_process(name, description)
        logger.info(f"Initialized process with ID: {self.current_process_id}")
        return self.current_process_id
    
    def execute_stage(self, stage: str, algorithm_name: Optional[str] = None,
                     algorithm_params: Optional[Dict[str, Any]] = None) -> bool:
        """Execute a specific process stage."""
        try:
            logger.info(f"Executing stage: {stage}")
            
            if self.process_manager:
                current_stage = self.process_manager.start_stage(stage, algorithm_name)
            
            # Stage-specific logic
            if stage == "data_loading":
                success = self._execute_data_loading()
            elif stage == "data_transformation":
                success = self._execute_data_transformation()
            elif stage == "processing":
                success = self._execute_processing(algorithm_name, algorithm_params)
            elif stage == "result_analysis":
                success = self._execute_result_analysis()
            else:
                logger.error(f"Unknown stage: {stage}")
                return False
            
            # Record completion
            if self.process_manager:
                self.process_manager.complete_stage(stage, success)
            
            return success
        
        except Exception as e:
            logger.error(f"Error executing stage {stage}: {str(e)}", exc_info=True)
            
            if self.process_manager:
                self.process_manager.complete_stage(stage, False, {"error": str(e)})
            
            return False
    
    def _execute_data_loading(self) -> bool:
        """Execute the data loading stage."""
        try:
            logger.info("Loading data")
            
            # Load users
            users = self.data_manager.load_data('users')
            if users is None or len(users) == 0:
                logger.error("Failed to load users data")
                return False
            
            # Log users data summary
            logger.info(f"Loaded {len(users)} users")
            
            # Load transactions
            transactions = self.data_manager.load_data('transactions')
            if transactions is None or len(transactions) == 0:
                logger.error("Failed to load transactions data")
                return False
            
            # Log transactions data summary
            logger.info(f"Loaded {len(transactions)} transactions")
            
            # Store data for next stages
            self.users = users
            self.transactions = transactions
            
            return True
            
        except Exception as e:
            logger.error(f"Error in data loading: {str(e)}", exc_info=True)
            return False
    
    def _execute_data_transformation(self) -> bool:
        """Execute the data transformation stage."""
        try:
            logger.info("Transforming data")
            
            # Get transformation decisions
            filter_active_only = False
            min_transaction_amount = 0
            
            if self.process_manager:
                # Get decisions from process manager
                transformations = self.process_manager.get_decision("data_transformation", "transformations")
                filter_active_only = transformations.get("filter_active_only", False)
                min_transaction_amount = transformations.get("min_transaction_amount", 0)
            
            # Apply transformations
            users = self.users.copy()
            transactions = self.transactions.copy()
            
            # Filter users if requested
            if filter_active_only:
                logger.info("Filtering for active users only")
                users = users[users['status'] == 'active']
                # Also filter transactions
                valid_user_ids = users['id'].tolist()
                transactions = transactions[transactions['user_id'].isin(valid_user_ids)]
            
            # Filter transactions if threshold set
            if min_transaction_amount > 0:
                logger.info(f"Filtering transactions with minimum amount: {min_transaction_amount}")
                transactions = transactions[transactions['amount'] >= min_transaction_amount]
            
            # Convert date column to datetime
            transactions['date'] = pd.to_datetime(transactions['date'])
            
            # Store transformed data
            self.transformed_users = users
            self.transformed_transactions = transactions
            
            logger.info(f"Transformation complete: {len(users)} users, {len(transactions)} transactions")
            return True
            
        except Exception as e:
            logger.error(f"Error in data transformation: {str(e)}", exc_info=True)
            return False
    
    def _execute_processing(self, algorithm_name: Optional[str] = None,
                          algorithm_params: Optional[Dict[str, Any]] = None) -> bool:
        """Execute the processing stage."""
        try:
            # Default algorithm if not specified
            if not algorithm_name:
                algorithm_name = "user_activity_analysis"
            
            logger.info(f"Processing data with algorithm: {algorithm_name}")
            
            # Get algorithm parameters
            params = {}
            if algorithm_params:
                params.update(algorithm_params)
            
            # Create algorithm instance
            from base_data_project.algorithms.factory import AlgorithmFactory
            algorithm = AlgorithmFactory.create_algorithm(
                algorithm_name=algorithm_name,
                parameters=params
            )
            
            # Prepare data for algorithm
            algorithm_data = {
                'users': self.transformed_users,
                'transactions': self.transformed_transactions
            }
            
            # Run algorithm
            result = algorithm.run(algorithm_data)
            
            # Check result status
            if result.get("status") != "completed":
                logger.error(f"Algorithm execution failed: {result.get('error', 'Unknown error')}")
                return False
            
            # Store results
            self.processing_results = result
            
            logger.info("Processing complete")
            logger.info(f"Metrics: {result.get('metrics', {})}")
            
            return True
            
        except Exception as e:
            logger.error(f"Error in processing: {str(e)}", exc_info=True)
            return False
    
    def _execute_result_analysis(self) -> bool:
        """Execute the result analysis stage."""
        try:
            logger.info("Analyzing results")
            
            # Get user activity data
            user_activity = pd.DataFrame(self.processing_results['data']['user_activity'])
            
            # Get metrics
            metrics = self.processing_results.get('metrics', {})
            
            # Create summary report
            summary = pd.DataFrame([{
                'total_users': metrics.get('total_users', 0),
                'active_users': metrics.get('active_users', 0),
                'high_activity_users': metrics.get('high_activity_users', 0),
                'average_transaction_amount': metrics.get('average_transaction_amount', 0),
                'total_transaction_amount': metrics.get('total_transaction_amount', 0),
                'execution_time': self.processing_results.get('execution_time', 0),
                'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }])
            
            # Save user activity data
            self.data_manager.save_data('user_activity', user_activity)
            
            # Save summary report
            self.data_manager.save_data('activity_summary', summary)
            
            logger.info("Results analysis complete")
            logger.info(f"Results saved to output directory")
            
            return True
            
        except Exception as e:
            logger.error(f"Error in result analysis: {str(e)}", exc_info=True)
            return False
    
    def finalize_process(self) -> bool:
        """Finalize the process and clean up."""
        if self.process_manager:
            logger.info("Finalizing process")
            # Any finalization logic can go here
            return True
        return False
    
    def get_process_summary(self) -> Dict[str, Any]:
        """Get a summary of the process."""
        if self.process_manager:
            return self.process_manager.get_process_summary()
        return {"status": "no_tracking"}
```

### Run the Project

Now you can run the project in interactive mode:

```bash
python main.py run-process
```

Or in batch mode:

```bash
python batch_process.py
```

This will:
1. Load user and transaction data
2. Apply transformations based on decisions
3. Run the user activity analysis algorithm
4. Generate and save results

## Example 2: Integrating with External Systems

This example demonstrates how to integrate the framework with external systems using the API server.

### Enable API Server

Update `routes.py` to add custom endpoints:

```python
@app.route('/api/users', methods=['GET'])
def get_users():
    """Get list of users."""
    try:
        with data_manager:
            users = data_manager.load_data('users')
            return jsonify({
                'status': 'success',
                'count': len(users),
                'data': users.to_dict('records')
            })
    except Exception as e:
        logger.error(f"Error getting users: {str(e)}")
        return jsonify({
            'status': 'error',
            'error': str(e)
        }), 500

@app.route('/api/analyze', methods=['POST'])
def analyze_data():
    """Run analysis on provided data."""
    try:
        # Get request data
        data = request.json
        
        # Validate request
        if not data or 'users' not in data or 'transactions' not in data:
            return jsonify({
                'status': 'error',
                'error': 'Missing required data'
            }), 400
        
        # Convert to DataFrames
        users = pd.DataFrame(data['users'])
        transactions = pd.DataFrame(data['transactions'])
        
        # Get algorithm parameters
        params = data.get('parameters', {})
        
        # Create algorithm
        from base_data_project.algorithms.factory import AlgorithmFactory
        algorithm = AlgorithmFactory.create_algorithm(
            algorithm_name='user_activity_analysis',
            parameters=params
        )
        
        # Run algorithm
        result = algorithm.run({
            'users': users,
            'transactions': transactions
        })
        
        return jsonify({
            'status': 'success',
            'result': result
        })
        
    except Exception as e:
        logger.error(f"Error in analysis: {str(e)}")
        return jsonify({
            'status': 'error',
            'error': str(e)
        }), 500
```

### Start the API Server

```bash
python routes.py
```

Now you can interact with the API:

```bash
# Get users
curl http://localhost:5000/api/users

# Run analysis
curl -X POST -H "Content-Type: application/json" -d '{"users": [...], "transactions": [...], "parameters": {"activity_threshold": 200}}' http://localhost:5000/api/analyze
```

## Example 3: Database Integration

This example demonstrates how to use the framework with a database instead of CSV files.

### Setup Database Configuration

Update configuration in `src/config.py`:

```python
CONFIG = {
    'use_db': True,
    'db_url': 'sqlite:///data/example.db',
    # Other configuration...
}
```

### Create Database Tables

Create a script to initialize the database:

```python
import sqlalchemy as sa
from sqlalchemy import create_engine, Column, Integer, String, Float, Date, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Create base class for declarative models
Base = declarative_base()

# Define models
class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    email = Column(String, nullable=False)
    age = Column(Integer)
    status = Column(String)

class Transaction(Base):
    __tablename__ = 'transactions'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    amount = Column(Float, nullable=False)
    date = Column(Date, nullable=False)
    category = Column(String)

# Create database and tables
def initialize_database():
    engine = create_engine('sqlite:///data/example.db')
    Base.metadata.create_all(engine)
    
    # Create session
    Session = sessionmaker(bind=engine)
    session = Session()
    
    # Add sample data
    users = [
        User(id=1, name='John Doe', email='john@example.com', age=35, status='active'),
        User(id=2, name='Jane Smith', email='jane@example.com', age=28, status='active'),
        User(id=3, name='Bob Johnson', email='bob@example.com', age=42, status='inactive'),
        User(id=4, name='Alice Brown', email='alice@example.com', age=31, status='active'),
        User(id=5, name='Charlie Davis', email='charlie@example.com', age=45, status='pending')
    ]
    
    transactions = [
        Transaction(id=101, user_id=1, amount=125.50, date='2023-01-15', category='shopping'),
        Transaction(id=102, user_id=2, amount=75.20, date='2023-01-16', category='groceries'),
        Transaction(id=103, user_id=1, amount=50.00, date='2023-01-18', category='entertainment'),
        Transaction(id=104, user_id=3, amount=200.00, date='2023-01-20', category='travel'),
        Transaction(id=105, user_id=4, amount=35.75, date='2023-01-22', category='groceries')
    ]
    
    # Add users to session
    session.add_all(users)
    session.commit()
    
    # Add transactions to session
    session.add_all(transactions)
    session.commit()
    
    session.close()

if __name__ == '__main__':
    initialize_database()
```

Save this as `init_db.py` and run it:

```bash
python init_db.py
```

### Using the Database

The service implementation remains largely the same - the framework handles the data source abstraction:

```python
# Create components (using database)
data_manager, process_manager = create_components(
    use_db=True,  # Switch to database
    config=CONFIG
)

# Usage is the same as with CSV files
with data_manager:
    users = data_manager.load_data('users')
    transactions = data_manager.load_data('transactions')
    
    # Process data
    # ...
    
    # Save results
    data_manager.save_data('user_activity', user_activity)
```

If you need to use SQLAlchemy models directly:

```python
from sqlalchemy.orm import Session

# Get model class for users
User = get_model_class('users')

# Using with SQLAlchemy models
with data_manager:
    # Get SQLAlchemy session
    session = data_manager.session
    
    # Query using models
    active_users = session.query(User).filter(User.status == 'active').all()
    
    # Convert to DataFrame if needed
    import pandas as pd
    users_df = pd.DataFrame([
        {column.name: getattr(user, column.name) 
         for column in User.__table__.columns}
        for user in active_users
    ])
```

## Example 4: Custom Algorithm for Time Series Analysis

This example demonstrates implementing a more complex algorithm for time series analysis.

### Time Series Algorithm Implementation

```python
from base_data_project.algorithms.base import BaseAlgorithm
import pandas as pd
import numpy as np

class TimeSeriesAnalysisAlgorithm(BaseAlgorithm):
    def __init__(self, algo_name="TimeSeriesAnalysis", parameters=None):
        default_params = {
            'window_size': 7,
            'forecast_horizon': 14,
            'seasonality': 'auto'
        }
        if parameters:
            default_params.update(parameters)
        super().__init__(algo_name=algo_name, parameters=default_params)
    
    def adapt_data(self, data=None):
        """Transform input data into algorithm-specific format"""
        self.logger.info("Adapting data for time series analysis")
        
        if data is None or not isinstance(data, pd.DataFrame):
            self.logger.warning("Expected DataFrame for time series data")
            return None
        
        # Check for required columns
        required_cols = ['date', 'value']
        if not all(col in data.columns for col in required_cols):
            self.logger.warning(f"Data missing required columns: {required_cols}")
            return None
        
        # Ensure date is datetime
        df = data.copy()
        if not pd.api.types.is_datetime64_any_dtype(df['date']):
            try:
                df['date'] = pd.to_datetime(df['date'])
            except Exception as e:
                self.logger.error(f"Error converting date column: {str(e)}")
                return None
        
        # Sort by date
        df = df.sort_values('date')
        
        # Set date as index
        df = df.set_index('date')
        
        # Resample to daily frequency if needed
        if df.index.to_series().diff().min().days > 1:
            self.logger.info("Resampling to daily frequency")
            df = df.resample('D').mean().interpolate(method='linear')
        
        return df
    
    def execute_algorithm(self, adapted_data=None):
        """Execute the core algorithm logic"""
        self.logger.info("Executing time series analysis")
        
        if adapted_data is None:
            return None
        
        # Get parameters
        window_size = self.parameters.get('window_size', 7)
        forecast_horizon = self.parameters.get('forecast_horizon', 14)
        seasonality = self.parameters.get('seasonality', 'auto')
        
        # Calculate rolling statistics
        df = adapted_data.copy()
        df['rolling_mean'] = df['value'].rolling(window=window_size).mean()
        df['rolling_std'] = df['value'].rolling(window=window_size).std()
        
        # Detect seasonality
        if seasonality == 'auto':
            # Simple detection using autocorrelation
            autocorr = pd.Series(df['value']).autocorr(lag=7)
            seasonality = 7 if autocorr > 0.6 else None
        
        # Generate forecast
        last_date = df.index[-1]
        forecast_dates = pd.date_range(start=last_date + pd.Timedelta(days=1), 
                                     periods=forecast_horizon)
        
        # Simple forecast using last n values mean
        last_values = df['value'].tail(window_size)
        forecast_mean = last_values.mean()
        forecast_std = last_values.std()
        
        # Create forecast DataFrame
        forecast = pd.DataFrame(index=forecast_dates)
        forecast['value'] = forecast_mean
        forecast['lower_bound'] = forecast_mean - 1.96 * forecast_std
        forecast['upper_bound'] = forecast_mean + 1.96 * forecast_std
        
        # Calculate metrics
        metrics = {
            'total_observations': len(df),
            'mean': df['value'].mean(),
            'std': df['value'].std(),
            'min': df['value'].min(),
            'max': df['value'].max(),
            'last_value': df['value'].iloc[-1],
            'forecast_mean': forecast_mean,
            'detected_seasonality': seasonality
        }
        
        return {
            'original_data': df,
            'forecast': forecast,
            'metrics': metrics
        }
    
    def format_results(self, algorithm_results=None):
        """Format the results into a standardized structure"""
        self.logger.info("Formatting time series analysis results")
        
        if algorithm_results is None:
            return {
                "algorithm_name": self.algo_name,
                "status": "failed",
                "error": "No results to format"
            }
        
        # Extract components from results
        original_data = algorithm_results.get('original_data', pd.DataFrame())
        forecast = algorithm_results.get('forecast', pd.DataFrame())
        metrics = algorithm_results.get('metrics', {})
        
        # Reset index for serialization
        original_data = original_data.reset_index()
        forecast = forecast.reset_index()
        
        # Format for output
        formatted_results = {
            "algorithm_name": self.algo_name,
            "status": "completed",
            "execution_time": self.execution_time,
            "metrics": metrics,
            "data": {
                "original_data": original_data.to_dict('records'),
                "forecast": forecast.to_dict('records'),
                "parameters_used": self.parameters
            }
        }
        
        return formatted_results
```

### Usage Example

```python
import pandas as pd
from datetime import datetime, timedelta
import numpy as np
from base_data_project.algorithms.factory import AlgorithmFactory

# Register the algorithm
from src.algorithms.time_series_analysis import TimeSeriesAnalysisAlgorithm
AlgorithmFactory.register_algorithm('time_series_analysis', TimeSeriesAnalysisAlgorithm)

# Generate sample time series data
dates = [datetime.now() - timedelta(days=x) for x in range(100, 0, -1)]
values = [10 + x * 0.5 + np.sin(x/7) * 5 + np.random.normal(0, 2) for x in range(100)]

data = pd.DataFrame({
    'date': dates,
    'value': values
})

# Create and run algorithm
algorithm = AlgorithmFactory.create_algorithm(
    algorithm_name='time_series_analysis',
    parameters={
        'window_size': 10,
        'forecast_horizon': 30
    }
)

results = algorithm.run(data)

# Access results
original_data = pd.DataFrame(results['data']['original_data'])
forecast = pd.DataFrame(results['data']['forecast'])
metrics = results['metrics']

print(f"Time Series Analysis Results:")
print(f"Mean value: {metrics['mean']:.2f}")
print(f"Forecast mean: {metrics['forecast_mean']:.2f}")
print(f"Detected seasonality: {metrics['detected_seasonality']}")
```

## Additional Examples

### Saving and Comparing Scenarios

```python
# Initialize process managers
data_manager, process_manager = create_components(
    use_db=False,
    no_tracking=False,
    config=CONFIG
)

# Make decisions for baseline scenario
process_manager.make_decisions(1, {
    "selections": {
        "load_users": True,
        "load_transactions": True
    }
})

process_manager.make_decisions(2, {
    "transformations": {
        "filter_active_only": False,
        "min_transaction_amount": 0
    }
})

process_manager.make_decisions(3, {
    "algorithm_selection": {
        "algorithm": "user_activity_analysis",
        "parameters": {
            "activity_threshold": 100
        }
    }
})

# Save baseline scenario
baseline_id = process_manager.save_current_scenario("Baseline")

# Make different decisions for alternative scenario
process_manager.make_decisions(2, {
    "transformations": {
        "filter_active_only": True,
        "min_transaction_amount": 50
    }
})

process_manager.make_decisions(3, {
    "algorithm_selection": {
        "algorithm": "user_activity_analysis",
        "parameters": {
            "activity_threshold": 200
        }
    }
})

# Save alternative scenario
alternative_id = process_manager.save_current_scenario("Alternative")

# Compare scenarios
comparison = process_manager.compare_scenarios([baseline_id, alternative_id])

print("Scenario Comparison:")
for scenario in comparison:
    print(f"Scenario: {scenario['name']}")
    print(f"Decisions:")
    for stage, decisions in scenario['decisions'].items():
        print(f"  Stage {stage}: {decisions}")
    print()
```

### Custom Data Validation Example

```python
# Define validation rules
validation_rules = {
    'required_columns': ['id', 'name', 'email', 'status'],
    'non_empty': True,
    'unique_columns': ['id', 'email'],
    'no_nulls_columns': ['id', 'name', 'status'],
    'value_ranges': {
        'age': {'min': 0, 'max': 120}
    },
    'allowed_values': {
        'status': ['active', 'inactive', 'pending']
    }
}

# Validate data
with data_manager:
    users = data_manager.load_data('users')
    validation_results = data_manager.validate_data(users, validation_rules)
    
    if validation_results.get('valid', False):
        print("Data validation successful")
    else:
        print("Data validation failed:")
        for key, result in validation_results.items():
            if key != 'valid' and not result:
                print(f"- {key}")
```

These examples demonstrate how to use the Base Data Project Framework for various common data processing tasks. You can adapt them to your specific needs and extend them with additional functionality.
