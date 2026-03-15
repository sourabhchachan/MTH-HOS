"""
Admin Operational Dashboards - Real-time operational views for hospital administrators
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_, case, desc
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, timezone, date, timedelta
from decimal import Decimal
from pydantic import BaseModel, ConfigDict
import io
import csv

from database import get_db
from models import (
    Order, OrderItem, DispatchEvent, Billing, BillingItem,
    Department, User, Patient, IPD, Item, Vendor,
    OrderStatus, OrderItemStatus, PatientWorkflowPhase, IPDStatus
)
from auth import get_admin_user

router = APIRouter()


# ============ SCHEMAS ============

class OrderMetrics(BaseModel):
    orders_created_today: int
    orders_pending_dispatch: int
    orders_partially_dispatched: int
    orders_awaiting_receipt: int
    orders_completed_today: int
    urgent_orders_pending: int


class PatientMetrics(BaseModel):
    active_ipd_patients: int
    patients_by_phase: dict


class DepartmentWorkloadItem(BaseModel):
    department_id: int
    department_name: str
    department_code: str
    orders_pending: int
    avg_dispatch_time_hours: Optional[float] = None


class MainDashboardResponse(BaseModel):
    order_metrics: OrderMetrics
    patient_metrics: PatientMetrics
    department_workload: List[DepartmentWorkloadItem]
    generated_at: datetime


class DeptWorkloadDetail(BaseModel):
    department_id: int
    department_name: str
    department_code: str
    total_orders_assigned: int
    pending_dispatch: int
    partially_dispatched: int
    completed_today: int
    avg_dispatch_time_hours: Optional[float] = None
    urgent_orders_handled: int


class PatientOrderSummary(BaseModel):
    order_id: int
    order_number: str
    order_type: str
    status: str
    priority: str
    items_count: int
    total_amount: Optional[Decimal] = None
    created_at: datetime
    completed_at: Optional[datetime] = None


class PatientDashboardItem(BaseModel):
    patient_id: int
    patient_uhid: str
    patient_name: str
    ipd_id: Optional[int] = None
    ipd_number: Optional[str] = None
    current_phase: Optional[str] = None
    admission_date: Optional[datetime] = None
    department_name: Optional[str] = None
    length_of_stay_days: Optional[int] = None
    total_orders: int
    total_billing: Decimal


class BillingSummaryResponse(BaseModel):
    total_billing_today: Decimal
    total_billing_this_month: Decimal
    billing_by_department: dict
    billing_by_item: List[dict]
    billing_by_consultant: List[dict]


# ============ MAIN ADMIN DASHBOARD ============

@router.get("/dashboards/main")
async def get_main_dashboard(
    date_filter: Optional[date] = Query(None, description="Filter by date"),
    department_id: Optional[int] = Query(None, description="Filter by department"),
    item_id: Optional[int] = Query(None, description="Filter by item"),
    patient_uhid: Optional[str] = Query(None, description="Filter by patient UHID"),
    ipd_id: Optional[int] = Query(None, description="Filter by IPD"),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Main Admin Dashboard with real-time operational metrics"""
    filter_date = date_filter or date.today()
    today_start = datetime.combine(filter_date, datetime.min.time()).replace(tzinfo=timezone.utc)
    today_end = datetime.combine(filter_date, datetime.max.time()).replace(tzinfo=timezone.utc)
    
    # Build base filter conditions
    order_filters = []
    if department_id:
        order_filters.append(Order.ordering_department_id == department_id)
    if patient_uhid:
        patient_result = await db.execute(select(Patient.id).where(Patient.uhid == patient_uhid))
        patient_row = patient_result.first()
        if patient_row:
            order_filters.append(Order.patient_id == patient_row[0])
    if ipd_id:
        order_filters.append(Order.ipd_id == ipd_id)
    
    # Orders Created Today
    orders_created_query = select(func.count(Order.id)).where(
        Order.created_at >= today_start,
        Order.created_at <= today_end
    )
    if order_filters:
        orders_created_query = orders_created_query.where(and_(*order_filters))
    orders_created_today = await db.scalar(orders_created_query) or 0
    
    # Orders Pending Dispatch
    pending_dispatch_query = select(func.count(Order.id)).where(
        Order.status == OrderStatus.CREATED
    )
    if order_filters:
        pending_dispatch_query = pending_dispatch_query.where(and_(*order_filters))
    orders_pending_dispatch = await db.scalar(pending_dispatch_query) or 0
    
    # Orders Partially Dispatched
    partial_query = select(func.count(Order.id)).where(
        Order.status == OrderStatus.PARTIALLY_DISPATCHED
    )
    if order_filters:
        partial_query = partial_query.where(and_(*order_filters))
    orders_partially_dispatched = await db.scalar(partial_query) or 0
    
    # Orders Awaiting Receipt (Fully Dispatched but not completed)
    awaiting_query = select(func.count(Order.id)).where(
        Order.status == OrderStatus.FULLY_DISPATCHED
    )
    if order_filters:
        awaiting_query = awaiting_query.where(and_(*order_filters))
    orders_awaiting_receipt = await db.scalar(awaiting_query) or 0
    
    # Orders Completed Today
    completed_query = select(func.count(Order.id)).where(
        Order.status == OrderStatus.COMPLETED,
        Order.completed_at >= today_start,
        Order.completed_at <= today_end
    )
    if order_filters:
        completed_query = completed_query.where(and_(*order_filters))
    orders_completed_today = await db.scalar(completed_query) or 0
    
    # Urgent Orders Pending
    urgent_query = select(func.count(Order.id)).where(
        Order.priority == "URGENT",
        Order.status.in_([OrderStatus.CREATED, OrderStatus.PARTIALLY_DISPATCHED, OrderStatus.FULLY_DISPATCHED])
    )
    if order_filters:
        urgent_query = urgent_query.where(and_(*order_filters))
    urgent_orders_pending = await db.scalar(urgent_query) or 0
    
    # Patient Metrics
    active_ipd_query = select(func.count(IPD.id)).where(IPD.status == IPDStatus.ACTIVE)
    active_ipd_patients = await db.scalar(active_ipd_query) or 0
    
    # Patients by Phase
    phase_query = await db.execute(
        select(IPD.current_phase, func.count(IPD.id))
        .where(IPD.status == IPDStatus.ACTIVE)
        .group_by(IPD.current_phase)
    )
    patients_by_phase = {}
    for row in phase_query.all():
        phase_name = row[0].value if hasattr(row[0], 'value') else str(row[0])
        patients_by_phase[phase_name] = row[1]
    
    # Department Workload - Orders pending per department
    dept_workload_query = await db.execute(
        select(
            Department.id,
            Department.name,
            Department.code,
            func.count(OrderItem.id).filter(
                OrderItem.status.in_([OrderItemStatus.PENDING_DISPATCH, OrderItemStatus.PARTIALLY_DISPATCHED])
            )
        )
        .join(OrderItem, OrderItem.dispatching_department_id == Department.id, isouter=True)
        .where(Department.is_active == True)
        .group_by(Department.id, Department.name, Department.code)
        .order_by(desc(func.count(OrderItem.id)))
    )
    
    department_workload = []
    for row in dept_workload_query.all():
        department_workload.append(DepartmentWorkloadItem(
            department_id=row[0],
            department_name=row[1],
            department_code=row[2],
            orders_pending=row[3] or 0,
            avg_dispatch_time_hours=None  # Will calculate separately if needed
        ))
    
    return {
        "order_metrics": {
            "orders_created_today": orders_created_today,
            "orders_pending_dispatch": orders_pending_dispatch,
            "orders_partially_dispatched": orders_partially_dispatched,
            "orders_awaiting_receipt": orders_awaiting_receipt,
            "orders_completed_today": orders_completed_today,
            "urgent_orders_pending": urgent_orders_pending
        },
        "patient_metrics": {
            "active_ipd_patients": active_ipd_patients,
            "patients_by_phase": patients_by_phase
        },
        "department_workload": [d.model_dump() for d in department_workload],
        "filters_applied": {
            "date": str(filter_date),
            "department_id": department_id,
            "item_id": item_id,
            "patient_uhid": patient_uhid,
            "ipd_id": ipd_id
        },
        "generated_at": datetime.now(timezone.utc).isoformat()
    }


# ============ DEPARTMENT WORKLOAD DASHBOARD ============

@router.get("/dashboards/department-workload")
async def get_department_workload_dashboard(
    department_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Department Workload Dashboard showing detailed metrics per department"""
    today = date.today()
    today_start = datetime.combine(today, datetime.min.time()).replace(tzinfo=timezone.utc)
    
    # Get departments
    dept_query = select(Department).where(Department.is_active == True)
    if department_id:
        dept_query = dept_query.where(Department.id == department_id)
    
    dept_result = await db.execute(dept_query)
    departments = dept_result.scalars().all()
    
    workload_data = []
    
    for dept in departments:
        # Total orders assigned (where this dept is the dispatching dept)
        total_assigned = await db.scalar(
            select(func.count(OrderItem.id)).where(
                OrderItem.dispatching_department_id == dept.id
            )
        ) or 0
        
        # Pending dispatch
        pending_dispatch = await db.scalar(
            select(func.count(OrderItem.id)).where(
                OrderItem.dispatching_department_id == dept.id,
                OrderItem.status == OrderItemStatus.PENDING_DISPATCH
            )
        ) or 0
        
        # Partially dispatched
        partially = await db.scalar(
            select(func.count(OrderItem.id)).where(
                OrderItem.dispatching_department_id == dept.id,
                OrderItem.status == OrderItemStatus.PARTIALLY_DISPATCHED
            )
        ) or 0
        
        # Completed today
        completed_items = await db.execute(
            select(OrderItem.id)
            .join(DispatchEvent, DispatchEvent.order_item_id == OrderItem.id)
            .where(
                OrderItem.dispatching_department_id == dept.id,
                OrderItem.status == OrderItemStatus.RECEIVED,
                DispatchEvent.received_at >= today_start
            )
        )
        completed_today = len(completed_items.all())
        
        # Average dispatch time (from order creation to dispatch)
        dispatch_times = await db.execute(
            select(
                func.extract('epoch', DispatchEvent.dispatched_at - Order.created_at) / 3600
            )
            .join(OrderItem, OrderItem.id == DispatchEvent.order_item_id)
            .join(Order, Order.id == OrderItem.order_id)
            .where(
                OrderItem.dispatching_department_id == dept.id,
                DispatchEvent.dispatched_at.isnot(None)
            )
            .limit(100)  # Sample last 100 for performance
        )
        times = [t[0] for t in dispatch_times.all() if t[0] is not None]
        avg_dispatch_time = round(sum(times) / len(times), 2) if times else None
        
        # Urgent orders handled today
        urgent_handled = await db.scalar(
            select(func.count(DispatchEvent.id))
            .join(OrderItem, OrderItem.id == DispatchEvent.order_item_id)
            .join(Order, Order.id == OrderItem.order_id)
            .where(
                OrderItem.dispatching_department_id == dept.id,
                Order.priority == "URGENT",
                DispatchEvent.dispatched_at >= today_start
            )
        ) or 0
        
        workload_data.append(DeptWorkloadDetail(
            department_id=dept.id,
            department_name=dept.name,
            department_code=dept.code,
            total_orders_assigned=total_assigned,
            pending_dispatch=pending_dispatch,
            partially_dispatched=partially,
            completed_today=completed_today,
            avg_dispatch_time_hours=avg_dispatch_time,
            urgent_orders_handled=urgent_handled
        ))
    
    return {
        "departments": [d.model_dump() for d in workload_data],
        "summary": {
            "total_departments": len(workload_data),
            "total_pending": sum(d.pending_dispatch for d in workload_data),
            "total_completed_today": sum(d.completed_today for d in workload_data)
        },
        "generated_at": datetime.now(timezone.utc).isoformat()
    }


# ============ PATIENT OPERATIONAL DASHBOARD ============

@router.get("/dashboards/patients")
async def get_patient_dashboard(
    status: Optional[str] = Query("ACTIVE", description="IPD status filter"),
    phase: Optional[str] = Query(None, description="Workflow phase filter"),
    search: Optional[str] = Query(None, description="Search by UHID or name"),
    skip: int = 0,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Patient Operational Dashboard showing active patients and their orders"""
    now = datetime.now(timezone.utc)
    
    # Build query for IPD records
    query = select(IPD).options(
        selectinload(IPD.patient),
        selectinload(IPD.current_department)
    )
    
    if status:
        query = query.where(IPD.status == status)
    if phase:
        query = query.where(IPD.current_phase == phase)
    if search:
        query = query.join(Patient).where(
            or_(
                Patient.uhid.ilike(f"%{search}%"),
                Patient.name.ilike(f"%{search}%")
            )
        )
    
    query = query.order_by(IPD.admission_date.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    ipd_records = result.scalars().all()
    
    patients_data = []
    
    for ipd in ipd_records:
        patient = ipd.patient
        
        # Get order count
        order_count = await db.scalar(
            select(func.count(Order.id)).where(Order.ipd_id == ipd.id)
        ) or 0
        
        # Get total billing
        total_billing = await db.scalar(
            select(func.sum(Billing.total_amount)).where(Billing.ipd_id == ipd.id)
        ) or Decimal(0)
        
        # Calculate length of stay
        los_days = None
        if ipd.admission_date:
            los_days = (now - ipd.admission_date).days
        
        patients_data.append(PatientDashboardItem(
            patient_id=patient.id,
            patient_uhid=patient.uhid,
            patient_name=patient.name,
            ipd_id=ipd.id,
            ipd_number=ipd.ipd_number,
            current_phase=ipd.current_phase.value if hasattr(ipd.current_phase, 'value') else str(ipd.current_phase),
            admission_date=ipd.admission_date,
            department_name=ipd.current_department.name if ipd.current_department else None,
            length_of_stay_days=los_days,
            total_orders=order_count,
            total_billing=total_billing
        ))
    
    # Summary stats
    total_active = await db.scalar(
        select(func.count(IPD.id)).where(IPD.status == IPDStatus.ACTIVE)
    ) or 0
    
    phase_counts = await db.execute(
        select(IPD.current_phase, func.count(IPD.id))
        .where(IPD.status == IPDStatus.ACTIVE)
        .group_by(IPD.current_phase)
    )
    phases = {row[0].value if hasattr(row[0], 'value') else str(row[0]): row[1] for row in phase_counts.all()}
    
    return {
        "patients": [p.model_dump() for p in patients_data],
        "summary": {
            "total_active_ipd": total_active,
            "patients_by_phase": phases,
            "total_returned": len(patients_data)
        },
        "generated_at": datetime.now(timezone.utc).isoformat()
    }


@router.get("/dashboards/patients/{ipd_id}/orders")
async def get_patient_orders(
    ipd_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get all operational orders linked to a specific IPD"""
    # Get IPD with patient
    ipd_result = await db.execute(
        select(IPD).options(selectinload(IPD.patient)).where(IPD.id == ipd_id)
    )
    ipd = ipd_result.scalar_one_or_none()
    
    if not ipd:
        raise HTTPException(status_code=404, detail="IPD not found")
    
    # Get orders
    orders_result = await db.execute(
        select(Order).options(
            selectinload(Order.items)
        ).where(Order.ipd_id == ipd_id).order_by(Order.created_at.desc())
    )
    orders = orders_result.scalars().all()
    
    # Get billing total
    total_billing = await db.scalar(
        select(func.sum(Billing.total_amount)).where(Billing.ipd_id == ipd_id)
    ) or Decimal(0)
    
    orders_data = []
    for order in orders:
        # Get billing for this order
        order_billing = await db.scalar(
            select(Billing.total_amount).where(Billing.order_id == order.id)
        )
        
        orders_data.append(PatientOrderSummary(
            order_id=order.id,
            order_number=order.order_number,
            order_type=order.order_type.value if hasattr(order.order_type, 'value') else str(order.order_type),
            status=order.status.value if hasattr(order.status, 'value') else str(order.status),
            priority=order.priority.value if hasattr(order.priority, 'value') else str(order.priority),
            items_count=len(order.items),
            total_amount=order_billing,
            created_at=order.created_at,
            completed_at=order.completed_at
        ))
    
    return {
        "patient": {
            "id": ipd.patient.id,
            "uhid": ipd.patient.uhid,
            "name": ipd.patient.name
        },
        "ipd": {
            "id": ipd.id,
            "ipd_number": ipd.ipd_number,
            "status": ipd.status.value if hasattr(ipd.status, 'value') else str(ipd.status),
            "current_phase": ipd.current_phase.value if hasattr(ipd.current_phase, 'value') else str(ipd.current_phase),
            "admission_date": ipd.admission_date.isoformat() if ipd.admission_date else None
        },
        "orders": [o.model_dump() for o in orders_data],
        "summary": {
            "total_orders": len(orders_data),
            "total_billing": float(total_billing),
            "orders_by_status": {}
        },
        "generated_at": datetime.now(timezone.utc).isoformat()
    }


# ============ BILLING SUMMARY DASHBOARD ============

@router.get("/dashboards/billing")
async def get_billing_dashboard(
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Billing Summary Dashboard with financial breakdown"""
    today = date.today()
    month_start = today.replace(day=1)
    
    if not from_date:
        from_date = month_start
    if not to_date:
        to_date = today
    
    from_dt = datetime.combine(from_date, datetime.min.time()).replace(tzinfo=timezone.utc)
    to_dt = datetime.combine(to_date, datetime.max.time()).replace(tzinfo=timezone.utc)
    today_start = datetime.combine(today, datetime.min.time()).replace(tzinfo=timezone.utc)
    month_start_dt = datetime.combine(month_start, datetime.min.time()).replace(tzinfo=timezone.utc)
    
    # Total billing today
    billing_today = await db.scalar(
        select(func.sum(Billing.total_amount)).where(
            Billing.generated_at >= today_start
        )
    ) or Decimal(0)
    
    # Total billing this month
    billing_month = await db.scalar(
        select(func.sum(Billing.total_amount)).where(
            Billing.generated_at >= month_start_dt
        )
    ) or Decimal(0)
    
    # Billing by department (ordering department)
    dept_billing = await db.execute(
        select(
            Department.name,
            func.sum(Billing.total_amount),
            func.count(Billing.id)
        )
        .join(Billing, Billing.ordering_department_id == Department.id)
        .where(Billing.generated_at >= from_dt, Billing.generated_at <= to_dt)
        .group_by(Department.name)
        .order_by(desc(func.sum(Billing.total_amount)))
    )
    billing_by_department = {}
    for row in dept_billing.all():
        billing_by_department[row[0]] = {
            "amount": float(row[1] or 0),
            "count": row[2]
        }
    
    # Billing by item (top 20)
    item_billing = await db.execute(
        select(
            BillingItem.item_name,
            func.sum(BillingItem.line_amount),
            func.sum(BillingItem.quantity_dispatched)
        )
        .join(Billing, Billing.id == BillingItem.billing_id)
        .where(Billing.generated_at >= from_dt, Billing.generated_at <= to_dt)
        .group_by(BillingItem.item_name)
        .order_by(desc(func.sum(BillingItem.line_amount)))
        .limit(20)
    )
    billing_by_item = []
    for row in item_billing.all():
        billing_by_item.append({
            "item_name": row[0],
            "amount": float(row[1] or 0),
            "quantity": row[2] or 0
        })
    
    # Billing by consultant (order creator)
    consultant_billing = await db.execute(
        select(
            User.name,
            User.designation,
            func.sum(Billing.total_amount),
            func.count(Billing.id)
        )
        .join(Billing, Billing.order_creator_id == User.id)
        .where(Billing.generated_at >= from_dt, Billing.generated_at <= to_dt)
        .group_by(User.id, User.name, User.designation)
        .order_by(desc(func.sum(Billing.total_amount)))
        .limit(20)
    )
    billing_by_consultant = []
    for row in consultant_billing.all():
        billing_by_consultant.append({
            "name": row[0],
            "designation": row[1] or "Staff",
            "amount": float(row[2] or 0),
            "orders_count": row[3]
        })
    
    # Paid vs Pending
    paid_amount = await db.scalar(
        select(func.sum(Billing.paid_amount)).where(
            Billing.generated_at >= from_dt,
            Billing.generated_at <= to_dt
        )
    ) or Decimal(0)
    
    total_in_period = await db.scalar(
        select(func.sum(Billing.total_amount)).where(
            Billing.generated_at >= from_dt,
            Billing.generated_at <= to_dt
        )
    ) or Decimal(0)
    
    return {
        "total_billing_today": float(billing_today),
        "total_billing_this_month": float(billing_month),
        "period": {
            "from": str(from_date),
            "to": str(to_date),
            "total_amount": float(total_in_period),
            "paid_amount": float(paid_amount),
            "pending_amount": float(total_in_period - paid_amount)
        },
        "billing_by_department": billing_by_department,
        "billing_by_item": billing_by_item,
        "billing_by_consultant": billing_by_consultant,
        "generated_at": datetime.now(timezone.utc).isoformat()
    }


# ============ EXPORT ENDPOINTS ============

@router.get("/dashboards/billing/export")
async def export_billing_dashboard(
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    format: str = Query("csv", description="Export format: csv or json"),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Export billing dashboard data as CSV or Excel-compatible format"""
    data = await get_billing_dashboard(from_date, to_date, db, admin)
    
    if format == "csv":
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Summary section
        writer.writerow(["BILLING SUMMARY REPORT"])
        writer.writerow(["Period", f"{data['period']['from']} to {data['period']['to']}"])
        writer.writerow([""])
        writer.writerow(["Metric", "Amount (₹)"])
        writer.writerow(["Total Billing Today", data['total_billing_today']])
        writer.writerow(["Total Billing This Month", data['total_billing_this_month']])
        writer.writerow(["Total (Period)", data['period']['total_amount']])
        writer.writerow(["Paid (Period)", data['period']['paid_amount']])
        writer.writerow(["Pending (Period)", data['period']['pending_amount']])
        writer.writerow([""])
        
        # By Department
        writer.writerow(["BILLING BY DEPARTMENT"])
        writer.writerow(["Department", "Amount (₹)", "Bills Count"])
        for dept, info in data['billing_by_department'].items():
            writer.writerow([dept, info['amount'], info['count']])
        writer.writerow([""])
        
        # By Item
        writer.writerow(["BILLING BY ITEM (Top 20)"])
        writer.writerow(["Item", "Amount (₹)", "Quantity"])
        for item in data['billing_by_item']:
            writer.writerow([item['item_name'], item['amount'], item['quantity']])
        writer.writerow([""])
        
        # By Consultant
        writer.writerow(["BILLING BY CONSULTANT"])
        writer.writerow(["Name", "Designation", "Amount (₹)", "Orders"])
        for cons in data['billing_by_consultant']:
            writer.writerow([cons['name'], cons['designation'], cons['amount'], cons['orders_count']])
        
        output.seek(0)
        return StreamingResponse(
            iter([output.getvalue()]),
            media_type="text/csv",
            headers={"Content-Disposition": f"attachment; filename=billing_report_{date.today()}.csv"}
        )
    
    return data


@router.get("/dashboards/department-workload/export")
async def export_department_workload(
    format: str = Query("csv", description="Export format: csv or json"),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Export department workload data"""
    data = await get_department_workload_dashboard(None, db, admin)
    
    if format == "csv":
        output = io.StringIO()
        writer = csv.writer(output)
        
        writer.writerow(["DEPARTMENT WORKLOAD REPORT"])
        writer.writerow(["Generated", datetime.now().strftime("%Y-%m-%d %H:%M")])
        writer.writerow([""])
        writer.writerow([
            "Department", "Code", "Total Assigned", "Pending", 
            "Partial", "Completed Today", "Avg Dispatch (hrs)", "Urgent Handled"
        ])
        
        for dept in data['departments']:
            writer.writerow([
                dept['department_name'],
                dept['department_code'],
                dept['total_orders_assigned'],
                dept['pending_dispatch'],
                dept['partially_dispatched'],
                dept['completed_today'],
                dept['avg_dispatch_time_hours'] or "N/A",
                dept['urgent_orders_handled']
            ])
        
        output.seek(0)
        return StreamingResponse(
            iter([output.getvalue()]),
            media_type="text/csv",
            headers={"Content-Disposition": f"attachment; filename=department_workload_{date.today()}.csv"}
        )
    
    return data


@router.get("/dashboards/patients/export")
async def export_patient_dashboard(
    status: Optional[str] = "ACTIVE",
    format: str = Query("csv", description="Export format: csv or json"),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Export patient dashboard data"""
    data = await get_patient_dashboard(status, None, None, 0, 1000, db, admin)
    
    if format == "csv":
        output = io.StringIO()
        writer = csv.writer(output)
        
        writer.writerow(["PATIENT OPERATIONAL REPORT"])
        writer.writerow(["Generated", datetime.now().strftime("%Y-%m-%d %H:%M")])
        writer.writerow(["Status Filter", status])
        writer.writerow([""])
        writer.writerow([
            "UHID", "Name", "IPD Number", "Phase", "Department",
            "Admission Date", "LOS (Days)", "Orders", "Billing (₹)"
        ])
        
        for patient in data['patients']:
            # Handle admission_date which can be datetime or string
            admission_date = patient['admission_date']
            if admission_date:
                if hasattr(admission_date, 'strftime'):
                    admission_date = admission_date.strftime('%Y-%m-%d')
                elif isinstance(admission_date, str) and len(admission_date) >= 10:
                    admission_date = admission_date[:10]
            else:
                admission_date = "N/A"
            
            writer.writerow([
                patient['patient_uhid'],
                patient['patient_name'],
                patient['ipd_number'] or "N/A",
                patient['current_phase'] or "N/A",
                patient['department_name'] or "N/A",
                admission_date,
                patient['length_of_stay_days'] or 0,
                patient['total_orders'],
                float(patient['total_billing'])
            ])
        
        output.seek(0)
        return StreamingResponse(
            iter([output.getvalue()]),
            media_type="text/csv",
            headers={"Content-Disposition": f"attachment; filename=patient_report_{date.today()}.csv"}
        )
    
    return data
