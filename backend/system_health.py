"""
System Health Dashboard - Deployment Hardening

Provides operational health metrics for early problem detection:
- Active Users
- Orders Created Today
- Dispatch Delays (> 2 hours)
- API Error Count
- Performance Metrics
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, timezone, timedelta
from decimal import Decimal
from pydantic import BaseModel

from database import get_db
from models import (
    Order, OrderItem, OrderStatus, OrderItemStatus, User, Department,
    SystemLog, SystemLogLevel, ActivityLog, DispatchEvent
)
from auth import get_admin_user

router = APIRouter(prefix="/system-health", tags=["System Health"])


# ============ SCHEMAS ============

class ActiveUserInfo(BaseModel):
    user_id: int
    name: str
    department: str
    last_activity: datetime
    activity_count: int


class DispatchDelayInfo(BaseModel):
    order_number: str
    item_name: str
    ordering_department: str
    dispatching_department: str
    hours_pending: float
    created_at: datetime


class DepartmentDelayStats(BaseModel):
    department_id: int
    department_name: str
    pending_items: int
    avg_delay_hours: float
    max_delay_hours: float


class SystemHealthResponse(BaseModel):
    timestamp: datetime
    active_users_today: int
    orders_created_today: int
    orders_completed_today: int
    orders_pending_dispatch: int
    orders_pending_dispatch_critical: int  # > 2 hours
    api_errors_today: int
    api_warnings_today: int
    avg_api_response_ms: float
    slow_requests_today: int
    activities_today: int


class DetailedHealthResponse(BaseModel):
    summary: SystemHealthResponse
    active_users: List[ActiveUserInfo]
    critical_delays: List[DispatchDelayInfo]
    department_delays: List[DepartmentDelayStats]
    recent_errors: List[dict]


# ============ API ENDPOINTS ============

@router.get("/summary", response_model=SystemHealthResponse)
async def get_health_summary(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get system health summary - Admin only"""
    today = datetime.now(timezone.utc).date()
    two_hours_ago = datetime.now(timezone.utc) - timedelta(hours=2)
    
    # Active users (users with activity today)
    active_users_result = await db.execute(
        select(func.count(func.distinct(ActivityLog.user_id))).where(
            func.date(ActivityLog.timestamp) == today
        )
    )
    active_users = active_users_result.scalar() or 0
    
    # Orders created today
    orders_created_result = await db.execute(
        select(func.count(Order.id)).where(
            func.date(Order.created_at) == today
        )
    )
    orders_created = orders_created_result.scalar() or 0
    
    # Orders completed today
    orders_completed_result = await db.execute(
        select(func.count(Order.id)).where(
            func.date(Order.completed_at) == today,
            Order.status == OrderStatus.COMPLETED
        )
    )
    orders_completed = orders_completed_result.scalar() or 0
    
    # Orders pending dispatch
    pending_dispatch_result = await db.execute(
        select(func.count(OrderItem.id)).where(
            OrderItem.status.in_([
                OrderItemStatus.PENDING_DISPATCH,
                OrderItemStatus.PARTIALLY_DISPATCHED
            ])
        )
    )
    pending_dispatch = pending_dispatch_result.scalar() or 0
    
    # Critical delays (> 2 hours)
    critical_result = await db.execute(
        select(func.count(OrderItem.id))
        .join(Order, OrderItem.order_id == Order.id)
        .where(
            OrderItem.status.in_([
                OrderItemStatus.PENDING_DISPATCH,
                OrderItemStatus.PARTIALLY_DISPATCHED
            ]),
            Order.created_at < two_hours_ago
        )
    )
    critical_delays = critical_result.scalar() or 0
    
    # API errors today
    errors_result = await db.execute(
        select(func.count(SystemLog.id)).where(
            func.date(SystemLog.timestamp) == today,
            SystemLog.level == SystemLogLevel.ERROR
        )
    )
    api_errors = errors_result.scalar() or 0
    
    # API warnings today
    warnings_result = await db.execute(
        select(func.count(SystemLog.id)).where(
            func.date(SystemLog.timestamp) == today,
            SystemLog.level == SystemLogLevel.WARNING
        )
    )
    api_warnings = warnings_result.scalar() or 0
    
    # Average API response time
    avg_response_result = await db.execute(
        select(func.avg(SystemLog.duration_ms)).where(
            func.date(SystemLog.timestamp) == today,
            SystemLog.duration_ms.isnot(None)
        )
    )
    avg_response = avg_response_result.scalar() or 0
    
    # Slow requests (> 500ms)
    slow_result = await db.execute(
        select(func.count(SystemLog.id)).where(
            func.date(SystemLog.timestamp) == today,
            SystemLog.duration_ms > 500
        )
    )
    slow_requests = slow_result.scalar() or 0
    
    # Total activities today
    activities_result = await db.execute(
        select(func.count(ActivityLog.id)).where(
            func.date(ActivityLog.timestamp) == today
        )
    )
    activities = activities_result.scalar() or 0
    
    return SystemHealthResponse(
        timestamp=datetime.now(timezone.utc),
        active_users_today=active_users,
        orders_created_today=orders_created,
        orders_completed_today=orders_completed,
        orders_pending_dispatch=pending_dispatch,
        orders_pending_dispatch_critical=critical_delays,
        api_errors_today=api_errors,
        api_warnings_today=api_warnings,
        avg_api_response_ms=float(avg_response),
        slow_requests_today=slow_requests,
        activities_today=activities
    )


@router.get("/detailed", response_model=DetailedHealthResponse)
async def get_detailed_health(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get detailed system health with breakdowns - Admin only"""
    today = datetime.now(timezone.utc).date()
    two_hours_ago = datetime.now(timezone.utc) - timedelta(hours=2)
    
    # Get summary first
    summary = await get_health_summary(db, admin)
    
    # Active users details
    active_users_result = await db.execute(
        select(
            User.id,
            User.name,
            Department.name.label('department'),
            func.max(ActivityLog.timestamp).label('last_activity'),
            func.count(ActivityLog.id).label('activity_count')
        )
        .join(ActivityLog, ActivityLog.user_id == User.id)
        .join(Department, User.primary_department_id == Department.id)
        .where(func.date(ActivityLog.timestamp) == today)
        .group_by(User.id, User.name, Department.name)
        .order_by(func.count(ActivityLog.id).desc())
        .limit(20)
    )
    active_users = [
        ActiveUserInfo(
            user_id=r.id,
            name=r.name,
            department=r.department,
            last_activity=r.last_activity,
            activity_count=r.activity_count
        ) for r in active_users_result.all()
    ]
    
    # Critical delays (> 2 hours pending dispatch)
    delays_result = await db.execute(
        select(
            Order.order_number,
            OrderItem.item_id,
            Order.created_at,
            Department.name.label('ordering_dept')
        )
        .select_from(OrderItem)
        .join(Order, OrderItem.order_id == Order.id)
        .join(Department, Order.ordering_department_id == Department.id)
        .where(
            OrderItem.status.in_([
                OrderItemStatus.PENDING_DISPATCH,
                OrderItemStatus.PARTIALLY_DISPATCHED
            ]),
            Order.created_at < two_hours_ago
        )
        .order_by(Order.created_at.asc())
        .limit(20)
    )
    
    critical_delays = []
    for r in delays_result.all():
        hours_pending = (datetime.now(timezone.utc) - r.created_at.replace(tzinfo=timezone.utc)).total_seconds() / 3600
        critical_delays.append(DispatchDelayInfo(
            order_number=r.order_number,
            item_name=f"Item #{r.item_id}",
            ordering_department=r.ordering_dept,
            dispatching_department="TBD",
            hours_pending=round(hours_pending, 1),
            created_at=r.created_at
        ))
    
    # Department delay stats
    dept_delays_result = await db.execute(
        select(
            Department.id,
            Department.name,
            func.count(OrderItem.id).label('pending_count'),
            func.avg(
                func.extract('epoch', func.now() - Order.created_at) / 3600
            ).label('avg_hours')
        )
        .select_from(OrderItem)
        .join(Order, OrderItem.order_id == Order.id)
        .join(Department, OrderItem.dispatching_department_id == Department.id)
        .where(
            OrderItem.status.in_([
                OrderItemStatus.PENDING_DISPATCH,
                OrderItemStatus.PARTIALLY_DISPATCHED
            ])
        )
        .group_by(Department.id, Department.name)
        .order_by(func.count(OrderItem.id).desc())
    )
    
    department_delays = [
        DepartmentDelayStats(
            department_id=r.id,
            department_name=r.name,
            pending_items=r.pending_count,
            avg_delay_hours=round(float(r.avg_hours or 0), 1),
            max_delay_hours=0  # Would need subquery
        ) for r in dept_delays_result.all()
    ]
    
    # Recent errors
    errors_result = await db.execute(
        select(SystemLog)
        .where(
            func.date(SystemLog.timestamp) == today,
            SystemLog.level.in_([SystemLogLevel.ERROR, SystemLogLevel.CRITICAL])
        )
        .order_by(SystemLog.timestamp.desc())
        .limit(10)
    )
    recent_errors = [
        {
            "id": e.id,
            "timestamp": e.timestamp.isoformat(),
            "level": e.level.value if hasattr(e.level, 'value') else str(e.level),
            "error_type": e.error_type,
            "endpoint": e.endpoint,
            "message": e.error_message[:200] if e.error_message else None
        } for e in errors_result.scalars().all()
    ]
    
    return DetailedHealthResponse(
        summary=summary,
        active_users=active_users,
        critical_delays=critical_delays,
        department_delays=department_delays,
        recent_errors=recent_errors
    )


@router.get("/performance-metrics")
async def get_performance_metrics(
    hours: int = 24,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get performance metrics for the last N hours - Admin only"""
    since = datetime.now(timezone.utc) - timedelta(hours=hours)
    
    # Response time distribution
    response_times = await db.execute(
        select(
            func.percentile_cont(0.5).within_group(SystemLog.duration_ms).label('p50'),
            func.percentile_cont(0.95).within_group(SystemLog.duration_ms).label('p95'),
            func.percentile_cont(0.99).within_group(SystemLog.duration_ms).label('p99'),
            func.avg(SystemLog.duration_ms).label('avg'),
            func.max(SystemLog.duration_ms).label('max'),
            func.count(SystemLog.id).label('total')
        )
        .where(
            SystemLog.timestamp >= since,
            SystemLog.duration_ms.isnot(None)
        )
    )
    
    row = response_times.one()
    
    # Requests per endpoint
    endpoint_stats = await db.execute(
        select(
            SystemLog.endpoint,
            func.count(SystemLog.id).label('count'),
            func.avg(SystemLog.duration_ms).label('avg_ms')
        )
        .where(
            SystemLog.timestamp >= since,
            SystemLog.endpoint.isnot(None)
        )
        .group_by(SystemLog.endpoint)
        .order_by(func.count(SystemLog.id).desc())
        .limit(20)
    )
    
    # Error rate
    total_requests = await db.execute(
        select(func.count(SystemLog.id)).where(SystemLog.timestamp >= since)
    )
    error_requests = await db.execute(
        select(func.count(SystemLog.id)).where(
            SystemLog.timestamp >= since,
            SystemLog.level.in_([SystemLogLevel.ERROR, SystemLogLevel.CRITICAL])
        )
    )
    
    total = total_requests.scalar() or 0
    errors = error_requests.scalar() or 0
    error_rate = (errors / total * 100) if total > 0 else 0
    
    return {
        "period_hours": hours,
        "response_times": {
            "p50_ms": float(row.p50 or 0),
            "p95_ms": float(row.p95 or 0),
            "p99_ms": float(row.p99 or 0),
            "avg_ms": float(row.avg or 0),
            "max_ms": float(row.max or 0),
            "total_tracked": row.total or 0
        },
        "error_rate_percent": round(error_rate, 2),
        "top_endpoints": [
            {
                "endpoint": e.endpoint,
                "requests": e.count,
                "avg_ms": round(float(e.avg_ms or 0), 1)
            } for e in endpoint_stats.all()
        ]
    }
