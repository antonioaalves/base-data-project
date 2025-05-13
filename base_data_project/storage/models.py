from sqlalchemy import create_engine, Column, Integer, String, LargeBinary, DateTime, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import datetime

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