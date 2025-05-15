# tests/integration/test_data_process_integration.py
import pytest
import pandas as pd
from base_data_project.data_manager.managers.managers import CSVDataManager
from base_data_project.process_management.manager import ProcessManager
from base_data_project.utils import create_components

class TestDataProcessIntegration:
    
    @pytest.fixture
    def integrated_components(self, mock_config, tmp_path, monkeypatch):
        """Create integrated data manager and process manager"""
        # Set up configuration with temporary directories
        test_config = mock_config.copy()
        test_config['data_dir'] = str(tmp_path / "data")
        test_config['output_dir'] = str(tmp_path / "output")
        
        # Create necessary directories
        (tmp_path / "data").mkdir(exist_ok=True)
        (tmp_path / "data" / "csvs").mkdir(exist_ok=True)
        (tmp_path / "output").mkdir(exist_ok=True)
        
        # Create sample data file
        sample_df = pd.DataFrame({
            'id': [1, 2, 3],
            'value': [10, 20, 30]
        })
        sample_file = tmp_path / "data" / "csvs" / "sample.csv"
        sample_df.to_csv(sample_file)
        
        # Set up filepaths in config
        test_config['dummy_data_filepaths'] = {
            'sample': str(sample_file)
        }
        
        # Mock the path-dependent functions
        monkeypatch.setattr('base_data_project.utils.create_components', 
                            lambda use_db, no_tracking, config: (
                                CSVDataManager(config),
                                ProcessManager({'config': config, 'version': '1.0.0'})
                            ))
        
        # Create components
        data_manager = CSVDataManager(test_config)
        process_manager = ProcessManager({'config': test_config, 'version': '1.0.0'})
        
        # Connect data manager
        data_manager.connect()
        
        return data_manager, process_manager
    
    def test_load_data_and_make_decisions(self, integrated_components):
        """Test loading data and making decisions based on it"""
        data_manager, process_manager = integrated_components
        
        # Load data
        data = data_manager.load_data('sample')
        assert not data.empty
        
        # Register a decision point
        process_manager.register_decision_point(
            stage=1,
            schema=dict,
            required=True,
            defaults={"threshold": 15}
        )
        
        # Make a decision based on data analysis
        mean_value = data['value'].mean()
        process_manager.make_decisions(1, {"mean_value": mean_value})
        
        # Verify the decision was recorded
        assert process_manager.current_decisions[1]["mean_value"] == 20
        
        # Clean up
        data_manager.disconnect()
    
    def test_data_processing_workflow(self, integrated_components):
        """Test a typical data processing workflow"""
        data_manager, process_manager = integrated_components
        
        # Stage 1: Load and filter data
        raw_data = data_manager.load_data('sample')
        
        # Register decision points
        process_manager.register_decision_point(
            stage=1,
            schema=dict,
            required=True,
            defaults={"min_value": 15}
        )
        
        # Make decision
        process_manager.make_decisions(1, {"min_value": 15})
        
        # Compute stage 1 results
        stage1_result = process_manager.get_stage_data(1)
        
        # Simulate stage computation
        filtered_data = raw_data[raw_data['value'] >= 
                                process_manager.current_decisions[1]["min_value"]]
        
        # Save processed data
        data_manager.save_data('filtered_sample', filtered_data)
        
        # Verify the data was processed correctly
        assert len(filtered_data) == 2  # Only values >= 15
        
        # Clean up
        data_manager.disconnect()