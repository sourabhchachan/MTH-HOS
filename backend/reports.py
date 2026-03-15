"""
Admin Reports Engine - Operational and Financial Reports
"""
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, timezone, date, timedelta
from decimal import Decimal
from pydantic import BaseModel
import io
import json

from database import get_db
from models import (
    Order, OrderItem, DispatchEvent, Billing, BillingItem,
    Department, User, Patient, IPD, Item, Vendor, Asset,
    OrderStatus, OrderItemStatus, PatientWorkflowPhase
)
from auth import get_admin_user

router = APIRouter()


# Report Schemas
class DepartmentStats(BaseModel):
    department_id: int
    department_name: str
    orders_created: int
    orders_completed: int
    items_dispatched: int
    avg_dispatch_time_hours: Optional[float] = None


class DailyOrderStats(BaseModel):
    date: str
    orders_created: int
    orders_completed: int
    orders_cancelled: int
    total_items: int


class VendorSpendReport(BaseModel):
    vendor_id: int
    vendor_name: str
    total_items_supplied: int
    total_amount: Decimal


class PatientBillingReport(BaseModel):
    patient_id: int
    patient_uhid: str
    patient_name: str
    total_bills: int
    total_amount: Decimal
    paid_amount: Decimal
    pending_amount: Decimal


class InsightAlert(BaseModel):
    type: str
    severity: str  # LOW, MEDIUM, HIGH, CRITICAL
    title: str
    message: str
    data: Optional[dict] = None
    created_at: datetime


class AdminDashboardReport(BaseModel):
    total_orders_today: int
    total_orders_pending: int
    total_orders_completed_today: int
    total_billing_today: Decimal
    total_billing_pending: Decimal
    active_patients: int
    active_ipds: int
    department_stats: List[DepartmentStats]
    insights: List[InsightAlert]


# ============ OPERATIONAL REPORTS ============

@router.get("/reports/operational/orders")
async def get_orders_report(
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    department_id: Optional[int] = None,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get orders operational report"""
    if not from_date:
        from_date = date.today() - timedelta(days=30)
    if not to_date:
        to_date = date.today()
    
    query = select(Order).options(
        selectinload(Order.ordering_department),
        selectinload(Order.creator),
        selectinload(Order.patient)
    )
    
    query = query.where(
        and_(
            func.date(Order.created_at) >= from_date,
            func.date(Order.created_at) <= to_date
        )
    )
    
    if department_id:
        query = query.where(Order.ordering_department_id == department_id)
    if status:
        query = query.where(Order.status == status)
    
    query = query.order_by(Order.created_at.desc())
    result = await db.execute(query)
    orders = result.scalars().all()
    
    # Aggregate stats
    total = len(orders)
    by_status = {}
    by_department = {}
    by_priority = {"NORMAL": 0, "URGENT": 0}
    
    for order in orders:
        status_key = order.status.value if hasattr(order.status, 'value') else str(order.status)
        by_status[status_key] = by_status.get(status_key, 0) + 1
        
        dept_name = order.ordering_department.name if order.ordering_department else "Unknown"
        by_department[dept_name] = by_department.get(dept_name, 0) + 1
        
        priority_key = order.priority.value if hasattr(order.priority, 'value') else str(order.priority)
        by_priority[priority_key] = by_priority.get(priority_key, 0) + 1
    
    return {
        "period": {"from": str(from_date), "to": str(to_date)},
        "total_orders": total,
        "by_status": by_status,
        "by_department": by_department,
        "by_priority": by_priority,
        "orders": [
            {
                "id": o.id,
                "order_number": o.order_number,
                "status": o.status.value if hasattr(o.status, 'value') else str(o.status),
                "priority": o.priority.value if hasattr(o.priority, 'value') else str(o.priority),
                "department": o.ordering_department.name if o.ordering_department else None,
                "created_by": o.creator.name if o.creator else None,
                "patient": o.patient.name if o.patient else None,
                "created_at": o.created_at.isoformat() if o.created_at else None,
                "completed_at": o.completed_at.isoformat() if o.completed_at else None
            }
            for o in orders[:100]  # Limit to 100 for response size
        ]
    }


@router.get("/reports/operational/dispatch-performance")
async def get_dispatch_performance_report(
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get dispatch performance report by department"""
    if not from_date:
        from_date = date.today() - timedelta(days=30)
    if not to_date:
        to_date = date.today()
    
    # Get dispatch events with timing
    result = await db.execute(
        select(DispatchEvent, OrderItem, Order, Item)
        .join(OrderItem, DispatchEvent.order_item_id == OrderItem.id)
        .join(Order, OrderItem.order_id == Order.id)
        .join(Item, OrderItem.item_id == Item.id)
        .where(
            and_(
                func.date(DispatchEvent.dispatched_at) >= from_date,
                func.date(DispatchEvent.dispatched_at) <= to_date
            )
        )
    )
    
    dispatches = result.all()
    
    # Aggregate by dispatching department
    dept_stats = {}
    for dispatch, order_item, order, item in dispatches:
        dept_id = order_item.dispatching_department_id
        if dept_id not in dept_stats:
            dept_stats[dept_id] = {
                "total_dispatches": 0,
                "total_quantity": 0,
                "total_received": 0,
                "dispatch_times": []
            }
        
        dept_stats[dept_id]["total_dispatches"] += 1
        dept_stats[dept_id]["total_quantity"] += dispatch.quantity_dispatched
        if dispatch.received_at:
            dept_stats[dept_id]["total_received"] += dispatch.quantity_received or 0
            # Calculate dispatch to receive time
            if dispatch.dispatched_at and dispatch.received_at:
                time_diff = (dispatch.received_at - dispatch.dispatched_at).total_seconds() / 3600
                dept_stats[dept_id]["dispatch_times"].append(time_diff)
    
    # Get department names
    dept_result = await db.execute(select(Department))
    depts = {d.id: d.name for d in dept_result.scalars().all()}
    
    performance = []
    for dept_id, stats in dept_stats.items():
        avg_time = None
        if stats["dispatch_times"]:
            avg_time = sum(stats["dispatch_times"]) / len(stats["dispatch_times"])
        
        performance.append({
            "department_id": dept_id,
            "department_name": depts.get(dept_id, "Unknown"),
            "total_dispatches": stats["total_dispatches"],
            "total_quantity_dispatched": stats["total_quantity"],
            "total_quantity_received": stats["total_received"],
            "avg_dispatch_to_receive_hours": round(avg_time, 2) if avg_time else None
        })
    
    return {
        "period": {"from": str(from_date), "to": str(to_date)},
        "department_performance": sorted(performance, key=lambda x: x["total_dispatches"], reverse=True)
    }


@router.get("/reports/operational/pending-orders")
async def get_pending_orders_report(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get all pending orders with aging"""
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.ordering_department),
            selectinload(Order.items).selectinload(OrderItem.dispatching_department),
            selectinload(Order.patient)
        )
        .where(Order.status.in_([
            OrderStatus.CREATED,
            OrderStatus.PARTIALLY_DISPATCHED,
            OrderStatus.FULLY_DISPATCHED
        ]))
        .order_by(Order.priority.desc(), Order.created_at.asc())
    )
    orders = result.scalars().all()
    
    now = datetime.now(timezone.utc)
    pending_orders = []
    
    for order in orders:
        age_hours = (now - order.created_at).total_seconds() / 3600 if order.created_at else 0
        
        pending_items = []
        for item in order.items:
            if item.status not in [OrderItemStatus.RECEIVED, OrderItemStatus.CANCELLED]:
                pending_items.append({
                    "item_id": item.item_id,
                    "status": item.status.value if hasattr(item.status, 'value') else str(item.status),
                    "quantity_requested": item.quantity_requested,
                    "quantity_dispatched": item.quantity_dispatched,
                    "quantity_pending": item.quantity_requested - item.quantity_dispatched,
                    "dispatching_department": item.dispatching_department.name if item.dispatching_department else None
                })
        
        pending_orders.append({
            "order_id": order.id,
            "order_number": order.order_number,
            "status": order.status.value if hasattr(order.status, 'value') else str(order.status),
            "priority": order.priority.value if hasattr(order.priority, 'value') else str(order.priority),
            "age_hours": round(age_hours, 1),
            "ordering_department": order.ordering_department.name if order.ordering_department else None,
            "patient": order.patient.name if order.patient else None,
            "created_at": order.created_at.isoformat() if order.created_at else None,
            "pending_items": pending_items
        })
    
    return {
        "total_pending": len(pending_orders),
        "urgent_count": sum(1 for o in pending_orders if o["priority"] == "URGENT"),
        "orders": pending_orders
    }


# ============ FINANCIAL REPORTS ============

@router.get("/reports/financial/billing")
async def get_billing_report(
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get billing financial report"""
    if not from_date:
        from_date = date.today() - timedelta(days=30)
    if not to_date:
        to_date = date.today()
    
    result = await db.execute(
        select(Billing)
        .options(
            selectinload(Billing.order).selectinload(Order.patient),
            selectinload(Billing.order).selectinload(Order.ordering_department)
        )
        .where(
            and_(
                func.date(Billing.generated_at) >= from_date,
                func.date(Billing.generated_at) <= to_date
            )
        )
        .order_by(Billing.generated_at.desc())
    )
    billings = result.scalars().all()
    
    total_amount = sum(b.total_amount for b in billings)
    paid_amount = sum(b.paid_amount for b in billings)
    
    # By department
    by_department = {}
    for b in billings:
        dept_name = b.order.ordering_department.name if b.order and b.order.ordering_department else "Unknown"
        if dept_name not in by_department:
            by_department[dept_name] = {"count": 0, "amount": Decimal(0)}
        by_department[dept_name]["count"] += 1
        by_department[dept_name]["amount"] += b.total_amount
    
    return {
        "period": {"from": str(from_date), "to": str(to_date)},
        "total_bills": len(billings),
        "total_amount": float(total_amount),
        "paid_amount": float(paid_amount),
        "pending_amount": float(total_amount - paid_amount),
        "by_department": {k: {"count": v["count"], "amount": float(v["amount"])} for k, v in by_department.items()},
        "recent_bills": [
            {
                "id": b.id,
                "billing_number": b.billing_number,
                "patient": b.order.patient.name if b.order and b.order.patient else None,
                "amount": float(b.total_amount),
                "status": b.status.value if hasattr(b.status, 'value') else str(b.status),
                "generated_at": b.generated_at.isoformat() if b.generated_at else None
            }
            for b in billings[:50]
        ]
    }


@router.get("/reports/financial/patient-billing")
async def get_patient_billing_report(
    patient_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get patient-wise billing report"""
    query = select(Patient).options(selectinload(Patient.ipd_records))
    if patient_id:
        query = query.where(Patient.id == patient_id)
    
    result = await db.execute(query)
    patients = result.scalars().all()
    
    patient_reports = []
    for patient in patients:
        # Get billing for this patient
        billing_result = await db.execute(
            select(Billing).where(Billing.patient_id == patient.id)
        )
        billings = billing_result.scalars().all()
        
        if billings:
            total = sum(b.total_amount for b in billings)
            paid = sum(b.paid_amount for b in billings)
            
            patient_reports.append(PatientBillingReport(
                patient_id=patient.id,
                patient_uhid=patient.uhid,
                patient_name=patient.name,
                total_bills=len(billings),
                total_amount=total,
                paid_amount=paid,
                pending_amount=total - paid
            ))
    
    return sorted(patient_reports, key=lambda x: x.total_amount, reverse=True)


@router.get("/reports/financial/vendor-spend")
async def get_vendor_spend_report(
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get vendor spending report"""
    if not from_date:
        from_date = date.today() - timedelta(days=30)
    if not to_date:
        to_date = date.today()
    
    # Get billing items with vendor info
    result = await db.execute(
        select(BillingItem, Billing, Item)
        .join(Billing, BillingItem.billing_id == Billing.id)
        .join(Item, BillingItem.item_id == Item.id)
        .where(
            and_(
                func.date(Billing.generated_at) >= from_date,
                func.date(Billing.generated_at) <= to_date
            )
        )
    )
    
    items = result.all()
    
    # Aggregate by vendor
    vendor_spend = {}
    for billing_item, billing, item in items:
        vendor_id = item.vendor_id
        if vendor_id:
            if vendor_id not in vendor_spend:
                vendor_spend[vendor_id] = {"items": 0, "amount": Decimal(0)}
            vendor_spend[vendor_id]["items"] += billing_item.quantity_dispatched
            vendor_spend[vendor_id]["amount"] += billing_item.line_amount
    
    # Get vendor names
    vendor_result = await db.execute(select(Vendor))
    vendors = {v.id: v.name for v in vendor_result.scalars().all()}
    
    report = []
    for vendor_id, stats in vendor_spend.items():
        report.append(VendorSpendReport(
            vendor_id=vendor_id,
            vendor_name=vendors.get(vendor_id, "Unknown"),
            total_items_supplied=stats["items"],
            total_amount=stats["amount"]
        ))
    
    return {
        "period": {"from": str(from_date), "to": str(to_date)},
        "vendors": sorted(report, key=lambda x: x.total_amount, reverse=True)
    }


# ============ INSIGHT ENGINE ============

@router.get("/reports/insights")
async def get_operational_insights(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Generate operational insights and alerts"""
    insights = []
    now = datetime.now(timezone.utc)
    today = date.today()
    
    # 1. Check for dispatch delays (orders pending > 24 hours)
    delayed_result = await db.execute(
        select(func.count(Order.id))
        .where(
            and_(
                Order.status.in_([OrderStatus.CREATED, OrderStatus.PARTIALLY_DISPATCHED]),
                Order.created_at < now - timedelta(hours=24)
            )
        )
    )
    delayed_count = delayed_result.scalar() or 0
    if delayed_count > 0:
        insights.append(InsightAlert(
            type="DISPATCH_DELAY",
            severity="HIGH" if delayed_count > 10 else "MEDIUM",
            title="Dispatch Delays Detected",
            message=f"{delayed_count} orders pending for more than 24 hours",
            data={"count": delayed_count},
            created_at=now
        ))
    
    # 2. Check for excessive urgent orders
    urgent_result = await db.execute(
        select(func.count(Order.id))
        .where(
            and_(
                Order.priority == "URGENT",
                func.date(Order.created_at) == today
            )
        )
    )
    urgent_count = urgent_result.scalar() or 0
    total_today_result = await db.execute(
        select(func.count(Order.id))
        .where(func.date(Order.created_at) == today)
    )
    total_today = total_today_result.scalar() or 1
    
    urgent_ratio = urgent_count / total_today if total_today > 0 else 0
    if urgent_ratio > 0.3:  # More than 30% urgent
        insights.append(InsightAlert(
            type="EXCESSIVE_URGENT",
            severity="MEDIUM",
            title="High Urgent Order Ratio",
            message=f"{urgent_count} of {total_today} orders today are marked urgent ({int(urgent_ratio*100)}%)",
            data={"urgent": urgent_count, "total": total_today, "ratio": round(urgent_ratio, 2)},
            created_at=now
        ))
    
    # 3. Check for pending billing
    pending_billing_result = await db.execute(
        select(func.sum(Billing.total_amount - Billing.paid_amount))
        .where(Billing.status != "PAID")
    )
    pending_amount = pending_billing_result.scalar() or 0
    if pending_amount > 100000:  # More than 1 lakh pending
        insights.append(InsightAlert(
            type="PENDING_BILLING",
            severity="HIGH" if pending_amount > 500000 else "MEDIUM",
            title="High Pending Billing",
            message=f"Total pending billing amount: ₹{pending_amount:,.2f}",
            data={"amount": float(pending_amount)},
            created_at=now
        ))
    
    # 4. Check for items with low dispatch rate
    # (items ordered but not dispatched within reasonable time)
    
    return {
        "generated_at": now.isoformat(),
        "total_insights": len(insights),
        "insights": [i.model_dump() for i in insights]
    }


# ============ ADMIN DASHBOARD ============

@router.get("/reports/admin-dashboard", response_model=AdminDashboardReport)
async def get_admin_dashboard(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get comprehensive admin dashboard"""
    today = date.today()
    now = datetime.now(timezone.utc)
    
    # Orders today
    orders_today = await db.execute(
        select(func.count(Order.id))
        .where(func.date(Order.created_at) == today)
    )
    
    # Pending orders
    pending_orders = await db.execute(
        select(func.count(Order.id))
        .where(Order.status.in_([
            OrderStatus.CREATED,
            OrderStatus.PARTIALLY_DISPATCHED,
            OrderStatus.FULLY_DISPATCHED
        ]))
    )
    
    # Completed today
    completed_today = await db.execute(
        select(func.count(Order.id))
        .where(
            and_(
                Order.status == OrderStatus.COMPLETED,
                func.date(Order.completed_at) == today
            )
        )
    )
    
    # Billing today
    billing_today = await db.execute(
        select(func.sum(Billing.total_amount))
        .where(func.date(Billing.generated_at) == today)
    )
    
    # Pending billing
    pending_billing = await db.execute(
        select(func.sum(Billing.total_amount - Billing.paid_amount))
        .where(Billing.status != "PAID")
    )
    
    # Active patients
    active_patients = await db.execute(
        select(func.count(Patient.id))
    )
    
    # Active IPDs
    active_ipds = await db.execute(
        select(func.count(IPD.id))
        .where(IPD.status == "ACTIVE")
    )
    
    # Department stats
    dept_result = await db.execute(
        select(Department).where(Department.is_active == True)
    )
    departments = dept_result.scalars().all()
    
    dept_stats = []
    for dept in departments:
        orders_created = await db.execute(
            select(func.count(Order.id))
            .where(Order.ordering_department_id == dept.id)
        )
        orders_completed = await db.execute(
            select(func.count(Order.id))
            .where(
                and_(
                    Order.ordering_department_id == dept.id,
                    Order.status == OrderStatus.COMPLETED
                )
            )
        )
        items_dispatched = await db.execute(
            select(func.count(OrderItem.id))
            .where(
                and_(
                    OrderItem.dispatching_department_id == dept.id,
                    OrderItem.status.in_([
                        OrderItemStatus.FULLY_DISPATCHED,
                        OrderItemStatus.RECEIVED
                    ])
                )
            )
        )
        
        dept_stats.append(DepartmentStats(
            department_id=dept.id,
            department_name=dept.name,
            orders_created=orders_created.scalar() or 0,
            orders_completed=orders_completed.scalar() or 0,
            items_dispatched=items_dispatched.scalar() or 0
        ))
    
    # Get insights
    insights_response = await get_operational_insights(db, admin)
    insights = [InsightAlert(**i) for i in insights_response["insights"]]
    
    return AdminDashboardReport(
        total_orders_today=orders_today.scalar() or 0,
        total_orders_pending=pending_orders.scalar() or 0,
        total_orders_completed_today=completed_today.scalar() or 0,
        total_billing_today=billing_today.scalar() or Decimal(0),
        total_billing_pending=pending_billing.scalar() or Decimal(0),
        active_patients=active_patients.scalar() or 0,
        active_ipds=active_ipds.scalar() or 0,
        department_stats=dept_stats,
        insights=insights
    )


# ============ EXPORT ENDPOINTS ============

@router.get("/reports/export/orders")
async def export_orders_report(
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    format: str = "json",
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Export orders report as JSON or CSV"""
    report = await get_orders_report(from_date, to_date, None, None, db, admin)
    
    if format == "csv":
        # Generate CSV
        csv_data = "Order Number,Status,Priority,Department,Created By,Patient,Created At,Completed At\n"
        for order in report["orders"]:
            csv_data += f"{order['order_number']},{order['status']},{order['priority']},{order['department']},{order['created_by']},{order['patient']},{order['created_at']},{order['completed_at']}\n"
        
        return StreamingResponse(
            io.StringIO(csv_data),
            media_type="text/csv",
            headers={"Content-Disposition": f"attachment; filename=orders_report_{date.today()}.csv"}
        )
    
    return report


@router.get("/reports/export/billing")
async def export_billing_report(
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    format: str = "json",
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Export billing report as JSON or CSV"""
    report = await get_billing_report(from_date, to_date, db, admin)
    
    if format == "csv":
        csv_data = "Billing Number,Patient,Amount,Status,Generated At\n"
        for bill in report["recent_bills"]:
            csv_data += f"{bill['billing_number']},{bill['patient']},{bill['amount']},{bill['status']},{bill['generated_at']}\n"
        
        return StreamingResponse(
            io.StringIO(csv_data),
            media_type="text/csv",
            headers={"Content-Disposition": f"attachment; filename=billing_report_{date.today()}.csv"}
        )
    
    return report
