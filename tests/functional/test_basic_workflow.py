# tests/functional/test_basic_workflow.py
import pytest
import pandas as pd
import os
from base_data_project.data_manager.factory import DataManagerFactory
from base_data_project.process_management.manager import ProcessManager
from base_data_project.process_management.stage_handler import ProcessStageHandler
from base_data_project.algorithms.factory import AlgorithmFactory
from base_data_project.algorithms.examples.example_algorithm import ExampleAlgorithm

class TestBasicWorkflow:
    
    @pytest.fixture
    def workflow_setup(self, tmp_path):
        """Set up a complete workflow environment"""
        # Create configuration
        config = {
            'PROJECT_NAME': 'workflow_test',
            'data_dir': str(tmp_path / "data"),
            'output_dir': str(tmp_path / "output"),
            'log_dir': str(tmp_path / "logs"),
            'stages': {
                'data_loading': {
                    'sequence': 1,
                    'requires_previous': False
                },
                'data_processing': {
                    'sequence': 2,
                    'requires_previous': True
                },
                'data_analysis': {
                    'sequence': 3,
                    'requires_previous': True
                }
            }
        }
        
        # Create directories
        os.makedirs(tmp_path / "data", exist_ok=True)
        os.makedirs(tmp_path / "data" / "csvs", exist_ok=True)
        os.makedirs(tmp_path / "output", exist_ok=True)
        os.makedirs(tmp_path / "logs", exist_ok=True)
        
        # Create sample data file
        sample_df = pd.DataFrame({
            'id': [1, 2, 3, 4, 5],
            'value': [10, 20, 30, 40, 50],
            'category': ['A', 'B', 'A', 'C', 'B']
        })
        sample_file = tmp_path / "data" / "csvs" / "workflow_sample.csv"
        sample_df.to_csv(sample_file)
        
        # Update config with file path
        config['dummy_data_filepaths'] = {
            'workflow_sample': str(sample_file)
        }
        
        # Create data manager
        data_manager = DataManagerFactory.create_data_manager(
            data_source_type='csv',
            config=config
        )
        
        # Create process manager with core data
        process_manager = ProcessManager(
            core_data={"config": config, "version": "1.0.0"}
        )
        
        # Register decision points
        process_manager.register_decision_point(
            stage=1,
            schema=dict,
            required=True,
            defaults={"entity": "workflow_sample"}
        )
        
        process_manager.register_decision_point(
            stage=2,
            schema=dict,
            required=True,
            defaults={
                "filter_column": "value",
                "min_value": 25
            }
        )
        
        process_manager.register_decision_point(
            stage=3,
            schema=dict,
            required=True,
            defaults={
                "algorithm": "example",
                "threshold": 0.5
            }
        )
        
        # Create stage handler
        stage_handler = ProcessStageHandler(process_manager, config)
        
        # Register algorithm
        AlgorithmFactory.register_algorithm("example", ExampleAlgorithm)
        
        return {
            'config': config,
            'data_manager': data_manager,
            'process_manager': process_manager,
            'stage_handler': stage_handler,
            'temp_dir': tmp_path
        }
    
    def test_complete_workflow(self, workflow_setup):
        """Test a complete workflow from data loading to analysis"""
        setup = workflow_setup
        data_manager = setup['data_manager']
        process_manager = setup['process_manager']
        stage_handler = setup['stage_handler']
        
        # Connect to data source
        data_manager.connect()
        
        # Initialize process
        process_id = stage_handler.initialize_process(
            "Test Workflow", 
            "Testing the complete workflow"
        )
        
        # Stage 1: Data Loading
        stage_handler.start_stage("data_loading")
        
        # Make decision for stage 1
        process_manager.make_decisions(1, {"entity": "workflow_sample"})
        
        # Execute stage 1 logic
        entity = process_manager.current_decisions[1]["entity"]
        raw_data = data_manager.load_data(entity)
        
        # Complete stage 1
        stage_handler.complete_stage("data_loading", True, {"rows": len(raw_data)})
        
        # Stage 2: Data Processing
        stage_handler.start_stage("data_processing")
        
        # Make decision for stage 2
        process_manager.make_decisions(2, {
            "filter_column": "value",
            "min_value": 30
        })
        
        # Execute stage 2 logic
        filter_col = process_manager.current_decisions[2]["filter_column"]
        min_val = process_manager.current_decisions[2]["min_value"]
        
        filtered_data = raw_data[raw_data[filter_col] >= min_val]
        
        # Track progress
        stage_handler.track_progress("data_processing", 0.5, "Filtering data")
        
        # Save processed data
        output_path = data_manager.save_data('processed_workflow', filtered_data)
        
        # Complete stage 2
        stage_handler.complete_stage("data_processing", True, {
            "rows_before": len(raw_data),
            "rows_after": len(filtered_data),
            "output_path": output_path
        })
        
        # Stage 3: Data Analysis
        stage_handler.start_stage("data_analysis", "example")
        
        # Make decision for stage 3
        process_manager.make_decisions(3, {
            "algorithm": "example",
            "threshold": 0.7
        })
        
        # Execute stage 3 logic - use algorithm
        algorithm_name = process_manager.current_decisions[3]["algorithm"]
        algorithm_params = {"threshold": process_manager.current_decisions[3]["threshold"]}
        
        # Create algorithm
        algorithm = AlgorithmFactory.create_algorithm(
            algorithm_name,
            parameters=algorithm_params
        )
        
        # Convert DataFrame to algorithm input format
        algorithm_input = {
            "values": filtered_data["value"].tolist(),
            "metadata": {"source": entity}
        }
        
        # Track progress
        stage_handler.track_progress("data_analysis", 0.3, "Running algorithm")
        
        # Run algorithm
        algorithm_result = algorithm.run(data=algorithm_input)
        
        # Track progress
        stage_handler.track_progress("data_analysis", 0.8, "Analyzing results")
        
        # Complete stage 3
        stage_handler.complete_stage("data_analysis", True, algorithm_result)
        
        # Get summary
        summary = stage_handler.get_process_summary()
        
        # Verify workflow results
        assert summary["active_stage"] is None  # All stages completed
        assert len(summary["stages"]) == 3
        
        # Verify each stage status
        for stage_name in ["data_loading", "data_processing", "data_analysis"]:
            assert summary["stages"][stage_name]["status"] == "completed"
        
        # Verify filtered data has only values >= 30
        assert len(filtered_data) == 3  # IDs 3, 4, 5
        assert filtered_data["value"].min() >= 30
        
        # Clean up
        data_manager.disconnect()