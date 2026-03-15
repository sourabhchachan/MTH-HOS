from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from typing import List
from datetime import datetime, timezone

from database import get_db
from models import (
    Department, User, UserSecondaryDepartment, Patient, IPD, IPDPhaseLog,
    Vendor, ItemCategory, Item, ItemOrderingDepartment, Order, OrderItem,
    DispatchEvent, ReturnReason
)
from schemas import (
    DepartmentCreate, DepartmentUpdate, DepartmentResponse,
    UserCreate, UserUpdate, UserResponse, UserMinimal,
    PatientCreate, PatientUpdate, PatientResponse,
    IPDCreate, IPDUpdate, IPDResponse,
    VendorCreate, VendorUpdate, VendorResponse,
    ItemCategoryCreate, ItemCategoryResponse,
    ItemCreate, ItemUpdate, ItemResponse,
    OrderCreate, OrderUpdate, OrderResponse, OrderItemResponse,
    DispatchCreate, ReceiveCreate, DispatchEventResponse,
    DispatchQueueItem, DashboardStats, UserDashboard,
    LoginRequest, Token, ChangePasswordRequest,
    ReturnReasonCreate, ReturnReasonResponse,
    OrderStatus, OrderItemStatus, OrderType, OrderPriority, IPDStatus
)
from auth import (
    get_current_user, get_admin_user, get_password_hash, 
    verify_password, create_access_token, get_user_departments
)

router = APIRouter()


# ============ AUTH ROUTES ============
@router.post("/auth/login", response_model=Token)
async def login(request: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User)
        .options(selectinload(User.primary_department))
        .where(User.phone == request.phone)
    )
    user = result.scalar_one_or_none()
    
    if not user or not verify_password(request.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid phone or password")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is deactivated")
    
    user.last_login_at = datetime.now(timezone.utc)
    await db.commit()
    
    access_token = create_access_token(data={"user_id": user.id, "phone": user.phone})
    return Token(access_token=access_token)


@router.get("/auth/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    secondary_depts = [sd.department for sd in current_user.secondary_departments]
    return UserResponse(
        id=current_user.id,
        phone=current_user.phone,
        name=current_user.name,
        email=current_user.email,
        primary_department_id=current_user.primary_department_id,
        is_admin=current_user.is_admin,
        can_view_costs=current_user.can_view_costs,
        can_reactivate_ipd=current_user.can_reactivate_ipd,
        is_active=current_user.is_active,
        employee_code=current_user.employee_code,
        designation=current_user.designation,
        created_at=current_user.created_at,
        primary_department=current_user.primary_department,
        secondary_departments=secondary_depts
    )


@router.post("/auth/change-password")
async def change_password(
    request: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    if not verify_password(request.current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    current_user.password_hash = get_password_hash(request.new_password)
    await db.commit()
    return {"message": "Password changed successfully"}


# ============ DEPARTMENT ROUTES ============
@router.get("/departments", response_model=List[DepartmentResponse])
async def list_departments(
    skip: int = 0, limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(Department).where(Department.is_active == True).offset(skip).limit(limit)
    )
    return result.scalars().all()


@router.post("/departments", response_model=DepartmentResponse)
async def create_department(
    data: DepartmentCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    dept = Department(**data.model_dump(), created_by=admin.id)
    db.add(dept)
    await db.commit()
    await db.refresh(dept)
    return dept


@router.put("/departments/{dept_id}", response_model=DepartmentResponse)
async def update_department(
    dept_id: int, data: DepartmentUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    result = await db.execute(select(Department).where(Department.id == dept_id))
    dept = result.scalar_one_or_none()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(dept, key, value)
    dept.updated_by = admin.id
    await db.commit()
    await db.refresh(dept)
    return dept


# ============ USER ROUTES ============
@router.get("/users", response_model=List[UserResponse])
async def list_users(
    skip: int = 0, limit: int = 100,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    result = await db.execute(
        select(User)
        .options(
            selectinload(User.primary_department),
            selectinload(User.secondary_departments).selectinload(UserSecondaryDepartment.department)
        )
        .offset(skip).limit(limit)
    )
    users = result.scalars().all()
    response = []
    for user in users:
        secondary_depts = [sd.department for sd in user.secondary_departments]
        response.append(UserResponse(
            id=user.id,
            phone=user.phone,
            name=user.name,
            email=user.email,
            primary_department_id=user.primary_department_id,
            is_admin=user.is_admin,
            can_view_costs=user.can_view_costs,
            can_reactivate_ipd=user.can_reactivate_ipd,
            is_active=user.is_active,
            employee_code=user.employee_code,
            designation=user.designation,
            created_at=user.created_at,
            primary_department=user.primary_department,
            secondary_departments=secondary_depts
        ))
    return response


@router.post("/users", response_model=UserResponse)
async def create_user(
    data: UserCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    # Check if phone already exists
    existing = await db.execute(select(User).where(User.phone == data.phone))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Phone number already registered")
    
    user_data = data.model_dump(exclude={"password", "secondary_department_ids"})
    user = User(**user_data, password_hash=get_password_hash(data.password), created_by=admin.id)
    db.add(user)
    await db.flush()
    
    # Add secondary departments
    for dept_id in data.secondary_department_ids or []:
        sec_dept = UserSecondaryDepartment(user_id=user.id, department_id=dept_id)
        db.add(sec_dept)
    
    await db.commit()
    
    # Reload with relationships
    result = await db.execute(
        select(User)
        .options(
            selectinload(User.primary_department),
            selectinload(User.secondary_departments).selectinload(UserSecondaryDepartment.department)
        )
        .where(User.id == user.id)
    )
    user = result.scalar_one()
    secondary_depts = [sd.department for sd in user.secondary_departments]
    return UserResponse(
        id=user.id,
        phone=user.phone,
        name=user.name,
        email=user.email,
        primary_department_id=user.primary_department_id,
        is_admin=user.is_admin,
        can_view_costs=user.can_view_costs,
        can_reactivate_ipd=user.can_reactivate_ipd,
        is_active=user.is_active,
        employee_code=user.employee_code,
        designation=user.designation,
        created_at=user.created_at,
        primary_department=user.primary_department,
        secondary_departments=secondary_depts
    )


@router.put("/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int, data: UserUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    result = await db.execute(
        select(User)
        .options(
            selectinload(User.primary_department),
            selectinload(User.secondary_departments).selectinload(UserSecondaryDepartment.department)
        )
        .where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    update_data = data.model_dump(exclude_unset=True, exclude={"secondary_department_ids"})
    for key, value in update_data.items():
        setattr(user, key, value)
    user.updated_by = admin.id
    
    # Update secondary departments if provided
    if data.secondary_department_ids is not None:
        await db.execute(
            select(UserSecondaryDepartment).where(UserSecondaryDepartment.user_id == user_id)
        )
        for sec_dept in user.secondary_departments:
            await db.delete(sec_dept)
        for dept_id in data.secondary_department_ids:
            sec_dept = UserSecondaryDepartment(user_id=user.id, department_id=dept_id)
            db.add(sec_dept)
    
    await db.commit()
    
    # Reload
    result = await db.execute(
        select(User)
        .options(
            selectinload(User.primary_department),
            selectinload(User.secondary_departments).selectinload(UserSecondaryDepartment.department)
        )
        .where(User.id == user_id)
    )
    user = result.scalar_one()
    secondary_depts = [sd.department for sd in user.secondary_departments]
    return UserResponse(
        id=user.id,
        phone=user.phone,
        name=user.name,
        email=user.email,
        primary_department_id=user.primary_department_id,
        is_admin=user.is_admin,
        can_view_costs=user.can_view_costs,
        can_reactivate_ipd=user.can_reactivate_ipd,
        is_active=user.is_active,
        employee_code=user.employee_code,
        designation=user.designation,
        created_at=user.created_at,
        primary_department=user.primary_department,
        secondary_departments=secondary_depts
    )


# ============ PATIENT ROUTES ============
@router.get("/patients", response_model=List[PatientResponse])
async def list_patients(
    skip: int = 0, limit: int = 100, search: str = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(Patient)
    if search:
        query = query.where(
            (Patient.uhid.ilike(f"%{search}%")) | (Patient.name.ilike(f"%{search}%"))
        )
    result = await db.execute(query.offset(skip).limit(limit))
    return result.scalars().all()


@router.post("/patients", response_model=PatientResponse)
async def create_patient(
    data: PatientCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    patient = Patient(**data.model_dump(), created_by=current_user.id)
    db.add(patient)
    await db.commit()
    await db.refresh(patient)
    return patient


@router.get("/patients/{patient_id}", response_model=PatientResponse)
async def get_patient(
    patient_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Patient).where(Patient.id == patient_id))
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient


# ============ IPD ROUTES ============
@router.get("/ipd", response_model=List[IPDResponse])
async def list_ipd(
    skip: int = 0, limit: int = 100, status: str = None, patient_id: int = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(IPD).options(selectinload(IPD.patient))
    if status:
        query = query.where(IPD.status == status)
    if patient_id:
        query = query.where(IPD.patient_id == patient_id)
    result = await db.execute(query.offset(skip).limit(limit))
    return result.scalars().all()


@router.post("/ipd", response_model=IPDResponse)
async def create_ipd(
    data: IPDCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    ipd = IPD(
        **data.model_dump(),
        admission_date=datetime.now(timezone.utc),
        created_by=current_user.id
    )
    db.add(ipd)
    await db.flush()
    
    # Log phase
    phase_log = IPDPhaseLog(
        ipd_id=ipd.id,
        from_phase=None,
        to_phase=ipd.current_phase,
        changed_by=current_user.id
    )
    db.add(phase_log)
    await db.commit()
    
    result = await db.execute(
        select(IPD).options(selectinload(IPD.patient)).where(IPD.id == ipd.id)
    )
    return result.scalar_one()


@router.put("/ipd/{ipd_id}", response_model=IPDResponse)
async def update_ipd(
    ipd_id: int, data: IPDUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(IPD).options(selectinload(IPD.patient)).where(IPD.id == ipd_id)
    )
    ipd = result.scalar_one_or_none()
    if not ipd:
        raise HTTPException(status_code=404, detail="IPD not found")
    
    # Check IPD reactivation permission
    if data.status == IPDStatus.ACTIVE and ipd.status == IPDStatus.INACTIVE:
        if not current_user.is_admin and not current_user.can_reactivate_ipd:
            raise HTTPException(status_code=403, detail="Not authorized to reactivate IPD")
    
    old_phase = ipd.current_phase
    
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(ipd, key, value)
    ipd.updated_by = current_user.id
    
    # Log phase change
    if data.current_phase and data.current_phase != old_phase:
        phase_log = IPDPhaseLog(
            ipd_id=ipd.id,
            from_phase=old_phase,
            to_phase=data.current_phase,
            changed_by=current_user.id
        )
        db.add(phase_log)
    
    await db.commit()
    await db.refresh(ipd)
    return ipd


# ============ VENDOR ROUTES ============
@router.get("/vendors", response_model=List[VendorResponse])
async def list_vendors(
    skip: int = 0, limit: int = 100,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    result = await db.execute(
        select(Vendor).where(Vendor.is_active == True).offset(skip).limit(limit)
    )
    return result.scalars().all()


@router.post("/vendors", response_model=VendorResponse)
async def create_vendor(
    data: VendorCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    vendor = Vendor(**data.model_dump(), created_by=admin.id)
    db.add(vendor)
    await db.commit()
    await db.refresh(vendor)
    return vendor


# ============ ITEM CATEGORY ROUTES ============
@router.get("/item-categories", response_model=List[ItemCategoryResponse])
async def list_item_categories(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(ItemCategory).where(ItemCategory.is_active == True)
    )
    return result.scalars().all()


@router.post("/item-categories", response_model=ItemCategoryResponse)
async def create_item_category(
    data: ItemCategoryCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    category = ItemCategory(**data.model_dump())
    db.add(category)
    await db.commit()
    await db.refresh(category)
    return category


# ============ ITEM ROUTES ============
@router.get("/items", response_model=List[ItemResponse])
async def list_items(
    skip: int = 0, limit: int = 100, category_id: int = None, active_only: bool = True,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(Item).options(
        selectinload(Item.dispatching_department),
        selectinload(Item.category),
        selectinload(Item.ordering_departments).selectinload(ItemOrderingDepartment.department)
    )
    if active_only:
        query = query.where(Item.is_active == True)
    if category_id:
        query = query.where(Item.category_id == category_id)
    result = await db.execute(query.offset(skip).limit(limit))
    items = result.scalars().all()
    
    response = []
    for item in items:
        ordering_depts = [od.department for od in item.ordering_departments]
        response.append(ItemResponse(
            id=item.id,
            name=item.name,
            code=item.code,
            description=item.description,
            category_id=item.category_id,
            unit=item.unit,
            dispatching_department_id=item.dispatching_department_id,
            vendor_id=item.vendor_id if current_user.is_admin or current_user.can_view_costs else None,
            all_departments_allowed=item.all_departments_allowed,
            workflow_phase=item.workflow_phase,
            priority_requirement=item.priority_requirement.value if item.priority_requirement else "NON_MANDATORY",
            patient_ipd_requirement=item.patient_ipd_requirement.value if item.patient_ipd_requirement else "NON_MANDATORY",
            ipd_status_allowed=item.ipd_status_allowed.value if item.ipd_status_allowed else "BOTH",
            cost_per_unit=item.cost_per_unit if current_user.is_admin or current_user.can_view_costs else 0,
            is_active=item.is_active,
            created_at=item.created_at,
            dispatching_department=item.dispatching_department,
            category=item.category,
            ordering_departments=ordering_depts
        ))
    return response


@router.get("/items/orderable", response_model=List[ItemResponse])
async def list_orderable_items(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get items that the current user's department can order"""
    user_depts = get_user_departments(current_user)
    
    query = select(Item).options(
        selectinload(Item.dispatching_department),
        selectinload(Item.category),
        selectinload(Item.ordering_departments).selectinload(ItemOrderingDepartment.department)
    ).where(Item.is_active == True)
    
    result = await db.execute(query)
    items = result.scalars().all()
    
    response = []
    for item in items:
        # Check if user can order this item
        can_order = item.all_departments_allowed
        if not can_order:
            allowed_depts = [od.department_id for od in item.ordering_departments]
            can_order = any(dept_id in allowed_depts for dept_id in user_depts)
        
        if can_order:
            ordering_depts = [od.department for od in item.ordering_departments]
            response.append(ItemResponse(
                id=item.id,
                name=item.name,
                code=item.code,
                description=item.description,
                category_id=item.category_id,
                unit=item.unit,
                dispatching_department_id=item.dispatching_department_id,
                vendor_id=None,
                all_departments_allowed=item.all_departments_allowed,
                workflow_phase=item.workflow_phase,
                priority_requirement=item.priority_requirement.value if item.priority_requirement else "NON_MANDATORY",
                patient_ipd_requirement=item.patient_ipd_requirement.value if item.patient_ipd_requirement else "NON_MANDATORY",
                ipd_status_allowed=item.ipd_status_allowed.value if item.ipd_status_allowed else "BOTH",
                cost_per_unit=0,
                is_active=item.is_active,
                created_at=item.created_at,
                dispatching_department=item.dispatching_department,
                category=item.category,
                ordering_departments=ordering_depts
            ))
    return response


@router.post("/items", response_model=ItemResponse)
async def create_item(
    data: ItemCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    item_data = data.model_dump(exclude={"ordering_department_ids"})
    item = Item(**item_data, created_by=admin.id)
    db.add(item)
    await db.flush()
    
    # Add ordering departments
    for dept_id in data.ordering_department_ids or []:
        ordering_dept = ItemOrderingDepartment(item_id=item.id, department_id=dept_id)
        db.add(ordering_dept)
    
    await db.commit()
    
    result = await db.execute(
        select(Item).options(
            selectinload(Item.dispatching_department),
            selectinload(Item.category),
            selectinload(Item.ordering_departments).selectinload(ItemOrderingDepartment.department)
        ).where(Item.id == item.id)
    )
    item = result.scalar_one()
    ordering_depts = [od.department for od in item.ordering_departments]
    return ItemResponse(
        id=item.id,
        name=item.name,
        code=item.code,
        description=item.description,
        category_id=item.category_id,
        unit=item.unit,
        dispatching_department_id=item.dispatching_department_id,
        vendor_id=item.vendor_id,
        all_departments_allowed=item.all_departments_allowed,
        workflow_phase=item.workflow_phase,
        priority_requirement=item.priority_requirement.value if item.priority_requirement else "NON_MANDATORY",
        patient_ipd_requirement=item.patient_ipd_requirement.value if item.patient_ipd_requirement else "NON_MANDATORY",
        ipd_status_allowed=item.ipd_status_allowed.value if item.ipd_status_allowed else "BOTH",
        cost_per_unit=item.cost_per_unit,
        is_active=item.is_active,
        created_at=item.created_at,
        dispatching_department=item.dispatching_department,
        category=item.category,
        ordering_departments=ordering_depts
    )


@router.put("/items/{item_id}", response_model=ItemResponse)
async def update_item(
    item_id: int, data: ItemUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    result = await db.execute(
        select(Item).options(
            selectinload(Item.dispatching_department),
            selectinload(Item.category),
            selectinload(Item.ordering_departments).selectinload(ItemOrderingDepartment.department)
        ).where(Item.id == item_id)
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    update_data = data.model_dump(exclude_unset=True, exclude={"ordering_department_ids"})
    for key, value in update_data.items():
        setattr(item, key, value)
    item.updated_by = admin.id
    
    # Update ordering departments
    if data.ordering_department_ids is not None:
        for od in item.ordering_departments:
            await db.delete(od)
        for dept_id in data.ordering_department_ids:
            ordering_dept = ItemOrderingDepartment(item_id=item.id, department_id=dept_id)
            db.add(ordering_dept)
    
    await db.commit()
    
    result = await db.execute(
        select(Item).options(
            selectinload(Item.dispatching_department),
            selectinload(Item.category),
            selectinload(Item.ordering_departments).selectinload(ItemOrderingDepartment.department)
        ).where(Item.id == item_id)
    )
    item = result.scalar_one()
    ordering_depts = [od.department for od in item.ordering_departments]
    return ItemResponse(
        id=item.id,
        name=item.name,
        code=item.code,
        description=item.description,
        category_id=item.category_id,
        unit=item.unit,
        dispatching_department_id=item.dispatching_department_id,
        vendor_id=item.vendor_id,
        all_departments_allowed=item.all_departments_allowed,
        workflow_phase=item.workflow_phase,
        priority_requirement=item.priority_requirement.value if item.priority_requirement else "NON_MANDATORY",
        patient_ipd_requirement=item.patient_ipd_requirement.value if item.patient_ipd_requirement else "NON_MANDATORY",
        ipd_status_allowed=item.ipd_status_allowed.value if item.ipd_status_allowed else "BOTH",
        cost_per_unit=item.cost_per_unit,
        is_active=item.is_active,
        created_at=item.created_at,
        dispatching_department=item.dispatching_department,
        category=item.category,
        ordering_departments=ordering_depts
    )


# ============ ORDER ROUTES ============
async def generate_order_number(db: AsyncSession, order_type: OrderType) -> str:
    prefix = "ORD" if order_type == OrderType.REGULAR else "RET"
    date_str = datetime.now(timezone.utc).strftime("%Y%m%d")
    
    result = await db.execute(
        select(func.count(Order.id)).where(
            Order.order_number.like(f"{prefix}-{date_str}%")
        )
    )
    count = result.scalar() + 1
    return f"{prefix}-{date_str}-{count:04d}"


@router.get("/orders", response_model=List[OrderResponse])
async def list_orders(
    skip: int = 0, limit: int = 50, status: str = None, order_type: str = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    user_depts = get_user_departments(current_user)
    
    query = select(Order).options(
        selectinload(Order.patient),
        selectinload(Order.ipd),
        selectinload(Order.ordering_department),
        selectinload(Order.creator),
        selectinload(Order.items).selectinload(OrderItem.item),
        selectinload(Order.items).selectinload(OrderItem.dispatching_department)
    )
    
    # Filter by user's departments (as creator or dispatching)
    if not current_user.is_admin:
        query = query.where(Order.ordering_department_id.in_(user_depts))
    
    if status:
        query = query.where(Order.status == status)
    if order_type:
        query = query.where(Order.order_type == order_type)
    
    query = query.order_by(Order.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/orders/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(Order).options(
            selectinload(Order.patient),
            selectinload(Order.ipd),
            selectinload(Order.ordering_department),
            selectinload(Order.creator),
            selectinload(Order.items).selectinload(OrderItem.item),
            selectinload(Order.items).selectinload(OrderItem.dispatching_department)
        ).where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order


@router.post("/orders", response_model=OrderResponse)
async def create_order(
    data: OrderCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    user_depts = get_user_departments(current_user)
    
    # Validate items
    if not data.items:
        raise HTTPException(status_code=400, detail="Order must have at least one item")
    
    # Validate priority consistency
    item_ids = [i.item_id for i in data.items]
    result = await db.execute(
        select(Item).options(
            selectinload(Item.ordering_departments)
        ).where(Item.id.in_(item_ids))
    )
    items_db = {item.id: item for item in result.scalars().all()}
    
    for order_item in data.items:
        item = items_db.get(order_item.item_id)
        if not item:
            raise HTTPException(status_code=400, detail=f"Item {order_item.item_id} not found")
        if not item.is_active:
            raise HTTPException(status_code=400, detail=f"Item {item.name} is inactive")
        
        # Check ordering permission
        can_order = item.all_departments_allowed
        if not can_order:
            allowed_depts = [od.department_id for od in item.ordering_departments]
            can_order = any(dept_id in allowed_depts for dept_id in user_depts)
        if not can_order:
            raise HTTPException(status_code=403, detail=f"Not authorized to order {item.name}")
        
        # Validate priority requirement
        if item.priority_requirement and item.priority_requirement.value == "MANDATORY" and data.priority == OrderPriority.NORMAL:
            raise HTTPException(status_code=400, detail=f"Item {item.name} requires urgent priority")
    
    # Validate IPD if required
    if data.ipd_id:
        ipd_result = await db.execute(select(IPD).where(IPD.id == data.ipd_id))
        ipd = ipd_result.scalar_one_or_none()
        if not ipd:
            raise HTTPException(status_code=400, detail="IPD not found")
        
        for order_item in data.items:
            item = items_db.get(order_item.item_id)
            if item.patient_ipd_requirement and item.patient_ipd_requirement.value == "MANDATORY":
                if item.ipd_status_allowed:
                    if item.ipd_status_allowed.value == "ACTIVE_ONLY" and ipd.status != IPDStatus.ACTIVE:
                        raise HTTPException(status_code=400, detail=f"Item {item.name} requires active IPD")
                    if item.ipd_status_allowed.value == "INACTIVE_ONLY" and ipd.status != IPDStatus.INACTIVE:
                        raise HTTPException(status_code=400, detail=f"Item {item.name} requires inactive IPD")
    else:
        for order_item in data.items:
            item = items_db.get(order_item.item_id)
            if item.patient_ipd_requirement and item.patient_ipd_requirement.value == "MANDATORY":
                raise HTTPException(status_code=400, detail=f"Item {item.name} requires patient IPD")
    
    # Create order
    order_number = await generate_order_number(db, data.order_type)
    order = Order(
        order_number=order_number,
        order_type=data.order_type,
        original_order_id=data.original_order_id,
        return_reason=data.return_reason,
        patient_id=data.patient_id,
        ipd_id=data.ipd_id,
        ordering_department_id=current_user.primary_department_id,
        priority=data.priority,
        notes=data.notes,
        created_by=current_user.id
    )
    db.add(order)
    await db.flush()
    
    # Create order items
    for order_item_data in data.items:
        item = items_db[order_item_data.item_id]
        order_item = OrderItem(
            order_id=order.id,
            item_id=order_item_data.item_id,
            original_order_item_id=order_item_data.original_order_item_id,
            quantity_requested=order_item_data.quantity_requested,
            return_reason=order_item_data.return_reason,
            dispatching_department_id=item.dispatching_department_id,
            notes=order_item_data.notes
        )
        db.add(order_item)
    
    await db.commit()
    
    # Reload with relationships
    result = await db.execute(
        select(Order).options(
            selectinload(Order.patient),
            selectinload(Order.ipd),
            selectinload(Order.ordering_department),
            selectinload(Order.creator),
            selectinload(Order.items).selectinload(OrderItem.item),
            selectinload(Order.items).selectinload(OrderItem.dispatching_department)
        ).where(Order.id == order.id)
    )
    return result.scalar_one()


@router.put("/orders/{order_id}/cancel")
async def cancel_order(
    order_id: int, reason: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if order.status in [OrderStatus.COMPLETED, OrderStatus.CANCELLED]:
        raise HTTPException(status_code=400, detail="Cannot cancel completed or already cancelled order")
    
    order.status = OrderStatus.CANCELLED
    order.cancelled_by = current_user.id
    order.cancelled_at = datetime.now(timezone.utc)
    order.cancellation_reason = reason
    
    # Cancel all items
    items_result = await db.execute(select(OrderItem).where(OrderItem.order_id == order_id))
    for item in items_result.scalars().all():
        item.status = OrderItemStatus.CANCELLED
    
    await db.commit()
    return {"message": "Order cancelled successfully"}


# ============ DISPATCH ROUTES ============
@router.get("/dispatch-queue", response_model=List[DispatchQueueItem])
async def get_dispatch_queue(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get pending dispatch items for current user's departments"""
    user_depts = get_user_departments(current_user)
    
    result = await db.execute(
        select(OrderItem, Order, Item, Department, Patient, IPD)
        .join(Order, OrderItem.order_id == Order.id)
        .join(Item, OrderItem.item_id == Item.id)
        .join(Department, Order.ordering_department_id == Department.id)
        .outerjoin(Patient, Order.patient_id == Patient.id)
        .outerjoin(IPD, Order.ipd_id == IPD.id)
        .where(
            OrderItem.dispatching_department_id.in_(user_depts),
            OrderItem.status.in_([OrderItemStatus.PENDING_DISPATCH, OrderItemStatus.PARTIALLY_DISPATCHED])
        )
        .order_by(
            Order.priority.desc(),
            Order.created_at.asc()
        )
    )
    
    queue = []
    for row in result.all():
        order_item, order, item, dept, patient, ipd = row
        queue.append(DispatchQueueItem(
            order_item_id=order_item.id,
            order_id=order.id,
            order_number=order.order_number,
            order_priority=order.priority,
            item_id=item.id,
            item_name=item.name,
            item_code=item.code,
            unit=item.unit,
            quantity_requested=order_item.quantity_requested,
            quantity_dispatched=order_item.quantity_dispatched,
            quantity_pending=order_item.quantity_requested - order_item.quantity_dispatched,
            status=order_item.status,
            ordering_department=dept.name,
            patient_name=patient.name if patient else None,
            ipd_number=ipd.ipd_number if ipd else None,
            created_at=order.created_at
        ))
    return queue


@router.post("/dispatch", response_model=DispatchEventResponse)
async def dispatch_item(
    data: DispatchCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    user_depts = get_user_departments(current_user)
    
    # Get order item
    result = await db.execute(
        select(OrderItem)
        .options(selectinload(OrderItem.order))
        .where(OrderItem.id == data.order_item_id)
    )
    order_item = result.scalar_one_or_none()
    if not order_item:
        raise HTTPException(status_code=404, detail="Order item not found")
    
    # Check dispatch permission
    if order_item.dispatching_department_id not in user_depts:
        raise HTTPException(status_code=403, detail="Not authorized to dispatch this item")
    
    # Validate quantity
    remaining = order_item.quantity_requested - order_item.quantity_dispatched
    if data.quantity_dispatched > remaining:
        raise HTTPException(status_code=400, detail=f"Cannot dispatch more than remaining quantity ({remaining})")
    
    # Create dispatch event
    dispatch_event = DispatchEvent(
        order_item_id=order_item.id,
        quantity_dispatched=data.quantity_dispatched,
        dispatched_by=current_user.id,
        dispatch_notes=data.dispatch_notes,
        batch_number=data.batch_number,
        expiry_date=data.expiry_date
    )
    db.add(dispatch_event)
    
    # Update order item
    order_item.quantity_dispatched += data.quantity_dispatched
    if order_item.quantity_dispatched >= order_item.quantity_requested:
        order_item.status = OrderItemStatus.FULLY_DISPATCHED
    else:
        order_item.status = OrderItemStatus.PARTIALLY_DISPATCHED
    
    # Update order status
    order = order_item.order
    items_result = await db.execute(
        select(OrderItem).where(OrderItem.order_id == order.id)
    )
    all_items = items_result.scalars().all()
    
    fully_dispatched = all(i.status == OrderItemStatus.FULLY_DISPATCHED for i in all_items)
    partially_dispatched = any(i.status in [OrderItemStatus.PARTIALLY_DISPATCHED, OrderItemStatus.FULLY_DISPATCHED] for i in all_items)
    
    if fully_dispatched:
        order.status = OrderStatus.FULLY_DISPATCHED
    elif partially_dispatched:
        order.status = OrderStatus.PARTIALLY_DISPATCHED
    
    await db.commit()
    
    result = await db.execute(
        select(DispatchEvent)
        .options(
            selectinload(DispatchEvent.dispatcher),
            selectinload(DispatchEvent.receiver)
        )
        .where(DispatchEvent.id == dispatch_event.id)
    )
    return result.scalar_one()


@router.get("/pending-receive", response_model=List[DispatchEventResponse])
async def get_pending_receive(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get dispatched items pending receipt for current user's departments"""
    user_depts = get_user_departments(current_user)
    
    result = await db.execute(
        select(DispatchEvent)
        .join(OrderItem, DispatchEvent.order_item_id == OrderItem.id)
        .join(Order, OrderItem.order_id == Order.id)
        .options(
            selectinload(DispatchEvent.dispatcher),
            selectinload(DispatchEvent.receiver)
        )
        .where(
            Order.ordering_department_id.in_(user_depts),
            DispatchEvent.received_at.is_(None)
        )
        .order_by(DispatchEvent.dispatched_at.asc())
    )
    return result.scalars().all()


@router.post("/receive", response_model=DispatchEventResponse)
async def receive_item(
    data: ReceiveCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    user_depts = get_user_departments(current_user)
    
    # Get dispatch event
    result = await db.execute(
        select(DispatchEvent)
        .options(
            selectinload(DispatchEvent.order_item).selectinload(OrderItem.order)
        )
        .where(DispatchEvent.id == data.dispatch_event_id)
    )
    dispatch_event = result.scalar_one_or_none()
    if not dispatch_event:
        raise HTTPException(status_code=404, detail="Dispatch event not found")
    
    # Check receive permission
    order = dispatch_event.order_item.order
    if order.ordering_department_id not in user_depts:
        raise HTTPException(status_code=403, detail="Not authorized to receive this item")
    
    if dispatch_event.received_at:
        raise HTTPException(status_code=400, detail="Item already received")
    
    # Update dispatch event
    dispatch_event.quantity_received = data.quantity_received
    dispatch_event.received_by = current_user.id
    dispatch_event.received_at = datetime.now(timezone.utc)
    dispatch_event.receipt_notes = data.receipt_notes
    
    # Update order item
    order_item = dispatch_event.order_item
    order_item.quantity_received += data.quantity_received
    
    # Check if fully received
    if order_item.quantity_received >= order_item.quantity_dispatched:
        order_item.status = OrderItemStatus.RECEIVED
    
    # Check if all items received
    items_result = await db.execute(
        select(OrderItem).where(OrderItem.order_id == order.id)
    )
    all_items = items_result.scalars().all()
    
    all_received = all(i.status == OrderItemStatus.RECEIVED for i in all_items)
    if all_received:
        order.status = OrderStatus.COMPLETED
        order.completed_by = current_user.id
        order.completed_at = datetime.now(timezone.utc)
    
    await db.commit()
    
    result = await db.execute(
        select(DispatchEvent)
        .options(
            selectinload(DispatchEvent.dispatcher),
            selectinload(DispatchEvent.receiver)
        )
        .where(DispatchEvent.id == dispatch_event.id)
    )
    return result.scalar_one()


# ============ DASHBOARD ROUTES ============
@router.get("/dashboard", response_model=UserDashboard)
async def get_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    user_depts = get_user_departments(current_user)
    today = datetime.now(timezone.utc).date()
    
    # Get stats
    pending_dispatch = await db.execute(
        select(func.count(OrderItem.id))
        .where(
            OrderItem.dispatching_department_id.in_(user_depts),
            OrderItem.status.in_([OrderItemStatus.PENDING_DISPATCH, OrderItemStatus.PARTIALLY_DISPATCHED])
        )
    )
    
    pending_receive = await db.execute(
        select(func.count(DispatchEvent.id))
        .join(OrderItem, DispatchEvent.order_item_id == OrderItem.id)
        .join(Order, OrderItem.order_id == Order.id)
        .where(
            Order.ordering_department_id.in_(user_depts),
            DispatchEvent.received_at.is_(None)
        )
    )
    
    orders_created = await db.execute(
        select(func.count(Order.id))
        .where(
            Order.ordering_department_id.in_(user_depts),
            func.date(Order.created_at) == today
        )
    )
    
    orders_completed = await db.execute(
        select(func.count(Order.id))
        .where(
            Order.ordering_department_id.in_(user_depts),
            Order.status == OrderStatus.COMPLETED,
            func.date(Order.completed_at) == today
        )
    )
    
    stats = DashboardStats(
        pending_dispatch_count=pending_dispatch.scalar() or 0,
        pending_receive_count=pending_receive.scalar() or 0,
        orders_created_today=orders_created.scalar() or 0,
        orders_completed_today=orders_completed.scalar() or 0
    )
    
    # Get dispatch queue (limited)
    dispatch_queue = await get_dispatch_queue(db, current_user)
    
    # Get pending receive (limited)
    pending_receive_items = await get_pending_receive(db, current_user)
    
    secondary_depts = [sd.department for sd in current_user.secondary_departments]
    user_response = UserResponse(
        id=current_user.id,
        phone=current_user.phone,
        name=current_user.name,
        email=current_user.email,
        primary_department_id=current_user.primary_department_id,
        is_admin=current_user.is_admin,
        can_view_costs=current_user.can_view_costs,
        can_reactivate_ipd=current_user.can_reactivate_ipd,
        is_active=current_user.is_active,
        employee_code=current_user.employee_code,
        designation=current_user.designation,
        created_at=current_user.created_at,
        primary_department=current_user.primary_department,
        secondary_departments=secondary_depts
    )
    
    return UserDashboard(
        user=user_response,
        stats=stats,
        pending_dispatch_items=dispatch_queue[:10],
        pending_receive_items=pending_receive_items[:10]
    )


# ============ RETURN REASON ROUTES ============
@router.get("/return-reasons", response_model=List[ReturnReasonResponse])
async def list_return_reasons(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(ReturnReason).where(ReturnReason.is_active == True)
    )
    return result.scalars().all()


@router.post("/return-reasons", response_model=ReturnReasonResponse)
async def create_return_reason(
    data: ReturnReasonCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    reason = ReturnReason(**data.model_dump())
    db.add(reason)
    await db.commit()
    await db.refresh(reason)
    return reason
