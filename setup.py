from setuptools import setup, find_packages

setup(
    name="base-data-project",
    version="0.1.0",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "pandas>=1.3.0",
        "sqlalchemy>=1.4.0",
        "click>=8.0.0",
        "pulp>=2.5.0",
        "numpy>=1.21.0",
        "jinja2>=3.0.0",
        "pyyaml>=6.0",
    ],
    entry_points={
        "console_scripts": [
            "base-data-project=base_data_project.cli:main",
        ],
    },
)