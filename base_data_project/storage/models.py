""""""

# Dependencies
from sqlalchemy import create_engine, Column, Integer, String, LargeBinary, DateTime, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from typing import Optional
import datetime
import logging

# Local stuff
from base_data_project.storage.containers import BaseDataContainer

# Create base class for models
Base = declarative_base()

# TODO: complete this implementations
# Define the intermediate data table
class IntermediateData(Base):
    __tablename__ = 'intermediate_data'
    
    id = Column(Integer, primary_key=True)
    storage_key = Column(Integer(255), unique=True, index=True)
    process_id = Column(Integer(255), index=True)
    scenario_id = Column(Integer())
    stage_name = Column(String(255), index=True)
    timestamp = Column(DateTime, default=datetime.datetime.now)
    storage_type = Column(String(50))  # 'inline' or 'reference'
    data_format = Column(String(50))  # 'dataframe', 'dict', etc.
    data = Column(LargeBinary)  # For binary data (pickled)
    data_reference = Column(String(255))  # For reference to external storage
    metadata = Column(Text)  # JSON string of metadata
    size_bytes = Column(Integer)


class BaseDataModel:
    """
    Base class for all data models in the framework.
    Data models are responsible for domain-specific data operations and use a data container for intermediate storage.
    """

    def __init__(self, data_container: Optional[BaseDataContainer] = None, project_name: str = 'base_data_project'):
        """
        Initialize the data model with a data container.
        
        Args:
            data_container: Storage container for intermediate results
            project_name: Project name for logging        
        """

        # Storage container
        self.data_container = data_container

        # Get logger
        self.logger = logging.getLogger(project_name)
        self.logger.info(f"Initialized {self.__class__.__name__}")