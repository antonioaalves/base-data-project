"""Base data model implementation."""

# Dependencies
from sqlalchemy import create_engine, Column, Integer, String, LargeBinary, DateTime, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from typing import Optional, Dict, Any
import datetime
import logging

# Local stuff
from base_data_project.storage.containers import BaseDataContainer
from base_data_project.log_config import get_logger

# Create base class for models
Base = declarative_base()

# TODO: complete this implementations
# Define the intermediate data table
class IntermediateData(Base):
    __tablename__ = 'intermediate_data'
    
    id = Column(Integer, primary_key=True)
    storage_key = Column(String(255), unique=True, index=True)
    process_id = Column(String(255), index=True)
    scenario_id = Column(Integer)
    stage_name = Column(String(255), index=True)
    timestamp = Column(DateTime, default=datetime.datetime.now)
    storage_type = Column(String(50))  # 'inline' or 'reference'
    data_format = Column(String(50))  # 'dataframe', 'dict', etc.
    data = Column(LargeBinary)  # For binary data (pickled)
    data_reference = Column(String(255))  # For reference to external storage
    metadata_json = Column(Text)  # JSON string of metadata (renamed from metadata)
    size_bytes = Column(Integer)


class BaseDataModel:
    """Base class for data models in the framework."""
    
    def __init__(self, data_container: Optional[BaseDataContainer] = None, project_name: str = 'base_data_project'):
        """
        Initialize the data model.
        
        Args:
            data_container: Optional data container to initialize with
            project_name: Project name for logging
        """
        self.project_name = project_name
        self.logger = get_logger(project_name)
        
        ## Create default data container with project name if none provided
        #if data_container is None:
        #    data_container = BaseDataContainer(project_name=project_name, config=config)
            
        self.data_container = data_container
        
        self.logger.info(f"Initialized {self.__class__.__name__} with project {project_name}")