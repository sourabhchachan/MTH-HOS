"""
Pre-Admission and Patient Workflow Management
"""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, timezone, date
from pydantic import BaseModel, ConfigDict
from decimal import Decimal
import io
import csv

from database import get_db
from models import (
    Patient, IPD, IPDPhaseLog, Order, OrderItem, Department, User, Item,
    PatientWorkflowPhase, IPDStatus, OrderStatus
)
from auth import get_current_user, get_admin_user

router = APIRouter()


# Schemas
class EligibilityCheckRequest(BaseModel):
    patient_id: int
    consultant_id: Optional[int] = None
    diagnosis: str
    proposed_treatment: str
    referral_details: Optional[str] = None
    payment_mode: str  # CASH, INSURANCE
    insurance_details: Optional[str] = None
    notes: Optional[str] = None


class EligibilityCheckResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    patient_uhid: str
    patient_name: str
    consultant_name: Optional[str] = None
    diagnosis: str
    proposed_treatment: str
    payment_mode: str
    status: str
    created_at: datetime


class AdmissionRequest(BaseModel):
    eligibility_order_id: int
    department_id: int
    bed_number: str
    admission_notes: Optional[str] = None


class PatientPhaseStats(BaseModel):
    phase: str
    patient_count: int
    orders_count: int


class PatientWorkflowResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    patient_id: int
    patient_uhid: str
    patient_name: str
    ipd_id: Optional[int] = None
    ipd_number: Optional[str] = None
    current_phase: str
    phase_started_at: Optional[datetime] = None
    days_in_phase: int = 0
    total_orders: int = 0
    pending_orders: int = 0


# ============ PRE-ADMISSION WORKFLOW ============

@router.post("/pre-admission/eligibility-check")
async def create_eligibility_check(
    data: EligibilityCheckRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Step 1: Create admission eligibility check order"""
    # Get patient
    patient_result = await db.execute(
        select(Patient).where(Patient.id == data.patient_id)
    )
    patient = patient_result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    # Check if patient already has active IPD
    existing_ipd = await db.execute(
        select(IPD).where(
            and_(
                IPD.patient_id == data.patient_id,
                IPD.status == IPDStatus.ACTIVE
            )
        )
    )
    if existing_ipd.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Patient already has active admission")
    
    # Create eligibility check as a special order
    # Get or create pre-admission item
    item_result = await db.execute(
        select(Item).where(Item.code == "PREADM-ELIGIBILITY")
    )
    item = item_result.scalar_one_or_none()
    
    if not item:
        # Create pre-admission item if not exists
        admin_dept = await db.execute(
            select(Department).where(Department.code == "ADMIN")
        )
        admin_dept_id = admin_dept.scalar_one().id if admin_dept.scalar_one() else 1
        
        item = Item(
            name="Admission Eligibility Check",
            code="PREADM-ELIGIBILITY",
            unit="check",
            dispatching_department_id=admin_dept_id,
            all_departments_allowed=True,
            workflow_phase=PatientWorkflowPhase.PRE_ADMISSION,
            cost_per_unit=0
        )
        db.add(item)
        await db.flush()
    
    # Generate order number
    date_str = datetime.now(timezone.utc).strftime("%Y%m%d")
    count_result = await db.execute(
        select(func.count(Order.id)).where(
            Order.order_number.like(f"ELIG-{date_str}%")
        )
    )
    count = count_result.scalar() + 1
    order_number = f"ELIG-{date_str}-{count:04d}"
    
    # Create eligibility order
    order = Order(
        order_number=order_number,
        order_type="REGULAR",
        patient_id=data.patient_id,
        ordering_department_id=current_user.primary_department_id,
        priority="NORMAL",
        notes=f"Diagnosis: {data.diagnosis}\nTreatment: {data.proposed_treatment}\nPayment: {data.payment_mode}\n{data.notes or ''}",
        created_by=current_user.id,
        status=OrderStatus.CREATED
    )
    db.add(order)
    await db.flush()
    
    # Create order item
    order_item = OrderItem(
        order_id=order.id,
        item_id=item.id,
        quantity_requested=1,
        dispatching_department_id=item.dispatching_department_id,
        notes=data.referral_details
    )
    db.add(order_item)
    
    # Create/update IPD in PRE_ADMISSION phase
    ipd_number = f"IPD-{date_str}-{count:04d}"
    ipd = IPD(
        ipd_number=ipd_number,
        patient_id=data.patient_id,
        status=IPDStatus.ACTIVE,
        current_phase=PatientWorkflowPhase.PRE_ADMISSION,
        attending_doctor_id=data.consultant_id,
        primary_diagnosis=data.diagnosis,
        created_by=current_user.id
    )
    db.add(ipd)
    await db.flush()
    
    # Update order with IPD
    order.ipd_id = ipd.id
    
    # Log phase
    phase_log = IPDPhaseLog(
        ipd_id=ipd.id,
        from_phase=None,
        to_phase=PatientWorkflowPhase.PRE_ADMISSION,
        changed_by=current_user.id,
        notes=f"Eligibility check initiated. Payment mode: {data.payment_mode}"
    )
    db.add(phase_log)
    
    await db.commit()
    
    # Get consultant name
    consultant_name = None
    if data.consultant_id:
        consultant_result = await db.execute(
            select(User).where(User.id == data.consultant_id)
        )
        consultant = consultant_result.scalar_one_or_none()
        if consultant:
            consultant_name = consultant.name
    
    return EligibilityCheckResponse(
        id=order.id,
        patient_uhid=patient.uhid,
        patient_name=patient.name,
        consultant_name=consultant_name,
        diagnosis=data.diagnosis,
        proposed_treatment=data.proposed_treatment,
        payment_mode=data.payment_mode,
        status="PENDING_APPROVAL",
        created_at=order.created_at
    )


@router.post("/pre-admission/admit")
async def admit_patient(
    data: AdmissionRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Step 2: Complete admission - transitions patient to ADMISSION phase"""
    # Get eligibility order
    order_result = await db.execute(
        select(Order).options(
            selectinload(Order.ipd),
            selectinload(Order.patient)
        ).where(Order.id == data.eligibility_order_id)
    )
    order = order_result.scalar_one_or_none()
    
    if not order:
        raise HTTPException(status_code=404, detail="Eligibility order not found")
    
    if not order.ipd:
        raise HTTPException(status_code=400, detail="No IPD associated with this order")
    
    ipd = order.ipd
    
    if ipd.current_phase != PatientWorkflowPhase.PRE_ADMISSION:
        raise HTTPException(status_code=400, detail="Patient is not in pre-admission phase")
    
    # Update IPD to ADMISSION phase
    old_phase = ipd.current_phase
    ipd.current_phase = PatientWorkflowPhase.ADMISSION
    ipd.admission_date = datetime.now(timezone.utc)
    ipd.admitting_department_id = data.department_id
    ipd.current_department_id = data.department_id
    ipd.bed_number = data.bed_number
    ipd.updated_by = current_user.id
    
    # Log phase transition
    phase_log = IPDPhaseLog(
        ipd_id=ipd.id,
        from_phase=old_phase,
        to_phase=PatientWorkflowPhase.ADMISSION,
        changed_by=current_user.id,
        notes=f"Admitted to bed {data.bed_number}. {data.admission_notes or ''}"
    )
    db.add(phase_log)
    
    # Complete the eligibility order
    order.status = OrderStatus.COMPLETED
    order.completed_by = current_user.id
    order.completed_at = datetime.now(timezone.utc)
    
    await db.commit()
    
    return {
        "message": "Patient admitted successfully",
        "ipd_number": ipd.ipd_number,
        "phase": "ADMISSION",
        "bed_number": data.bed_number
    }


@router.post("/patient/{ipd_id}/transition-to-ipd")
async def transition_to_ipd_phase(
    ipd_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Transition patient from ADMISSION to IPD phase"""
    result = await db.execute(
        select(IPD).where(IPD.id == ipd_id)
    )
    ipd = result.scalar_one_or_none()
    
    if not ipd:
        raise HTTPException(status_code=404, detail="IPD not found")
    
    if ipd.current_phase != PatientWorkflowPhase.ADMISSION:
        raise HTTPException(status_code=400, detail="Patient must be in ADMISSION phase")
    
    old_phase = ipd.current_phase
    ipd.current_phase = PatientWorkflowPhase.IPD
    ipd.updated_by = current_user.id
    
    phase_log = IPDPhaseLog(
        ipd_id=ipd.id,
        from_phase=old_phase,
        to_phase=PatientWorkflowPhase.IPD,
        changed_by=current_user.id,
        notes="Moved to active IPD care"
    )
    db.add(phase_log)
    
    await db.commit()
    
    return {"message": "Patient transitioned to IPD phase", "phase": "IPD"}


@router.post("/patient/{ipd_id}/initiate-discharge")
async def initiate_discharge(
    ipd_id: int,
    discharge_notes: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Transition patient to DISCHARGE phase"""
    result = await db.execute(
        select(IPD).where(IPD.id == ipd_id)
    )
    ipd = result.scalar_one_or_none()
    
    if not ipd:
        raise HTTPException(status_code=404, detail="IPD not found")
    
    if ipd.current_phase not in [PatientWorkflowPhase.IPD, PatientWorkflowPhase.ADMISSION]:
        raise HTTPException(status_code=400, detail="Invalid phase for discharge")
    
    old_phase = ipd.current_phase
    ipd.current_phase = PatientWorkflowPhase.DISCHARGE
    ipd.updated_by = current_user.id
    
    phase_log = IPDPhaseLog(
        ipd_id=ipd.id,
        from_phase=old_phase,
        to_phase=PatientWorkflowPhase.DISCHARGE,
        changed_by=current_user.id,
        notes=discharge_notes or "Discharge initiated"
    )
    db.add(phase_log)
    
    await db.commit()
    
    return {"message": "Discharge initiated", "phase": "DISCHARGE"}


@router.post("/patient/{ipd_id}/complete-discharge")
async def complete_discharge(
    ipd_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Complete discharge - move to POST_DISCHARGE and deactivate IPD"""
    result = await db.execute(
        select(IPD).where(IPD.id == ipd_id)
    )
    ipd = result.scalar_one_or_none()
    
    if not ipd:
        raise HTTPException(status_code=404, detail="IPD not found")
    
    if ipd.current_phase != PatientWorkflowPhase.DISCHARGE:
        raise HTTPException(status_code=400, detail="Patient must be in DISCHARGE phase")
    
    # Check for pending orders
    pending_orders = await db.execute(
        select(func.count(Order.id))
        .where(
            and_(
                Order.ipd_id == ipd_id,
                Order.status.in_([
                    OrderStatus.CREATED,
                    OrderStatus.PARTIALLY_DISPATCHED,
                    OrderStatus.FULLY_DISPATCHED
                ])
            )
        )
    )
    pending_count = pending_orders.scalar() or 0
    
    if pending_count > 0:
        raise HTTPException(
            status_code=400, 
            detail=f"Cannot complete discharge: {pending_count} orders still pending"
        )
    
    old_phase = ipd.current_phase
    ipd.current_phase = PatientWorkflowPhase.POST_DISCHARGE
    ipd.status = IPDStatus.INACTIVE
    ipd.discharge_date = datetime.now(timezone.utc)
    ipd.updated_by = current_user.id
    
    phase_log = IPDPhaseLog(
        ipd_id=ipd.id,
        from_phase=old_phase,
        to_phase=PatientWorkflowPhase.POST_DISCHARGE,
        changed_by=current_user.id,
        notes="Discharge completed. IPD deactivated."
    )
    db.add(phase_log)
    
    await db.commit()
    
    return {"message": "Discharge completed", "phase": "POST_DISCHARGE", "ipd_status": "INACTIVE"}


@router.post("/patient/{ipd_id}/archive")
async def archive_patient(
    ipd_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Archive patient record (admin only)"""
    result = await db.execute(
        select(IPD).where(IPD.id == ipd_id)
    )
    ipd = result.scalar_one_or_none()
    
    if not ipd:
        raise HTTPException(status_code=404, detail="IPD not found")
    
    if ipd.current_phase != PatientWorkflowPhase.POST_DISCHARGE:
        raise HTTPException(status_code=400, detail="Only post-discharge patients can be archived")
    
    old_phase = ipd.current_phase
    ipd.current_phase = PatientWorkflowPhase.ARCHIVED
    ipd.updated_by = admin.id
    
    phase_log = IPDPhaseLog(
        ipd_id=ipd.id,
        from_phase=old_phase,
        to_phase=PatientWorkflowPhase.ARCHIVED,
        changed_by=admin.id,
        notes="Patient record archived"
    )
    db.add(phase_log)
    
    await db.commit()
    
    return {"message": "Patient archived", "phase": "ARCHIVED"}


# ============ PATIENT WORKFLOW ANALYTICS ============

@router.get("/patient-workflow/stats")
async def get_workflow_phase_stats(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get patient counts by workflow phase"""
    phases = [phase.value for phase in PatientWorkflowPhase]
    
    stats = []
    for phase in phases:
        # Count patients in this phase
        patient_count = await db.execute(
            select(func.count(IPD.id))
            .where(IPD.current_phase == phase)
        )
        
        # Count orders in this phase
        orders_count = await db.execute(
            select(func.count(Order.id))
            .join(IPD, Order.ipd_id == IPD.id)
            .where(IPD.current_phase == phase)
        )
        
        stats.append(PatientPhaseStats(
            phase=phase,
            patient_count=patient_count.scalar() or 0,
            orders_count=orders_count.scalar() or 0
        ))
    
    return stats


@router.get("/patient-workflow/patients")
async def get_patients_by_phase(
    phase: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get patients with workflow details"""
    query = select(IPD).options(
        selectinload(IPD.patient)
    ).where(IPD.status == IPDStatus.ACTIVE)
    
    if phase:
        query = query.where(IPD.current_phase == phase)
    
    result = await db.execute(query)
    ipds = result.scalars().all()
    
    now = datetime.now(timezone.utc)
    patients = []
    
    for ipd in ipds:
        # Get phase start time from log
        phase_log_result = await db.execute(
            select(IPDPhaseLog)
            .where(
                and_(
                    IPDPhaseLog.ipd_id == ipd.id,
                    IPDPhaseLog.to_phase == ipd.current_phase
                )
            )
            .order_by(IPDPhaseLog.changed_at.desc())
            .limit(1)
        )
        phase_log = phase_log_result.scalar_one_or_none()
        phase_started = phase_log.changed_at if phase_log else ipd.created_at
        
        days_in_phase = (now - phase_started).days if phase_started else 0
        
        # Count orders
        orders_result = await db.execute(
            select(func.count(Order.id))
            .where(Order.ipd_id == ipd.id)
        )
        total_orders = orders_result.scalar() or 0
        
        pending_result = await db.execute(
            select(func.count(Order.id))
            .where(
                and_(
                    Order.ipd_id == ipd.id,
                    Order.status.in_([
                        OrderStatus.CREATED,
                        OrderStatus.PARTIALLY_DISPATCHED,
                        OrderStatus.FULLY_DISPATCHED
                    ])
                )
            )
        )
        pending_orders = pending_result.scalar() or 0
        
        patients.append(PatientWorkflowResponse(
            patient_id=ipd.patient_id,
            patient_uhid=ipd.patient.uhid if ipd.patient else "",
            patient_name=ipd.patient.name if ipd.patient else "",
            ipd_id=ipd.id,
            ipd_number=ipd.ipd_number,
            current_phase=ipd.current_phase.value if hasattr(ipd.current_phase, 'value') else str(ipd.current_phase),
            phase_started_at=phase_started,
            days_in_phase=days_in_phase,
            total_orders=total_orders,
            pending_orders=pending_orders
        ))
    
    return patients


@router.get("/patient/{ipd_id}/phase-history")
async def get_phase_history(
    ipd_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get complete phase transition history for a patient"""
    result = await db.execute(
        select(IPDPhaseLog)
        .options(selectinload(IPDPhaseLog.ipd))
        .where(IPDPhaseLog.ipd_id == ipd_id)
        .order_by(IPDPhaseLog.changed_at.asc())
    )
    logs = result.scalars().all()
    
    # Get user names for changed_by
    user_ids = [log.changed_by for log in logs if log.changed_by]
    users = {}
    if user_ids:
        user_result = await db.execute(
            select(User).where(User.id.in_(user_ids))
        )
        users = {u.id: u.name for u in user_result.scalars().all()}
    
    history = []
    for log in logs:
        history.append({
            "from_phase": log.from_phase.value if log.from_phase and hasattr(log.from_phase, 'value') else str(log.from_phase) if log.from_phase else None,
            "to_phase": log.to_phase.value if hasattr(log.to_phase, 'value') else str(log.to_phase),
            "changed_at": log.changed_at.isoformat() if log.changed_at else None,
            "changed_by": users.get(log.changed_by, "Unknown"),
            "notes": log.notes
        })
    
    return {"ipd_id": ipd_id, "history": history}


# ============ BULK ITEM UPLOAD ============

@router.post("/items/bulk-upload")
async def bulk_upload_items(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Bulk upload items from CSV file"""
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="Only CSV files are supported")
    
    content = await file.read()
    decoded = content.decode('utf-8')
    reader = csv.DictReader(io.StringIO(decoded))
    
    # Get departments and vendors for lookup
    dept_result = await db.execute(select(Department))
    departments = {d.code: d.id for d in dept_result.scalars().all()}
    
    vendor_result = await db.execute(select(Vendor))
    vendors = {v.code: v.id for v in vendor_result.scalars().all()}
    
    created = 0
    errors = []
    
    for row_num, row in enumerate(reader, start=2):
        try:
            # Required fields
            name = row.get('name', '').strip()
            code = row.get('code', '').strip()
            unit = row.get('unit', '').strip()
            dispatching_dept_code = row.get('dispatching_department_code', '').strip()
            
            if not all([name, code, unit, dispatching_dept_code]):
                errors.append(f"Row {row_num}: Missing required fields")
                continue
            
            if dispatching_dept_code not in departments:
                errors.append(f"Row {row_num}: Invalid department code '{dispatching_dept_code}'")
                continue
            
            # Check if item exists
            existing = await db.execute(
                select(Item).where(Item.code == code)
            )
            if existing.scalar_one_or_none():
                errors.append(f"Row {row_num}: Item code '{code}' already exists")
                continue
            
            # Optional fields
            vendor_code = row.get('vendor_code', '').strip()
            vendor_id = vendors.get(vendor_code) if vendor_code else None
            
            cost = Decimal(row.get('cost_per_unit', '0') or '0')
            all_depts = row.get('all_departments_allowed', '').lower() == 'true'
            
            # Create item
            item = Item(
                name=name,
                code=code,
                unit=unit,
                dispatching_department_id=departments[dispatching_dept_code],
                vendor_id=vendor_id,
                cost_per_unit=cost,
                all_departments_allowed=all_depts,
                description=row.get('description', ''),
                created_by=admin.id
            )
            db.add(item)
            created += 1
            
        except Exception as e:
            errors.append(f"Row {row_num}: {str(e)}")
    
    await db.commit()
    
    return {
        "message": f"Bulk upload completed",
        "created": created,
        "errors": errors[:20] if errors else [],
        "total_errors": len(errors)
    }


@router.get("/items/template")
async def get_item_upload_template():
    """Get CSV template for bulk item upload"""
    template = "name,code,unit,dispatching_department_code,vendor_code,cost_per_unit,all_departments_allowed,description\n"
    template += "Paracetamol 500mg,MED001,tablet,PHRM,VEND001,2.50,true,Pain reliever\n"
    template += "Blood Test CBC,LAB001,test,LAB,VEND002,350.00,true,Complete blood count\n"
    
    return StreamingResponse(
        io.StringIO(template),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=item_upload_template.csv"}
    )
