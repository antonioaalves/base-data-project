# debug_test.py - Run this to isolate and fix the issue
from typing import Dict, Any, Tuple

def validate_config(config: Dict[str, Any], required_keys: Dict[str, Any]) -> Tuple[bool, Dict[str, str]]:
    """Copy of your current validate_config function"""
    errors = {}
    
    for key_path, expected_type in required_keys.items():
        keys = key_path.split('.')
        
        # This is the critical part - for flat keys, check differently
        if len(keys) == 1:
            # Simple flat key
            key = keys[0]
            if key not in config:
                errors[key_path] = f"Missing required key: {key_path}"
            else:
                value = config[key]
                # Check type
                if callable(expected_type):
                    if not expected_type(value):
                        errors[key_path] = f"Invalid value for key {key_path}: {value}"
                elif not isinstance(value, expected_type):
                    errors[key_path] = f"Expected {expected_type.__name__} for key {key_path}, got {type(value).__name__}"
            continue
            
        # For nested keys, use the existing approach
        value = config
        key_exists = True
        
        # Navigate to the nested key
        for key in keys:
            if isinstance(value, dict) and key in value:
                value = value[key]
            else:
                key_exists = False
                errors[key_path] = f"Missing required key: {key_path}"
                break
                
        # If the key exists, check its type
        if key_exists:
            if callable(expected_type) and not expected_type(value):
                errors[key_path] = f"Invalid value for key {key_path}: {value}"
            elif not callable(expected_type) and not isinstance(value, expected_type):
                errors[key_path] = f"Expected {expected_type.__name__} for key {key_path}, got {type(value).__name__}"
                
    return len(errors) == 0, errors

# Test function
def test_validate_config_debug():
    # Test with just the version field
    print("\n1. Testing with just 'version' field:")
    required_keys = {'version': str}
    invalid_config = {'version': 1.0}  # Wrong type
    
    is_valid, errors = validate_config(invalid_config, required_keys)
    print(f"Is valid: {is_valid}")
    print(f"Errors: {errors}")
    
    # Test with various configurations to pinpoint the issue
    print("\n2. Testing with flat key 'count' expecting int but got string:")
    required_keys = {'count': int}
    invalid_config = {'count': '42'}
    
    is_valid, errors = validate_config(invalid_config, required_keys)
    print(f"Is valid: {is_valid}")
    print(f"Errors: {errors}")
    
    # The exact test case that's failing
    print("\n3. Testing the exact test case that's failing:")
    full_required_keys = {
        'name': str,
        'version': str,
        'count': int,
        'nested.key': str,
        'validation_func': lambda x: x > 0
    }
    
    full_invalid_config = {
        'name': 'test',
        'version': 1.0,  # Wrong type
        'count': '42',  # Wrong type
        'nested': {'wrong_key': 'value'},  # Missing required nested key
        'validation_func': -5  # Fails validation function
    }
    
    is_valid, errors = validate_config(full_invalid_config, full_required_keys)
    print(f"Is valid: {is_valid}")
    print(f"Errors: {errors}")
    
    # With the test directly testing for version
    print("\n4. Testing directly for version:")
    print(f"Is version in config: {'version' in full_invalid_config}")
    print(f"Value of version: {full_invalid_config['version']}")
    print(f"Type of version: {type(full_invalid_config['version'])}")
    print(f"Is instance of str: {isinstance(full_invalid_config['version'], str)}")
    
    # This should test our fix 
    version_check = "version" in full_invalid_config and not isinstance(full_invalid_config["version"], str)
    print(f"Should version error be detected: {version_check}")

if __name__ == "__main__":
    test_validate_config_debug()