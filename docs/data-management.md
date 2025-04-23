# Data Management

The data management layer of the Base Data Project framework provides abstraction over different data sources with a consistent interface, making it easy to switch between data sources without changing your application logic.

## Architecture

The data management layer has these core components:

1. **BaseDataManager**: Abstract base class defining the interface
2. **CSVDataManager**: Implementation for CSV files
3. **DBDataManager**: Implementation for databases
4. **DataManagerFactory**: Factory for creating data manager instances

## Getting a Data Manager

The recommended way to get a data manager is through the `create_components` utility function:

```python
from base_data_project.utils import create_components

# Create data manager (CSV-based)
data_manager, process_manager = create_components(
    use_db=False,
    config=CONFIG
)

# Create data manager (database-based)
data_manager, process_manager = create_components(
    use_db=True,
    config=CONFIG
)
```

Alternatively, you can use the factory directly:

```python
from base_data_project.data_manager.factory import DataManagerFactory

# Create CSV data manager
csv_manager = DataManagerFactory.create_data_manager('csv', config=CONFIG)

# Create database data manager
db_manager = DataManagerFactory.create_data_manager('db', config=CONFIG)
```

## Using the Data Manager

All data managers implement the same interface, providing these key methods:

### Connection Management

```python
# Using with context manager (recommended)
with data_manager:
    # Data operations (connect/disconnect handled automatically)
    data = data_manager.load_data('users')
    # Process data...
    data_manager.save_data('processed_users', processed_data)

# Explicitly managing connections
data_manager.connect()
# Data operations
data = data_manager.load_data('users')
data_manager.save_data('processed_users', processed_data)
data_manager.disconnect()
```

### Loading Data

```python
# Basic loading
data = data_manager.load_data('entity_name')

# Loading with additional parameters
data = data_manager.load_data(
    'users',
    filepath='custom/path/to/users.csv',  # For CSV
    separator=',',                        # For CSV
    encoding='utf-8',                     # For CSV
    query="SELECT * FROM users LIMIT 10", # For DB
    filters={'status': 'active'},         # For DB
    limit=100                             # For both
)
```

### Saving Data

```python
# Basic saving
data_manager.save_data('entity_name', dataframe)

# Saving with additional parameters
data_manager.save_data(
    'processed_users',
    dataframe,
    filepath='custom/path/output.csv',    # For CSV
    separator=';',                        # For CSV
    index=False,                          # For both
    if_exists='replace',                  # For DB
    chunk_size=1000                       # For both
)
```

### Data Validation

```python
validation_rules = {
    'required_columns': ['id', 'name', 'email'],
    'non_empty': True,
    'unique_columns': ['id', 'email'],
    'no_nulls_columns': ['id', 'name'],
    'value_ranges': {
        'age': {'min': 0, 'max': 120}
    },
    'allowed_values': {
        'status': ['active', 'inactive', 'pending']
    }
}

validation_results = data_manager.validate_data(dataframe, validation_rules)

if validation_results.get('valid', False):
    # Data is valid
    print("Validation successful")
else:
    # Print specific validation failures
    for key, result in validation_results.items():
        if key != 'valid' and not result:
            print(f"Validation failed for {key}")
```

## CSV Data Manager

The `CSVDataManager` is designed for projects that use CSV files for data storage.

### Configuration

```python
config = {
    'data_dir': 'data',                 # Base directory for data
    'output_dir': 'data/output',        # Directory for output files
    
    # Optional mapping of entity names to file paths
    'filepath_map': {
        'users': 'data/csvs/users.csv',
        'transactions': 'data/csvs/transactions.csv'
    }
}
```

### CSV-Specific Features

- File path resolution based on entity name
- Automatic creation of output directories
- Customizable separator, decimal, and encoding
- Timestamp-based output file naming

## Database Data Manager

The `DBDataManager` provides access to database data through SQLAlchemy.

### Configuration

```python
config = {
    'db_url': 'sqlite:///data/production.db',  # SQLAlchemy database URL
    # Or for other databases:
    # 'db_url': 'postgresql://user:pass@localhost/dbname',
    # 'db_url': 'mysql+pymysql://user:pass@localhost/dbname',
}
```

### DB-Specific Features

- Support for SQLAlchemy models
- Query customization
- Direct table access
- Filtering capabilities
- Transaction support with automatic rollback on errors

## Creating Custom Data Managers

You can create custom data managers for other data sources by implementing the `BaseDataManager` interface:

```python
from base_data_project.data_manager.managers.base import BaseDataManager

class MyCustomDataManager(BaseDataManager):
    def connect(self) -> None:
        # Implementation
        pass
        
    def disconnect(self) -> None:
        # Implementation
        pass
        
    def load_data(self, entity: str, **kwargs) -> pd.DataFrame:
        # Implementation
        pass
        
    def save_data(self, entity: str, data: pd.DataFrame, **kwargs) -> None:
        # Implementation
        pass
```

Then register your custom data manager with the factory:

```python
from base_data_project.data_manager.factory import DataManagerFactory

DataManagerFactory.register_data_manager('custom', MyCustomDataManager)

# Now you can create instances using the factory
custom_manager = DataManagerFactory.create_data_manager('custom', config=config)
```

## Best Practices

1. **Always use context managers** when possible to ensure proper resource management:
   ```python
   with data_manager:
       # Operations
   ```

2. **Validate data** before processing to catch issues early:
   ```python
   validation_results = data_manager.validate_data(data, validation_rules)
   if not validation_results.get('valid', False):
       raise ValueError("Invalid data")
   ```

3. **Use consistent entity names** across your application

4. **Consider data privacy** when saving processed data

5. **Include error handling** for data operations:
   ```python
   try:
       with data_manager:
           data = data_manager.load_data('users')
           # Process data
           data_manager.save_data('processed_users', processed_data)
   except Exception as e:
       logger.error(f"Data operation failed: {str(e)}")
       # Handle the error appropriately
   ```

## Common Issues and Solutions

### Issue: File Not Found

```
FileNotFoundError: [Errno 2] No such file or directory: 'data/csvs/users.csv'
```

**Solution:**
1. Check if the file exists at the specified path
2. Ensure the `data_dir` and filepath in your config are correct
3. Use absolute paths if needed

### Issue: Database Connection Failed

```
Error connecting to database: Could not connect to database URL
```

**Solution:**
1. Verify the database URL is correct
2. Ensure the database server is running
3. Check credentials and permissions
4. Verify that required database drivers are installed

### Issue: Data Type Mismatch

```
ValueError: could not convert string to float: 'N/A'
```

**Solution:**
1. Add data cleaning steps before processing
2. Use `pd.to_numeric` with `errors='coerce'` to handle non-numeric values
3. Define explicit column types when loading CSV data

### Issue: Memory Issues with Large Datasets

**Solution:**
1. Use chunking when loading and saving data:
   ```python
   data_manager.save_data('large_entity', data, chunk_size=10000)
   ```
2. Process data in chunks instead of loading it all at once
3. Use database filtering to reduce the amount of data loaded
