# tests/unit/test_storage.py
import pytest
import pandas as pd
import os
import json
from base_data_project.storage.containers import (
    MemoryDataContainer, 
    CSVDataContainer
)

class TestMemoryDataContainer:
    
    @pytest.fixture
    def memory_container(self):
        """Create a memory data container"""
        config = {
            'project_name': 'test_project',
            'cleanup_policy': 'keep_latest'
        }
        return MemoryDataContainer(config)
    
    @pytest.fixture
    def sample_data(self):
        """Create sample data for testing"""
        return {
            'simple': pd.DataFrame({'a': [1, 2, 3], 'b': [4, 5, 6]}),
            'nested': {
                'level1': {
                    'data': [1, 2, 3]
                }
            }
        }
    
    def test_store_and_retrieve(self, memory_container, sample_data):
        """Test storing and retrieving data"""
        # Store data
        key = memory_container.store_stage_data(
            'test_stage', 
            sample_data['simple'],
            {'process_id': 'test_process'}
        )
        
        # Retrieve data
        retrieved = memory_container.retrieve_stage_data('test_stage', 'test_process')
        
        # Verify data was properly stored and retrieved
        pd.testing.assert_frame_equal(sample_data['simple'], retrieved)
    
    def test_list_available_data(self, memory_container, sample_data):
        """Test listing available data"""
        # Store multiple data items
        key1 = memory_container.store_stage_data(
            'stage1', 
            sample_data['simple'],
            {'process_id': 'process1'}
        )
        
        key2 = memory_container.store_stage_data(
            'stage2', 
            sample_data['nested'],
            {'process_id': 'process1'}
        )
        
        key3 = memory_container.store_stage_data(
            'stage1', 
            sample_data['simple'],
            {'process_id': 'process2'}
        )
        
        # List all data
        all_data = memory_container.list_available_data()
        assert len(all_data) == 3
        
        # List with filters
        stage1_data = memory_container.list_available_data({'stage_name': 'stage1'})
        assert len(stage1_data) == 2
        
        process1_data = memory_container.list_available_data({'process_id': 'process1'})
        assert len(process1_data) == 2
        
        specific_data = memory_container.list_available_data({
            'stage_name': 'stage1',
            'process_id': 'process1'
        })
        assert len(specific_data) == 1
    
    def test_cleanup(self, memory_container, sample_data):
        """Test cleanup policies"""
        # Store multiple versions of the same stage data
        memory_container.store_stage_data(
            'stage1', 
            sample_data['simple'],
            {'process_id': 'process1'}
        )
        
        memory_container.store_stage_data(
            'stage1', 
            sample_data['nested'],
            {'process_id': 'process1'}
        )
        
        # Store data for different stage
        memory_container.store_stage_data(
            'stage2', 
            sample_data['simple'],
            {'process_id': 'process1'}
        )
        
        # Verify we have multiple items
        all_data_before = memory_container.list_available_data()
        assert len(all_data_before) == 3
        
        # Run cleanup with keep_latest policy
        memory_container.cleanup('keep_latest')
        
        # Verify only the latest for each stage+process combination remains
        all_data_after = memory_container.list_available_data()
        assert len(all_data_after) == 2
        
        # Try keep_none policy
        memory_container.cleanup('keep_none')
        
        # Verify all data is gone
        all_data_final = memory_container.list_available_data()
        assert len(all_data_final) == 0

class TestCSVDataContainer:
    
    @pytest.fixture
    def csv_container(self, tmp_path):
        """Create a CSV data container with temp directory"""
        config = {
            'project_name': 'test_project',
            'cleanup_policy': 'keep_latest',
            'storage_dir': str(tmp_path / "storage")
        }
        return CSVDataContainer(config)
    
    @pytest.fixture
    def sample_dataframe(self):
        """Create a sample DataFrame for testing"""
        return pd.DataFrame({'a': [1, 2, 3], 'b': [4, 5, 6]})
    
    def test_store_and_retrieve_dataframe(self, csv_container, sample_dataframe, tmp_path):
        """Test storing and retrieving a DataFrame as CSV"""
        # Store DataFrame
        key = csv_container.store_stage_data(
            'test_stage', 
            sample_dataframe,
            {'process_id': 'test_process'}
        )
        
        # Verify files were created
        storage_dir = tmp_path / "storage" / "test_process"
        assert os.path.exists(storage_dir)
        
        # Metadata file should exist
        metadata_file = os.path.join(storage_dir, f"{key}_metadata.json")
        assert os.path.exists(metadata_file)
        
        # Check metadata content
        with open(metadata_file, 'r') as f:
            metadata = json.load(f)
        
        assert metadata['stage_name'] == 'test_stage'
        assert metadata['process_id'] == 'test_process'
        assert metadata['file_type'] == 'dataframe'
        
        # Retrieve data
        retrieved = csv_container.retrieve_stage_data('test_stage', 'test_process')
        
        # Convert column types to match (CSV serialization can change types)
        for col in retrieved.columns:
            retrieved[col] = retrieved[col].astype(sample_dataframe[col].dtype)
        
        # Verify data matches
        pd.testing.assert_frame_equal(
            sample_dataframe.reset_index(drop=True), 
            retrieved.reset_index(drop=True)
        )