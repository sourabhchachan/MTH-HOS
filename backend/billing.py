"""
Billing Engine - Auto-generates billing on order completion
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, timezone, date
from decimal import Decimal
from pydantic import BaseModel, ConfigDict

from database import get_db
from models import (
    Order, OrderItem, Item, Billing, BillingItem, Patient, IPD,
    Department, User, OrderStatus
)
from auth import get_current_user, get_admin_user

router = APIRouter()


# Schemas
class BillingItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    item_name: str
    item_code: str
    unit: str
    cost_per_unit: Decimal
    quantity_dispatched: int
    line_amount: Decimal


class BillingResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    billing_number: str
    order_id: int
    patient_id: int
    ipd_id: Optional[int] = None
    order_creator_id: int
    ordering_department_id: int
    dispatching_department_id: int
    total_amount: Decimal
    status: str
    paid_amount: Decimal
    payment_date: Optional[datetime] = None
    payment_reference: Optional[str] = None
    generated_at: datetime
    patient_uhid: Optional[str] = None
    patient_name: Optional[str] = None
    ipd_number: Optional[str] = None
    items: List[BillingItemResponse] = []


class BillingSummary(BaseModel):
    total_bills: int
    total_amount: Decimal
    paid_amount: Decimal
    pending_amount: Decimal
    bills_by_status: dict


async def generate_billing_number(db: AsyncSession) -> str:
    """Generate unique billing number"""
    date_str = datetime.now(timezone.utc).strftime("%Y%m%d")
    result = await db.execute(
        select(func.count(Billing.id)).where(
            Billing.billing_number.like(f"BILL-{date_str}%")
        )
    )
    count = result.scalar() + 1
    return f"BILL-{date_str}-{count:04d}"


async def create_billing_for_order(order_id: int, db: AsyncSession, user_id: int):
    """Create billing record when order is completed"""
    # Get order with all details
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.item),
            selectinload(Order.patient),
            selectinload(Order.ipd)
        )
        .where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    
    if not order:
        return None
    
    if order.status != OrderStatus.COMPLETED:
        return None
    
    # Check if billing already exists
    existing = await db.execute(
        select(Billing).where(Billing.order_id == order_id)
    )
    if existing.scalar_one_or_none():
        return None  # Billing already exists
    
    # Calculate total amount
    total_amount = Decimal(0)
    billing_items_data = []
    
    # Get primary dispatching department (from first item)
    dispatching_dept_id = order.items[0].dispatching_department_id if order.items else order.ordering_department_id
    
    for order_item in order.items:
        if order_item.quantity_dispatched > 0:
            item = order_item.item
            line_amount = Decimal(order_item.quantity_dispatched) * (item.cost_per_unit or Decimal(0))
            total_amount += line_amount
            
            billing_items_data.append({
                'order_item_id': order_item.id,
                'item_id': item.id,
                'item_name': item.name,
                'item_code': item.code,
                'unit': item.unit,
                'cost_per_unit': item.cost_per_unit or Decimal(0),
                'quantity_dispatched': order_item.quantity_dispatched,
                'line_amount': line_amount
            })
    
    if total_amount == 0:
        return None  # No billable items
    
    # Create billing
    billing_number = await generate_billing_number(db)
    billing = Billing(
        billing_number=billing_number,
        order_id=order.id,
        patient_id=order.patient_id,
        ipd_id=order.ipd_id,
        order_creator_id=order.created_by,
        ordering_department_id=order.ordering_department_id,
        dispatching_department_id=dispatching_dept_id,
        total_amount=total_amount,
        generated_by=user_id
    )
    db.add(billing)
    await db.flush()
    
    # Create billing items
    for item_data in billing_items_data:
        billing_item = BillingItem(
            billing_id=billing.id,
            **item_data
        )
        db.add(billing_item)
    
    await db.commit()
    return billing


@router.get("/billing", response_model=List[BillingResponse])
async def list_billing(
    skip: int = 0,
    limit: int = 50,
    patient_id: Optional[int] = None,
    ipd_id: Optional[int] = None,
    status: Optional[str] = None,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """List billing records - cost visibility restricted"""
    if not current_user.is_admin and not current_user.can_view_costs:
        raise HTTPException(status_code=403, detail="Not authorized to view billing")
    
    query = select(Billing).options(
        selectinload(Billing.order).selectinload(Order.patient),
        selectinload(Billing.order).selectinload(Order.ipd)
    )
    
    if patient_id:
        query = query.where(Billing.patient_id == patient_id)
    if ipd_id:
        query = query.where(Billing.ipd_id == ipd_id)
    if status:
        query = query.where(Billing.status == status)
    if from_date:
        query = query.where(func.date(Billing.generated_at) >= from_date)
    if to_date:
        query = query.where(func.date(Billing.generated_at) <= to_date)
    
    query = query.order_by(Billing.generated_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    billings = result.scalars().all()
    
    response = []
    for billing in billings:
        # Get billing items
        items_result = await db.execute(
            select(BillingItem).where(BillingItem.billing_id == billing.id)
        )
        items = items_result.scalars().all()
        
        response.append(BillingResponse(
            id=billing.id,
            billing_number=billing.billing_number,
            order_id=billing.order_id,
            patient_id=billing.patient_id,
            ipd_id=billing.ipd_id,
            order_creator_id=billing.order_creator_id,
            ordering_department_id=billing.ordering_department_id,
            dispatching_department_id=billing.dispatching_department_id,
            total_amount=billing.total_amount,
            status=billing.status.value if hasattr(billing.status, 'value') else billing.status,
            paid_amount=billing.paid_amount,
            payment_date=billing.payment_date,
            payment_reference=billing.payment_reference,
            generated_at=billing.generated_at,
            patient_uhid=billing.order.patient.uhid if billing.order and billing.order.patient else None,
            patient_name=billing.order.patient.name if billing.order and billing.order.patient else None,
            ipd_number=billing.order.ipd.ipd_number if billing.order and billing.order.ipd else None,
            items=[BillingItemResponse.model_validate(i) for i in items]
        ))
    
    return response


@router.get("/billing/{billing_id}", response_model=BillingResponse)
async def get_billing(
    billing_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get billing details"""
    if not current_user.is_admin and not current_user.can_view_costs:
        raise HTTPException(status_code=403, detail="Not authorized to view billing")
    
    result = await db.execute(
        select(Billing).options(
            selectinload(Billing.order).selectinload(Order.patient),
            selectinload(Billing.order).selectinload(Order.ipd)
        ).where(Billing.id == billing_id)
    )
    billing = result.scalar_one_or_none()
    
    if not billing:
        raise HTTPException(status_code=404, detail="Billing not found")
    
    items_result = await db.execute(
        select(BillingItem).where(BillingItem.billing_id == billing.id)
    )
    items = items_result.scalars().all()
    
    return BillingResponse(
        id=billing.id,
        billing_number=billing.billing_number,
        order_id=billing.order_id,
        patient_id=billing.patient_id,
        ipd_id=billing.ipd_id,
        order_creator_id=billing.order_creator_id,
        ordering_department_id=billing.ordering_department_id,
        dispatching_department_id=billing.dispatching_department_id,
        total_amount=billing.total_amount,
        status=billing.status.value if hasattr(billing.status, 'value') else billing.status,
        paid_amount=billing.paid_amount,
        payment_date=billing.payment_date,
        payment_reference=billing.payment_reference,
        generated_at=billing.generated_at,
        patient_uhid=billing.order.patient.uhid if billing.order and billing.order.patient else None,
        patient_name=billing.order.patient.name if billing.order and billing.order.patient else None,
        ipd_number=billing.order.ipd.ipd_number if billing.order and billing.order.ipd else None,
        items=[BillingItemResponse.model_validate(i) for i in items]
    )


@router.get("/billing/summary/stats", response_model=BillingSummary)
async def get_billing_summary(
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get billing summary statistics"""
    query = select(Billing)
    
    if from_date:
        query = query.where(func.date(Billing.generated_at) >= from_date)
    if to_date:
        query = query.where(func.date(Billing.generated_at) <= to_date)
    
    result = await db.execute(query)
    billings = result.scalars().all()
    
    total_amount = sum(b.total_amount for b in billings)
    paid_amount = sum(b.paid_amount for b in billings)
    
    status_counts = {}
    for b in billings:
        status = b.status.value if hasattr(b.status, 'value') else str(b.status)
        status_counts[status] = status_counts.get(status, 0) + 1
    
    return BillingSummary(
        total_bills=len(billings),
        total_amount=total_amount,
        paid_amount=paid_amount,
        pending_amount=total_amount - paid_amount,
        bills_by_status=status_counts
    )


@router.put("/billing/{billing_id}/payment")
async def update_billing_payment(
    billing_id: int,
    amount: Decimal,
    reference: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Record payment for billing"""
    result = await db.execute(select(Billing).where(Billing.id == billing_id))
    billing = result.scalar_one_or_none()
    
    if not billing:
        raise HTTPException(status_code=404, detail="Billing not found")
    
    billing.paid_amount = amount
    billing.payment_date = datetime.now(timezone.utc)
    billing.payment_reference = reference
    
    if amount >= billing.total_amount:
        billing.status = "PAID"
    
    await db.commit()
    return {"message": "Payment recorded successfully"}
