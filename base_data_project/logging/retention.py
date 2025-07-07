"""File retention management for automatic log cleanup."""

import os
import time
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any, List, Tuple
import threading
import schedule

from base_data_project.log_config import get_logger

def cleanup_old_logs(log_dir: str, retention_days: int, project_name: str = 'base_data_project') -> int:
    """
    Remove log files older than retention_days.
    
    Args:
        log_dir: Directory containing log files
        retention_days: Number of days to retain log files
        project_name: Project name for logging
        
    Returns:
        int: Number of files deleted
        
    Implementation:
        - Only delete .log files
        - Check file modification time
        - Log cleanup actions
        - Handle permission errors gracefully
    """
    logger = get_logger(project_name)
    
    if retention_days is None or retention_days <= 0:
        logger.debug(f"Log retention disabled (retention_days: {retention_days})")
        return 0
    
    if not os.path.exists(log_dir):
        logger.debug(f"Log directory does not exist: {log_dir}")
        return 0
    
    try:
        # Calculate cutoff time
        cutoff_time = time.time() - (retention_days * 24 * 60 * 60)
        cutoff_date = datetime.fromtimestamp(cutoff_time)
        
        logger.info(f"Starting log cleanup for files older than {retention_days} days (before {cutoff_date.strftime('%Y-%m-%d %H:%M:%S')})")
        
        deleted_count = 0
        error_count = 0
        total_size_deleted = 0
        
        # Scan log directory
        log_path = Path(log_dir)
        log_files = list(log_path.glob('*.log'))
        
        logger.debug(f"Found {len(log_files)} log files in {log_dir}")
        
        for log_file in log_files:
            try:
                # Get file modification time
                file_mtime = log_file.stat().st_mtime
                file_size = log_file.stat().st_size
                file_date = datetime.fromtimestamp(file_mtime)
                
                # Check if file is older than retention period
                if file_mtime < cutoff_time:
                    logger.debug(f"Deleting old log file: {log_file.name} (modified: {file_date.strftime('%Y-%m-%d %H:%M:%S')})")
                    
                    # Delete the file
                    log_file.unlink()
                    
                    deleted_count += 1
                    total_size_deleted += file_size
                    
                    logger.debug(f"Successfully deleted: {log_file.name}")
                else:
                    logger.debug(f"Keeping log file: {log_file.name} (modified: {file_date.strftime('%Y-%m-%d %H:%M:%S')})")
                    
            except PermissionError as e:
                logger.warning(f"Permission denied deleting {log_file.name}: {str(e)}")
                error_count += 1
                
            except OSError as e:
                logger.warning(f"OS error deleting {log_file.name}: {str(e)}")
                error_count += 1
                
            except Exception as e:
                logger.error(f"Unexpected error deleting {log_file.name}: {str(e)}")
                error_count += 1
        
        # Log summary
        if deleted_count > 0:
            size_mb = total_size_deleted / (1024 * 1024)
            logger.info(f"Log cleanup completed: {deleted_count} files deleted, {size_mb:.2f} MB freed")
        else:
            logger.info("Log cleanup completed: no old files found")
            
        if error_count > 0:
            logger.warning(f"Log cleanup had {error_count} errors")
        
        return deleted_count
        
    except Exception as e:
        logger.error(f"Error during log cleanup: {str(e)}")
        return 0

def get_log_file_stats(log_dir: str, project_name: str = 'base_data_project') -> Dict[str, Any]:
    """
    Get statistics about log files in the directory.
    
    Args:
        log_dir: Directory containing log files
        project_name: Project name for logging
        
    Returns:
        Dictionary with log file statistics
    """
    logger = get_logger(project_name)
    
    if not os.path.exists(log_dir):
        return {'error': f'Log directory does not exist: {log_dir}'}
    
    try:
        log_path = Path(log_dir)
        log_files = list(log_path.glob('*.log'))
        
        if not log_files:
            return {
                'total_files': 0,
                'total_size_bytes': 0,
                'total_size_mb': 0.0,
                'oldest_file': None,
                'newest_file': None,
                'files_by_age': {}
            }
        
        # Collect file information
        file_info = []
        total_size = 0
        
        for log_file in log_files:
            try:
                stat = log_file.stat()
                file_info.append({
                    'name': log_file.name,
                    'size': stat.st_size,
                    'mtime': stat.st_mtime,
                    'mtime_str': datetime.fromtimestamp(stat.st_mtime).strftime('%Y-%m-%d %H:%M:%S')
                })
                total_size += stat.st_size
                
            except Exception as e:
                logger.warning(f"Error reading file stats for {log_file.name}: {str(e)}")
                continue
        
        if not file_info:
            return {'error': 'No accessible log files found'}
        
        # Sort by modification time
        file_info.sort(key=lambda x: x['mtime'])
        
        # Calculate age distribution
        now = time.time()
        files_by_age = {
            'today': 0,
            'last_7_days': 0,
            'last_30_days': 0,
            'older': 0
        }
        
        for file in file_info:
            age_days = (now - file['mtime']) / (24 * 60 * 60)
            
            if age_days < 1:
                files_by_age['today'] += 1
            elif age_days < 7:
                files_by_age['last_7_days'] += 1
            elif age_days < 30:
                files_by_age['last_30_days'] += 1
            else:
                files_by_age['older'] += 1
        
        return {
            'total_files': len(file_info),
            'total_size_bytes': total_size,
            'total_size_mb': total_size / (1024 * 1024),
            'oldest_file': {
                'name': file_info[0]['name'],
                'date': file_info[0]['mtime_str']
            },
            'newest_file': {
                'name': file_info[-1]['name'],
                'date': file_info[-1]['mtime_str']
            },
            'files_by_age': files_by_age
        }
        
    except Exception as e:
        logger.error(f"Error getting log file stats: {str(e)}")
        return {'error': str(e)}

def schedule_retention_cleanup(config: Dict[str, Any], project_name: str = 'base_data_project') -> None:
    """
    Setup automatic cleanup based on environment.
    
    Args:
        config: Configuration dictionary
        project_name: Project name for logging
        
    Server environment: Schedule daily cleanup
    Local environment: Skip cleanup
    """
    logger = get_logger(project_name)
    
    logging_config = config.get('logging', {})
    environment = logging_config.get('environment', 'local')
    
    if environment != 'server':
        logger.info(f"Log retention cleanup disabled for {environment} environment")
        return
    
    retention_days = logging_config.get('retention_days_server')
    log_dir = logging_config.get('log_dir', 'logs')
    
    if retention_days is None or retention_days <= 0:
        logger.info("Log retention cleanup disabled (retention_days not set)")
        return
    
    def cleanup_job():
        """Background cleanup job"""
        try:
            deleted_count = cleanup_old_logs(log_dir, retention_days, project_name)
            logger.info(f"Scheduled cleanup completed: {deleted_count} files deleted")
        except Exception as e:
            logger.error(f"Scheduled cleanup failed: {str(e)}")
    
    # Schedule daily cleanup at 2 AM
    schedule.every().day.at("02:00").do(cleanup_job)
    
    logger.info(f"Scheduled daily log cleanup at 02:00 (retention: {retention_days} days)")
    
    # Run scheduler in background thread
    def run_scheduler():
        while True:
            schedule.run_pending()
            time.sleep(60)  # Check every minute
    
    scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
    scheduler_thread.start()
    
    logger.info("Log retention scheduler started in background")

def run_manual_cleanup(config: Dict[str, Any], project_name: str = 'base_data_project') -> Dict[str, Any]:
    """
    Run manual log cleanup and return results.
    
    Args:
        config: Configuration dictionary
        project_name: Project name for logging
        
    Returns:
        Dictionary with cleanup results
    """
    logger = get_logger(project_name)
    
    logging_config = config.get('logging', {})
    environment = logging_config.get('environment', 'local')
    
    # Determine retention days based on environment
    if environment == 'server':
        retention_days = logging_config.get('retention_days_server')
    else:
        retention_days = logging_config.get('retention_days_local')
    
    log_dir = logging_config.get('log_dir', 'logs')
    
    # Get stats before cleanup
    stats_before = get_log_file_stats(log_dir, project_name)
    
    # Run cleanup
    if retention_days and retention_days > 0:
        deleted_count = cleanup_old_logs(log_dir, retention_days, project_name)
    else:
        logger.info("Manual cleanup skipped: retention_days not configured")
        deleted_count = 0
    
    # Get stats after cleanup
    stats_after = get_log_file_stats(log_dir, project_name)
    
    # Calculate results
    size_freed_mb = 0
    if 'total_size_mb' in stats_before and 'total_size_mb' in stats_after:
        size_freed_mb = stats_before['total_size_mb'] - stats_after['total_size_mb']
    
    return {
        'deleted_count': deleted_count,
        'size_freed_mb': size_freed_mb,
        'retention_days': retention_days,
        'environment': environment,
        'stats_before': stats_before,
        'stats_after': stats_after
    }