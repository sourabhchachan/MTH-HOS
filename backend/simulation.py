"""
Operational Simulation Module - Simulate hospital workday scenarios
Allows admins to run and verify complete operational workflows
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_, delete
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, timezone, date, timedelta
from pydantic import BaseModel
from decimal import Decimal
import random

from database import get_db
from models import (
    Department, User, Vendor, Item, ItemOrderingDepartment,
    Patient, IPD, Order, OrderItem, DispatchEvent,
    Asset, AssetMaintenance, Billing, BillingItem,
    OrderType, OrderStatus, OrderItemStatus, PatientWorkflowPhase,
    PriorityRequirement, PatientIPDRequirement, IPDStatusAllowed,
    AssetStatus, BillingStatus, IPDStatus
)
from auth import get_admin_user

router = APIRouter(prefix="/simulation", tags=["Operational Simulation"])


# ============ SCHEMAS ============

class SimulationMetrics(BaseModel):
    orders_created_today: int
    orders_dispatched_today: int
    orders_pending: int
    orders_completed_today: int
    urgent_orders_pending: int
    patients_admitted_today: int
    billing_generated_today: float
    department_workload: dict


class ScenarioResult(BaseModel):
    success: bool
    scenario: str
    steps_completed: List[dict]
    errors: List[str]
    created_entities: dict


class SimulationSummary(BaseModel):
    metrics: SimulationMetrics
    recent_orders: List[dict]
    recent_dispatches: List[dict]
    pending_by_department: dict


# ============ METRICS ENDPOINT ============

@router.get("/metrics", response_model=SimulationMetrics)
async def get_simulation_metrics(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get real-time operational metrics"""
    today = date.today()
    today_start = datetime.combine(today, datetime.min.time()).replace(tzinfo=timezone.utc)
    
    # Orders created today
    orders_today = await db.scalar(
        select(func.count()).select_from(Order).where(
            Order.created_at >= today_start
        )
    )
    
    # Orders dispatched today (by dispatch events)
    dispatches_today = await db.scalar(
        select(func.count()).select_from(DispatchEvent).where(
            DispatchEvent.dispatched_at >= today_start
        )
    )
    
    # Orders pending (not completed/cancelled)
    orders_pending = await db.scalar(
        select(func.count()).select_from(Order).where(
            Order.status.in_([OrderStatus.CREATED, OrderStatus.PARTIALLY_DISPATCHED, OrderStatus.FULLY_DISPATCHED])
        )
    )
    
    # Orders completed today
    orders_completed = await db.scalar(
        select(func.count()).select_from(Order).where(
            and_(
                Order.status == OrderStatus.COMPLETED,
                Order.completed_at >= today_start
            )
        )
    )
    
    # Urgent orders pending
    urgent_pending = await db.scalar(
        select(func.count()).select_from(Order).where(
            and_(
                Order.priority == 'URGENT',
                Order.status.in_([OrderStatus.CREATED, OrderStatus.PARTIALLY_DISPATCHED])
            )
        )
    )
    
    # Patients admitted today
    patients_today = await db.scalar(
        select(func.count()).select_from(IPD).where(
            IPD.admission_date == today
        )
    )
    
    # Billing generated today
    billing_today = await db.scalar(
        select(func.coalesce(func.sum(Billing.total_amount), 0)).where(
            Billing.generated_at >= today_start
        )
    )
    
    # Department workload (pending dispatch items by dispatching department)
    dept_workload_query = await db.execute(
        select(
            Department.name,
            func.count(OrderItem.id)
        ).join(
            Item, Item.dispatching_department_id == Department.id
        ).join(
            OrderItem, OrderItem.item_id == Item.id
        ).where(
            OrderItem.status.in_([OrderItemStatus.PENDING_DISPATCH, OrderItemStatus.PARTIALLY_DISPATCHED])
        ).group_by(Department.name)
    )
    dept_workload = {row[0]: row[1] for row in dept_workload_query.all()}
    
    return SimulationMetrics(
        orders_created_today=orders_today or 0,
        orders_dispatched_today=dispatches_today or 0,
        orders_pending=orders_pending or 0,
        orders_completed_today=orders_completed or 0,
        urgent_orders_pending=urgent_pending or 0,
        patients_admitted_today=patients_today or 0,
        billing_generated_today=float(billing_today or 0),
        department_workload=dept_workload
    )


# ============ SIMULATION SUMMARY ============

@router.get("/summary", response_model=SimulationSummary)
async def get_simulation_summary(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get comprehensive simulation summary"""
    metrics = await get_simulation_metrics(db=db, admin=admin)
    
    # Recent orders
    recent_orders_result = await db.execute(
        select(Order).options(
            selectinload(Order.patient),
            selectinload(Order.ordering_department)
        ).order_by(Order.created_at.desc()).limit(10)
    )
    recent_orders = [
        {
            "id": o.id,
            "order_number": o.order_number,
            "patient_name": o.patient.name if o.patient else "N/A",
            "department": o.ordering_department.name if o.ordering_department else "N/A",
            "status": o.status.value,
            "priority": o.priority,
            "created_at": o.created_at.isoformat() if o.created_at else None
        }
        for o in recent_orders_result.scalars().all()
    ]
    
    # Recent dispatches
    recent_dispatch_result = await db.execute(
        select(DispatchEvent).options(
            selectinload(DispatchEvent.order_item).selectinload(OrderItem.item),
            selectinload(DispatchEvent.dispatcher)
        ).order_by(DispatchEvent.dispatched_at.desc()).limit(10)
    )
    recent_dispatches = [
        {
            "id": d.id,
            "item_name": d.order_item.item.name if d.order_item and d.order_item.item else "N/A",
            "quantity": d.quantity_dispatched,
            "dispatcher": d.dispatcher.name if d.dispatcher else "N/A",
            "dispatched_at": d.dispatched_at.isoformat() if d.dispatched_at else None,
            "received": d.received_at is not None
        }
        for d in recent_dispatch_result.scalars().all()
    ]
    
    return SimulationSummary(
        metrics=metrics,
        recent_orders=recent_orders,
        recent_dispatches=recent_dispatches,
        pending_by_department=metrics.department_workload
    )


# ============ SCENARIO 1: PATIENT ADMISSION FLOW ============

@router.post("/scenario/patient-admission", response_model=ScenarioResult)
async def run_patient_admission_scenario(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Simulate Patient Admission Flow:
    1. Create patient
    2. Create Admission Order
    3. Generate IPD
    4. Move patient to Admission phase
    """
    steps = []
    errors = []
    created = {}
    
    try:
        # Step 1: Create Patient
        uhid = f"SIM-{datetime.now().strftime('%H%M%S')}"
        patient = Patient(
            uhid=uhid,
            name=f"Simulation Patient {random.randint(100, 999)}",
            phone=f"98{random.randint(10000000, 99999999)}",
            gender=random.choice(["Male", "Female"]),
            created_by=admin.id
        )
        db.add(patient)
        await db.flush()
        created["patient_id"] = patient.id
        created["patient_uhid"] = patient.uhid
        steps.append({"step": 1, "action": "Create Patient", "status": "success", "data": {"uhid": uhid, "name": patient.name}})
        
        # Step 2: Get admission department (Ward)
        ward_dept = await db.execute(select(Department).where(Department.code == "WARD"))
        ward = ward_dept.scalar_one_or_none()
        if not ward:
            ward_dept = await db.execute(select(Department).where(Department.is_active == True).limit(1))
            ward = ward_dept.scalar_one()
        
        # Step 3: Create IPD record
        ipd_number = f"IPD-{datetime.now().strftime('%Y%m%d')}-{random.randint(100, 999)}"
        ipd = IPD(
            patient_id=patient.id,
            ipd_number=ipd_number,
            admission_date=datetime.now(timezone.utc),
            admitting_department_id=ward.id,
            current_department_id=ward.id,
            current_phase=PatientWorkflowPhase.ADMISSION,
            status=IPDStatus.ACTIVE,
            created_by=admin.id
        )
        db.add(ipd)
        await db.flush()
        created["ipd_id"] = ipd.id
        created["ipd_number"] = ipd.ipd_number
        steps.append({"step": 2, "action": "Create IPD", "status": "success", "data": {"ipd_number": ipd_number}})
        
        # Step 4: Create Admission Order
        order_number = f"ORD-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        order = Order(
            order_number=order_number,
            order_type=OrderType.REGULAR,
            patient_id=patient.id,
            ipd_id=ipd.id,
            ordering_department_id=ward.id,
            priority="NORMAL",
            status=OrderStatus.CREATED,
            created_by=admin.id
        )
        db.add(order)
        await db.flush()
        created["order_id"] = order.id
        created["order_number"] = order.order_number
        steps.append({"step": 3, "action": "Create Admission Order", "status": "success", "data": {"order_number": order_number}})
        
        # Step 5: Transition patient to IPD phase
        ipd.current_phase = PatientWorkflowPhase.IPD
        steps.append({"step": 4, "action": "Transition to IPD Phase", "status": "success", "data": {"phase": "IPD"}})
        
        await db.commit()
        
    except Exception as e:
        errors.append(str(e))
        await db.rollback()
    
    return ScenarioResult(
        success=len(errors) == 0,
        scenario="Patient Admission Flow",
        steps_completed=steps,
        errors=errors,
        created_entities=created
    )


# ============ SCENARIO 2: CLINICAL ORDER FLOW (LAB) ============

@router.post("/scenario/clinical-order", response_model=ScenarioResult)
async def run_clinical_order_scenario(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Simulate Clinical Order Flow (Lab Test):
    1. Get existing patient with IPD
    2. Create Lab Order
    3. Route to Laboratory
    4. Dispatch test
    5. Receive result
    6. Complete order
    7. Generate billing
    """
    steps = []
    errors = []
    created = {}
    
    try:
        # Step 1: Get or create patient with IPD
        patient_result = await db.execute(
            select(Patient).join(IPD).where(IPD.status == IPDStatus.ACTIVE).limit(1)
        )
        patient = patient_result.scalar_one_or_none()
        
        if not patient:
            # Create new patient and IPD
            patient = Patient(
                uhid=f"SIM-LAB-{datetime.now().strftime('%H%M%S')}",
                name=f"Lab Test Patient {random.randint(100, 999)}",
                created_by=admin.id
            )
            db.add(patient)
            await db.flush()
            
            ward = (await db.execute(select(Department).where(Department.code == "WARD"))).scalar_one_or_none()
            if not ward:
                ward = (await db.execute(select(Department).limit(1))).scalar_one()
            
            ipd = IPD(
                patient_id=patient.id,
                ipd_number=f"IPD-LAB-{random.randint(1000, 9999)}",
                admission_date=datetime.now(timezone.utc),
                admitting_department_id=ward.id,
                current_department_id=ward.id,
                current_phase=PatientWorkflowPhase.IPD,
                status=IPDStatus.ACTIVE,
                created_by=admin.id
            )
            db.add(ipd)
            await db.flush()
        else:
            ipd_result = await db.execute(
                select(IPD).where(and_(IPD.patient_id == patient.id, IPD.status == IPDStatus.ACTIVE))
            )
            ipd = ipd_result.scalar_one()
        
        created["patient_id"] = patient.id
        steps.append({"step": 1, "action": "Get Patient", "status": "success", "data": {"uhid": patient.uhid}})
        
        # Step 2: Get Lab item (CBC)
        lab_item_result = await db.execute(
            select(Item).options(selectinload(Item.dispatching_department)).where(
                Item.code.in_(["LAB001", "LAB002", "LAB003"])
            ).limit(1)
        )
        lab_item = lab_item_result.scalar_one_or_none()
        
        if not lab_item:
            errors.append("No lab items found. Please seed data first.")
            return ScenarioResult(success=False, scenario="Clinical Order Flow", steps_completed=steps, errors=errors, created_entities=created)
        
        steps.append({"step": 2, "action": "Select Lab Test", "status": "success", "data": {"item": lab_item.name}})
        
        # Step 3: Create Lab Order
        order_number = f"LAB-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        order = Order(
            order_number=order_number,
            order_type=OrderType.REGULAR,
            patient_id=patient.id,
            ipd_id=ipd.id,
            ordering_department_id=ipd.current_department_id,
            priority="NORMAL",
            status=OrderStatus.CREATED,
            created_by=admin.id
        )
        db.add(order)
        await db.flush()
        
        order_item = OrderItem(
            order_id=order.id,
            item_id=lab_item.id,
            dispatching_department_id=lab_item.dispatching_department_id,
            quantity_requested=1,
            quantity_dispatched=0,
            quantity_received=0,
            status=OrderItemStatus.PENDING_DISPATCH
        )
        db.add(order_item)
        await db.flush()
        
        created["order_id"] = order.id
        created["order_number"] = order_number
        steps.append({"step": 3, "action": "Create Lab Order", "status": "success", "data": {"order_number": order_number, "routed_to": lab_item.dispatching_department.name if lab_item.dispatching_department else "Lab"}})
        
        # Step 4: Dispatch test
        dispatch_event = DispatchEvent(
            order_item_id=order_item.id,
            quantity_dispatched=1,
            dispatched_by=admin.id,
            dispatched_at=datetime.now(timezone.utc)
        )
        db.add(dispatch_event)
        
        order_item.quantity_dispatched = 1
        order_item.status = OrderItemStatus.FULLY_DISPATCHED
        order.status = OrderStatus.FULLY_DISPATCHED
        await db.flush()
        
        steps.append({"step": 4, "action": "Dispatch Test", "status": "success", "data": {"quantity": 1}})
        
        # Step 5: Receive result
        dispatch_event.received_by = admin.id
        dispatch_event.received_at = datetime.now(timezone.utc)
        dispatch_event.quantity_received = 1
        
        order_item.quantity_received = 1
        order_item.status = OrderItemStatus.RECEIVED
        
        steps.append({"step": 5, "action": "Receive Result", "status": "success", "data": {"received": 1}})
        
        # Step 6: Complete order
        order.status = OrderStatus.COMPLETED
        order.completed_at = datetime.now(timezone.utc)
        
        steps.append({"step": 6, "action": "Complete Order", "status": "success", "data": {"status": "COMPLETED"}})
        
        # Step 7: Generate billing
        unit_cost = lab_item.cost_per_unit or Decimal("350")
        total_amount = unit_cost * 1  # quantity=1
        billing_number = f"BILL-SIM-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        billing = Billing(
            billing_number=billing_number,
            order_id=order.id,
            patient_id=patient.id,
            ipd_id=ipd.id,
            order_creator_id=admin.id,
            ordering_department_id=ipd.current_department_id,
            dispatching_department_id=lab_item.dispatching_department_id,
            total_amount=total_amount,
            status=BillingStatus.PENDING,
            generated_by=admin.id
        )
        db.add(billing)
        await db.flush()
        
        billing_item = BillingItem(
            billing_id=billing.id,
            order_item_id=order_item.id,
            item_id=lab_item.id,
            item_name=lab_item.name,
            item_code=lab_item.code,
            unit=lab_item.unit,
            cost_per_unit=unit_cost,
            quantity_dispatched=1,
            line_amount=total_amount
        )
        db.add(billing_item)
        
        created["billing_id"] = billing.id
        created["billing_amount"] = float(total_amount)
        steps.append({"step": 7, "action": "Generate Billing", "status": "success", "data": {"amount": float(total_amount)}})
        
        await db.commit()
        
    except Exception as e:
        errors.append(str(e))
        await db.rollback()
    
    return ScenarioResult(
        success=len(errors) == 0,
        scenario="Clinical Order Flow (Lab)",
        steps_completed=steps,
        errors=errors,
        created_entities=created
    )


# ============ SCENARIO 3: PHARMACY ORDER FLOW ============

@router.post("/scenario/pharmacy-order", response_model=ScenarioResult)
async def run_pharmacy_order_scenario(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Simulate Pharmacy Order Flow:
    1. Ward orders medicine
    2. Pharmacy dispatches medicine
    3. Ward receives medicine
    4. Order completes
    """
    steps = []
    errors = []
    created = {}
    
    try:
        # Step 1: Get patient with active IPD
        patient_result = await db.execute(
            select(Patient).join(IPD).where(IPD.status == IPDStatus.ACTIVE).limit(1)
        )
        patient = patient_result.scalar_one_or_none()
        
        if not patient:
            patient = Patient(
                uhid=f"SIM-PHR-{datetime.now().strftime('%H%M%S')}",
                name=f"Pharmacy Patient {random.randint(100, 999)}",
                created_by=admin.id
            )
            db.add(patient)
            await db.flush()
            
            ward = (await db.execute(select(Department).where(Department.code == "WARD"))).scalar_one_or_none()
            if not ward:
                ward = (await db.execute(select(Department).limit(1))).scalar_one()
            
            ipd = IPD(
                patient_id=patient.id,
                ipd_number=f"IPD-PHR-{random.randint(1000, 9999)}",
                admission_date=datetime.now(timezone.utc),
                admitting_department_id=ward.id,
                current_department_id=ward.id,
                current_phase=PatientWorkflowPhase.IPD,
                status=IPDStatus.ACTIVE,
                created_by=admin.id
            )
            db.add(ipd)
            await db.flush()
        else:
            ipd_result = await db.execute(
                select(IPD).where(and_(IPD.patient_id == patient.id, IPD.status == IPDStatus.ACTIVE))
            )
            ipd = ipd_result.scalar_one()
        
        steps.append({"step": 1, "action": "Get Patient", "status": "success", "data": {"uhid": patient.uhid}})
        
        # Step 2: Get Medicine items
        med_items_result = await db.execute(
            select(Item).options(selectinload(Item.dispatching_department)).where(
                Item.code.in_(["MED001", "MED002", "MED003", "MED004"])
            ).limit(2)
        )
        med_items = med_items_result.scalars().all()
        
        if not med_items:
            errors.append("No medicine items found. Please seed data first.")
            return ScenarioResult(success=False, scenario="Pharmacy Order Flow", steps_completed=steps, errors=errors, created_entities=created)
        
        steps.append({"step": 2, "action": "Select Medicines", "status": "success", "data": {"items": [m.name for m in med_items]}})
        
        # Step 3: Ward creates order
        order_number = f"PHR-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        order = Order(
            order_number=order_number,
            order_type=OrderType.REGULAR,
            patient_id=patient.id,
            ipd_id=ipd.id,
            ordering_department_id=ipd.current_department_id,
            priority=random.choice(["NORMAL", "URGENT"]),
            status=OrderStatus.CREATED,
            created_by=admin.id
        )
        db.add(order)
        await db.flush()
        
        order_items = []
        for med in med_items:
            qty = random.randint(5, 20)
            oi = OrderItem(
                order_id=order.id,
                item_id=med.id,
                dispatching_department_id=med.dispatching_department_id,
                quantity_requested=qty,
                quantity_dispatched=0,
                quantity_received=0,
                status=OrderItemStatus.PENDING_DISPATCH
            )
            db.add(oi)
            order_items.append((oi, med, qty))
        await db.flush()
        
        created["order_id"] = order.id
        created["order_number"] = order_number
        steps.append({"step": 3, "action": "Ward Creates Order", "status": "success", "data": {"order_number": order_number, "priority": order.priority}})
        
        # Step 4: Pharmacy dispatches
        total_amount = Decimal("0")
        for oi, med, qty in order_items:
            dispatch = DispatchEvent(
                order_item_id=oi.id,
                quantity_dispatched=qty,
                dispatched_by=admin.id,
                dispatched_at=datetime.now(timezone.utc)
            )
            db.add(dispatch)
            
            oi.quantity_dispatched = qty
            oi.status = OrderItemStatus.FULLY_DISPATCHED
            total_amount += (med.cost_per_unit or Decimal("10")) * qty
        
        order.status = OrderStatus.FULLY_DISPATCHED
        await db.flush()
        
        steps.append({"step": 4, "action": "Pharmacy Dispatches", "status": "success", "data": {"items_dispatched": len(order_items)}})
        
        # Step 5: Ward receives
        dispatch_events = await db.execute(
            select(DispatchEvent).join(OrderItem).where(OrderItem.order_id == order.id)
        )
        for de in dispatch_events.scalars().all():
            de.received_by = admin.id
            de.received_at = datetime.now(timezone.utc)
            de.quantity_received = de.quantity_dispatched
        
        for oi, _, _ in order_items:
            oi.quantity_received = oi.quantity_dispatched
            oi.status = OrderItemStatus.RECEIVED
        
        steps.append({"step": 5, "action": "Ward Receives", "status": "success", "data": {"received": True}})
        
        # Step 6: Complete order
        order.status = OrderStatus.COMPLETED
        order.completed_at = datetime.now(timezone.utc)
        
        # Generate billing
        dispatching_dept_id = med_items[0].dispatching_department_id if med_items else ipd.current_department_id
        billing_number = f"BILL-PHR-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        billing = Billing(
            billing_number=billing_number,
            order_id=order.id,
            patient_id=patient.id,
            ipd_id=ipd.id,
            order_creator_id=admin.id,
            ordering_department_id=ipd.current_department_id,
            dispatching_department_id=dispatching_dept_id,
            total_amount=total_amount,
            status=BillingStatus.PENDING,
            generated_by=admin.id
        )
        db.add(billing)
        await db.flush()
        
        # Create billing items
        for oi, med, qty in order_items:
            unit_cost = med.cost_per_unit or Decimal("10")
            line_amount = unit_cost * qty
            billing_item = BillingItem(
                billing_id=billing.id,
                order_item_id=oi.id,
                item_id=med.id,
                item_name=med.name,
                item_code=med.code,
                unit=med.unit,
                cost_per_unit=unit_cost,
                quantity_dispatched=qty,
                line_amount=line_amount
            )
            db.add(billing_item)
        
        created["billing_amount"] = float(total_amount)
        steps.append({"step": 6, "action": "Complete & Bill", "status": "success", "data": {"total_amount": float(total_amount)}})
        
        await db.commit()
        
    except Exception as e:
        errors.append(str(e))
        await db.rollback()
    
    return ScenarioResult(
        success=len(errors) == 0,
        scenario="Pharmacy Order Flow",
        steps_completed=steps,
        errors=errors,
        created_entities=created
    )


# ============ SCENARIO 4: RETURN ORDER FLOW ============

@router.post("/scenario/return-order", response_model=ScenarioResult)
async def run_return_order_scenario(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Simulate Return Order Flow:
    1. Find completed order with medicines
    2. Create return order
    3. Pharmacy receives return
    """
    steps = []
    errors = []
    created = {}
    
    try:
        # Step 1: Find a completed order
        completed_order_result = await db.execute(
            select(Order).options(
                selectinload(Order.items).selectinload(OrderItem.item)
            ).where(
                and_(
                    Order.status == OrderStatus.COMPLETED,
                    Order.order_type == OrderType.REGULAR
                )
            ).order_by(Order.created_at.desc()).limit(1)
        )
        original_order = completed_order_result.scalar_one_or_none()
        
        if not original_order or not original_order.items:
            errors.append("No completed orders found to return. Run Pharmacy Order scenario first.")
            return ScenarioResult(success=False, scenario="Return Order Flow", steps_completed=steps, errors=errors, created_entities=created)
        
        steps.append({"step": 1, "action": "Find Completed Order", "status": "success", "data": {"order_number": original_order.order_number}})
        
        # Step 2: Select item to return
        original_item = original_order.items[0]
        return_qty = max(1, original_item.quantity_received // 2)
        
        steps.append({"step": 2, "action": "Select Return Item", "status": "success", "data": {"item": original_item.item.name, "quantity": return_qty}})
        
        # Step 3: Create return order
        return_order_number = f"RET-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        return_order = Order(
            order_number=return_order_number,
            order_type=OrderType.RETURN,
            patient_id=original_order.patient_id,
            ipd_id=original_order.ipd_id,
            ordering_department_id=original_order.ordering_department_id,
            original_order_id=original_order.id,
            priority="NORMAL",
            status=OrderStatus.CREATED,
            created_by=admin.id
        )
        db.add(return_order)
        await db.flush()
        
        return_item = OrderItem(
            order_id=return_order.id,
            item_id=original_item.item_id,
            dispatching_department_id=original_item.dispatching_department_id,
            original_order_item_id=original_item.id,
            quantity_requested=return_qty,
            quantity_dispatched=0,
            quantity_received=0,
            status=OrderItemStatus.PENDING_DISPATCH
        )
        db.add(return_item)
        await db.flush()
        
        created["return_order_id"] = return_order.id
        created["return_order_number"] = return_order_number
        steps.append({"step": 3, "action": "Create Return Order", "status": "success", "data": {"order_number": return_order_number}})
        
        # Step 4: Department sends back
        dispatch = DispatchEvent(
            order_item_id=return_item.id,
            quantity_dispatched=return_qty,
            dispatched_by=admin.id,
            dispatched_at=datetime.now(timezone.utc)
        )
        db.add(dispatch)
        
        return_item.quantity_dispatched = return_qty
        return_item.status = OrderItemStatus.FULLY_DISPATCHED
        return_order.status = OrderStatus.FULLY_DISPATCHED
        await db.flush()
        
        steps.append({"step": 4, "action": "Department Sends Back", "status": "success", "data": {"quantity": return_qty}})
        
        # Step 5: Pharmacy receives return
        dispatch.received_by = admin.id
        dispatch.received_at = datetime.now(timezone.utc)
        dispatch.quantity_received = return_qty
        
        return_item.quantity_received = return_qty
        return_item.status = OrderItemStatus.RECEIVED
        return_order.status = OrderStatus.COMPLETED
        return_order.completed_at = datetime.now(timezone.utc)
        
        steps.append({"step": 5, "action": "Pharmacy Receives Return", "status": "success", "data": {"completed": True}})
        
        await db.commit()
        
    except Exception as e:
        errors.append(str(e))
        await db.rollback()
    
    return ScenarioResult(
        success=len(errors) == 0,
        scenario="Return Order Flow",
        steps_completed=steps,
        errors=errors,
        created_entities=created
    )


# ============ SCENARIO 5: PARTIAL DISPATCH FLOW ============

@router.post("/scenario/partial-dispatch", response_model=ScenarioResult)
async def run_partial_dispatch_scenario(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Simulate Partial Dispatch Flow:
    1. Create order with large quantity
    2. Dispatch partial quantity
    3. Dispatch remaining quantity
    4. Receive all
    5. Complete
    """
    steps = []
    errors = []
    created = {}
    
    try:
        # Get patient
        patient = (await db.execute(
            select(Patient).join(IPD).where(IPD.status == IPDStatus.ACTIVE).limit(1)
        )).scalar_one_or_none()
        
        if not patient:
            patient = Patient(uhid=f"SIM-PRT-{datetime.now().strftime('%H%M%S')}", name="Partial Test Patient", created_by=admin.id)
            db.add(patient)
            await db.flush()
            
            ward = (await db.execute(select(Department).where(Department.code == "WARD"))).scalar_one_or_none() or (await db.execute(select(Department).limit(1))).scalar_one()
            ipd = IPD(patient_id=patient.id, ipd_number=f"IPD-PRT-{random.randint(1000,9999)}", admission_date=datetime.now(timezone.utc), admitting_department_id=ward.id, current_department_id=ward.id, current_phase=PatientWorkflowPhase.IPD, status=IPDStatus.ACTIVE, created_by=admin.id)
            db.add(ipd)
            await db.flush()
        else:
            ipd = (await db.execute(select(IPD).where(and_(IPD.patient_id == patient.id, IPD.status == IPDStatus.ACTIVE)))).scalar_one()
        
        # Get consumable item
        item = (await db.execute(select(Item).where(Item.code.like("CON%")).limit(1))).scalar_one_or_none()
        if not item:
            item = (await db.execute(select(Item).limit(1))).scalar_one()
        
        steps.append({"step": 1, "action": "Setup", "status": "success", "data": {"patient": patient.uhid, "item": item.name}})
        
        # Create order with qty 100
        total_qty = 100
        order = Order(
            order_number=f"PRT-{datetime.now().strftime('%Y%m%d%H%M%S')}",
            order_type=OrderType.REGULAR,
            patient_id=patient.id,
            ipd_id=ipd.id,
            ordering_department_id=ipd.current_department_id,
            priority="NORMAL",
            status=OrderStatus.CREATED,
            created_by=admin.id
        )
        db.add(order)
        await db.flush()
        
        order_item = OrderItem(
            order_id=order.id,
            item_id=item.id,
            dispatching_department_id=item.dispatching_department_id,
            quantity_requested=total_qty,
            quantity_dispatched=0,
            quantity_received=0,
            status=OrderItemStatus.PENDING_DISPATCH
        )
        db.add(order_item)
        await db.flush()
        
        created["order_id"] = order.id
        created["order_number"] = order.order_number
        steps.append({"step": 2, "action": "Create Order", "status": "success", "data": {"order_number": order.order_number, "quantity": total_qty}})
        
        # Partial dispatch 1 (40 units)
        dispatch1 = DispatchEvent(
            order_item_id=order_item.id,
            quantity_dispatched=40,
            dispatched_by=admin.id,
            dispatched_at=datetime.now(timezone.utc)
        )
        db.add(dispatch1)
        order_item.quantity_dispatched = 40
        order_item.status = OrderItemStatus.PARTIALLY_DISPATCHED
        order.status = OrderStatus.PARTIALLY_DISPATCHED
        await db.flush()
        
        steps.append({"step": 3, "action": "Partial Dispatch 1", "status": "success", "data": {"dispatched": 40, "remaining": 60}})
        
        # Partial dispatch 2 (60 units)
        dispatch2 = DispatchEvent(
            order_item_id=order_item.id,
            quantity_dispatched=60,
            dispatched_by=admin.id,
            dispatched_at=datetime.now(timezone.utc)
        )
        db.add(dispatch2)
        order_item.quantity_dispatched = 100
        order_item.status = OrderItemStatus.FULLY_DISPATCHED
        order.status = OrderStatus.FULLY_DISPATCHED
        await db.flush()
        
        steps.append({"step": 4, "action": "Partial Dispatch 2", "status": "success", "data": {"dispatched": 60, "total_dispatched": 100}})
        
        # Receive all
        dispatch1.received_by = admin.id
        dispatch1.received_at = datetime.now(timezone.utc)
        dispatch1.quantity_received = 40
        
        dispatch2.received_by = admin.id
        dispatch2.received_at = datetime.now(timezone.utc)
        dispatch2.quantity_received = 60
        
        order_item.quantity_received = 100
        order_item.status = OrderItemStatus.RECEIVED
        order.status = OrderStatus.COMPLETED
        order.completed_at = datetime.now(timezone.utc)
        
        steps.append({"step": 5, "action": "Receive All", "status": "success", "data": {"total_received": 100}})
        steps.append({"step": 6, "action": "Order Complete", "status": "success", "data": {"status": "COMPLETED"}})
        
        await db.commit()
        
    except Exception as e:
        errors.append(str(e))
        await db.rollback()
    
    return ScenarioResult(
        success=len(errors) == 0,
        scenario="Partial Dispatch Flow",
        steps_completed=steps,
        errors=errors,
        created_entities=created
    )


# ============ RUN ALL SCENARIOS ============

@router.post("/run-all")
async def run_all_scenarios(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Run all simulation scenarios"""
    results = []
    
    # Run each scenario
    scenarios = [
        ("Patient Admission", run_patient_admission_scenario),
        ("Clinical Order (Lab)", run_clinical_order_scenario),
        ("Pharmacy Order", run_pharmacy_order_scenario),
        ("Partial Dispatch", run_partial_dispatch_scenario),
        ("Return Order", run_return_order_scenario),
    ]
    
    for name, scenario_fn in scenarios:
        try:
            result = await scenario_fn(db=db, admin=admin)
            results.append({
                "scenario": name,
                "success": result.success,
                "steps": len(result.steps_completed),
                "errors": result.errors
            })
        except Exception as e:
            results.append({
                "scenario": name,
                "success": False,
                "steps": 0,
                "errors": [str(e)]
            })
    
    success_count = sum(1 for r in results if r["success"])
    
    return {
        "summary": f"{success_count}/{len(results)} scenarios passed",
        "results": results,
        "all_passed": success_count == len(results)
    }



# Reset simulation data (only removes simulation-generated data)
@router.post("/reset")
async def reset_simulation_data(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Reset all simulation-generated data:
    - Orders with SIM/LAB/PHR/PRT/RET prefixes
    - Patients with SIM prefix UHID
    - Associated IPD records, billing, etc.
    """
    try:
        deleted = {
            "billing_items": 0,
            "billing": 0,
            "dispatch_events": 0,
            "order_items": 0,
            "orders": 0,
            "ipd_records": 0,
            "patients": 0
        }
        
        # Delete billing items for simulation orders
        sim_orders = await db.execute(
            select(Order.id).where(
                or_(
                    Order.order_number.like("ORD-%"),
                    Order.order_number.like("LAB-%"),
                    Order.order_number.like("PHR-%"),
                    Order.order_number.like("PRT-%"),
                    Order.order_number.like("RET-%")
                )
            )
        )
        sim_order_ids = [r[0] for r in sim_orders.fetchall()]
        
        if sim_order_ids:
            # Delete billing items
            billing_result = await db.execute(
                select(Billing.id).where(Billing.order_id.in_(sim_order_ids))
            )
            billing_ids = [r[0] for r in billing_result.fetchall()]
            
            if billing_ids:
                await db.execute(
                    delete(BillingItem).where(BillingItem.billing_id.in_(billing_ids))
                )
                deleted["billing_items"] = len(billing_ids)
                
                await db.execute(
                    delete(Billing).where(Billing.id.in_(billing_ids))
                )
                deleted["billing"] = len(billing_ids)
            
            # Delete dispatch events
            order_items_result = await db.execute(
                select(OrderItem.id).where(OrderItem.order_id.in_(sim_order_ids))
            )
            order_item_ids = [r[0] for r in order_items_result.fetchall()]
            
            if order_item_ids:
                await db.execute(
                    delete(DispatchEvent).where(DispatchEvent.order_item_id.in_(order_item_ids))
                )
                deleted["dispatch_events"] = len(order_item_ids)
                
                await db.execute(
                    delete(OrderItem).where(OrderItem.id.in_(order_item_ids))
                )
                deleted["order_items"] = len(order_item_ids)
            
            # Delete orders
            await db.execute(
                delete(Order).where(Order.id.in_(sim_order_ids))
            )
            deleted["orders"] = len(sim_order_ids)
        
        # Delete simulation patients and their IPDs
        sim_patients = await db.execute(
            select(Patient.id).where(Patient.uhid.like("SIM-%"))
        )
        sim_patient_ids = [r[0] for r in sim_patients.fetchall()]
        
        if sim_patient_ids:
            await db.execute(
                delete(IPD).where(IPD.patient_id.in_(sim_patient_ids))
            )
            deleted["ipd_records"] = len(sim_patient_ids)
            
            await db.execute(
                delete(Patient).where(Patient.id.in_(sim_patient_ids))
            )
            deleted["patients"] = len(sim_patient_ids)
        
        await db.commit()
        
        return {
            "success": True,
            "message": "Simulation data reset complete",
            "deleted": deleted
        }
        
    except Exception as e:
        await db.rollback()
        return {
            "success": False,
            "message": str(e),
            "deleted": {}
        }
