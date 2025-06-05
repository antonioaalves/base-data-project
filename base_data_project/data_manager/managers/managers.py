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

class CSVDataManager(BaseDataManager):
    """
    Unified CSV data manager that supports both SQL queries and pandas filtering.
    
    Automatically chooses the best approach:
    - SQL execution via pandasql (when available and SQL queries provided)
    - Pandas filtering (fallback when pandasql not available)
    
    Your code remains identical regardless of which approach is used.
    """
    
    def __init__(self, config: Dict[str, Any]) -> None:
        """Initialize the unified CSV data manager."""
        super().__init__(config)
        
        # Try to import pandasql for SQL query support
        self.pandasql_available = False
        self.sqldf = None
        try:
            from pandasql import sqldf
            self.sqldf = sqldf
            self.pandasql_available = True
            self.logger.info("PandasSQL available - SQL queries will be executed directly")
        except ImportError:
            self.logger.info("PandasSQL not available - will use pandas filtering for queries")
        
        # Cache for loaded DataFrames (when using SQL queries)
        self.dataframe_cache = {}
        self.cache_loaded = False
    
    def connect(self) -> None:
        """
        'Connect' to CSV files - validates that the data directory exists.
        
        If pandasql is available, optionally pre-loads CSV files for SQL queries.
        """
        # FIXED: Use only dummy_data_filepaths for CSV mappings
        filepath_map = self.config.get('dummy_data_filepaths', {})
        
        # Get data directory path
        data_dir = self.config.get('data_dir', 'data')
        
        # Check if data directory exists
        if not os.path.exists(data_dir):
            os.makedirs(data_dir, exist_ok=True)
            self.logger.info(f"Created data directory: {data_dir}")
        
        # Check output directory
        output_dir = self.config.get('output_dir', os.path.join(data_dir, 'output'))
        if not os.path.exists(output_dir):
            os.makedirs(output_dir, exist_ok=True)
            self.logger.info(f"Created output directory: {output_dir}")
        
        # FIXED: Raise errors instead of warnings for missing files
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

    def _load_dataframes_for_sql(self) -> None:
        """
        Load all CSV files into DataFrame cache for SQL query execution.
        
        This is called on-demand when SQL queries are used.
        """
        if self.cache_loaded or not self.pandasql_available:
            return
            
        self.logger.info("Loading CSV files into DataFrame cache for SQL queries")
        
        # FIXED: Use only dummy_data_filepaths
        filepath_map = self.config.get('dummy_data_filepaths', {})
        
        for entity, filepath in filepath_map.items():
            if os.path.exists(filepath):
                try:
                    df = pd.read_csv(filepath)
                    self.dataframe_cache[entity] = df
                    
                    # Also create mappings for SQL table names
                    # Handle patterns like 'wfm.esc_feriado' -> 'esc_feriado'
                    table_name = entity
                    if '.' in table_name:
                        table_name = table_name.split('.')[-1]
                    
                    self.dataframe_cache[table_name] = df
                    
                    self.logger.info(f"Loaded {len(df)} rows from {filepath} as table '{table_name}'")
                    
                except Exception as e:
                    self.logger.error(f"Error loading CSV {filepath}: {str(e)}")
                    # FIXED: Raise error instead of continuing silently
                    raise
            else:
                # FIXED: Raise error for missing files instead of warning
                error_msg = f"CSV file not found during cache loading: {filepath}"
                self.logger.error(error_msg)
                raise FileNotFoundError(error_msg)
        
        # Auto-detect table names from SQL files
        self._auto_detect_table_mappings()
        self.cache_loaded = True

    def _auto_detect_table_mappings(self) -> None:
        """Auto-detect table names from SQL files and map them to entities."""
        entities_config = self.config.get('available_entities_processing', {})
        
        for entity, query_file in entities_config.items():
            if os.path.exists(query_file):
                try:
                    with open(query_file, 'r', encoding='utf-8') as f:
                        sql_content = f.read()
                    
                    # Extract table names from FROM clauses
                    from_matches = re.findall(r'from\s+(\w+\.?\w+)', sql_content, re.IGNORECASE)
                    
                    for table_ref in from_matches:
                        if '.' in table_ref:
                            schema, table = table_ref.split('.', 1)
                            clean_table = table
                        else:
                            clean_table = table_ref
                        
                        # Map this table name to the entity if we have the DataFrame
                        if entity in self.dataframe_cache:
                            self.dataframe_cache[clean_table] = self.dataframe_cache[entity]
                            self.logger.debug(f"Auto-mapped SQL table '{clean_table}' to entity '{entity}'")
                
                except Exception as e:
                    self.logger.warning(f"Error parsing SQL file {query_file}: {str(e)}")

    def disconnect(self) -> None:
        """
        Disconnect and clear DataFrame cache if loaded.
        """
        if hasattr(self, 'dataframe_cache'):
            self.dataframe_cache.clear()
            self.cache_loaded = False
        self.logger.info("Disconnected from CSV data source")

    def load_data(self, entity: str, **kwargs) -> pd.DataFrame:
        """
        Load data from a CSV file with support for both SQL queries and pandas filtering.
        
        Args:
            entity: Entity type determining the file to load
            **kwargs: Additional parameters including:
                # SQL Query parameters (when pandasql is available)
                - query_file: Path to SQL query file
                - query: Direct SQL query string
                
                # File parameters
                - filepath: Optional explicit filepath
                - separator: CSV separator (default ',')
                - decimal: Decimal separator (default '.')
                - encoding: File encoding (default 'utf-8')
                - header: Header row number (default 0)
                - index_col: Column to use as index
                - parse_dates: Parse date columns
                
                # Pandas filtering parameters (fallback when no SQL)
                - filters: Dictionary of column filters {column: value}
                - where_conditions: List of condition strings for complex filtering
                - limit: Maximum number of rows to return
                - offset: Number of rows to skip (for pagination)
                - sort_by: Column name(s) to sort by
                - sort_ascending: Sort direction (default True)
                - columns: List of specific columns to return
                
                # Any other parameters will be used for SQL parameter substitution
                
        Returns:
            DataFrame with loaded data
        """
        query_file = kwargs.get('query_file')
        direct_query = kwargs.get('query')
        
        # IMPROVED: Query file handling - execute SQL against DataFrames when available
        if (query_file or direct_query) and self.pandasql_available:
            self.logger.info(f"Executing SQL query against DataFrames for entity '{entity}'")
            return self._load_data_with_sql(entity, **kwargs)
        else:
            # Fall back to pandas filtering approach
            if query_file or direct_query:
                self.logger.info("SQL query provided but pandasql not available, using pandas filtering fallback")
            return self._load_data_with_pandas(entity, **kwargs)

    def _load_data_with_sql(self, entity: str, **kwargs) -> pd.DataFrame:
        """
        Load data using SQL queries against cached DataFrames.
        
        Args:
            entity: Entity name
            **kwargs: Parameters including query_file, query, and SQL parameters
            
        Returns:
            DataFrame with query results
        """
        # Ensure DataFrames are loaded into cache
        self._load_dataframes_for_sql()
        
        query_file = kwargs.get('query_file')
        direct_query = kwargs.get('query')
        
        if query_file:
            # FIXED: Proper error handling for query files
            if not os.path.exists(query_file):
                error_msg = f"SQL query file not found: {query_file}"
                self.logger.error(error_msg)
                raise FileNotFoundError(error_msg)
                
            # Read SQL from file
            with open(query_file, 'r', encoding='utf-8') as f:
                sql_query = f.read().strip()
                
            if not sql_query:
                error_msg = f"SQL query file is empty: {query_file}"
                self.logger.error(error_msg)
                raise ValueError(error_msg)
                
            self.logger.info(f"Loaded SQL query from {query_file}")
            
            # Extract table names from this specific SQL query and map them to the entity
            self._map_sql_tables_to_entity(sql_query, entity)
            
        elif direct_query:
            # Use direct query
            sql_query = direct_query
            self.logger.info("Using direct SQL query")
            
            # Extract table names from this specific SQL query and map them to the entity
            self._map_sql_tables_to_entity(sql_query, entity)
            
        else:
            # No query provided, return the entire DataFrame for the entity
            if entity in self.dataframe_cache:
                self.logger.info(f"Returning entire DataFrame for entity '{entity}'")
                return self.dataframe_cache[entity].copy()
            else:
                # FIXED: Raise error instead of returning empty DataFrame
                error_msg = f"No data found for entity '{entity}' in DataFrame cache"
                self.logger.error(error_msg)
                raise ValueError(error_msg)
        
        # Format SQL query with parameters
        formatted_query = self._format_sql_query(sql_query, **kwargs)
        
        try:
            self.logger.info(f"Executing SQL query for entity '{entity}'")
            self.logger.debug(f"SQL Query: {formatted_query}")
            
            # Execute SQL query using pandasql
            result = self.sqldf(formatted_query, self.dataframe_cache)
            
            self.logger.info(f"SQL query returned {len(result)} rows")
            return result
            
        except Exception as e:
            self.logger.error(f"Error executing SQL query: {str(e)}")
            self.logger.error(f"Query: {formatted_query}")
            self.logger.error(f"Available tables: {list(self.dataframe_cache.keys())}")
            # Fall back to CSV filtering approach
            return self._load_data_with_pandas(entity, **kwargs)

    def _map_sql_tables_to_entity(self, sql_query: str, entity: str) -> None:
        """
        Extract table names from a specific SQL query and map them to the entity DataFrame.
        
        This only processes the SQL query being executed, not all SQL files in config.
        """
        if entity not in self.dataframe_cache:
            self.logger.warning(f"Entity '{entity}' not found in DataFrame cache")
            return
            
        try:
            # Extract table names from FROM clauses in this specific query
            from_matches = re.findall(r'from\s+(\w+\.?\w+)', sql_query, re.IGNORECASE)
            
            for table_ref in from_matches:
                if '.' in table_ref:
                    schema, table = table_ref.split('.', 1)
                    clean_table = table
                else:
                    clean_table = table_ref
                
                # Map this table name to the entity DataFrame
                self.dataframe_cache[clean_table] = self.dataframe_cache[entity]
                self.logger.debug(f"Mapped SQL table '{clean_table}' to entity '{entity}' for this query")
        
        except Exception as e:
            self.logger.debug(f"Error mapping SQL tables for query: {str(e)}")
            # This is not critical - the query might still work with entity names

    def _load_data_with_pandas(self, entity: str, **kwargs) -> pd.DataFrame:
        """
        Load data using pandas filtering (original implementation).
        
        This is the fallback when pandasql is not available or no SQL query is provided.
        """
        filepath = kwargs.get('filepath')

        # Handle query_file mapping and automatic SQL-to-CSV translation
        query_file = kwargs.get('query_file')
        if query_file and not filepath:
            # FIXED: Use only dummy_data_filepaths for CSV mappings
            filepath = self.config.get('dummy_data_filepaths', {}).get(entity)
            
            if filepath:
                self.logger.info(f"Mapped entity '{entity}' to CSV file: {filepath}")
            
            # Automatically translate SQL query to CSV filtering if query file exists
            kwargs_without_query_file = {k: v for k, v in kwargs.items() if k != 'query_file'}
            auto_filters, auto_conditions, auto_columns = self._parse_sql_query_for_csv(query_file, **kwargs_without_query_file)
            
            # Merge automatic filters with explicitly provided ones
            if auto_filters:
                existing_filters = kwargs.get('filters', {})
                kwargs['filters'] = {**auto_filters, **existing_filters}
            
            if auto_conditions:
                existing_conditions = kwargs.get('where_conditions', [])
                kwargs['where_conditions'] = auto_conditions + existing_conditions
                
            if auto_columns and not kwargs.get('columns'):
                kwargs['columns'] = auto_columns

        if not filepath:
            # FIXED: Use only dummy_data_filepaths
            filepath_map = self.config.get('dummy_data_filepaths', {})
                
            if entity in filepath_map:
                filepath = filepath_map[entity]
            else:
                # Try to construct a default path
                data_dir = self.config.get('data_dir', 'data')
                filepath = os.path.join(data_dir, 'csvs', f"{entity}.csv")
                self.logger.info(f"No explicit mapping for entity '{entity}', using default path: {filepath}")

        # FIXED: Raise error instead of returning empty DataFrame
        if not filepath:
            error_msg = f"No filepath configured for entity '{entity}'"
            self.logger.error(error_msg)
            raise ValueError(error_msg)

        # Get CSV reading parameters
        separator = kwargs.get('separator', ',')
        decimal = kwargs.get('decimal', '.')
        encoding = kwargs.get('encoding', 'utf-8')
        header = kwargs.get('header', 0)
        index_col = kwargs.get('index_col', None)
        parse_dates = kwargs.get('parse_dates', False)
        
        # Get filtering parameters
        filters = kwargs.get('filters', {})
        where_conditions = kwargs.get('where_conditions', [])
        limit = kwargs.get('limit')
        offset = kwargs.get('offset', 0)
        sort_by = kwargs.get('sort_by')
        sort_ascending = kwargs.get('sort_ascending', True)
        columns = kwargs.get('columns')
        
        try:
            self.logger.info(f"Loading CSV data for entity {entity} from {filepath}")
            
            # FIXED: Raise error instead of returning empty DataFrame
            if not os.path.exists(filepath):
                error_msg = f"CSV file not found: {filepath}"
                self.logger.error(error_msg)
                raise FileNotFoundError(error_msg)
                
            # Read CSV file
            data = pd.read_csv(
                filepath, 
                sep=separator, 
                decimal=decimal, 
                encoding=encoding,
                header=header,
                index_col=index_col,
                parse_dates=parse_dates
            )
            
            self.logger.info(f"Successfully loaded {len(data)} rows for entity '{entity}'")
            
            # Apply filtering if specified
            if filters or where_conditions or columns or sort_by or limit or offset:
                # Remove conflicting parameters from kwargs
                filtered_kwargs = {k: v for k, v in kwargs.items() 
                                if k not in ['filters', 'where_conditions', 'columns', 'sort_by', 
                                            'sort_ascending', 'limit', 'offset']}
                data = self._apply_filters(data, filters, where_conditions, columns, 
                                        sort_by, sort_ascending, limit, offset, **filtered_kwargs)
            
            return data
            
        except pd.errors.EmptyDataError:
            # FIXED: Raise error instead of returning empty DataFrame
            error_msg = f"Empty CSV file: {filepath}"
            self.logger.error(error_msg)
            raise ValueError(error_msg)
            
        except Exception as e:
            self.logger.error(f"Error loading CSV data: {str(e)}")
            raise

    def _format_sql_query(self, query: str, **kwargs) -> str:
        """
        Format SQL query with parameter substitution.
        
        Args:
            query: SQL query string with parameter placeholders
            **kwargs: Parameters for substitution
            
        Returns:
            Formatted SQL query
        """
        formatted_query = query
        
        # Remove non-SQL parameters from kwargs
        sql_params = {k: v for k, v in kwargs.items() 
                     if k not in ['query_file', 'query', 'filepath', 'separator', 'encoding', 
                                 'filters', 'where_conditions', 'limit', 'offset', 'sort_by', 
                                 'sort_ascending', 'columns', 'header', 'index_col', 'parse_dates']}
        
        # Replace parameters in the query
        for param_name, param_value in sql_params.items():
            placeholder = f"{{{param_name}}}"
            
            if placeholder in formatted_query:
                # Handle different data types
                if isinstance(param_value, str):
                    # Remove leading/trailing quotes if present
                    unquoted_value = param_value.strip("'\"")
                    escaped_value = unquoted_value.replace("'", "''")
                    replacement = f"'{escaped_value}'"
                else:
                    # For numeric values, use as-is
                    replacement = str(param_value)
                
                formatted_query = formatted_query.replace(placeholder, replacement)
                self.logger.debug(f"Replaced {placeholder} with {replacement}")
        
        return formatted_query

    def _apply_filters(self, data: pd.DataFrame, filters: Dict[str, Any], 
                      where_conditions: List[str], columns: Optional[List[str]],
                      sort_by: Optional[Union[str, List[str]]], sort_ascending: bool,
                      limit: Optional[int], offset: int, **kwargs) -> pd.DataFrame:
        """
        Apply filtering, sorting, and selection to the DataFrame.
        
        Args:
            data: Input DataFrame
            filters: Dictionary of simple column filters
            where_conditions: List of complex condition strings
            columns: Specific columns to select
            sort_by: Column(s) to sort by
            sort_ascending: Sort direction
            limit: Maximum rows to return
            offset: Rows to skip
            **kwargs: Additional parameters for substitution in conditions
            
        Returns:
            Filtered DataFrame
        """
        original_rows = len(data)
        
        # 1. Apply simple filters (exact matches)
        if filters:
            self.logger.info(f"Applying filters: {filters}")
            for column, value in filters.items():
                if column in data.columns:
                    if isinstance(value, list):
                        # Handle list of values (IN operation)
                        data = data[data[column].isin(value)]
                    else:
                        # Handle single value (equals operation)
                        data = data[data[column] == value]
                else:
                    self.logger.warning(f"Filter column '{column}' not found in data")
        
        # 2. Apply complex where conditions
        if where_conditions:
            self.logger.info(f"Applying where conditions: {where_conditions}")
            for condition in where_conditions:
                try:
                    # Substitute parameters in condition
                    formatted_condition = self._format_condition(condition, **kwargs)
                    
                    # Evaluate the condition
                    mask = self._evaluate_condition(data, formatted_condition)
                    data = data[mask]
                    
                except Exception as e:
                    self.logger.error(f"Error applying condition '{condition}': {str(e)}")
                    raise
        
        # 3. Select specific columns if specified
        if columns:
            self.logger.info(f"Selecting columns: {columns}")
            # Only select columns that exist in the data
            existing_columns = [col for col in columns if col in data.columns]
            missing_columns = [col for col in columns if col not in data.columns]
            
            if missing_columns:
                self.logger.warning(f"Columns not found in data: {missing_columns}")
            
            if existing_columns:
                data = data[existing_columns]
            else:
                # FIXED: Raise error instead of returning empty DataFrame
                error_msg = "No valid columns found for selection"
                self.logger.error(error_msg)
                raise ValueError(error_msg)
        
        # 4. Apply sorting
        if sort_by:
            self.logger.info(f"Sorting by: {sort_by}, ascending: {sort_ascending}")
            if isinstance(sort_by, str):
                sort_by = [sort_by]
            
            # Only sort by columns that exist
            existing_sort_columns = [col for col in sort_by if col in data.columns]
            if existing_sort_columns:
                data = data.sort_values(by=existing_sort_columns, ascending=sort_ascending)
            else:
                self.logger.warning(f"Sort columns not found: {sort_by}")
        
        # 5. Apply offset (skip rows)
        if offset > 0:
            self.logger.info(f"Applying offset: {offset}")
            data = data.iloc[offset:]
        
        # 6. Apply limit
        if limit is not None and limit > 0:
            self.logger.info(f"Applying limit: {limit}")
            data = data.head(limit)
        
        # Reset index after all operations
        data = data.reset_index(drop=True)
        
        filtered_rows = len(data)
        self.logger.info(f"Filtering complete: {original_rows} -> {filtered_rows} rows")
        
        return data

    def _format_condition(self, condition: str, **kwargs) -> str:
        """
        Format condition string with parameter substitution.
        
        Args:
            condition: Condition string with placeholders
            **kwargs: Parameters for substitution
            
        Returns:
            Formatted condition string
        """
        formatted_condition = condition
        
        # Replace parameters in the condition
        for param_name, param_value in kwargs.items():
            # Handle different placeholder formats
            placeholders = [
                f"{{{param_name}}}",  # {param_name}
                f":{param_name}",     # :param_name
                f"@{param_name}"      # @param_name
            ]
            
            for placeholder in placeholders:
                if placeholder in formatted_condition:
                    # Handle different data types appropriately
                    if isinstance(param_value, str):
                        # Quote string values and escape quotes
                        escaped_value = param_value.replace("'", "''")
                        replacement = f"'{escaped_value}'"
                    else:
                        replacement = str(param_value)
                    
                    formatted_condition = formatted_condition.replace(placeholder, replacement)
                    self.logger.debug(f"Replaced {placeholder} with {replacement}")
        
        return formatted_condition

    def _evaluate_condition(self, data: pd.DataFrame, condition: str) -> pd.Series:
        """
        Evaluate a condition string against a DataFrame.
        
        Args:
            data: DataFrame to evaluate against
            condition: Condition string to evaluate
            
        Returns:
            Boolean Series representing the condition result
        """
        # Create a safe evaluation environment with just the DataFrame columns
        # and common functions
        eval_env = {
            # Add DataFrame columns to the environment
            **{col: data[col] for col in data.columns},
            
            # Add common functions that might be useful
            'abs': abs,
            'len': len,
            'str': str,
            'int': int,
            'float': float,
            'min': min,
            'max': max,
            'sum': sum,
            'any': any,
            'all': all,
            
            # Add pandas functions
            'isnull': pd.isnull,
            'notnull': pd.notnull,
            'isna': pd.isna,
            'notna': pd.notna,
        }
        
        try:
            # Evaluate the condition
            self.logger.debug(f"Evaluating condition: {condition}")
            
            # Special handling for 'in' operations with single values
            # Convert "column in (value)" to "column == value" for single values
            import re
            in_pattern = r'(\w+)\s+in\s+\(([^)]+)\)'
            match = re.match(in_pattern, condition.strip())
            
            if match:
                column_name = match.group(1)
                values_str = match.group(2).strip()
                
                # Check if column exists
                if column_name not in data.columns:
                    raise ValueError(f"Column '{column_name}' not found in data")
                
                # Parse values - handle both single values and lists
                if ',' in values_str:
                    # Multiple values - create a list
                    values = [v.strip().strip("'\"") for v in values_str.split(',')]
                    # Convert to appropriate types
                    try:
                        # Try converting to numeric
                        values = [float(v) if '.' in v else int(v) for v in values]
                    except ValueError:
                        # Keep as strings if conversion fails
                        pass
                    result = data[column_name].isin(values)
                else:
                    # Single value
                    value = values_str.strip().strip("'\"")
                    # Try converting to appropriate type
                    try:
                        if '.' in value:
                            value = float(value)
                        else:
                            value = int(value)
                    except ValueError:
                        # Keep as string if conversion fails
                        pass
                    result = data[column_name] == value
            else:
                # For other conditions, use regular eval
                result = eval(condition, {"__builtins__": {}}, eval_env)
            
            # Ensure result is a boolean Series
            if isinstance(result, pd.Series):
                return result.astype(bool)
            else:
                # If result is a scalar, create a Series
                return pd.Series([bool(result)] * len(data), index=data.index)
                
        except Exception as e:
            self.logger.error(f"Error evaluating condition '{condition}': {str(e)}")
            raise ValueError(f"Invalid condition: {condition}")
    

    def _parse_sql_query_for_csv(self, query_file: str, **kwargs) -> tuple:
        """
        Parse SQL query file to automatically generate CSV filtering parameters.
        
        This method reads SQL query files and extracts:
        1. Column selections (SELECT clause)
        2. Filter conditions (WHERE clause) 
        3. Parameter placeholders for substitution
        
        Args:
            query_file: Path to SQL query file
            **kwargs: Parameters for substitution in the query
            
        Returns:
            Tuple of (filters_dict, conditions_list, columns_list)
        """
        # Skip empty or invalid file paths
        if not query_file or not isinstance(query_file, str) or query_file.strip() == '':
            self.logger.debug("Skipping empty query file path")
            return {}, [], None
            
        # Check if it's a directory path
        if query_file.endswith(os.sep) or query_file.endswith('/'):
            self.logger.warning(f"Query file path appears to be a directory: {query_file}")
            return {}, [], None
            
        # FIXED: Raise error instead of returning empty results
        if not os.path.exists(query_file) or not os.path.isfile(query_file):
            error_msg = f"Query file not found: {query_file}"
            self.logger.error(error_msg)
            raise FileNotFoundError(error_msg)
            
        try:
            self.logger.info(f"Parsing SQL query file for CSV translation: {query_file}")
            
            with open(query_file, 'r', encoding='utf-8') as f:
                sql_content = f.read().strip()
                
            if not sql_content:
                error_msg = f"Query file is empty: {query_file}"
                self.logger.error(error_msg)
                raise ValueError(error_msg)
                
            sql_content = sql_content.lower()
            
            # Remove comments and normalize whitespace
            sql_content = re.sub(r'--.*?\n', '\n', sql_content)  # Remove line comments
            sql_content = re.sub(r'/\*.*?\*/', '', sql_content, flags=re.DOTALL)  # Remove block comments
            sql_content = ' '.join(sql_content.split())  # Normalize whitespace
            
            auto_filters = {}
            auto_conditions = []
            auto_columns = None
            
            # Extract SELECT columns
            select_match = re.search(r'select\s+(.*?)\s+from', sql_content)
            if select_match:
                select_clause = select_match.group(1)
                if select_clause.strip() != '*':
                    # Parse column names (handle aliases and table prefixes)
                    columns = []
                    for col in select_clause.split(','):
                        col = col.strip()
                        # Remove table prefixes (e.g., "table.column" -> "column")
                        if '.' in col:
                            col = col.split('.')[-1]
                        # Handle aliases (e.g., "column as alias" -> "column")
                        if ' as ' in col:
                            col = col.split(' as ')[0].strip()
                        columns.append(col.strip())
                    auto_columns = columns
                    self.logger.info(f"Auto-detected columns: {auto_columns}")
            
            # Extract WHERE conditions
            where_match = re.search(r'where\s+(.*?)(?:\s+order\s+by|\s+group\s+by|\s+limit|$)', sql_content)
            if where_match:
                where_clause = where_match.group(1).strip()
                
                # Split conditions by AND (simple parsing)
                conditions = [cond.strip() for cond in where_clause.split(' and ')]
                
                for condition in conditions:
                    # Try to parse simple equality conditions
                    eq_match = re.match(r'(\w+(?:\.\w+)?)\s*=\s*\{(\w+)\}', condition)
                    if eq_match:
                        column = eq_match.group(1)
                        param = eq_match.group(2)
                        
                        # Remove table prefix from column name
                        if '.' in column:
                            column = column.split('.')[-1]
                        
                        # Check if parameter is provided in kwargs
                        if param in kwargs:
                            auto_filters[column] = kwargs[param]
                            self.logger.info(f"Auto-filter: {column} = {kwargs[param]} (from {param})")
                        else:
                            # Convert to where_condition for later substitution
                            auto_conditions.append(f'{column} == {{{param}}}')
                            self.logger.info(f"Auto-condition: {column} == {{{param}}}")
                    else:
                        # For complex conditions, convert parameter placeholders and add as-is
                        converted_condition = condition
                        
                        # Convert SQL parameter format to our format
                        converted_condition = re.sub(r'\{(\w+)\}', r'{\1}', converted_condition)
                        
                        # Remove table prefixes from column references
                        converted_condition = re.sub(r'\b\w+\.(\w+)\b', r'\1', converted_condition)
                        
                        auto_conditions.append(converted_condition)
                        self.logger.info(f"Auto-condition (complex): {converted_condition}")
            
            return auto_filters, auto_conditions, auto_columns
            
        except Exception as e:
            self.logger.error(f"Error parsing SQL query file {query_file}: {str(e)}")
            raise

    def save_data(self, entity: str, data: pd.DataFrame, **kwargs) -> str:
        """
        Save data to a CSV file.
        
        Args:
            entity: Entity type determining the file to save to
            data: DataFrame to save
            **kwargs: Additional parameters including:
                - filepath: Optional explicit filepath
                - separator: CSV separator (default ',')
                - index: Whether to include index (default False)
                - encoding: File encoding (default 'utf-8')
        
        Returns:
            Path to the saved file
        """
        filepath = kwargs.get('filepath')
        
        if not filepath:
            # Generate output path
            output_dir = self.config.get('output_dir', os.path.join('data', 'output'))
            
            # Use timestamp in the filename
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filepath = os.path.join(output_dir, f"{entity}_{timestamp}.csv")
        
        # Get CSV writing parameters
        separator = kwargs.get('separator', ',')
        include_index = kwargs.get('index', False)
        encoding = kwargs.get('encoding', 'utf-8')
        
        try:
            # Create directory if it doesn't exist
            os.makedirs(os.path.dirname(filepath), exist_ok=True)
            
            self.logger.info(f"Saving {len(data)} rows for entity '{entity}' to {filepath}")
            
            # Save data to CSV
            data.to_csv(
                filepath, 
                sep=separator, 
                index=include_index,
                encoding=encoding
            )
            
            # Update cache if this entity is cached
            if hasattr(self, 'dataframe_cache') and entity in self.dataframe_cache:
                self.dataframe_cache[entity] = data.copy()
                self.logger.info(f"Updated cache for entity '{entity}'")
            
            self.logger.info(f"Successfully saved data to {filepath}")
            return filepath
            
        except Exception as e:
            self.logger.error(f"Error saving CSV data: {str(e)}")
            raise

    def execute_sql(self, sql_query: str, **kwargs) -> pd.DataFrame:
        """
        Execute a raw SQL query against cached DataFrames (when pandasql is available).
        
        Args:
            sql_query: SQL query to execute
            **kwargs: Parameters for query substitution
            
        Returns:
            DataFrame with query results
        """
        if not self.pandasql_available:
            error_msg = "SQL execution requires pandasql. Install with: pip install pandasql"
            self.logger.error(error_msg)
            raise ImportError(error_msg)
        
        # Ensure DataFrames are loaded
        self._load_dataframes_for_sql()
        
        formatted_query = self._format_sql_query(sql_query, **kwargs)
        
        try:
            self.logger.info("Executing raw SQL query")
            self.logger.debug(f"SQL: {formatted_query}")
            
            result = self.sqldf(formatted_query, self.dataframe_cache)
            
            self.logger.info(f"Raw SQL query returned {len(result)} rows")
            return result
            
        except Exception as e:
            self.logger.error(f"Error executing raw SQL: {str(e)}")
            raise

    def clear_cache(self, entity: Optional[str] = None) -> None:
        """
        Clear cached DataFrames.
        
        Args:
            entity: Optional specific entity to clear. If None, clears all cached DataFrames.
        """
        if entity:
            if entity in self.dataframe_cache:
                del self.dataframe_cache[entity]
                self.logger.info(f"Cleared cached DataFrame for entity: {entity}")
            else:
                self.logger.warning(f"No cached DataFrame found for entity: {entity}")
        else:
            self.dataframe_cache.clear()
            self.cache_loaded = False
            self.logger.info("Cleared all cached DataFrames")

    def get_cached_entities(self) -> List[str]:
        """
        Get list of currently cached entity names.
        
        Returns:
            List of cached entity names
        """
        return list(self.dataframe_cache.keys())

    def load_multiple_entities(self, entities: List[str], **kwargs) -> Dict[str, pd.DataFrame]:
        """
        Load multiple entities at once and cache them for potential SQL joins.
        
        Args:
            entities: List of entity names to load
            **kwargs: Parameters passed to load_data for each entity
            
        Returns:
            Dictionary mapping entity names to their DataFrames
        """
        self.logger.info(f"Loading multiple entities: {entities}")
        
        results = {}
        for entity in entities:
            try:
                results[entity] = self.load_data(entity, **kwargs)
                self.logger.info(f"Successfully loaded entity: {entity}")
            except Exception as e:
                self.logger.error(f"Failed to load entity '{entity}': {str(e)}")
                # Decide whether to continue or fail completely
                if kwargs.get('fail_on_missing', True):
                    raise
                else:
                    self.logger.warning(f"Skipping entity '{entity}' due to error")
        
        return results

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
        db_url = self.config.get('db_url')
        if not db_url:
            # Try to construct a default SQLite database path
            data_dir = self.config.get('data_dir', 'data')
            db_path = os.path.join(data_dir, 'production.db')
            db_url = f"sqlite:///{db_path}"
            
            self.logger.info(f"No database URL provided, using default: {db_url}")
        
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
                    # Remove leading/trailing quotes if present
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
