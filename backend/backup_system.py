"""
Database Backup System - Deployment Hardening

Provides:
- Manual backup trigger from Admin settings
- Automated daily backups (via cron)
- 30-day retention policy
- Backup listing and download
"""
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional
from datetime import datetime, timezone, timedelta
from pathlib import Path
from pydantic import BaseModel
import subprocess
import os
import glob
import shutil

from database import get_db
from models import User, ActivityLog, ActivityLogAction, ActivityLogEntityType
from auth import get_admin_user
from logging_service import log_activity

router = APIRouter(prefix="/backups", tags=["Database Backups"])

# Backup configuration
BACKUP_DIR = Path("/app/backups")
BACKUP_RETENTION_DAYS = 30
DB_HOST = "127.0.0.1"
DB_PORT = "5432"
DB_NAME = "mth_hospital"
DB_USER = "mthuser"
DB_PASSWORD = "mthpass123"


# ============ SCHEMAS ============

class BackupInfo(BaseModel):
    filename: str
    size_bytes: int
    size_mb: float
    created_at: datetime
    age_days: float


class BackupResponse(BaseModel):
    success: bool
    filename: Optional[str] = None
    size_mb: Optional[float] = None
    duration_seconds: Optional[float] = None
    message: str


class BackupListResponse(BaseModel):
    total_backups: int
    total_size_mb: float
    oldest_backup: Optional[datetime] = None
    newest_backup: Optional[datetime] = None
    backups: List[BackupInfo]


# ============ HELPER FUNCTIONS ============

def ensure_backup_dir():
    """Ensure backup directory exists"""
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)


def get_backup_filename():
    """Generate backup filename with timestamp"""
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    return f"mth_hospital_backup_{timestamp}.sql"


def cleanup_old_backups():
    """Remove backups older than retention period"""
    cutoff_date = datetime.now(timezone.utc) - timedelta(days=BACKUP_RETENTION_DAYS)
    
    for backup_file in BACKUP_DIR.glob("mth_hospital_backup_*.sql"):
        try:
            # Parse timestamp from filename
            timestamp_str = backup_file.stem.replace("mth_hospital_backup_", "")
            file_date = datetime.strptime(timestamp_str, "%Y%m%d_%H%M%S")
            file_date = file_date.replace(tzinfo=timezone.utc)
            
            if file_date < cutoff_date:
                backup_file.unlink()
                print(f"Deleted old backup: {backup_file.name}")
        except Exception as e:
            print(f"Error processing backup file {backup_file}: {e}")


def perform_backup() -> tuple[bool, str, float, float]:
    """
    Perform PostgreSQL backup using pg_dump.
    Returns: (success, filename, size_mb, duration_seconds)
    """
    ensure_backup_dir()
    
    filename = get_backup_filename()
    filepath = BACKUP_DIR / filename
    
    start_time = datetime.now(timezone.utc)
    
    try:
        # Set password in environment
        env = os.environ.copy()
        env["PGPASSWORD"] = DB_PASSWORD
        
        # Run pg_dump
        result = subprocess.run(
            [
                "pg_dump",
                "-h", DB_HOST,
                "-p", DB_PORT,
                "-U", DB_USER,
                "-d", DB_NAME,
                "-F", "p",  # Plain text format
                "-f", str(filepath),
                "--no-owner",
                "--no-privileges"
            ],
            env=env,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )
        
        duration = (datetime.now(timezone.utc) - start_time).total_seconds()
        
        if result.returncode != 0:
            error_msg = result.stderr or "Unknown error"
            return False, error_msg, 0, duration
        
        # Get file size
        size_bytes = filepath.stat().st_size
        size_mb = size_bytes / (1024 * 1024)
        
        # Cleanup old backups
        cleanup_old_backups()
        
        return True, filename, size_mb, duration
        
    except subprocess.TimeoutExpired:
        return False, "Backup timed out after 5 minutes", 0, 300
    except Exception as e:
        duration = (datetime.now(timezone.utc) - start_time).total_seconds()
        return False, str(e), 0, duration


def list_backups() -> List[BackupInfo]:
    """List all available backups"""
    ensure_backup_dir()
    
    backups = []
    now = datetime.now(timezone.utc)
    
    for backup_file in sorted(BACKUP_DIR.glob("mth_hospital_backup_*.sql"), reverse=True):
        try:
            # Parse timestamp from filename
            timestamp_str = backup_file.stem.replace("mth_hospital_backup_", "")
            file_date = datetime.strptime(timestamp_str, "%Y%m%d_%H%M%S")
            file_date = file_date.replace(tzinfo=timezone.utc)
            
            size_bytes = backup_file.stat().st_size
            age_days = (now - file_date).days
            
            backups.append(BackupInfo(
                filename=backup_file.name,
                size_bytes=size_bytes,
                size_mb=round(size_bytes / (1024 * 1024), 2),
                created_at=file_date,
                age_days=age_days
            ))
        except Exception as e:
            print(f"Error parsing backup file {backup_file}: {e}")
    
    return backups


# ============ API ENDPOINTS ============

@router.post("/create", response_model=BackupResponse)
async def create_backup(
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Manually trigger database backup - Admin only.
    Backup is created immediately and stored in /app/backups/
    """
    success, result, size_mb, duration = perform_backup()
    
    if success:
        # Log activity
        await log_activity(
            db=db,
            action_type=ActivityLogAction.BACKUP_CREATED,
            entity_type=ActivityLogEntityType.SYSTEM,
            entity_identifier=result,
            details={"size_mb": size_mb, "duration_seconds": duration},
            user_id=admin.id
        )
        
        return BackupResponse(
            success=True,
            filename=result,
            size_mb=round(size_mb, 2),
            duration_seconds=round(duration, 2),
            message=f"Backup created successfully: {result}"
        )
    else:
        return BackupResponse(
            success=False,
            message=f"Backup failed: {result}"
        )


@router.get("/list", response_model=BackupListResponse)
async def list_all_backups(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """List all available backups - Admin only"""
    backups = list_backups()
    
    total_size = sum(b.size_bytes for b in backups)
    
    return BackupListResponse(
        total_backups=len(backups),
        total_size_mb=round(total_size / (1024 * 1024), 2),
        oldest_backup=backups[-1].created_at if backups else None,
        newest_backup=backups[0].created_at if backups else None,
        backups=backups
    )


@router.get("/download/{filename}")
async def download_backup(
    filename: str,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Download a specific backup file - Admin only"""
    # Validate filename (security check)
    if not filename.startswith("mth_hospital_backup_") or not filename.endswith(".sql"):
        raise HTTPException(status_code=400, detail="Invalid backup filename")
    
    filepath = BACKUP_DIR / filename
    
    if not filepath.exists():
        raise HTTPException(status_code=404, detail="Backup file not found")
    
    return FileResponse(
        path=str(filepath),
        filename=filename,
        media_type="application/sql"
    )


@router.delete("/{filename}")
async def delete_backup(
    filename: str,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Delete a specific backup file - Admin only"""
    # Validate filename (security check)
    if not filename.startswith("mth_hospital_backup_") or not filename.endswith(".sql"):
        raise HTTPException(status_code=400, detail="Invalid backup filename")
    
    filepath = BACKUP_DIR / filename
    
    if not filepath.exists():
        raise HTTPException(status_code=404, detail="Backup file not found")
    
    try:
        filepath.unlink()
        return {"message": f"Backup {filename} deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete backup: {e}")


@router.post("/cleanup")
async def cleanup_backups(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Manually trigger cleanup of old backups (> 30 days) - Admin only"""
    before_count = len(list_backups())
    cleanup_old_backups()
    after_count = len(list_backups())
    
    deleted = before_count - after_count
    
    return {
        "message": f"Cleanup complete. Deleted {deleted} old backups.",
        "backups_remaining": after_count
    }


@router.get("/status")
async def get_backup_status(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get backup system status - Admin only"""
    backups = list_backups()
    
    # Check if backup is recent (within last 24 hours)
    has_recent_backup = False
    last_backup_age_hours = None
    
    if backups:
        newest = backups[0]
        age_hours = (datetime.now(timezone.utc) - newest.created_at).total_seconds() / 3600
        last_backup_age_hours = round(age_hours, 1)
        has_recent_backup = age_hours < 24
    
    return {
        "backup_dir": str(BACKUP_DIR),
        "retention_days": BACKUP_RETENTION_DAYS,
        "total_backups": len(backups),
        "has_recent_backup": has_recent_backup,
        "last_backup_age_hours": last_backup_age_hours,
        "status": "HEALTHY" if has_recent_backup else "NEEDS_BACKUP"
    }
