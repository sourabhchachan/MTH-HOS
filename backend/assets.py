"""
Asset Maintenance Automation
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, timezone, date, timedelta
from pydantic import BaseModel, ConfigDict
from decimal import Decimal

from database import get_db
from models import (
    Asset, AssetMaintenance, AssetAssignment, Department, User, Vendor,
    Order, OrderItem, Item, AssetStatus, OrderStatus
)
from auth import get_current_user, get_admin_user

router = APIRouter()


# Schemas
class AssetCreate(BaseModel):
    asset_code: str
    name: str
    description: Optional[str] = None
    category: Optional[str] = None
    current_department_id: Optional[int] = None
    location_details: Optional[str] = None
    purchase_date: Optional[date] = None
    purchase_price: Optional[Decimal] = None
    vendor_id: Optional[int] = None
    warranty_expiry: Optional[date] = None


class AssetUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    current_department_id: Optional[int] = None
    location_details: Optional[str] = None
    status: Optional[str] = None


class AssetResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    asset_code: str
    name: str
    description: Optional[str] = None
    category: Optional[str] = None
    current_department_id: Optional[int] = None
    department_name: Optional[str] = None
    location_details: Optional[str] = None
    purchase_date: Optional[date] = None
    purchase_price: Optional[Decimal] = None
    vendor_id: Optional[int] = None
    warranty_expiry: Optional[date] = None
    status: str
    last_maintenance_date: Optional[date] = None
    next_maintenance_date: Optional[date] = None


class MaintenanceCreate(BaseModel):
    asset_id: int
    maintenance_type: str  # PREVENTIVE, CORRECTIVE, INSPECTION
    description: str
    cost: Optional[Decimal] = None
    performed_by: Optional[str] = None
    performed_at: date
    next_maintenance_date: Optional[date] = None


class MaintenanceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    asset_id: int
    asset_name: Optional[str] = None
    asset_code: Optional[str] = None
    maintenance_type: str
    description: str
    cost: Optional[Decimal] = None
    performed_by: Optional[str] = None
    performed_at: date
    next_maintenance_date: Optional[date] = None
    created_at: datetime


class MaintenanceDue(BaseModel):
    asset_id: int
    asset_code: str
    asset_name: str
    category: Optional[str] = None
    department_name: Optional[str] = None
    next_maintenance_date: date
    days_until_due: int
    last_maintenance_type: Optional[str] = None


# ============ ASSET CRUD ============

@router.get("/assets", response_model=List[AssetResponse])
async def list_assets(
    status: Optional[str] = None,
    department_id: Optional[int] = None,
    category: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """List all assets"""
    query = select(Asset)
    
    if status:
        query = query.where(Asset.status == status)
    if department_id:
        query = query.where(Asset.current_department_id == department_id)
    if category:
        query = query.where(Asset.category == category)
    
    result = await db.execute(query.order_by(Asset.name))
    assets = result.scalars().all()
    
    # Get department names
    dept_result = await db.execute(select(Department))
    depts = {d.id: d.name for d in dept_result.scalars().all()}
    
    # Get last maintenance for each asset
    response = []
    for asset in assets:
        last_maint = await db.execute(
            select(AssetMaintenance)
            .where(AssetMaintenance.asset_id == asset.id)
            .order_by(AssetMaintenance.performed_at.desc())
            .limit(1)
        )
        last_maint_record = last_maint.scalar_one_or_none()
        
        response.append(AssetResponse(
            id=asset.id,
            asset_code=asset.asset_code,
            name=asset.name,
            description=asset.description,
            category=asset.category,
            current_department_id=asset.current_department_id,
            department_name=depts.get(asset.current_department_id),
            location_details=asset.location_details,
            purchase_date=asset.purchase_date,
            purchase_price=asset.purchase_price,
            vendor_id=asset.vendor_id,
            warranty_expiry=asset.warranty_expiry,
            status=asset.status.value if hasattr(asset.status, 'value') else str(asset.status),
            last_maintenance_date=last_maint_record.performed_at if last_maint_record else None,
            next_maintenance_date=last_maint_record.next_maintenance_date if last_maint_record else None
        ))
    
    return response


@router.post("/assets", response_model=AssetResponse)
async def create_asset(
    data: AssetCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Create new asset"""
    # Check for duplicate code
    existing = await db.execute(
        select(Asset).where(Asset.asset_code == data.asset_code)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Asset code already exists")
    
    asset = Asset(
        **data.model_dump(),
        status=AssetStatus.AVAILABLE,
        created_by=admin.id
    )
    db.add(asset)
    await db.commit()
    await db.refresh(asset)
    
    return AssetResponse(
        id=asset.id,
        asset_code=asset.asset_code,
        name=asset.name,
        description=asset.description,
        category=asset.category,
        current_department_id=asset.current_department_id,
        location_details=asset.location_details,
        purchase_date=asset.purchase_date,
        purchase_price=asset.purchase_price,
        vendor_id=asset.vendor_id,
        warranty_expiry=asset.warranty_expiry,
        status=asset.status.value if hasattr(asset.status, 'value') else str(asset.status)
    )


@router.put("/assets/{asset_id}", response_model=AssetResponse)
async def update_asset(
    asset_id: int,
    data: AssetUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Update asset"""
    result = await db.execute(
        select(Asset).where(Asset.id == asset_id)
    )
    asset = result.scalar_one_or_none()
    
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    
    for key, value in data.model_dump(exclude_unset=True).items():
        if key == 'status' and value:
            setattr(asset, key, AssetStatus(value))
        else:
            setattr(asset, key, value)
    
    asset.updated_by = admin.id
    await db.commit()
    await db.refresh(asset)
    
    # Get department name
    dept_name = None
    if asset.current_department_id:
        dept_result = await db.execute(
            select(Department).where(Department.id == asset.current_department_id)
        )
        dept = dept_result.scalar_one_or_none()
        if dept:
            dept_name = dept.name
    
    return AssetResponse(
        id=asset.id,
        asset_code=asset.asset_code,
        name=asset.name,
        description=asset.description,
        category=asset.category,
        current_department_id=asset.current_department_id,
        department_name=dept_name,
        location_details=asset.location_details,
        purchase_date=asset.purchase_date,
        purchase_price=asset.purchase_price,
        vendor_id=asset.vendor_id,
        warranty_expiry=asset.warranty_expiry,
        status=asset.status.value if hasattr(asset.status, 'value') else str(asset.status)
    )


# ============ MAINTENANCE TRACKING ============

@router.get("/assets/maintenance", response_model=List[MaintenanceResponse])
async def list_maintenance(
    asset_id: Optional[int] = None,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """List maintenance records"""
    query = select(AssetMaintenance)
    
    if asset_id:
        query = query.where(AssetMaintenance.asset_id == asset_id)
    if from_date:
        query = query.where(AssetMaintenance.performed_at >= from_date)
    if to_date:
        query = query.where(AssetMaintenance.performed_at <= to_date)
    
    query = query.order_by(AssetMaintenance.performed_at.desc())
    result = await db.execute(query)
    records = result.scalars().all()
    
    # Get asset names
    asset_ids = list(set(r.asset_id for r in records))
    if asset_ids:
        assets_result = await db.execute(
            select(Asset).where(Asset.id.in_(asset_ids))
        )
        assets = {a.id: a for a in assets_result.scalars().all()}
    else:
        assets = {}
    
    response = []
    for record in records:
        asset = assets.get(record.asset_id)
        response.append(MaintenanceResponse(
            id=record.id,
            asset_id=record.asset_id,
            asset_name=asset.name if asset else None,
            asset_code=asset.asset_code if asset else None,
            maintenance_type=record.maintenance_type,
            description=record.description,
            cost=record.cost,
            performed_by=record.performed_by,
            performed_at=record.performed_at,
            next_maintenance_date=record.next_maintenance_date,
            created_at=record.created_at
        ))
    
    return response


@router.post("/assets/maintenance", response_model=MaintenanceResponse)
async def record_maintenance(
    data: MaintenanceCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Record maintenance activity"""
    # Verify asset exists
    asset_result = await db.execute(
        select(Asset).where(Asset.id == data.asset_id)
    )
    asset = asset_result.scalar_one_or_none()
    
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    
    # Create maintenance record
    record = AssetMaintenance(
        asset_id=data.asset_id,
        maintenance_type=data.maintenance_type,
        description=data.description,
        cost=data.cost,
        performed_by=data.performed_by,
        performed_at=data.performed_at,
        next_maintenance_date=data.next_maintenance_date,
        created_by=current_user.id
    )
    db.add(record)
    
    # Update asset status if it was in maintenance
    if asset.status == AssetStatus.MAINTENANCE:
        asset.status = AssetStatus.AVAILABLE
        asset.updated_by = current_user.id
    
    await db.commit()
    await db.refresh(record)
    
    return MaintenanceResponse(
        id=record.id,
        asset_id=record.asset_id,
        asset_name=asset.name,
        asset_code=asset.asset_code,
        maintenance_type=record.maintenance_type,
        description=record.description,
        cost=record.cost,
        performed_by=record.performed_by,
        performed_at=record.performed_at,
        next_maintenance_date=record.next_maintenance_date,
        created_at=record.created_at
    )


# ============ MAINTENANCE DUE AUTOMATION ============

@router.get("/assets/maintenance-due", response_model=List[MaintenanceDue])
async def get_maintenance_due(
    days_ahead: int = 7,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get assets with maintenance due within specified days"""
    today = date.today()
    due_date = today + timedelta(days=days_ahead)
    
    # Get latest maintenance for each asset
    subquery = (
        select(
            AssetMaintenance.asset_id,
            func.max(AssetMaintenance.performed_at).label('last_date')
        )
        .group_by(AssetMaintenance.asset_id)
        .subquery()
    )
    
    result = await db.execute(
        select(AssetMaintenance, Asset)
        .join(Asset, AssetMaintenance.asset_id == Asset.id)
        .join(
            subquery,
            and_(
                AssetMaintenance.asset_id == subquery.c.asset_id,
                AssetMaintenance.performed_at == subquery.c.last_date
            )
        )
        .where(
            and_(
                AssetMaintenance.next_maintenance_date.isnot(None),
                AssetMaintenance.next_maintenance_date <= due_date
            )
        )
        .order_by(AssetMaintenance.next_maintenance_date)
    )
    
    records = result.all()
    
    # Get department names
    dept_result = await db.execute(select(Department))
    depts = {d.id: d.name for d in dept_result.scalars().all()}
    
    due_list = []
    for maint, asset in records:
        days_until = (maint.next_maintenance_date - today).days
        due_list.append(MaintenanceDue(
            asset_id=asset.id,
            asset_code=asset.asset_code,
            asset_name=asset.name,
            category=asset.category,
            department_name=depts.get(asset.current_department_id),
            next_maintenance_date=maint.next_maintenance_date,
            days_until_due=days_until,
            last_maintenance_type=maint.maintenance_type
        ))
    
    return due_list


@router.post("/assets/maintenance-due/generate-orders")
async def generate_maintenance_orders(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Auto-generate maintenance orders for assets due today"""
    today = date.today()
    
    # Get assets with maintenance due today or overdue
    due_assets = await get_maintenance_due(days_ahead=0, db=db, current_user=admin)
    
    if not due_assets:
        return {"message": "No maintenance due", "orders_created": 0}
    
    # Get or create maintenance item
    item_result = await db.execute(
        select(Item).where(Item.code == "ASSET-MAINT")
    )
    item = item_result.scalar_one_or_none()
    
    if not item:
        # Get admin department
        admin_dept = await db.execute(
            select(Department).where(Department.code == "ADMIN")
        )
        admin_dept_obj = admin_dept.scalar_one_or_none()
        admin_dept_id = admin_dept_obj.id if admin_dept_obj else 1
        
        item = Item(
            name="Asset Maintenance",
            code="ASSET-MAINT",
            unit="service",
            dispatching_department_id=admin_dept_id,
            all_departments_allowed=True,
            cost_per_unit=0
        )
        db.add(item)
        await db.flush()
    
    orders_created = 0
    for due_asset in due_assets:
        if due_asset.days_until_due > 0:
            continue  # Only process overdue or due today
        
        # Generate order number
        date_str = datetime.now(timezone.utc).strftime("%Y%m%d")
        count_result = await db.execute(
            select(func.count(Order.id)).where(
                Order.order_number.like(f"MAINT-{date_str}%")
            )
        )
        count = count_result.scalar() + 1
        order_number = f"MAINT-{date_str}-{count:04d}"
        
        # Create order
        order = Order(
            order_number=order_number,
            order_type="REGULAR",
            ordering_department_id=admin.primary_department_id,
            priority="NORMAL",
            notes=f"Scheduled maintenance for asset: {due_asset.asset_code} - {due_asset.asset_name}",
            created_by=admin.id,
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
            notes=f"Asset: {due_asset.asset_code}"
        )
        db.add(order_item)
        
        # Set asset to maintenance status
        asset_result = await db.execute(
            select(Asset).where(Asset.id == due_asset.asset_id)
        )
        asset = asset_result.scalar_one_or_none()
        if asset:
            asset.status = AssetStatus.MAINTENANCE
            asset.updated_by = admin.id
        
        orders_created += 1
    
    await db.commit()
    
    return {
        "message": f"Maintenance orders generated",
        "orders_created": orders_created
    }


# ============ ASSET ASSIGNMENT ============

@router.post("/assets/{asset_id}/assign")
async def assign_asset(
    asset_id: int,
    user_id: Optional[int] = None,
    department_id: Optional[int] = None,
    notes: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Assign asset to user or department"""
    result = await db.execute(
        select(Asset).where(Asset.id == asset_id)
    )
    asset = result.scalar_one_or_none()
    
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    
    if asset.status != AssetStatus.AVAILABLE:
        raise HTTPException(status_code=400, detail="Asset is not available for assignment")
    
    # Create assignment record
    assignment = AssetAssignment(
        asset_id=asset_id,
        assigned_to_user_id=user_id,
        assigned_to_department_id=department_id,
        assigned_by=current_user.id,
        notes=notes
    )
    db.add(assignment)
    
    # Update asset
    asset.status = AssetStatus.IN_USE
    if department_id:
        asset.current_department_id = department_id
    asset.updated_by = current_user.id
    
    await db.commit()
    
    return {"message": "Asset assigned successfully"}


@router.post("/assets/{asset_id}/return")
async def return_asset(
    asset_id: int,
    notes: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Return assigned asset"""
    result = await db.execute(
        select(Asset).where(Asset.id == asset_id)
    )
    asset = result.scalar_one_or_none()
    
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    
    # Find active assignment
    assignment_result = await db.execute(
        select(AssetAssignment)
        .where(
            and_(
                AssetAssignment.asset_id == asset_id,
                AssetAssignment.returned_at.is_(None)
            )
        )
        .order_by(AssetAssignment.assigned_at.desc())
        .limit(1)
    )
    assignment = assignment_result.scalar_one_or_none()
    
    if assignment:
        assignment.returned_at = datetime.now(timezone.utc)
        assignment.returned_by = current_user.id
        if notes:
            assignment.notes = (assignment.notes or "") + f"\nReturn: {notes}"
    
    asset.status = AssetStatus.AVAILABLE
    asset.updated_by = current_user.id
    
    await db.commit()
    
    return {"message": "Asset returned successfully"}
