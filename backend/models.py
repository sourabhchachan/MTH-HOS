from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, Numeric, Text, Enum, Date, Time, ARRAY, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
import enum


# Enums
class PatientWorkflowPhase(str, enum.Enum):
    PRE_ADMISSION = "PRE_ADMISSION"
    ADMISSION = "ADMISSION"
    IPD = "IPD"
    DISCHARGE = "DISCHARGE"
    POST_DISCHARGE = "POST_DISCHARGE"
    ARCHIVED = "ARCHIVED"


class IPDStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"


class PriorityRequirement(str, enum.Enum):
    MANDATORY = "MANDATORY"
    NON_MANDATORY = "NON_MANDATORY"


class PatientIPDRequirement(str, enum.Enum):
    MANDATORY = "MANDATORY"
    NON_MANDATORY = "NON_MANDATORY"


class IPDStatusAllowed(str, enum.Enum):
    ACTIVE_ONLY = "ACTIVE_ONLY"
    INACTIVE_ONLY = "INACTIVE_ONLY"
    BOTH = "BOTH"


class OrderType(str, enum.Enum):
    REGULAR = "REGULAR"
    RETURN = "RETURN"


class OrderPriority(str, enum.Enum):
    NORMAL = "NORMAL"
    URGENT = "URGENT"


class OrderStatus(str, enum.Enum):
    CREATED = "CREATED"
    PARTIALLY_DISPATCHED = "PARTIALLY_DISPATCHED"
    FULLY_DISPATCHED = "FULLY_DISPATCHED"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class OrderItemStatus(str, enum.Enum):
    PENDING_DISPATCH = "PENDING_DISPATCH"
    PARTIALLY_DISPATCHED = "PARTIALLY_DISPATCHED"
    FULLY_DISPATCHED = "FULLY_DISPATCHED"
    RECEIVED = "RECEIVED"
    CANCELLED = "CANCELLED"


class BillingStatus(str, enum.Enum):
    PENDING = "PENDING"
    GENERATED = "GENERATED"
    PARTIAL = "PARTIAL"  # Partial payment received
    PAID = "PAID"
    CANCELLED = "CANCELLED"


class PaymentMode(str, enum.Enum):
    CASH = "CASH"
    CARD = "CARD"
    UPI = "UPI"
    INSURANCE = "INSURANCE"
    OTHER = "OTHER"


class AssetStatus(str, enum.Enum):
    AVAILABLE = "AVAILABLE"
    IN_USE = "IN_USE"
    MAINTENANCE = "MAINTENANCE"
    RETIRED = "RETIRED"


class AttendanceStatus(str, enum.Enum):
    PRESENT = "PRESENT"
    ABSENT = "ABSENT"
    HALF_DAY = "HALF_DAY"
    LEAVE = "LEAVE"
    HOLIDAY = "HOLIDAY"


# Models
class Department(Base):
    __tablename__ = "departments"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    code = Column(String(20), unique=True, nullable=False)
    description = Column(Text)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(Integer)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    updated_by = Column(Integer)
    
    users = relationship("User", back_populates="primary_department", foreign_keys="User.primary_department_id")
    items = relationship("Item", back_populates="dispatching_department")


class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    phone = Column(String(15), unique=True, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100))
    password_hash = Column(String(255), nullable=False)
    primary_department_id = Column(Integer, ForeignKey("departments.id"), nullable=False)
    is_admin = Column(Boolean, default=False)
    can_view_costs = Column(Boolean, default=False)
    can_reactivate_ipd = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    employee_code = Column(String(50))
    designation = Column(String(100))
    date_of_joining = Column(Date)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(Integer)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    updated_by = Column(Integer)
    last_login_at = Column(DateTime(timezone=True))
    
    primary_department = relationship("Department", back_populates="users", foreign_keys=[primary_department_id])
    secondary_departments = relationship("UserSecondaryDepartment", back_populates="user", cascade="all, delete-orphan")


class UserSecondaryDepartment(Base):
    __tablename__ = "user_secondary_departments"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    department_id = Column(Integer, ForeignKey("departments.id"), nullable=False)
    
    user = relationship("User", back_populates="secondary_departments")
    department = relationship("Department")


class Patient(Base):
    __tablename__ = "patients"
    
    id = Column(Integer, primary_key=True, index=True)
    uhid = Column(String(20), unique=True, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    date_of_birth = Column(Date)
    gender = Column(String(10))
    phone = Column(String(15))
    email = Column(String(100))
    address = Column(Text)
    emergency_contact_name = Column(String(100))
    emergency_contact_phone = Column(String(15))
    blood_group = Column(String(5))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(Integer)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    updated_by = Column(Integer)
    
    ipd_records = relationship("IPD", back_populates="patient")


class IPD(Base):
    __tablename__ = "ipd"
    
    id = Column(Integer, primary_key=True, index=True)
    ipd_number = Column(String(20), unique=True, nullable=False, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    status = Column(Enum(IPDStatus), default=IPDStatus.ACTIVE)
    current_phase = Column(Enum(PatientWorkflowPhase), default=PatientWorkflowPhase.PRE_ADMISSION)
    admission_date = Column(DateTime(timezone=True))
    discharge_date = Column(DateTime(timezone=True))
    admitting_department_id = Column(Integer, ForeignKey("departments.id"))
    current_department_id = Column(Integer, ForeignKey("departments.id"))
    bed_number = Column(String(20))
    primary_diagnosis = Column(Text)
    attending_doctor_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(Integer)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    updated_by = Column(Integer)
    
    patient = relationship("Patient", back_populates="ipd_records")
    admitting_department = relationship("Department", foreign_keys=[admitting_department_id])
    current_department = relationship("Department", foreign_keys=[current_department_id])
    attending_doctor = relationship("User", foreign_keys=[attending_doctor_id])


class IPDPhaseLog(Base):
    __tablename__ = "ipd_phase_log"
    
    id = Column(Integer, primary_key=True, index=True)
    ipd_id = Column(Integer, ForeignKey("ipd.id"), nullable=False)
    from_phase = Column(Enum(PatientWorkflowPhase))
    to_phase = Column(Enum(PatientWorkflowPhase), nullable=False)
    changed_at = Column(DateTime(timezone=True), server_default=func.now())
    changed_by = Column(Integer, ForeignKey("users.id"))
    notes = Column(Text)
    
    ipd = relationship("IPD", backref="phase_logs")


class Vendor(Base):
    __tablename__ = "vendors"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    code = Column(String(50), unique=True, nullable=False)
    contact_person = Column(String(100))
    phone = Column(String(15))
    email = Column(String(100))
    address = Column(Text)
    gst_number = Column(String(20))
    pan_number = Column(String(20))
    bank_account_number = Column(String(30))
    bank_ifsc = Column(String(15))
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(Integer)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    updated_by = Column(Integer)
    
    items = relationship("Item", back_populates="vendor")


class ItemCategory(Base):
    __tablename__ = "item_categories"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    description = Column(Text)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    items = relationship("Item", back_populates="category")


class Item(Base):
    __tablename__ = "items"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    code = Column(String(50), unique=True, nullable=False)
    description = Column(Text)
    category_id = Column(Integer, ForeignKey("item_categories.id"))
    unit = Column(String(50), nullable=False)
    dispatching_department_id = Column(Integer, ForeignKey("departments.id"), nullable=False)
    vendor_id = Column(Integer, ForeignKey("vendors.id"))
    all_departments_allowed = Column(Boolean, default=False)
    workflow_phase = Column(Enum(PatientWorkflowPhase))
    priority_requirement = Column(Enum(PriorityRequirement), default=PriorityRequirement.NON_MANDATORY)
    patient_ipd_requirement = Column(Enum(PatientIPDRequirement), default=PatientIPDRequirement.NON_MANDATORY)
    ipd_status_allowed = Column(Enum(IPDStatusAllowed), default=IPDStatusAllowed.BOTH)
    cost_per_unit = Column(Numeric(12, 2), default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(Integer)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    updated_by = Column(Integer)
    
    category = relationship("ItemCategory", back_populates="items")
    dispatching_department = relationship("Department", back_populates="items")
    vendor = relationship("Vendor", back_populates="items")
    ordering_departments = relationship("ItemOrderingDepartment", back_populates="item", cascade="all, delete-orphan")


class ItemOrderingDepartment(Base):
    __tablename__ = "item_ordering_departments"
    
    id = Column(Integer, primary_key=True, index=True)
    item_id = Column(Integer, ForeignKey("items.id", ondelete="CASCADE"), nullable=False)
    department_id = Column(Integer, ForeignKey("departments.id"), nullable=False)
    
    item = relationship("Item", back_populates="ordering_departments")
    department = relationship("Department")


class Order(Base):
    __tablename__ = "orders"
    
    id = Column(Integer, primary_key=True, index=True)
    order_number = Column(String(30), unique=True, nullable=False, index=True)
    order_type = Column(Enum(OrderType), default=OrderType.REGULAR)
    original_order_id = Column(Integer, ForeignKey("orders.id"))
    return_reason = Column(Text)
    patient_id = Column(Integer, ForeignKey("patients.id"))
    ipd_id = Column(Integer, ForeignKey("ipd.id"))
    ordering_department_id = Column(Integer, ForeignKey("departments.id"), nullable=False)
    priority = Column(Enum(OrderPriority), default=OrderPriority.NORMAL)
    status = Column(Enum(OrderStatus), default=OrderStatus.CREATED, index=True)
    notes = Column(Text)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    completed_by = Column(Integer, ForeignKey("users.id"))
    completed_at = Column(DateTime(timezone=True))
    cancelled_by = Column(Integer, ForeignKey("users.id"))
    cancelled_at = Column(DateTime(timezone=True))
    cancellation_reason = Column(Text)
    
    patient = relationship("Patient")
    ipd = relationship("IPD")
    ordering_department = relationship("Department")
    creator = relationship("User", foreign_keys=[created_by])
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    original_order = relationship("Order", remote_side=[id])
    billing = relationship("Billing", back_populates="order", uselist=False)


class OrderItem(Base):
    __tablename__ = "order_items"
    
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id", ondelete="CASCADE"), nullable=False)
    item_id = Column(Integer, ForeignKey("items.id"), nullable=False)
    original_order_item_id = Column(Integer, ForeignKey("order_items.id"))
    quantity_requested = Column(Integer, nullable=False)
    quantity_dispatched = Column(Integer, default=0)
    quantity_received = Column(Integer, default=0)
    return_reason = Column(Text)
    dispatching_department_id = Column(Integer, ForeignKey("departments.id"), nullable=False, index=True)
    status = Column(Enum(OrderItemStatus), default=OrderItemStatus.PENDING_DISPATCH, index=True)
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    order = relationship("Order", back_populates="items")
    item = relationship("Item")
    dispatching_department = relationship("Department")
    dispatch_events = relationship("DispatchEvent", back_populates="order_item", cascade="all, delete-orphan")


class DispatchEvent(Base):
    __tablename__ = "dispatch_events"
    
    id = Column(Integer, primary_key=True, index=True)
    order_item_id = Column(Integer, ForeignKey("order_items.id"), nullable=False)
    quantity_dispatched = Column(Integer, nullable=False)
    dispatched_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    dispatched_at = Column(DateTime(timezone=True), server_default=func.now())
    dispatch_notes = Column(Text)
    quantity_received = Column(Integer)
    received_by = Column(Integer, ForeignKey("users.id"))
    received_at = Column(DateTime(timezone=True))
    receipt_notes = Column(Text)
    batch_number = Column(String(50))
    expiry_date = Column(Date)
    
    order_item = relationship("OrderItem", back_populates="dispatch_events")
    dispatcher = relationship("User", foreign_keys=[dispatched_by])
    receiver = relationship("User", foreign_keys=[received_by])


class Billing(Base):
    __tablename__ = "billing"
    
    id = Column(Integer, primary_key=True, index=True)
    billing_number = Column(String(30), unique=True, nullable=False)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    ipd_id = Column(Integer, ForeignKey("ipd.id"))
    order_creator_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    ordering_department_id = Column(Integer, ForeignKey("departments.id"), nullable=False)
    dispatching_department_id = Column(Integer, ForeignKey("departments.id"), nullable=False)
    total_amount = Column(Numeric(12, 2), nullable=False)
    status = Column(Enum(BillingStatus), default=BillingStatus.GENERATED)
    paid_amount = Column(Numeric(12, 2), default=0)
    payment_date = Column(DateTime(timezone=True))
    payment_reference = Column(String(100))
    generated_at = Column(DateTime(timezone=True), server_default=func.now())
    generated_by = Column(Integer, ForeignKey("users.id"))
    
    # Relationships
    order = relationship("Order", back_populates="billing")
    payments = relationship("Payment", back_populates="billing", cascade="all, delete-orphan")


class BillingItem(Base):
    __tablename__ = "billing_items"
    
    id = Column(Integer, primary_key=True, index=True)
    billing_id = Column(Integer, ForeignKey("billing.id", ondelete="CASCADE"), nullable=False)
    order_item_id = Column(Integer, ForeignKey("order_items.id"), nullable=False)
    item_id = Column(Integer, ForeignKey("items.id"), nullable=False)
    item_name = Column(String(200), nullable=False)
    item_code = Column(String(50), nullable=False)
    unit = Column(String(50), nullable=False)
    cost_per_unit = Column(Numeric(12, 2), nullable=False)
    quantity_dispatched = Column(Integer, nullable=False)
    line_amount = Column(Numeric(12, 2), nullable=False)


class Payment(Base):
    """
    Individual payment records against a billing.
    Multiple payments allowed per billing (partial payment support).
    Billing records are NEVER modified - payments are separate records.
    """
    __tablename__ = "payments"
    
    id = Column(Integer, primary_key=True, index=True)
    payment_number = Column(String(30), unique=True, nullable=False)
    billing_id = Column(Integer, ForeignKey("billing.id"), nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)
    payment_mode = Column(Enum(PaymentMode), nullable=False)
    payment_date = Column(DateTime(timezone=True), server_default=func.now())
    payment_reference = Column(String(100))  # Transaction ID, Check number, etc.
    notes = Column(Text)
    recorded_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    recorded_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    billing = relationship("Billing", back_populates="payments")
    recorder = relationship("User", foreign_keys=[recorded_by])


class Asset(Base):
    __tablename__ = "assets"
    
    id = Column(Integer, primary_key=True, index=True)
    asset_code = Column(String(50), unique=True, nullable=False)
    name = Column(String(200), nullable=False)
    description = Column(Text)
    category = Column(String(100))
    current_department_id = Column(Integer, ForeignKey("departments.id"))
    location_details = Column(String(200))
    purchase_date = Column(Date)
    purchase_price = Column(Numeric(12, 2))
    vendor_id = Column(Integer, ForeignKey("vendors.id"))
    warranty_expiry = Column(Date)
    status = Column(Enum(AssetStatus), default=AssetStatus.AVAILABLE)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(Integer)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    updated_by = Column(Integer)


class AssetAssignment(Base):
    __tablename__ = "asset_assignments"
    
    id = Column(Integer, primary_key=True, index=True)
    asset_id = Column(Integer, ForeignKey("assets.id"), nullable=False)
    assigned_to_user_id = Column(Integer, ForeignKey("users.id"))
    assigned_to_department_id = Column(Integer, ForeignKey("departments.id"))
    assigned_at = Column(DateTime(timezone=True), server_default=func.now())
    assigned_by = Column(Integer, ForeignKey("users.id"))
    returned_at = Column(DateTime(timezone=True))
    returned_by = Column(Integer, ForeignKey("users.id"))
    notes = Column(Text)


class AssetMaintenance(Base):
    __tablename__ = "asset_maintenance"
    
    id = Column(Integer, primary_key=True, index=True)
    asset_id = Column(Integer, ForeignKey("assets.id"), nullable=False)
    maintenance_type = Column(String(50))
    description = Column(Text)
    cost = Column(Numeric(12, 2))
    performed_by = Column(String(100))
    performed_at = Column(Date)
    next_maintenance_date = Column(Date)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(Integer, ForeignKey("users.id"))


class Shift(Base):
    __tablename__ = "shifts"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    is_active = Column(Boolean, default=True)


class LeaveType(Base):
    __tablename__ = "leave_types"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False)
    code = Column(String(10), unique=True, nullable=False)
    is_paid = Column(Boolean, default=True)
    max_days_per_year = Column(Integer)
    is_active = Column(Boolean, default=True)


class Attendance(Base):
    __tablename__ = "attendance"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    date = Column(Date, nullable=False)
    status = Column(Enum(AttendanceStatus), default=AttendanceStatus.PRESENT)
    shift_id = Column(Integer, ForeignKey("shifts.id"))
    check_in_time = Column(DateTime(timezone=True))
    check_out_time = Column(DateTime(timezone=True))
    biometric_check_in = Column(DateTime(timezone=True))
    biometric_check_out = Column(DateTime(timezone=True))
    total_hours = Column(Numeric(4, 2))
    overtime_hours = Column(Numeric(4, 2))
    leave_type_id = Column(Integer, ForeignKey("leave_types.id"))
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class SalaryComponent(Base):
    __tablename__ = "salary_components"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    code = Column(String(20), unique=True, nullable=False)
    component_type = Column(String(20), nullable=False)
    is_taxable = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)


class UserSalary(Base):
    __tablename__ = "user_salary"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    effective_from = Column(Date, nullable=False)
    effective_to = Column(Date)
    basic_salary = Column(Numeric(12, 2), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(Integer, ForeignKey("users.id"))


class PayrollRun(Base):
    __tablename__ = "payroll_runs"
    
    id = Column(Integer, primary_key=True, index=True)
    month = Column(Integer, nullable=False)
    year = Column(Integer, nullable=False)
    status = Column(String(20), default="DRAFT")
    processed_at = Column(DateTime(timezone=True))
    processed_by = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Payroll(Base):
    __tablename__ = "payroll"
    
    id = Column(Integer, primary_key=True, index=True)
    payroll_run_id = Column(Integer, ForeignKey("payroll_runs.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    total_working_days = Column(Integer)
    days_present = Column(Numeric(4, 1))
    days_absent = Column(Numeric(4, 1))
    leave_days = Column(Numeric(4, 1))
    overtime_hours = Column(Numeric(6, 2))
    basic_salary = Column(Numeric(12, 2))
    gross_earnings = Column(Numeric(12, 2))
    total_deductions = Column(Numeric(12, 2))
    net_salary = Column(Numeric(12, 2))
    payment_status = Column(String(20), default="PENDING")
    payment_date = Column(Date)
    payment_reference = Column(String(100))
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class ReturnReason(Base):
    __tablename__ = "return_reasons"
    
    id = Column(Integer, primary_key=True, index=True)
    reason = Column(String(200), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class BillingAdjustmentType(str, enum.Enum):
    RETURN_CREDIT = "RETURN_CREDIT"
    RETURN_DEDUCTION = "RETURN_DEDUCTION"
    MANUAL_ADJUSTMENT = "MANUAL_ADJUSTMENT"


class BillingAdjustment(Base):
    """
    Billing adjustments for returns and corrections.
    Original billing records are NEVER modified - adjustments are separate records.
    """
    __tablename__ = "billing_adjustments"
    
    id = Column(Integer, primary_key=True, index=True)
    adjustment_number = Column(String(30), unique=True, nullable=False)
    original_billing_id = Column(Integer, ForeignKey("billing.id"), nullable=False)
    return_order_id = Column(Integer, ForeignKey("orders.id"))
    adjustment_type = Column(Enum(BillingAdjustmentType), nullable=False)
    adjustment_amount = Column(Numeric(12, 2), nullable=False)  # Negative for deductions
    reason = Column(Text)
    is_credit = Column(Boolean, default=False)  # True if order was already paid
    credit_utilized = Column(Numeric(12, 2), default=0)  # For tracking credit usage
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    created_by = Column(Integer, ForeignKey("users.id"))
    
    # Relationships
    original_billing = relationship("Billing", foreign_keys=[original_billing_id])
    return_order = relationship("Order", foreign_keys=[return_order_id])


class BillingAdjustmentItem(Base):
    """Line items for billing adjustments"""
    __tablename__ = "billing_adjustment_items"
    
    id = Column(Integer, primary_key=True, index=True)
    adjustment_id = Column(Integer, ForeignKey("billing_adjustments.id", ondelete="CASCADE"), nullable=False)
    original_billing_item_id = Column(Integer, ForeignKey("billing_items.id"))
    item_id = Column(Integer, ForeignKey("items.id"), nullable=False)
    item_name = Column(String(200), nullable=False)
    item_code = Column(String(50), nullable=False)
    unit = Column(String(50), nullable=False)
    cost_per_unit = Column(Numeric(12, 2), nullable=False)
    quantity_returned = Column(Integer, nullable=False)
    line_amount = Column(Numeric(12, 2), nullable=False)  # Negative amount


class AuditLog(Base):
    __tablename__ = "audit_log"
    
    id = Column(Integer, primary_key=True, index=True)
    table_name = Column(String(100), nullable=False, index=True)
    record_id = Column(Integer, nullable=False)
    action = Column(String(20), nullable=False)
    old_values = Column(JSON)
    new_values = Column(JSON)
    user_id = Column(Integer, ForeignKey("users.id"))
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    ip_address = Column(String(45))


class UserSession(Base):
    __tablename__ = "user_sessions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    token_hash = Column(String(255), nullable=False)
    device_info = Column(Text)
    ip_address = Column(String(45))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_active = Column(Boolean, default=True)


class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    phone = Column(String(15))
    channel = Column(String(20), nullable=False)
    template_code = Column(String(50))
    message = Column(Text, nullable=False)
    status = Column(String(20), default="PENDING")
    sent_at = Column(DateTime(timezone=True))
    error_message = Column(Text)
    reference_type = Column(String(50))
    reference_id = Column(Integer)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class SystemLogLevel(str, enum.Enum):
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"


class SystemLog(Base):
    """
    Centralized error logging for deployment monitoring.
    Captures API failures, DB errors, Auth failures, Order/Billing errors.
    """
    __tablename__ = "system_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    level = Column(Enum(SystemLogLevel), default=SystemLogLevel.ERROR, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    endpoint = Column(String(255), index=True)
    method = Column(String(10))
    error_type = Column(String(100), index=True)  # API, DATABASE, AUTH, ORDER, BILLING
    error_message = Column(Text)
    stack_trace = Column(Text)
    request_body = Column(Text)
    response_status = Column(Integer)
    ip_address = Column(String(45))
    user_agent = Column(String(500))
    duration_ms = Column(Integer)  # Request duration for performance tracking
    
    # Relationships
    user = relationship("User", foreign_keys=[user_id])


class ActivityLogAction(str, enum.Enum):
    # Order Actions
    ORDER_CREATED = "ORDER_CREATED"
    ORDER_DISPATCHED = "ORDER_DISPATCHED"
    ORDER_RECEIVED = "ORDER_RECEIVED"
    ORDER_COMPLETED = "ORDER_COMPLETED"
    ORDER_CANCELLED = "ORDER_CANCELLED"
    # Return Actions
    RETURN_CREATED = "RETURN_CREATED"
    RETURN_DISPATCHED = "RETURN_DISPATCHED"
    RETURN_RECEIVED = "RETURN_RECEIVED"
    # Billing Actions
    BILLING_GENERATED = "BILLING_GENERATED"
    PAYMENT_RECORDED = "PAYMENT_RECORDED"
    BILLING_ADJUSTED = "BILLING_ADJUSTED"
    # Master Data Actions
    USER_CREATED = "USER_CREATED"
    USER_UPDATED = "USER_UPDATED"
    DEPARTMENT_CREATED = "DEPARTMENT_CREATED"
    DEPARTMENT_UPDATED = "DEPARTMENT_UPDATED"
    ITEM_CREATED = "ITEM_CREATED"
    ITEM_UPDATED = "ITEM_UPDATED"
    VENDOR_CREATED = "VENDOR_CREATED"
    VENDOR_UPDATED = "VENDOR_UPDATED"
    ASSET_CREATED = "ASSET_CREATED"
    ASSET_UPDATED = "ASSET_UPDATED"
    PATIENT_CREATED = "PATIENT_CREATED"
    PATIENT_UPDATED = "PATIENT_UPDATED"
    IPD_CREATED = "IPD_CREATED"
    IPD_UPDATED = "IPD_UPDATED"
    # Auth Actions
    USER_LOGIN = "USER_LOGIN"
    USER_LOGOUT = "USER_LOGOUT"
    PASSWORD_CHANGED = "PASSWORD_CHANGED"
    # System Actions
    SIMULATION_RUN = "SIMULATION_RUN"
    BACKUP_CREATED = "BACKUP_CREATED"
    DATA_SEEDED = "DATA_SEEDED"


class ActivityLogEntityType(str, enum.Enum):
    ORDER = "ORDER"
    BILLING = "BILLING"
    PAYMENT = "PAYMENT"
    USER = "USER"
    DEPARTMENT = "DEPARTMENT"
    ITEM = "ITEM"
    VENDOR = "VENDOR"
    ASSET = "ASSET"
    PATIENT = "PATIENT"
    IPD = "IPD"
    SYSTEM = "SYSTEM"


class ActivityLog(Base):
    """
    Global activity log for tracking major system actions.
    Used for audit trail and operational monitoring.
    """
    __tablename__ = "activity_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    action_type = Column(Enum(ActivityLogAction), nullable=False, index=True)
    entity_type = Column(Enum(ActivityLogEntityType), nullable=False, index=True)
    entity_id = Column(Integer, index=True)
    entity_identifier = Column(String(100))  # Order number, billing number, etc.
    details = Column(JSON)
    ip_address = Column(String(45))
    
    # Relationships
    user = relationship("User", foreign_keys=[user_id])
