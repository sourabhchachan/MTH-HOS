from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List
from datetime import datetime, date, time
from decimal import Decimal
from enum import Enum


# Enums for API
class PatientWorkflowPhase(str, Enum):
    PRE_ADMISSION = "PRE_ADMISSION"
    ADMISSION = "ADMISSION"
    IPD = "IPD"
    DISCHARGE = "DISCHARGE"
    POST_DISCHARGE = "POST_DISCHARGE"
    ARCHIVED = "ARCHIVED"


class IPDStatus(str, Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"


class OrderType(str, Enum):
    REGULAR = "REGULAR"
    RETURN = "RETURN"


class OrderPriority(str, Enum):
    NORMAL = "NORMAL"
    URGENT = "URGENT"


class OrderStatus(str, Enum):
    CREATED = "CREATED"
    PARTIALLY_DISPATCHED = "PARTIALLY_DISPATCHED"
    FULLY_DISPATCHED = "FULLY_DISPATCHED"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class OrderItemStatus(str, Enum):
    PENDING_DISPATCH = "PENDING_DISPATCH"
    PARTIALLY_DISPATCHED = "PARTIALLY_DISPATCHED"
    FULLY_DISPATCHED = "FULLY_DISPATCHED"
    RECEIVED = "RECEIVED"
    CANCELLED = "CANCELLED"


# Auth Schemas
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    user_id: Optional[int] = None
    phone: Optional[str] = None


class LoginRequest(BaseModel):
    phone: str
    password: str


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


# Department Schemas
class DepartmentBase(BaseModel):
    name: str
    code: str
    description: Optional[str] = None


class DepartmentCreate(DepartmentBase):
    pass


class DepartmentUpdate(BaseModel):
    name: Optional[str] = None
    code: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None


class DepartmentResponse(DepartmentBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    is_active: bool
    created_at: Optional[datetime] = None


# User Schemas
class UserBase(BaseModel):
    phone: str
    name: str
    email: Optional[str] = None
    primary_department_id: int
    employee_code: Optional[str] = None
    designation: Optional[str] = None


class UserCreate(UserBase):
    password: str
    is_admin: bool = False
    can_view_costs: bool = False
    can_reactivate_ipd: bool = False
    secondary_department_ids: Optional[List[int]] = []


class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    primary_department_id: Optional[int] = None
    is_admin: Optional[bool] = None
    can_view_costs: Optional[bool] = None
    can_reactivate_ipd: Optional[bool] = None
    is_active: Optional[bool] = None
    employee_code: Optional[str] = None
    designation: Optional[str] = None
    secondary_department_ids: Optional[List[int]] = None


class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    is_admin: bool
    can_view_costs: bool
    can_reactivate_ipd: bool
    is_active: bool
    created_at: Optional[datetime] = None
    primary_department: Optional[DepartmentResponse] = None
    secondary_departments: Optional[List[DepartmentResponse]] = []


class UserMinimal(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    name: str
    phone: str


# Patient Schemas
class PatientBase(BaseModel):
    uhid: str
    name: str
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    blood_group: Optional[str] = None


class PatientCreate(PatientBase):
    pass


class PatientUpdate(BaseModel):
    name: Optional[str] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    blood_group: Optional[str] = None


class PatientResponse(PatientBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    created_at: Optional[datetime] = None


# IPD Schemas
class IPDBase(BaseModel):
    ipd_number: str
    patient_id: int
    admitting_department_id: Optional[int] = None
    current_department_id: Optional[int] = None
    bed_number: Optional[str] = None
    primary_diagnosis: Optional[str] = None
    attending_doctor_id: Optional[int] = None


class IPDCreate(IPDBase):
    pass


class IPDUpdate(BaseModel):
    status: Optional[IPDStatus] = None
    current_phase: Optional[PatientWorkflowPhase] = None
    current_department_id: Optional[int] = None
    bed_number: Optional[str] = None
    primary_diagnosis: Optional[str] = None
    attending_doctor_id: Optional[int] = None
    discharge_date: Optional[datetime] = None


class IPDResponse(IPDBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    status: IPDStatus
    current_phase: PatientWorkflowPhase
    admission_date: Optional[datetime] = None
    discharge_date: Optional[datetime] = None
    created_at: Optional[datetime] = None
    patient: Optional[PatientResponse] = None


# Vendor Schemas
class VendorBase(BaseModel):
    name: str
    code: str
    contact_person: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    gst_number: Optional[str] = None
    pan_number: Optional[str] = None


class VendorCreate(VendorBase):
    pass


class VendorUpdate(BaseModel):
    name: Optional[str] = None
    contact_person: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    is_active: Optional[bool] = None


class VendorResponse(VendorBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    is_active: bool
    created_at: Optional[datetime] = None


# Item Category Schemas
class ItemCategoryBase(BaseModel):
    name: str
    description: Optional[str] = None


class ItemCategoryCreate(ItemCategoryBase):
    pass


class ItemCategoryResponse(ItemCategoryBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    is_active: bool


# Item Schemas
class ItemBase(BaseModel):
    name: str
    code: str
    description: Optional[str] = None
    category_id: Optional[int] = None
    unit: str
    dispatching_department_id: int
    vendor_id: Optional[int] = None
    all_departments_allowed: bool = False
    workflow_phase: Optional[PatientWorkflowPhase] = None
    priority_requirement: str = "NON_MANDATORY"
    patient_ipd_requirement: str = "NON_MANDATORY"
    ipd_status_allowed: str = "BOTH"
    cost_per_unit: Decimal = 0


class ItemCreate(ItemBase):
    ordering_department_ids: Optional[List[int]] = []


class ItemUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category_id: Optional[int] = None
    unit: Optional[str] = None
    dispatching_department_id: Optional[int] = None
    vendor_id: Optional[int] = None
    all_departments_allowed: Optional[bool] = None
    workflow_phase: Optional[PatientWorkflowPhase] = None
    priority_requirement: Optional[str] = None
    patient_ipd_requirement: Optional[str] = None
    ipd_status_allowed: Optional[str] = None
    cost_per_unit: Optional[Decimal] = None
    is_active: Optional[bool] = None
    ordering_department_ids: Optional[List[int]] = None


class ItemResponse(ItemBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    is_active: bool
    created_at: Optional[datetime] = None
    dispatching_department: Optional[DepartmentResponse] = None
    category: Optional[ItemCategoryResponse] = None
    ordering_departments: Optional[List[DepartmentResponse]] = []


class ItemMinimal(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    name: str
    code: str
    unit: str


# Order Item Schemas
class OrderItemCreate(BaseModel):
    item_id: int
    quantity_requested: int
    notes: Optional[str] = None
    original_order_item_id: Optional[int] = None
    return_reason: Optional[str] = None


class OrderItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    item_id: int
    quantity_requested: int
    quantity_dispatched: int
    quantity_received: int
    status: OrderItemStatus
    notes: Optional[str] = None
    dispatching_department_id: int
    item: Optional[ItemMinimal] = None
    dispatching_department: Optional[DepartmentResponse] = None


# Order Schemas
class OrderCreate(BaseModel):
    order_type: OrderType = OrderType.REGULAR
    original_order_id: Optional[int] = None
    return_reason: Optional[str] = None
    patient_id: Optional[int] = None
    ipd_id: Optional[int] = None
    priority: OrderPriority = OrderPriority.NORMAL
    notes: Optional[str] = None
    items: List[OrderItemCreate]


class OrderUpdate(BaseModel):
    notes: Optional[str] = None
    status: Optional[OrderStatus] = None
    cancellation_reason: Optional[str] = None


class OrderResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    order_number: str
    order_type: OrderType
    original_order_id: Optional[int] = None
    return_reason: Optional[str] = None
    patient_id: Optional[int] = None
    ipd_id: Optional[int] = None
    ordering_department_id: int
    priority: OrderPriority
    status: OrderStatus
    notes: Optional[str] = None
    created_at: datetime
    completed_at: Optional[datetime] = None
    patient: Optional[PatientResponse] = None
    ipd: Optional[IPDResponse] = None
    ordering_department: Optional[DepartmentResponse] = None
    creator: Optional[UserMinimal] = None
    items: List[OrderItemResponse] = []


# Dispatch Schemas
class DispatchCreate(BaseModel):
    order_item_id: int
    quantity_dispatched: int
    dispatch_notes: Optional[str] = None
    batch_number: Optional[str] = None
    expiry_date: Optional[date] = None


class ReceiveCreate(BaseModel):
    dispatch_event_id: int
    quantity_received: int
    receipt_notes: Optional[str] = None


class DispatchEventResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    order_item_id: int
    quantity_dispatched: int
    dispatched_at: datetime
    dispatch_notes: Optional[str] = None
    quantity_received: Optional[int] = None
    received_at: Optional[datetime] = None
    receipt_notes: Optional[str] = None
    batch_number: Optional[str] = None
    expiry_date: Optional[date] = None
    dispatcher: Optional[UserMinimal] = None
    receiver: Optional[UserMinimal] = None


# Pending Receive Item - with order info for frontend
class PendingReceiveItem(BaseModel):
    dispatch_event_id: int
    order_item_id: int
    order_id: int
    order_number: str
    item_name: str
    quantity_dispatched: int
    quantity_received: int
    quantity_pending: int
    dispatched_at: datetime
    patient_name: Optional[str] = None
    ordering_department: str


# Dispatch Queue Item
class DispatchQueueItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    order_item_id: int
    order_id: int
    order_number: str
    order_priority: OrderPriority
    item_id: int
    item_name: str
    item_code: str
    unit: str
    quantity_requested: int
    quantity_dispatched: int
    quantity_pending: int
    status: OrderItemStatus
    ordering_department: str
    patient_name: Optional[str] = None
    ipd_number: Optional[str] = None
    created_at: datetime


# Dashboard Schemas
class DashboardStats(BaseModel):
    pending_dispatch_count: int = 0
    pending_receive_count: int = 0
    orders_created_today: int = 0
    orders_completed_today: int = 0


class UserDashboard(BaseModel):
    user: UserResponse
    stats: DashboardStats
    pending_dispatch_items: List[DispatchQueueItem] = []
    pending_receive_items: List[DispatchEventResponse] = []


# Return Reason Schemas
class ReturnReasonCreate(BaseModel):
    reason: str


class ReturnReasonResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    reason: str
    is_active: bool
