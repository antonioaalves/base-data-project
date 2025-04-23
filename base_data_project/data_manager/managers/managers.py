"""Data manager implementations for CSV and database sources."""

import os
import pandas as pd
import logging
from typing import Dict, Any, List, Optional, Union
from datetime import datetime
import importlib

# Import base data manager
from base_data_project.data_manager.managers.base import BaseDataManager

class CSVDataManager(BaseDataManager):
    """
    Data manager implementation for CSV data sources.
    
    Handles all operations related to reading from and writing to CSV files.
    """
    
    def connect(self) -> None:
        """
        'Connect' to CSV files - validates that the data directory exists.
        
        CSV doesn't have a persistent connection, but we validate paths.
        """
        # Check if filepath_map is available in config
        filepath_map = self.config.get('filepath_map', {})
        
        if not filepath_map:
            # Try to get from dummy_data_filepaths if filepath_map is not found
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
        
        # Verify that all the specified files exist if filepath_map is provided
        if filepath_map:
            missing_files = []
            for entity, path in filepath_map.items():
                if not os.path.exists(path):
                    missing_files.append(f"{entity}: {path}")
            
            if missing_files:
                self.logger.warning(f"The following data files do not exist: {', '.join(missing_files)}")
                
        self.logger.info(f"Connected to CSV data source with {len(filepath_map)} file paths configured")

    def disconnect(self) -> None:
        """
        No actual disconnection needed for CSV files.
        
        Included for interface consistency.
        """
        self.logger.info("Disconnected from CSV data source")

    def load_data(self, entity: str, **kwargs) -> pd.DataFrame:
        """
        Load data from a CSV file.
        
        Args:
            entity: Entity type determining the file to load
            **kwargs: Additional parameters including:
                - filepath: Optional explicit filepath
                - separator: CSV separator (default ',')
                - decimal: Decimal separator (default '.')
                - encoding: File encoding (default 'utf-8')
                
        Returns:
            DataFrame with loaded data
        """
        filepath = kwargs.get('filepath')

        if not filepath:
            # Try to get from filepath map
            filepath_map = self.config.get('filepath_map', {})
            if not filepath_map:
                filepath_map = self.config.get('dummy_data_filepaths', {})
                
            if entity in filepath_map:
                filepath = filepath_map[entity]
            else:
                # Try to construct a default path
                data_dir = self.config.get('data_dir', 'data')
                filepath = os.path.join(data_dir, 'csvs', f"{entity}.csv")

        # Get CSV reading parameters
        separator = kwargs.get('separator', ',')
        decimal = kwargs.get('decimal', '.')
        encoding = kwargs.get('encoding', 'utf-8')
        header = kwargs.get('header', 0)
        index_col = kwargs.get('index_col', None)
        parse_dates = kwargs.get('parse_dates', False)
        
        try:
            self.logger.info(f"Loading CSV data for entity {entity} from {filepath}")
            
            # Check if file exists
            if not os.path.exists(filepath):
                self.logger.warning(f"CSV file not found: {filepath}")
                return pd.DataFrame()
                
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
            return data
            
        except pd.errors.EmptyDataError:
            self.logger.warning(f"Empty CSV file: {filepath}")
            return pd.DataFrame()
            
        except Exception as e:
            self.logger.error(f"Error loading CSV data: {str(e)}")
            raise
        
    def save_data(self, entity: str, data: pd.DataFrame, **kwargs) -> None:
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
            from sqlalchemy import create_engine
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
            from sqlalchemy import Table, MetaData
        except ImportError:
            self.logger.error("SQLAlchemy is required for DBDataManager")
            raise ImportError("SQLAlchemy is required for DBDataManager")
        
        # Get query parameters
        model_class = kwargs.get('model_class')
        custom_query = kwargs.get('query')
        filters = kwargs.get('filters', {})
        limit = kwargs.get('limit')
        
        try:
            self.logger.info(f"Loading database data for entity '{entity}'")
            
            # Case 1: Custom query provided
            if custom_query is not None:
                result = self.session.execute(custom_query)
                data = pd.DataFrame(result.fetchall())
                if result.keys():
                    data.columns = result.keys()
                
                self.logger.info(f"Successfully loaded {len(data)} rows using custom query")
                return data
                
            # Case 2: Model class provided
            elif model_class is not None:
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
            self.logger.error(f"Error loading database data: {str(e)}")
            # Create an empty DataFrame with appropriate message
            data = pd.DataFrame()
            raise
        
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