#!/usr/bin/env python3
"""Command-line interface for the Base Data Project framework."""

import os
import sys
import shutil
import logging
import argparse
from pathlib import Path
import pkg_resources
import jinja2

# Set up logger
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger('base-data-project')

def get_template_dir(template_name):
    """Get the path to a template directory."""
    template_path = pkg_resources.resource_filename('base_data_project', 
                                                  f'templates/{template_name}')
    if not os.path.exists(template_path):
        raise FileNotFoundError(f"Template '{template_name}' not found")
    return template_path

def list_templates():
    """List available project templates."""
    template_base_dir = pkg_resources.resource_filename('base_data_project', 'templates')
    templates = [d for d in os.listdir(template_base_dir) 
                if os.path.isdir(os.path.join(template_base_dir, d))]
    
    print("Available templates:")
    for template in templates:
        template_path = os.path.join(template_base_dir, template)
        readme_path = os.path.join(template_path, 'README.md')
        description = "No description available"
        
        if os.path.exists(readme_path):
            with open(readme_path, 'r') as f:
                first_line = f.readline().strip()
                if first_line.startswith('# '):
                    description = first_line[2:]
        
        print(f"  - {template}: {description}")

def init_project(project_name, template='base_project', custom_config=None):
    """Initialize a new project from a template."""
    if os.path.exists(project_name):
        logger.error(f"Directory '{project_name}' already exists")
        return False
    
    try:
        # Get template directory
        template_dir = get_template_dir(template)
        
        # Create project directory
        os.makedirs(project_name)
        
        # Copy template files
        for root, dirs, files in os.walk(template_dir):
            # Get relative path from template directory
            rel_path = os.path.relpath(root, template_dir)
            if rel_path == '.':
                rel_path = ''
            
            # Create subdirectories
            for dir_name in dirs:
                dir_path = os.path.join(project_name, rel_path, dir_name)
                os.makedirs(dir_path, exist_ok=True)
            
            # Copy files
            for file_name in files:
                # Skip __pycache__ and .pyc files
                if '__pycache__' in root or file_name.endswith('.pyc'):
                    continue
                
                # Check if it's a template file
                is_template = file_name.endswith('.jinja')
                src_file = os.path.join(root, file_name)
                
                # Remove .jinja extension for destination
                if is_template:
                    dest_file_name = file_name[:-6]  # Remove .jinja
                else:
                    dest_file_name = file_name
                
                dest_file = os.path.join(project_name, rel_path, dest_file_name)
                
                if is_template:
                    # Render template
                    with open(src_file, 'r') as f:
                        template_content = f.read()
                    
                    # Set up Jinja environment
                    env = jinja2.Environment(
                        loader=jinja2.FileSystemLoader(root)
                    )
                    template = env.from_string(template_content)
                    
                    # Render with context
                    context = {
                        'project_name': project_name,
                        'project_name_underscores': project_name.replace('-', '_'),
                        'custom_config': custom_config or {}
                    }
                    rendered_content = template.render(**context)
                    
                    # Write rendered content
                    with open(dest_file, 'w') as f:
                        f.write(rendered_content)
                else:
                    # Simple file copy
                    shutil.copy2(src_file, dest_file)
        
        # Create empty directories required for project
        os.makedirs(os.path.join(project_name, 'data', 'csvs'), exist_ok=True)
        os.makedirs(os.path.join(project_name, 'data', 'output'), exist_ok=True)
        os.makedirs(os.path.join(project_name, 'logs'), exist_ok=True)
        
        logger.info(f"Project '{project_name}' initialized successfully from template '{template}'")
        return True
    
    except Exception as e:
        logger.error(f"Error initializing project: {str(e)}")
        # Clean up on failure
        if os.path.exists(project_name):
            shutil.rmtree(project_name)
        return False

def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(description="Base Data Project framework CLI")
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # Init command
    init_parser = subparsers.add_parser('init', help='Initialize a new project')
    init_parser.add_argument('project_name', help='Name of the project to create')
    init_parser.add_argument('--template', '-t', default='base_project',
                            help='Template to use (default: base_project)')
    init_parser.add_argument('--config', '-c', help='Path to custom configuration file')
    
    # List templates command
    list_parser = subparsers.add_parser('list-templates', help='List available project templates')
    
    # Version command
    version_parser = subparsers.add_parser('version', help='Show version information')
    
    args = parser.parse_args()
    
    if args.command == 'init':
        custom_config = None
        if args.config:
            import yaml
            with open(args.config, 'r') as f:
                custom_config = yaml.safe_load(f)
        
        success = init_project(args.project_name, args.template, custom_config)
        sys.exit(0 if success else 1)
    
    elif args.command == 'list-templates':
        list_templates()
    
    elif args.command == 'version':
        from .__init__ import __version__
        print(f"Base Data Project framework v{__version__}")
    
    else:
        parser.print_help()

if __name__ == '__main__':
    main()