"""
Deployment Hardening - Logging Services

Provides centralized error logging and activity tracking for:
- API failures
- Database errors
- Authentication failures
- Order processing errors
- Billing failures
- Major system actions
"""
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, timezone, date, timedelta
from decimal import Decimal
from pydantic import BaseModel, ConfigDict
from enum import Enum
import traceback
import json

from database import get_db
from models import (
    SystemLog, SystemLogLevel, ActivityLog, ActivityLogAction, 
    ActivityLogEntityType, User
)
from auth import get_current_user, get_admin_user

router = APIRouter()


# ============ SCHEMAS ============

class SystemLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    timestamp: datetime
    level: str
    user_id: Optional[int] = None
    user_name: Optional[str] = None
    endpoint: Optional[str] = None
    method: Optional[str] = None
    error_type: Optional[str] = None
    error_message: Optional[str] = None
    stack_trace: Optional[str] = None
    response_status: Optional[int] = None
    ip_address: Optional[str] = None
    duration_ms: Optional[int] = None


class ActivityLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    timestamp: datetime
    user_id: Optional[int] = None
    user_name: Optional[str] = None
    action_type: str
    entity_type: str
    entity_id: Optional[int] = None
    entity_identifier: Optional[str] = None
    details: Optional[dict] = None
    ip_address: Optional[str] = None


class SystemLogStats(BaseModel):
    total_errors_today: int
    errors_by_type: dict
    errors_by_level: dict
    top_error_endpoints: List[dict]


class ActivityLogStats(BaseModel):
    total_activities_today: int
    activities_by_action: dict
    activities_by_entity: dict
    most_active_users: List[dict]


# ============ LOGGING HELPER FUNCTIONS ============

async def log_system_error(
    db: AsyncSession,
    error_type: str,
    error_message: str,
    endpoint: str = None,
    method: str = None,
    user_id: int = None,
    stack_trace: str = None,
    request_body: str = None,
    response_status: int = None,
    ip_address: str = None,
    user_agent: str = None,
    duration_ms: int = None,
    level: SystemLogLevel = SystemLogLevel.ERROR
):
    """Log a system error to the database"""
    try:
        log_entry = SystemLog(
            level=level,
            user_id=user_id,
            endpoint=endpoint,
            method=method,
            error_type=error_type,
            error_message=error_message[:2000] if error_message else None,
            stack_trace=stack_trace[:5000] if stack_trace else None,
            request_body=request_body[:2000] if request_body else None,
            response_status=response_status,
            ip_address=ip_address,
            user_agent=user_agent[:500] if user_agent else None,
            duration_ms=duration_ms
        )
        db.add(log_entry)
        await db.commit()
        return log_entry
    except Exception as e:
        # Don't fail if logging fails - just print to console
        print(f"Failed to log system error: {e}")
        return None


async def log_activity(
    db: AsyncSession,
    action_type: ActivityLogAction,
    entity_type: ActivityLogEntityType,
    entity_id: int = None,
    entity_identifier: str = None,
    details: dict = None,
    user_id: int = None,
    ip_address: str = None
):
    """Log a system activity to the database"""
    try:
        log_entry = ActivityLog(
            user_id=user_id,
            action_type=action_type,
            entity_type=entity_type,
            entity_id=entity_id,
            entity_identifier=entity_identifier,
            details=details,
            ip_address=ip_address
        )
        db.add(log_entry)
        await db.commit()
        return log_entry
    except Exception as e:
        # Don't fail if logging fails - just print to console
        print(f"Failed to log activity: {e}")
        return None


def get_client_ip(request: Request) -> str:
    """Extract client IP from request"""
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


# ============ SYSTEM LOGS API ENDPOINTS ============

@router.get("/system-logs", response_model=List[SystemLogResponse])
async def list_system_logs(
    skip: int = 0,
    limit: int = 100,
    level: Optional[str] = None,
    error_type: Optional[str] = None,
    endpoint: Optional[str] = None,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """List system logs with filtering - Admin only"""
    query = select(SystemLog).options(selectinload(SystemLog.user))
    
    if level:
        query = query.where(SystemLog.level == level)
    if error_type:
        query = query.where(SystemLog.error_type == error_type)
    if endpoint:
        query = query.where(SystemLog.endpoint.ilike(f"%{endpoint}%"))
    if from_date:
        query = query.where(func.date(SystemLog.timestamp) >= from_date)
    if to_date:
        query = query.where(func.date(SystemLog.timestamp) <= to_date)
    
    query = query.order_by(SystemLog.timestamp.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    logs = result.scalars().all()
    
    return [
        SystemLogResponse(
            id=log.id,
            timestamp=log.timestamp,
            level=log.level.value if hasattr(log.level, 'value') else str(log.level),
            user_id=log.user_id,
            user_name=log.user.name if log.user else None,
            endpoint=log.endpoint,
            method=log.method,
            error_type=log.error_type,
            error_message=log.error_message,
            stack_trace=log.stack_trace,
            response_status=log.response_status,
            ip_address=log.ip_address,
            duration_ms=log.duration_ms
        ) for log in logs
    ]


@router.get("/system-logs/stats", response_model=SystemLogStats)
async def get_system_log_stats(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get system log statistics for today - Admin only"""
    today = datetime.now(timezone.utc).date()
    
    # Total errors today
    total_result = await db.execute(
        select(func.count(SystemLog.id)).where(
            func.date(SystemLog.timestamp) == today
        )
    )
    total_errors = total_result.scalar() or 0
    
    # Errors by type
    type_result = await db.execute(
        select(SystemLog.error_type, func.count(SystemLog.id))
        .where(func.date(SystemLog.timestamp) == today)
        .group_by(SystemLog.error_type)
    )
    errors_by_type = {t or "UNKNOWN": c for t, c in type_result.all()}
    
    # Errors by level
    level_result = await db.execute(
        select(SystemLog.level, func.count(SystemLog.id))
        .where(func.date(SystemLog.timestamp) == today)
        .group_by(SystemLog.level)
    )
    errors_by_level = {
        (l.value if hasattr(l, 'value') else str(l)): c 
        for l, c in level_result.all()
    }
    
    # Top error endpoints
    endpoint_result = await db.execute(
        select(SystemLog.endpoint, func.count(SystemLog.id).label('count'))
        .where(
            func.date(SystemLog.timestamp) == today,
            SystemLog.endpoint.isnot(None)
        )
        .group_by(SystemLog.endpoint)
        .order_by(func.count(SystemLog.id).desc())
        .limit(10)
    )
    top_endpoints = [
        {"endpoint": e, "count": c} for e, c in endpoint_result.all()
    ]
    
    return SystemLogStats(
        total_errors_today=total_errors,
        errors_by_type=errors_by_type,
        errors_by_level=errors_by_level,
        top_error_endpoints=top_endpoints
    )


@router.get("/system-logs/{log_id}", response_model=SystemLogResponse)
async def get_system_log_detail(
    log_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get detailed system log entry - Admin only"""
    result = await db.execute(
        select(SystemLog).options(selectinload(SystemLog.user))
        .where(SystemLog.id == log_id)
    )
    log = result.scalar_one_or_none()
    
    if not log:
        raise HTTPException(status_code=404, detail="Log entry not found")
    
    return SystemLogResponse(
        id=log.id,
        timestamp=log.timestamp,
        level=log.level.value if hasattr(log.level, 'value') else str(log.level),
        user_id=log.user_id,
        user_name=log.user.name if log.user else None,
        endpoint=log.endpoint,
        method=log.method,
        error_type=log.error_type,
        error_message=log.error_message,
        stack_trace=log.stack_trace,
        response_status=log.response_status,
        ip_address=log.ip_address,
        duration_ms=log.duration_ms
    )


# ============ ACTIVITY LOGS API ENDPOINTS ============

@router.get("/activity-logs", response_model=List[ActivityLogResponse])
async def list_activity_logs(
    skip: int = 0,
    limit: int = 100,
    action_type: Optional[str] = None,
    entity_type: Optional[str] = None,
    user_id: Optional[int] = None,
    entity_id: Optional[int] = None,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """List activity logs with filtering - Admin only"""
    query = select(ActivityLog).options(selectinload(ActivityLog.user))
    
    if action_type:
        query = query.where(ActivityLog.action_type == action_type)
    if entity_type:
        query = query.where(ActivityLog.entity_type == entity_type)
    if user_id:
        query = query.where(ActivityLog.user_id == user_id)
    if entity_id:
        query = query.where(ActivityLog.entity_id == entity_id)
    if from_date:
        query = query.where(func.date(ActivityLog.timestamp) >= from_date)
    if to_date:
        query = query.where(func.date(ActivityLog.timestamp) <= to_date)
    
    query = query.order_by(ActivityLog.timestamp.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    logs = result.scalars().all()
    
    return [
        ActivityLogResponse(
            id=log.id,
            timestamp=log.timestamp,
            user_id=log.user_id,
            user_name=log.user.name if log.user else None,
            action_type=log.action_type.value if hasattr(log.action_type, 'value') else str(log.action_type),
            entity_type=log.entity_type.value if hasattr(log.entity_type, 'value') else str(log.entity_type),
            entity_id=log.entity_id,
            entity_identifier=log.entity_identifier,
            details=log.details,
            ip_address=log.ip_address
        ) for log in logs
    ]


@router.get("/activity-logs/stats", response_model=ActivityLogStats)
async def get_activity_log_stats(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get activity log statistics for today - Admin only"""
    today = datetime.now(timezone.utc).date()
    
    # Total activities today
    total_result = await db.execute(
        select(func.count(ActivityLog.id)).where(
            func.date(ActivityLog.timestamp) == today
        )
    )
    total_activities = total_result.scalar() or 0
    
    # Activities by action
    action_result = await db.execute(
        select(ActivityLog.action_type, func.count(ActivityLog.id))
        .where(func.date(ActivityLog.timestamp) == today)
        .group_by(ActivityLog.action_type)
    )
    activities_by_action = {
        (a.value if hasattr(a, 'value') else str(a)): c 
        for a, c in action_result.all()
    }
    
    # Activities by entity
    entity_result = await db.execute(
        select(ActivityLog.entity_type, func.count(ActivityLog.id))
        .where(func.date(ActivityLog.timestamp) == today)
        .group_by(ActivityLog.entity_type)
    )
    activities_by_entity = {
        (e.value if hasattr(e, 'value') else str(e)): c 
        for e, c in entity_result.all()
    }
    
    # Most active users
    user_result = await db.execute(
        select(User.name, func.count(ActivityLog.id).label('count'))
        .join(User, ActivityLog.user_id == User.id)
        .where(func.date(ActivityLog.timestamp) == today)
        .group_by(User.name)
        .order_by(func.count(ActivityLog.id).desc())
        .limit(10)
    )
    most_active = [
        {"user": name, "count": c} for name, c in user_result.all()
    ]
    
    return ActivityLogStats(
        total_activities_today=total_activities,
        activities_by_action=activities_by_action,
        activities_by_entity=activities_by_entity,
        most_active_users=most_active
    )


# ============ ERROR TYPES FOR CATEGORIZATION ============

ERROR_TYPES = {
    "API": "API",
    "DATABASE": "DATABASE", 
    "AUTH": "AUTH",
    "ORDER": "ORDER",
    "BILLING": "BILLING",
    "DISPATCH": "DISPATCH",
    "RETURN": "RETURN",
    "VALIDATION": "VALIDATION",
    "INTEGRATION": "INTEGRATION",
    "SYSTEM": "SYSTEM"
}
