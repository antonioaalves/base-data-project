"""Data manager implementations for CSV and database sources."""

import os
import pandas as pd
import logging
from typing import Dict, Any, List, Optional, Union
from datetime import datetime
import importlib
import re

# Import base data manager
from base_data_project.data_manager.managers.base import BaseDataManager

"""Simplified CSV data manager with consistent interface."""

import os
import pandas as pd
import logging
import re
from typing import Dict, Any, List, Optional
from datetime import datetime

# Import base data manager
from base_data_project.data_manager.managers.base import BaseDataManager

class CSVDataManager(BaseDataManager):
    """
    Simplified CSV data manager that provides consistent interface with DB manager.
    
    Flow:
    1. Get CSV path from config['dummy_data_filepaths'][entity]
    2. Load DataFrame with pd.read_csv()
    3. If no substitution args → return DataFrame as-is
    4. If substitution args → try SQL execution against DataFrame
    5. If SQL fails → extract WHERE clauses and apply as pandas filters
    
    Note: Entity corresponds to a query result (CSV), not a table name.
    CSV files are cached results of SQL queries with certain parameters.
    """
    
    def __init__(self, config: Dict[str, Any], project_name: str = 'base_data_project') -> None:
        """Initialize the CSV data manager."""
        super().__init__(config, project_name)
        
        # Try to import pandasql for SQL query support
        self.pandasql_available = False
        self.sqldf = None
        try:
            from pandasql import sqldf
            self.sqldf = sqldf
            self.pandasql_available = True
            self.logger.info("PandasSQL available - SQL queries supported")
        except ImportError:
            self.logger.info("PandasSQL not available - will use pandas filtering fallback")
    
    def connect(self) -> None:
        """
        Connect to CSV files - validates that configured files exist.
        """
        # Get CSV file mappings from config
        filepath_map = self.config.get('dummy_data_filepaths', {})
        
        # Get data directory path
        data_dir = self.config.get('data_dir', 'data')
        
        # Ensure data directory exists
        if not os.path.exists(data_dir):
            os.makedirs(data_dir, exist_ok=True)
            self.logger.info(f"Created data directory: {data_dir}")
        
        # Ensure output directory exists
        output_dir = self.config.get('output_dir', os.path.join(data_dir, 'output'))
        if not os.path.exists(output_dir):
            os.makedirs(output_dir, exist_ok=True)
            self.logger.info(f"Created output directory: {output_dir}")
        
        # Validate configured CSV files exist
        if filepath_map:
            missing_files = []
            for entity, path in filepath_map.items():
                if not os.path.exists(path):
                    missing_files.append(f"{entity}: {path}")
            
            if missing_files:
                error_msg = f"The following configured CSV files do not exist: {', '.join(missing_files)}"
                self.logger.error(error_msg)
                raise FileNotFoundError(error_msg)
                
        self.logger.info(f"Connected to CSV data source with {len(filepath_map)} file paths configured")

    def disconnect(self) -> None:
        """
        Disconnect from CSV data source.
        """
        self.logger.info("Disconnected from CSV data source")

    def load_data(self, entity: str, **kwargs) -> pd.DataFrame:
        """
        Load data from CSV file with consistent interface.
        
        Args:
            entity: Entity name to load (maps to CSV file via config)
            **kwargs: Parameters including:
                - query_file: Path to SQL query file (optional)
                - Any other parameters for WHERE clause substitution
                
        Returns:
            DataFrame with loaded data
        """
        # Step 1: Get CSV filepath from config
        filepath = self._get_csv_filepath(entity)
        
        # Step 2: Load DataFrame from CSV
        df = self._load_csv_file(filepath, entity)
        
        # Step 3: Check if we have query processing to do
        query_file = kwargs.get('query_file')
        substitution_args = {k: v for k, v in kwargs.items() if k != 'query_file'}
        
        # If no substitution args, return DataFrame as-is
        if not substitution_args:
            self.logger.info(f"No substitution args for entity '{entity}', returning raw DataFrame")
            return df
        
        # Step 4: Process query with substitution args
        if query_file:
            return self._process_query_with_substitution(df, entity, query_file, **substitution_args)
        else:
            self.logger.warning(f"Substitution args provided but no query_file for entity '{entity}'. Returning raw DataFrame.")
            return df

    def _get_csv_filepath(self, entity: str) -> str:
        """
        Get CSV filepath for entity from config.
        
        Args:
            entity: Entity name
            
        Returns:
            Filepath to CSV file
            
        Raises:
            ValueError: If no filepath configured for entity
            FileNotFoundError: If configured file doesn't exist
        """
        filepath_map = self.config.get('dummy_data_filepaths', {})
        
        if entity not in filepath_map:
            error_msg = f"No CSV filepath configured for entity '{entity}'"
            self.logger.error(error_msg)
            raise ValueError(error_msg)
        
        filepath = filepath_map[entity]
        
        if not os.path.exists(filepath):
            error_msg = f"CSV file not found: {filepath}"
            self.logger.error(error_msg)
            raise FileNotFoundError(error_msg)
        
        return filepath

    def _load_csv_file(self, filepath: str, entity: str) -> pd.DataFrame:
        """
        Load CSV file into DataFrame.
        
        Args:
            filepath: Path to CSV file
            entity: Entity name for logging
            
        Returns:
            Loaded DataFrame
            
        Raises:
            Exception: If CSV loading fails
        """
        try:
            self.logger.info(f"Loading CSV for entity '{entity}' from {filepath}")
            
            df = pd.read_csv(filepath)
            
            if df.empty:
                self.logger.warning(f"Loaded empty DataFrame for entity '{entity}'")
            else:
                self.logger.info(f"Successfully loaded {len(df)} rows for entity '{entity}'")
            
            return df
            
        except pd.errors.EmptyDataError:
            error_msg = f"Empty CSV file: {filepath}"
            self.logger.error(error_msg)
            raise ValueError(error_msg)
            
        except Exception as e:
            self.logger.error(f"Error loading CSV file {filepath}: {str(e)}")
            raise

    def _process_query_with_substitution(self, df: pd.DataFrame, entity: str, query_file: str, **substitution_args) -> pd.DataFrame:
        """
        Process query file against DataFrame with parameter substitution.
        
        Args:
            df: DataFrame to filter
            entity: Entity name
            query_file: Path to SQL query file
            **substitution_args: Arguments for parameter substitution
            
        Returns:
            Filtered DataFrame
        """
        # Validate query file exists
        if not os.path.exists(query_file):
            error_msg = f"Query file not found: {query_file}"
            self.logger.error(error_msg)
            raise FileNotFoundError(error_msg)
        
        # Read SQL query
        sql_query = self._read_query_file(query_file)
        self.logger.info(f"Processing query for entity '{entity}' with substitution args: {substitution_args}")
        self.logger.info(f"SQL query content: {sql_query[:200]}...")  # Log first 200 chars
        
        # Try SQL execution first if pandasql is available
        if self.pandasql_available:
            try:
                return self._execute_sql_against_dataframe(df, entity, sql_query, **substitution_args)
            except Exception as e:
                self.logger.warning(f"SQL execution failed: {str(e)}. Falling back to pandas filtering.")
        
        # Fallback to pandas filtering using WHERE clauses
        return self._apply_where_clauses_as_pandas_filters(df, entity, sql_query, **substitution_args)

    def _read_query_file(self, query_file: str) -> str:
        """
        Read SQL query from file.
        
        Args:
            query_file: Path to query file
            
        Returns:
            SQL query string
            
        Raises:
            ValueError: If file is empty
        """
        try:
            with open(query_file, 'r', encoding='utf-8') as f:
                sql_query = f.read().strip()
                
            if not sql_query:
                error_msg = f"Query file is empty: {query_file}"
                self.logger.error(error_msg)
                raise ValueError(error_msg)
                
            self.logger.info(f"Successfully read query from {query_file}")
            return sql_query
            
        except Exception as e:
            self.logger.error(f"Error reading query file {query_file}: {str(e)}")
            raise

    def _execute_sql_against_dataframe(self, df: pd.DataFrame, entity: str, sql_query: str, **substitution_args) -> pd.DataFrame:
        """
        Execute SQL query against DataFrame using pandasql.
        
        Args:
            df: DataFrame to query
            entity: Entity name
            sql_query: SQL query string
            **substitution_args: Arguments for parameter substitution
            
        Returns:
            Query result DataFrame
        """
        # Format SQL query with substitution arguments
        formatted_query = self._format_sql_query(sql_query, **substitution_args)
        
        # Create SQL environment with DataFrame available as 'df'
        sql_env = {'df': df}
        
        try:
            self.logger.info(f"Executing SQL query against DataFrame for entity '{entity}'")
            self.logger.debug(f"Formatted SQL: {formatted_query}")
            
            result = self.sqldf(formatted_query, sql_env)
            
            self.logger.info(f"SQL query returned {len(result)} rows")
            return result
            
        except Exception as e:
            self.logger.error(f"Error executing SQL query: {str(e)}")
            raise

    def _apply_where_clauses_as_pandas_filters(self, df: pd.DataFrame, entity: str, sql_query: str, **substitution_args) -> pd.DataFrame:
        """
        Extract WHERE clauses from SQL and apply as pandas filters.
        
        Args:
            df: DataFrame to filter
            entity: Entity name
            sql_query: SQL query string
            **substitution_args: Arguments for parameter substitution
            
        Returns:
            Filtered DataFrame
        """
        self.logger.info(f"Applying WHERE clauses as pandas filters for entity '{entity}'")
        
        try:
            # Parse WHERE conditions from SQL
            where_conditions = self._extract_where_conditions(sql_query)
            
            if not where_conditions:
                self.logger.info("No WHERE conditions found in SQL, returning original DataFrame")
                return df
            
            # Apply each condition to DataFrame
            filtered_df = df.copy()
            
            for condition in where_conditions:
                try:
                    # Substitute parameters in condition
                    formatted_condition = self._substitute_parameters_in_condition(condition, **substitution_args)
                    
                    # Apply condition as pandas filter
                    filtered_df = self._apply_pandas_condition(filtered_df, formatted_condition)
                    
                    self.logger.debug(f"Applied condition: {formatted_condition}")
                    
                except Exception as e:
                    self.logger.warning(f"Failed to apply condition '{condition}': {str(e)}")
                    # Continue with other conditions
            
            self.logger.info(f"Pandas filtering: {len(df)} -> {len(filtered_df)} rows")
            return filtered_df
            
        except Exception as e:
            self.logger.error(f"WHERE clause extraction and filtering failed: {str(e)}")
            self.logger.info("Returning original DataFrame without filtering")
            return df

    def _format_sql_query(self, query: str, **kwargs) -> str:
        """
        Format SQL query with parameter substitution.
        
        Args:
            query: SQL query with parameter placeholders
            **kwargs: Parameters for substitution
            
        Returns:
            Formatted SQL query
        """
        formatted_query = query
        
        for param_name, param_value in kwargs.items():
            placeholder = f"{{{param_name}}}"
            
            if placeholder in formatted_query:
                # Handle different data types
                if isinstance(param_value, str):
                    # Escape quotes and wrap in quotes
                    escaped_value = param_value.replace("'", "''")
                    replacement = f"'{escaped_value}'"
                else:
                    # For numeric values, use as-is
                    replacement = str(param_value)
                
                formatted_query = formatted_query.replace(placeholder, replacement)
                self.logger.debug(f"Replaced {placeholder} with {replacement}")
        
        return formatted_query

    def _extract_where_conditions(self, sql_query: str) -> List[str]:
        """
        Extract WHERE conditions from SQL query.
        
        Args:
            sql_query: SQL query string
            
        Returns:
            List of individual WHERE conditions
        """
        conditions = []
        
        try:
            # Convert to lowercase for pattern matching but preserve original case for conditions
            query_lower = sql_query.lower()
            
            # Find WHERE clause
            where_match = re.search(r'where\s+(.*?)(?:\s+order\s+by|\s+group\s+by|\s+limit|\s+;|$)', query_lower, re.DOTALL)
            
            if where_match:
                # Get the original case WHERE clause content
                where_start = where_match.start(1)
                where_end = where_match.end(1)
                
                # Find the actual positions in the original query
                original_where_start = 0
                original_where_end = len(sql_query)
                
                # Count characters to find position in original string
                lower_pos = 0
                for i, char in enumerate(sql_query):
                    if lower_pos == where_start:
                        original_where_start = i
                    if lower_pos == where_end:
                        original_where_end = i
                        break
                    if char.lower() == query_lower[lower_pos]:
                        lower_pos += 1
                
                where_clause = sql_query[original_where_start:original_where_end].strip()
                
                # Split by AND (simple parsing - doesn't handle complex nested conditions)
                and_conditions = re.split(r'\s+and\s+', where_clause, flags=re.IGNORECASE)
                
                for condition in and_conditions:
                    condition = condition.strip()
                    if condition:
                        conditions.append(condition)
                        
                self.logger.debug(f"Extracted {len(conditions)} WHERE conditions")
            
        except Exception as e:
            self.logger.debug(f"Error extracting WHERE conditions: {str(e)}")
        
        return conditions

    def _substitute_parameters_in_condition(self, condition: str, **kwargs) -> str:
        """
        Substitute parameters in WHERE condition.
        
        Args:
            condition: WHERE condition string
            **kwargs: Parameters for substitution
            
        Returns:
            Condition with parameters substituted
        """
        formatted_condition = condition
        
        # Replace parameter placeholders
        for param_name, param_value in kwargs.items():
            placeholder = f"{{{param_name}}}"
            
            if placeholder in formatted_condition:
                if isinstance(param_value, str):
                    replacement = f"'{param_value}'"
                else:
                    replacement = str(param_value)
                
                formatted_condition = formatted_condition.replace(placeholder, replacement)
        
        # Remove table prefixes (e.g., "table.column" -> "column")
        formatted_condition = re.sub(r'\b\w+\.(\w+)\b', r'\1', formatted_condition)
        
        return formatted_condition

    def _apply_pandas_condition(self, df: pd.DataFrame, condition: str) -> pd.DataFrame:
        """
        Apply a single WHERE condition to DataFrame using pandas.
        
        Args:
            df: DataFrame to filter
            condition: Condition string to apply
            
        Returns:
            Filtered DataFrame
        """
        # Create evaluation environment with DataFrame columns
        eval_env = {
            **{col: df[col] for col in df.columns},
            # Add useful functions
            'isnull': pd.isnull,
            'notnull': pd.notnull,
            'isna': pd.isna,
            'notna': pd.notna,
        }
        
        try:
            # Convert SQL operators to pandas operators
            pandas_condition = condition
            pandas_condition = re.sub(r'\s*=\s*', ' == ', pandas_condition)
            pandas_condition = re.sub(r'\s*<>\s*', ' != ', pandas_condition)
            
            # Evaluate condition
            self.logger.debug(f"Evaluating pandas condition: {pandas_condition}")
            mask = eval(pandas_condition, {"__builtins__": {}}, eval_env)
            
            # Ensure result is a boolean Series
            if isinstance(mask, pd.Series):
                return df[mask.astype(bool)]
            else:
                # If scalar result, apply to all rows
                if bool(mask):
                    return df
                else:
                    return df.iloc[0:0]  # Return empty DataFrame with same structure
                    
        except Exception as e:
            self.logger.error(f"Error evaluating condition '{condition}': {str(e)}")
            raise ValueError(f"Invalid condition for pandas evaluation: {condition}")

    def save_data(self, entity: str, data: pd.DataFrame, **kwargs) -> str:
        """
        Save DataFrame to CSV file.
        
        Args:
            entity: Entity name (used for filename)
            data: DataFrame to save
            **kwargs: Additional parameters including:
                - filepath: Explicit output filepath
                - index: Whether to include index (default False)
                - separator: CSV separator (default ',')
                
        Returns:
            Path to saved file
        """
        # Get output filepath
        filepath = kwargs.get('filepath')
        if not filepath:
            output_dir = self.config.get('output_dir', os.path.join('data', 'output'))
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filepath = os.path.join(output_dir, f"{entity}_{timestamp}.csv")
        
        # Get save parameters
        include_index = kwargs.get('index', False)
        separator = kwargs.get('separator', ',')
        
        try:
            # Ensure output directory exists
            os.makedirs(os.path.dirname(filepath), exist_ok=True)
            
            self.logger.info(f"Saving {len(data)} rows for entity '{entity}' to {filepath}")
            
            # Save DataFrame to CSV
            data.to_csv(
                filepath, 
                sep=separator, 
                index=include_index
            )
            
            self.logger.info(f"Successfully saved data to {filepath}")
            return filepath
            
        except Exception as e:
            self.logger.error(f"Error saving CSV data: {str(e)}")
            raise

class DBDataManager(BaseDataManager):
    """
    Data manager implementation for database sources.
    
    Handles all operations related to database connections and queries.
    """
    
    def connect(self) -> None:
        """
        Establish database connection using SQLAlchemy.
        
        Creates an engine and session for database operations.
        """
        # Lazy import SQLAlchemy to avoid dependency if not used
        try:
            import sqlalchemy
            from sqlalchemy import create_engine, text
            from sqlalchemy.orm import sessionmaker
        except ImportError:
            self.logger.error("SQLAlchemy is required for DBDataManager. Please install with: pip install sqlalchemy")
            raise ImportError("SQLAlchemy is required for DBDataManager")

        # Get database URL from config
        db_url = self.config.database.get_connection_url()
        if not db_url:
            # Try to construct a default SQLite database path
            #data_dir = self.config.get('data_dir', 'data')
            #db_path = os.path.join(data_dir, 'production.db')
            #db_url = f"sqlite:///{db_path}"
            
            self.logger.info(f"No database URL provided, using default: {db_url}")
            raise ValueError("No database URL provided in config, please check the config file and manager")
        
        try:
            # Create engine
            self.engine = create_engine(db_url)
            
            # Create session
            Session = sessionmaker(bind=self.engine)
            self.session = Session()
            
            self.logger.info(f"Connected to database: {db_url}")
            
        except Exception as e:
            self.logger.error(f"Failed to connect to database: {str(e)}")
            raise

    def disconnect(self) -> None:
        """
        Close the database connection.
        """
        if hasattr(self, 'session') and self.session:
            try:
                self.session.close()
                self.logger.info("Closed database session")
            except Exception as e:
                self.logger.error(f"Error closing database session: {str(e)}")
        
        if hasattr(self, 'engine'):
            try:
                self.engine.dispose()
                self.logger.info("Disposed database engine")
            except Exception as e:
                self.logger.error(f"Error disposing database engine: {str(e)}")

    def load_data(self, entity: str, **kwargs) -> pd.DataFrame:
        """
        Load data from database table.
        
        Args:
            entity: Entity type determining the table or model to query
            **kwargs: Additional parameters including:
                - query_file: Path to SQL query file
                - model_class: The SQLAlchemy model class
                - query: Custom query to execute
                - filters: Dictionary of filters to apply
                - limit: Maximum number of rows to return
                
        Returns: 
            DataFrame with loaded data
        """
        # Check if session exists
        if not hasattr(self, 'session') or self.session is None:
            self.logger.error("No database session available. Make sure to call connect() first.")
            raise RuntimeError("No database session available")
        
        try:
            from sqlalchemy import Table, MetaData, text
        except ImportError:
            self.logger.error("SQLAlchemy is required for DBDataManager")
            raise ImportError("SQLAlchemy is required for DBDataManager")
        
        # Get query parameters
        model_class = kwargs.get('model_class')
        custom_query = kwargs.get('query')
        filters = kwargs.get('filters', {})
        limit = kwargs.get('limit')
        
        # Add query_file support
        query_file = kwargs.get('query_file')
        if query_file and not custom_query:
            try: 
                self.logger.info(f"Loading query from file: {query_file}")

                # Check if the file exists
                if not os.path.exists(query_file):
                    self.logger.error(f"Query file not found: {query_file}")
                    raise FileNotFoundError(f"Query file not found: {query_file}")
                
                with open(query_file, 'r', encoding='utf-8') as f:
                    custom_query = f.read().strip()

                if not custom_query:
                    self.logger.error(f"Query file is empty: {query_file}")
                    raise ValueError(f"Query file is empty: {query_file}")                
            
                # Format query with parameters if needed
                custom_query = self._format_query(custom_query, **kwargs)
                self.logger.info(f"Loaded query from file: {query_file}")
                self.logger.debug(f"Query content: {custom_query[:200]}...")  # Log first 200 chars

            except Exception as e:
                self.logger.error(f"Error loading query file {query_file}: {str(e)}")
                raise
        
        try:
            self.logger.info(f"Loading database data for entity '{entity}'")
            
            # Case 1: Custom query provided
            if custom_query is not None:
                self.logger.info("Executing custom query")
                try: 
                    # FIXED: Wrap the query in text() for SQLAlchemy
                    result = self.session.execute(text(custom_query))
                    
                    # Get column names BEFORE consuming the result
                    columns = list(result.keys())
                    rows = result.fetchall()

                    if rows:
                        data = pd.DataFrame(rows, columns=columns)
                    else:
                        data = pd.DataFrame()
                    
                    self.logger.info(f"Successfully loaded {len(data)} rows using custom query")
                    return data
                except Exception as query_error:
                    self.logger.error(f"Error executing query: {str(query_error)}")
                    self.logger.debug(f"Failed query: {custom_query}")
                    raise
                
            # Case 2: Model class provided
            elif model_class is not None:
                self.logger.info(f"Using model class: {model_class}")
                query = self.session.query(model_class)
                
                # Apply filters if any
                for attr, value in filters.items():
                    if hasattr(model_class, attr):
                        query = query.filter(getattr(model_class, attr) == value)
                
                # Apply limit if specified
                if limit is not None:
                    query = query.limit(limit)
                
                # Execute query
                result = query.all()
                
                # Convert to DataFrame
                if result:
                    # Convert SQLAlchemy objects to dictionaries
                    records = []
                    for record in result:
                        record_dict = {k: getattr(record, k) for k in record.__table__.columns.keys()}
                        records.append(record_dict)
                    data = pd.DataFrame(records)
                else:
                    data = pd.DataFrame()
                    
                self.logger.info(f"Successfully loaded {len(data)} rows using model class")
                return data
                
            # Case 3: Direct table query
            else:
                self.logger.info(f"Querying table directly: {entity}")
                metadata = MetaData()
                table = Table(entity, metadata, autoload_with=self.engine)
                query = self.session.query(table)
                
                # Apply filters if any
                for column, value in filters.items():
                    if column in table.columns:
                        query = query.filter(table.columns[column] == value)
                
                # Apply limit if specified
                if limit is not None:
                    query = query.limit(limit)
                
                # Execute query
                result = query.all()
                
                # Convert to DataFrame
                if result:
                    data = pd.DataFrame(result)
                    data.columns = table.columns.keys()
                else:
                    data = pd.DataFrame()
                    
                self.logger.info(f"Successfully loaded {len(data)} rows from table {entity}")
                return data
                
        except Exception as e:
            self.logger.error(f"Error loading database data for entity '{entity}': {str(e)}")
            # Log additional context
            self.logger.error(f"Query file: {query_file}")
            self.logger.error(f"Custom query provided: {custom_query is not None}")
            self.logger.error(f"Model class: {model_class}")
            raise
    
    def _format_query(self, query: str, **kwargs) -> str:
        """
        Format query with parameters if needed.
        
        Args:
            query: SQL query string
            **kwargs: Parameters to substitute in query
            
        Returns:
            Formatted query string
        """
        formatted_query = query
        
        # Replace common parameters
        for param_name, param_value in kwargs.items():
            placeholder = f"{{{param_name}}}"
            if placeholder in formatted_query:
                # Handle different data types
                if isinstance(param_value, str):
                    # Check if this looks like a comma-separated list for IN clause
                    if ',' in param_value and param_value.replace(',', '').replace("'", '').replace('"', '').replace(' ', '').isdigit():
                        # This is a comma-separated list of numbers - use as-is
                        replacement = param_value
                    else:
                        # Regular string parameter
                        unquoted_value = param_value.strip("'\"")
                        escaped_value = unquoted_value.replace("'", "''")
                        replacement = f"'{escaped_value}'"
                else:
                    # For numeric values, use as-is
                    replacement = str(param_value)
                
                formatted_query = formatted_query.replace(placeholder, replacement)
                self.logger.info(f"Replaced {placeholder} with {replacement}")
        
        return formatted_query
        
    def save_data(self, entity: str, data: pd.DataFrame, **kwargs) -> None:
        """
        Save data to database table.
        
        Args:
            entity: Entity type determining the table to save to
            data: DataFrame to save
            **kwargs: Additional parameters including:
                - model_class: The SQLAlchemy model class
                - if_exists: How to behave if the table exists ('fail', 'replace', 'append')
                - index: Whether to include index (default False)
                - chunk_size: Number of rows to insert at once
        """
        # Check if session exists
        if not hasattr(self, 'session') or self.session is None:
            self.logger.error("No database session available. Make sure to call connect() first.")
            raise RuntimeError("No database session available")
        
        # Get parameters
        model_class = kwargs.get('model_class')
        if_exists = kwargs.get('if_exists', 'append')
        index = kwargs.get('index', False)
        chunk_size = kwargs.get('chunk_size', None)

        try:
            self.logger.info(f"Saving {len(data)} rows for entity '{entity}' to database")

            if model_class:
                # Save using sqlalchemy models
                records = data.to_dict('records')
                
                if chunk_size:
                    # Insert in chunks
                    for i in range(0, len(records), chunk_size):
                        chunk = records[i:i+chunk_size]
                        for record in chunk:
                            instance = model_class(**record)
                            self.session.add(instance)
                        self.session.commit()
                else:
                    # Insert all at once
                    for record in records:
                        instance = model_class(**record)
                        self.session.add(instance)
                    self.session.commit()
            else:
                # Direct table save if no model_class is provided
                data.to_sql(
                    entity, 
                    self.engine, 
                    if_exists=if_exists, 
                    index=index,
                    chunksize=chunk_size
                )
            
            self.logger.info(f"Successfully saved data for entity '{entity}'")

        except Exception as e:
            if hasattr(self, 'session') and self.session:
                self.session.rollback()
            self.logger.error(f"Error saving database data: {str(e)}")
            raise

    def execute_sql(self, sql_query: str, **kwargs) -> pd.DataFrame:
        """
        Execute a raw SQL query against the database.
        
        Args:
            sql_query: SQL query to execute
            **kwargs: Parameters for query substitution
            
        Returns:
            DataFrame with query results
        """
        # Check if session exists
        if not hasattr(self, 'session') or self.session is None:
            self.logger.error("No database session available. Make sure to call connect() first.")
            raise RuntimeError("No database session available")
        
        try:
            from sqlalchemy import text
        except ImportError:
            self.logger.error("SQLAlchemy is required for DBDataManager")
            raise ImportError("SQLAlchemy is required for DBDataManager")
        
        # Format query with parameters
        formatted_query = self._format_query(sql_query, **kwargs)
        
        try:
            self.logger.info("Executing raw SQL query")
            self.logger.debug(f"SQL: {formatted_query}")
            
            # FIXED: Wrap the query in text() for SQLAlchemy
            result = self.session.execute(text(formatted_query))
            
            # Get column names and rows
            columns = list(result.keys())
            rows = result.fetchall()
            
            if rows:
                data = pd.DataFrame(rows, columns=columns)
            else:
                data = pd.DataFrame()
            
            self.logger.info(f"Raw SQL query returned {len(data)} rows")
            return data
            
        except Exception as e:
            self.logger.error(f"Error executing raw SQL: {str(e)}")
            self.logger.debug(f"Failed query: {formatted_query}")
            raise

    def set_process_errors(self, message_key: str, rendered_message: str, values_replace_dict: dict, error_type: str = 'INFO', **kwargs) -> bool:
        """
        Log structured messages to database using Oracle stored procedure.
        
        Args:
            message_key: Template key (e.g., 'iniProc', 'errCallSubProc')
            rendered_message: Human-readable message after template rendering  
            error_type: Log level ('INFO', 'ERROR', 'WARNING')
            
        Returns:
            bool: True if database logging succeeded, False otherwise
        """
        try:
            if not hasattr(self, 'session') or self.session is None:
                return False

            if not values_replace_dict:
                self.logger.error("No values_replace_dict found")
                return False
            
            from sqlalchemy import text
            
            oracle_query = """
            declare 
            i_user VARCHAR2(242) := :user_param;
            i_fk_process NUMBER := :fk_process_param;
            i_type_error VARCHAR2(242) := :type_error_param; 
            i_process_type VARCHAR2(242) := :process_type_param; 
            i_error_code VARCHAR2(242) := :error_code_param; 
            i_description VARCHAR2(242) := :description_param; 
            i_employee_id NUMBER := :employee_id_param; 
            i_schedule_day DATE := to_date(:schedule_day_param,'yyyy-mm-dd'); 
            begin
            S_PROCESSO.SET_PROCESS_ERRORS(i_user,i_fk_process,i_type_error,i_process_type,i_error_code,i_description,i_employee_id,i_schedule_day);
            COMMIT;
            end;
            """
            
            params = {
                'user_param': values_replace_dict.get('wfm_user', 'WFM'),
                'fk_process_param': values_replace_dict.get('current_process_id'),
                'type_error_param': error_type,
                'process_type_param': 'WFM',
                'error_code_param': message_key,
                'description_param': rendered_message,
                'employee_id_param': values_replace_dict.get('wfm_proc_colab', None),
                'schedule_day_param': values_replace_dict.get('date_str', None)
            }
            
            self.session.execute(text(oracle_query), params)
            return True
            
        except Exception as e:
            self.logger.error(f"Database logging failed: {str(e)}")
            return False

    # Alternative implementation using query file approach
    # (Add this as well if you prefer the query file pattern)

    def set_process_errors_with_file(self, 
                                    message_key: str, 
                                    rendered_message: str, 
                                    error_type: str = 'INFO', 
                                    **kwargs) -> bool:
        """
        Alternative implementation using query file pattern.
        
        This version reads the Oracle stored procedure call from a SQL file,
        following the existing pattern used elsewhere in the framework.
        
        Args:
            message_key: Template key (e.g., 'iniProc', 'errCallSubProc')
            rendered_message: Human-readable message after template rendering
            error_type: Log level ('INFO', 'ERROR', 'WARNING')
            **kwargs: Additional parameters for query execution
            
        Returns:
            bool: True if database logging succeeded, False otherwise
        """
        try:
            # Get query file path from config
            query_file = self.config.get('logging', {}).get('db_logging_query', 'queries/log_process_errors.sql')
            
            # Check if query file exists
            if not os.path.exists(query_file):
                self.logger.error(f"Database logging query file not found: {query_file}")
                return False
            
            # Get external call data
            external_data = self.config.get('external_call_data', {})
            if not external_data:
                self.logger.error("No external_call_data found in config for process error logging")
                return False
            
            # Prepare parameters for query substitution
            query_params = {
                'user': external_data.get('wfm_user', 'WFM'),
                'fk_process': external_data.get('current_process_id'),
                'type_error': error_type,
                'process_type': 'WFM',
                'error_code': message_key,
                'description': rendered_message,
                'employee_id': external_data.get('wfm_proc_colab'),
                'schedule_day': external_data.get('start_date', '2025-01-01')
            }
            
            # Validate required parameters
            if query_params['fk_process'] is None:
                self.logger.error("Missing current_process_id in external_call_data")
                return False
            
            # Use existing execute_sql method
            self.execute_sql(query_file=query_file, **query_params)
            
            self.logger.debug(f"Successfully logged process error to database via query file: {message_key}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to log process error to database via query file: {str(e)}")
            return False