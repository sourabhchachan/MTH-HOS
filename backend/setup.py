"""
Admin Setup Module - Backend routes for system configuration
Handles bulk upload, entity management for Departments, Users, Vendors, Items, Assets, Patients
"""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, timezone, date
from pydantic import BaseModel, ConfigDict
from decimal import Decimal
import csv
import io

from database import get_db
from models import (
    Department, User, UserSecondaryDepartment, Vendor, 
    ItemCategory, Item, ItemOrderingDepartment,
    Asset, Patient, AssetStatus,
    PatientWorkflowPhase, PriorityRequirement, PatientIPDRequirement, IPDStatusAllowed
)
from auth import get_current_user, get_admin_user, get_password_hash

router = APIRouter(prefix="/setup", tags=["Admin Setup"])


# ============ CSV UPLOAD SCHEMAS ============

class CSVUploadResult(BaseModel):
    total_rows: int
    successful: int
    failed: int
    errors: List[dict]
    created_items: List[str]


class ItemCSVTemplate(BaseModel):
    columns: List[str]
    sample_rows: List[dict]


# ============ VENDOR ROUTES ============

class VendorUpdate(BaseModel):
    name: Optional[str] = None
    contact_person: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    gst_number: Optional[str] = None
    pan_number: Optional[str] = None
    is_active: Optional[bool] = None


@router.put("/vendors/{vendor_id}")
async def update_vendor(
    vendor_id: int,
    data: VendorUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    result = await db.execute(select(Vendor).where(Vendor.id == vendor_id))
    vendor = result.scalar_one_or_none()
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor not found")
    
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(vendor, key, value)
    vendor.updated_by = admin.id
    
    await db.commit()
    await db.refresh(vendor)
    return {"message": "Vendor updated", "id": vendor.id}


@router.put("/vendors/{vendor_id}/toggle-active")
async def toggle_vendor_active(
    vendor_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    result = await db.execute(select(Vendor).where(Vendor.id == vendor_id))
    vendor = result.scalar_one_or_none()
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor not found")
    
    vendor.is_active = not vendor.is_active
    vendor.updated_by = admin.id
    await db.commit()
    
    return {"message": f"Vendor {'activated' if vendor.is_active else 'deactivated'}", "is_active": vendor.is_active}


# ============ ITEM CSV UPLOAD ============

@router.get("/items/csv-template")
async def get_csv_template():
    """Get CSV template for bulk item upload"""
    columns = [
        "item_name", "item_code", "category", "dispatching_department_code",
        "departments_allowed_to_order", "workflow_phase", "priority_requirement",
        "patient_ipd_requirement", "ipd_status_allowed", "cost", "vendor_code", "unit"
    ]
    
    sample_rows = [
        {
            "item_name": "Paracetamol 500mg",
            "item_code": "MED001",
            "category": "Medicines",
            "dispatching_department_code": "PHRM",
            "departments_allowed_to_order": "ALL",
            "workflow_phase": "IPD",
            "priority_requirement": "NON_MANDATORY",
            "patient_ipd_requirement": "NON_MANDATORY",
            "ipd_status_allowed": "BOTH",
            "cost": "2.50",
            "vendor_code": "VEND001",
            "unit": "tablet"
        },
        {
            "item_name": "CBC Test",
            "item_code": "LAB001",
            "category": "Lab Tests",
            "dispatching_department_code": "LAB",
            "departments_allowed_to_order": "WARD-A,WARD-B,ICU,EMRG",
            "workflow_phase": "IPD",
            "priority_requirement": "NON_MANDATORY",
            "patient_ipd_requirement": "MANDATORY",
            "ipd_status_allowed": "ACTIVE_ONLY",
            "cost": "350.00",
            "vendor_code": "VEND003",
            "unit": "test"
        }
    ]
    
    return ItemCSVTemplate(columns=columns, sample_rows=sample_rows)


@router.post("/items/csv-upload", response_model=CSVUploadResult)
async def upload_items_csv(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Bulk upload items from CSV file"""
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="File must be a CSV")
    
    content = await file.read()
    try:
        text_content = content.decode('utf-8')
    except UnicodeDecodeError:
        text_content = content.decode('latin-1')
    
    reader = csv.DictReader(io.StringIO(text_content))
    
    # Pre-load lookup data
    dept_result = await db.execute(select(Department))
    departments = {d.code.upper(): d for d in dept_result.scalars().all()}
    
    vendor_result = await db.execute(select(Vendor).where(Vendor.is_active == True))
    vendors = {v.code.upper(): v for v in vendor_result.scalars().all()}
    
    cat_result = await db.execute(select(ItemCategory))
    categories = {c.name.upper(): c for c in cat_result.scalars().all()}
    
    existing_codes_result = await db.execute(select(Item.code))
    existing_codes = {c.upper() for c in existing_codes_result.scalars().all()}
    
    results = {
        "total_rows": 0,
        "successful": 0,
        "failed": 0,
        "errors": [],
        "created_items": []
    }
    
    for row_num, row in enumerate(reader, start=2):
        results["total_rows"] += 1
        errors = []
        
        # Get required fields
        item_name = row.get('item_name', '').strip()
        item_code = row.get('item_code', '').strip()
        unit = row.get('unit', '').strip()
        dispatching_dept_code = row.get('dispatching_department_code', '').strip().upper()
        
        if not item_name:
            errors.append("Missing item_name")
        if not item_code:
            errors.append("Missing item_code")
        if not unit:
            errors.append("Missing unit")
        if not dispatching_dept_code:
            errors.append("Missing dispatching_department_code")
        
        # Check duplicate code
        if item_code.upper() in existing_codes:
            errors.append(f"Duplicate item_code: {item_code}")
        
        # Validate department
        dispatching_dept = departments.get(dispatching_dept_code)
        if not dispatching_dept and dispatching_dept_code:
            errors.append(f"Invalid dispatching_department_code: {dispatching_dept_code}")
        
        # Validate vendor (optional)
        vendor_code = row.get('vendor_code', '').strip().upper()
        vendor = vendors.get(vendor_code) if vendor_code else None
        if vendor_code and not vendor:
            errors.append(f"Invalid vendor_code: {vendor_code}")
        
        # Validate category (optional)
        category_name = row.get('category', '').strip().upper()
        category = categories.get(category_name) if category_name else None
        
        # Parse ordering departments
        allowed_depts_str = row.get('departments_allowed_to_order', '').strip().upper()
        all_depts_allowed = allowed_depts_str in ['ALL', 'ALL DEPARTMENTS', '*', '']
        ordering_dept_ids = []
        if not all_depts_allowed and allowed_depts_str:
            for dept_code in allowed_depts_str.split(','):
                dept_code = dept_code.strip()
                if dept_code in departments:
                    ordering_dept_ids.append(departments[dept_code].id)
                else:
                    errors.append(f"Invalid ordering department code: {dept_code}")
        
        # Parse enums
        workflow_phase = row.get('workflow_phase', '').strip().upper()
        valid_phases = ['PRE_ADMISSION', 'ADMISSION', 'IPD', 'DISCHARGE', 'POST_DISCHARGE', 'ARCHIVED']
        workflow_phase_enum = None
        if workflow_phase and workflow_phase in valid_phases:
            workflow_phase_enum = PatientWorkflowPhase(workflow_phase)
        elif workflow_phase and workflow_phase not in valid_phases:
            errors.append(f"Invalid workflow_phase: {workflow_phase}")
        
        priority_req = row.get('priority_requirement', 'NON_MANDATORY').strip().upper()
        priority_req_enum = PriorityRequirement.NON_MANDATORY
        if priority_req == 'MANDATORY':
            priority_req_enum = PriorityRequirement.MANDATORY
        
        patient_ipd_req = row.get('patient_ipd_requirement', 'NON_MANDATORY').strip().upper()
        patient_ipd_enum = PatientIPDRequirement.NON_MANDATORY
        if patient_ipd_req == 'MANDATORY':
            patient_ipd_enum = PatientIPDRequirement.MANDATORY
        
        ipd_status = row.get('ipd_status_allowed', 'BOTH').strip().upper()
        ipd_status_enum = IPDStatusAllowed.BOTH
        if ipd_status == 'ACTIVE_ONLY':
            ipd_status_enum = IPDStatusAllowed.ACTIVE_ONLY
        elif ipd_status == 'INACTIVE_ONLY':
            ipd_status_enum = IPDStatusAllowed.INACTIVE_ONLY
        
        # Parse cost
        try:
            cost = Decimal(row.get('cost', '0') or '0')
        except:
            cost = Decimal('0')
            errors.append(f"Invalid cost value: {row.get('cost')}")
        
        if errors:
            results["failed"] += 1
            results["errors"].append({
                "row": row_num,
                "item_code": item_code,
                "errors": errors
            })
            continue
        
        # Create item
        try:
            item = Item(
                name=item_name,
                code=item_code,
                unit=unit,
                dispatching_department_id=dispatching_dept.id,
                vendor_id=vendor.id if vendor else None,
                category_id=category.id if category else None,
                all_departments_allowed=all_depts_allowed,
                workflow_phase=workflow_phase_enum,
                priority_requirement=priority_req_enum,
                patient_ipd_requirement=patient_ipd_enum,
                ipd_status_allowed=ipd_status_enum,
                cost_per_unit=cost,
                created_by=admin.id
            )
            db.add(item)
            await db.flush()
            
            # Add ordering departments
            if not all_depts_allowed:
                for dept_id in ordering_dept_ids:
                    od = ItemOrderingDepartment(item_id=item.id, department_id=dept_id)
                    db.add(od)
            
            existing_codes.add(item_code.upper())
            results["successful"] += 1
            results["created_items"].append(item_code)
            
        except Exception as e:
            results["failed"] += 1
            results["errors"].append({
                "row": row_num,
                "item_code": item_code,
                "errors": [str(e)]
            })
    
    await db.commit()
    return CSVUploadResult(**results)


# ============ PATIENT MANAGEMENT ============

class PatientCreate(BaseModel):
    uhid: str
    name: str
    phone: Optional[str] = None
    address: Optional[str] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None


class PatientUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None


class PatientResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    uhid: str
    name: str
    phone: Optional[str] = None
    address: Optional[str] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    created_at: Optional[datetime] = None


@router.get("/patients", response_model=List[PatientResponse])
async def list_patients_admin(
    search: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    query = select(Patient)
    if search:
        query = query.where(
            (Patient.uhid.ilike(f"%{search}%")) | 
            (Patient.name.ilike(f"%{search}%")) |
            (Patient.phone.ilike(f"%{search}%"))
        )
    query = query.order_by(Patient.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


@router.post("/patients", response_model=PatientResponse)
async def create_patient_admin(
    data: PatientCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    # Check for duplicate UHID
    existing = await db.execute(select(Patient).where(Patient.uhid == data.uhid))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="UHID already exists")
    
    patient = Patient(**data.model_dump(), created_by=admin.id)
    db.add(patient)
    await db.commit()
    await db.refresh(patient)
    return patient


@router.put("/patients/{patient_id}", response_model=PatientResponse)
async def update_patient_admin(
    patient_id: int,
    data: PatientUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    result = await db.execute(select(Patient).where(Patient.id == patient_id))
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(patient, key, value)
    patient.updated_by = admin.id
    
    await db.commit()
    await db.refresh(patient)
    return patient


# ============ INITIAL CATEGORIES ============

@router.post("/seed-categories")
async def seed_initial_categories(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Seed initial item categories if not exist"""
    initial_categories = [
        {"name": "Medicines", "description": "Pharmaceutical medicines and drugs"},
        {"name": "Lab Tests", "description": "Laboratory diagnostic tests"},
        {"name": "Radiology Tests", "description": "Imaging and radiology services"},
        {"name": "Consumables", "description": "Medical consumables and supplies"},
        {"name": "Procedures", "description": "Medical procedures and services"},
        {"name": "Maintenance Requests", "description": "Equipment maintenance requests"},
        {"name": "Housekeeping Requests", "description": "Housekeeping and cleaning requests"},
    ]
    
    created = []
    for cat_data in initial_categories:
        existing = await db.execute(
            select(ItemCategory).where(ItemCategory.name == cat_data["name"])
        )
        if not existing.scalar_one_or_none():
            cat = ItemCategory(**cat_data)
            db.add(cat)
            created.append(cat_data["name"])
    
    await db.commit()
    return {"message": "Categories seeded", "created": created}


# ============ ALL VENDORS (including inactive) ============

@router.get("/vendors/all")
async def list_all_vendors(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """List all vendors including inactive ones for admin"""
    result = await db.execute(select(Vendor).order_by(Vendor.name))
    vendors = result.scalars().all()
    return [
        {
            "id": v.id,
            "name": v.name,
            "code": v.code,
            "contact_person": v.contact_person,
            "phone": v.phone,
            "email": v.email,
            "address": v.address,
            "gst_number": v.gst_number,
            "is_active": v.is_active,
            "created_at": v.created_at
        }
        for v in vendors
    ]


# ============ ALL DEPARTMENTS (including inactive) ============

@router.get("/departments/all")
async def list_all_departments(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """List all departments including inactive ones for admin"""
    result = await db.execute(select(Department).order_by(Department.name))
    depts = result.scalars().all()
    return [
        {
            "id": d.id,
            "name": d.name,
            "code": d.code,
            "description": d.description,
            "is_active": d.is_active,
            "created_at": d.created_at
        }
        for d in depts
    ]


# ============ ALL ITEMS (including inactive) ============

@router.get("/items/all")
async def list_all_items(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """List all items including inactive ones for admin"""
    result = await db.execute(
        select(Item).options(
            selectinload(Item.dispatching_department),
            selectinload(Item.category),
            selectinload(Item.vendor),
            selectinload(Item.ordering_departments).selectinload(ItemOrderingDepartment.department)
        ).order_by(Item.name)
    )
    items = result.scalars().all()
    return [
        {
            "id": i.id,
            "name": i.name,
            "code": i.code,
            "unit": i.unit,
            "category": i.category.name if i.category else None,
            "category_id": i.category_id,
            "dispatching_department": i.dispatching_department.name if i.dispatching_department else None,
            "dispatching_department_id": i.dispatching_department_id,
            "vendor": i.vendor.name if i.vendor else None,
            "vendor_id": i.vendor_id,
            "all_departments_allowed": i.all_departments_allowed,
            "ordering_departments": [od.department.name for od in i.ordering_departments] if not i.all_departments_allowed else [],
            "ordering_department_ids": [od.department_id for od in i.ordering_departments],
            "workflow_phase": i.workflow_phase.value if i.workflow_phase else None,
            "priority_requirement": i.priority_requirement.value if i.priority_requirement else "NON_MANDATORY",
            "patient_ipd_requirement": i.patient_ipd_requirement.value if i.patient_ipd_requirement else "NON_MANDATORY",
            "ipd_status_allowed": i.ipd_status_allowed.value if i.ipd_status_allowed else "BOTH",
            "cost_per_unit": float(i.cost_per_unit) if i.cost_per_unit else 0,
            "is_active": i.is_active,
            "created_at": i.created_at
        }
        for i in items
    ]


# ============ ALL USERS (including inactive) ============

@router.get("/users/all")
async def list_all_users(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """List all users including inactive ones for admin"""
    result = await db.execute(
        select(User).options(
            selectinload(User.primary_department),
            selectinload(User.secondary_departments).selectinload(UserSecondaryDepartment.department)
        ).order_by(User.name)
    )
    users = result.scalars().all()
    return [
        {
            "id": u.id,
            "name": u.name,
            "phone": u.phone,
            "email": u.email,
            "employee_code": u.employee_code,
            "designation": u.designation,
            "primary_department": u.primary_department.name if u.primary_department else None,
            "primary_department_id": u.primary_department_id,
            "secondary_departments": [sd.department.name for sd in u.secondary_departments],
            "secondary_department_ids": [sd.department_id for sd in u.secondary_departments],
            "is_admin": u.is_admin,
            "can_view_costs": u.can_view_costs,
            "can_reactivate_ipd": u.can_reactivate_ipd,
            "is_active": u.is_active,
            "created_at": u.created_at
        }
        for u in users
    ]


# ============ RESET USER PASSWORD ============

class ResetPasswordRequest(BaseModel):
    new_password: str


@router.put("/users/{user_id}/reset-password")
async def reset_user_password(
    user_id: int,
    data: ResetPasswordRequest,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.password_hash = get_password_hash(data.new_password)
    user.updated_by = admin.id
    await db.commit()
    
    return {"message": "Password reset successfully"}
