"""
Billing Engine - Auto-generates billing on order completion
Payment Recording - Supports partial payments with full history
PDF Invoice Generation - Printable invoices with payment status
"""
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, timezone, date
from decimal import Decimal
from pydantic import BaseModel, ConfigDict
from enum import Enum
import io

from database import get_db
from models import (
    Order, OrderItem, Item, Billing, BillingItem, BillingStatus,
    Payment, PaymentMode, Patient, IPD, Department, User, OrderStatus,
    BillingAdjustment
)
from auth import get_current_user, get_admin_user

router = APIRouter()


# ============ SCHEMAS ============

class PaymentModeEnum(str, Enum):
    CASH = "CASH"
    CARD = "CARD"
    UPI = "UPI"
    INSURANCE = "INSURANCE"
    OTHER = "OTHER"


class BillingItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    item_name: str
    item_code: str
    unit: str
    cost_per_unit: Decimal
    quantity_dispatched: int
    line_amount: Decimal


class PaymentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    payment_number: str
    billing_id: int
    amount: Decimal
    payment_mode: str
    payment_date: datetime
    payment_reference: Optional[str] = None
    notes: Optional[str] = None
    recorded_by: int
    recorded_at: datetime
    recorder_name: Optional[str] = None


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
    outstanding_amount: Decimal = Decimal(0)
    payment_date: Optional[datetime] = None
    payment_reference: Optional[str] = None
    generated_at: datetime
    patient_uhid: Optional[str] = None
    patient_name: Optional[str] = None
    ipd_number: Optional[str] = None
    items: List[BillingItemResponse] = []
    payments: List[PaymentResponse] = []
    total_adjustments: Decimal = Decimal(0)
    effective_amount: Decimal = Decimal(0)


class BillingSummary(BaseModel):
    total_bills: int
    total_amount: Decimal
    paid_amount: Decimal
    pending_amount: Decimal
    bills_by_status: dict


class PaymentCreate(BaseModel):
    billing_id: int
    amount: Decimal
    payment_mode: PaymentModeEnum
    payment_reference: Optional[str] = None
    notes: Optional[str] = None


class PaymentSummary(BaseModel):
    billing_id: int
    billing_number: str
    total_amount: Decimal
    total_paid: Decimal
    total_adjustments: Decimal
    effective_amount: Decimal
    outstanding_amount: Decimal
    status: str
    payment_count: int


# ============ HELPER FUNCTIONS ============

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


async def generate_payment_number(db: AsyncSession) -> str:
    """Generate unique payment number"""
    date_str = datetime.now(timezone.utc).strftime("%Y%m%d")
    result = await db.execute(
        select(func.count(Payment.id)).where(
            Payment.payment_number.like(f"PAY-{date_str}%")
        )
    )
    count = result.scalar() + 1
    return f"PAY-{date_str}-{count:04d}"


async def get_billing_adjustments_total(billing_id: int, db: AsyncSession) -> Decimal:
    """Get sum of all billing adjustments for a billing"""
    result = await db.execute(
        select(func.sum(BillingAdjustment.adjustment_amount)).where(
            BillingAdjustment.original_billing_id == billing_id
        )
    )
    return result.scalar() or Decimal(0)


async def update_billing_status(billing_id: int, db: AsyncSession):
    """Update billing status based on payments and adjustments"""
    result = await db.execute(select(Billing).where(Billing.id == billing_id))
    billing = result.scalar_one_or_none()
    if not billing:
        return
    
    # Get total adjustments
    adjustments_total = await get_billing_adjustments_total(billing_id, db)
    effective_amount = billing.total_amount + adjustments_total
    
    # Get total payments
    payments_result = await db.execute(
        select(func.sum(Payment.amount)).where(Payment.billing_id == billing_id)
    )
    total_paid = payments_result.scalar() or Decimal(0)
    
    # Update paid_amount field
    billing.paid_amount = total_paid
    
    # Determine status
    if effective_amount <= 0:
        billing.status = BillingStatus.PAID  # Fully adjusted/credited
    elif total_paid >= effective_amount:
        billing.status = BillingStatus.PAID
        billing.payment_date = datetime.now(timezone.utc)
    elif total_paid > 0:
        billing.status = BillingStatus.PARTIAL
    else:
        billing.status = BillingStatus.GENERATED


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


# ============ BILLING ENDPOINTS ============

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
    """List billing records with payment history"""
    if not current_user.is_admin and not current_user.can_view_costs:
        raise HTTPException(status_code=403, detail="Not authorized to view billing")
    
    query = select(Billing).options(
        selectinload(Billing.order).selectinload(Order.patient),
        selectinload(Billing.order).selectinload(Order.ipd),
        selectinload(Billing.payments).selectinload(Payment.recorder)
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
        
        # Get adjustments total
        adjustments_total = await get_billing_adjustments_total(billing.id, db)
        effective_amount = billing.total_amount + adjustments_total
        outstanding = max(Decimal(0), effective_amount - billing.paid_amount)
        
        # Build payment responses
        payments = [
            PaymentResponse(
                id=p.id,
                payment_number=p.payment_number,
                billing_id=p.billing_id,
                amount=p.amount,
                payment_mode=p.payment_mode.value if hasattr(p.payment_mode, 'value') else str(p.payment_mode),
                payment_date=p.payment_date,
                payment_reference=p.payment_reference,
                notes=p.notes,
                recorded_by=p.recorded_by,
                recorded_at=p.recorded_at,
                recorder_name=p.recorder.name if p.recorder else None
            ) for p in billing.payments
        ]
        
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
            outstanding_amount=outstanding,
            payment_date=billing.payment_date,
            payment_reference=billing.payment_reference,
            generated_at=billing.generated_at,
            patient_uhid=billing.order.patient.uhid if billing.order and billing.order.patient else None,
            patient_name=billing.order.patient.name if billing.order and billing.order.patient else None,
            ipd_number=billing.order.ipd.ipd_number if billing.order and billing.order.ipd else None,
            items=[BillingItemResponse.model_validate(i) for i in items],
            payments=payments,
            total_adjustments=adjustments_total,
            effective_amount=effective_amount
        ))
    
    return response


@router.get("/billing/{billing_id}", response_model=BillingResponse)
async def get_billing(
    billing_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get billing details with full payment history"""
    if not current_user.is_admin and not current_user.can_view_costs:
        raise HTTPException(status_code=403, detail="Not authorized to view billing")
    
    result = await db.execute(
        select(Billing).options(
            selectinload(Billing.order).selectinload(Order.patient),
            selectinload(Billing.order).selectinload(Order.ipd),
            selectinload(Billing.payments).selectinload(Payment.recorder)
        ).where(Billing.id == billing_id)
    )
    billing = result.scalar_one_or_none()
    
    if not billing:
        raise HTTPException(status_code=404, detail="Billing not found")
    
    items_result = await db.execute(
        select(BillingItem).where(BillingItem.billing_id == billing.id)
    )
    items = items_result.scalars().all()
    
    # Get adjustments total
    adjustments_total = await get_billing_adjustments_total(billing.id, db)
    effective_amount = billing.total_amount + adjustments_total
    outstanding = max(Decimal(0), effective_amount - billing.paid_amount)
    
    # Build payment responses
    payments = [
        PaymentResponse(
            id=p.id,
            payment_number=p.payment_number,
            billing_id=p.billing_id,
            amount=p.amount,
            payment_mode=p.payment_mode.value if hasattr(p.payment_mode, 'value') else str(p.payment_mode),
            payment_date=p.payment_date,
            payment_reference=p.payment_reference,
            notes=p.notes,
            recorded_by=p.recorded_by,
            recorded_at=p.recorded_at,
            recorder_name=p.recorder.name if p.recorder else None
        ) for p in billing.payments
    ]
    
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
        outstanding_amount=outstanding,
        payment_date=billing.payment_date,
        payment_reference=billing.payment_reference,
        generated_at=billing.generated_at,
        patient_uhid=billing.order.patient.uhid if billing.order and billing.order.patient else None,
        patient_name=billing.order.patient.name if billing.order and billing.order.patient else None,
        ipd_number=billing.order.ipd.ipd_number if billing.order and billing.order.ipd else None,
        items=[BillingItemResponse.model_validate(i) for i in items],
        payments=payments,
        total_adjustments=adjustments_total,
        effective_amount=effective_amount
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


# ============ PAYMENT ENDPOINTS ============

@router.post("/billing/payments", response_model=PaymentResponse)
async def record_payment(
    data: PaymentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Record a payment against a billing.
    Supports partial payments - multiple payments per billing allowed.
    Original billing record is never modified.
    """
    if not current_user.is_admin and not current_user.can_view_costs:
        raise HTTPException(status_code=403, detail="Not authorized to record payments")
    
    # Get billing
    result = await db.execute(select(Billing).where(Billing.id == data.billing_id))
    billing = result.scalar_one_or_none()
    
    if not billing:
        raise HTTPException(status_code=404, detail="Billing not found")
    
    if data.amount <= 0:
        raise HTTPException(status_code=400, detail="Payment amount must be positive")
    
    # Get adjustments total
    adjustments_total = await get_billing_adjustments_total(billing.id, db)
    effective_amount = billing.total_amount + adjustments_total
    outstanding = max(Decimal(0), effective_amount - billing.paid_amount)
    
    if data.amount > outstanding:
        raise HTTPException(
            status_code=400, 
            detail=f"Payment amount ({data.amount}) exceeds outstanding amount ({outstanding})"
        )
    
    # Create payment record
    payment_number = await generate_payment_number(db)
    payment = Payment(
        payment_number=payment_number,
        billing_id=billing.id,
        amount=data.amount,
        payment_mode=PaymentMode(data.payment_mode.value),
        payment_reference=data.payment_reference,
        notes=data.notes,
        recorded_by=current_user.id
    )
    db.add(payment)
    await db.flush()
    
    # Update billing status
    await update_billing_status(billing.id, db)
    
    await db.commit()
    
    # Reload to get recorder relationship
    result = await db.execute(
        select(Payment)
        .options(selectinload(Payment.recorder))
        .where(Payment.id == payment.id)
    )
    payment = result.scalar_one()
    
    return PaymentResponse(
        id=payment.id,
        payment_number=payment.payment_number,
        billing_id=payment.billing_id,
        amount=payment.amount,
        payment_mode=payment.payment_mode.value if hasattr(payment.payment_mode, 'value') else str(payment.payment_mode),
        payment_date=payment.payment_date,
        payment_reference=payment.payment_reference,
        notes=payment.notes,
        recorded_by=payment.recorded_by,
        recorded_at=payment.recorded_at,
        recorder_name=payment.recorder.name if payment.recorder else None
    )


@router.get("/billing/{billing_id}/payments", response_model=List[PaymentResponse])
async def get_billing_payments(
    billing_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all payments for a billing"""
    if not current_user.is_admin and not current_user.can_view_costs:
        raise HTTPException(status_code=403, detail="Not authorized to view payments")
    
    result = await db.execute(
        select(Payment)
        .options(selectinload(Payment.recorder))
        .where(Payment.billing_id == billing_id)
        .order_by(Payment.recorded_at.desc())
    )
    payments = result.scalars().all()
    
    return [
        PaymentResponse(
            id=p.id,
            payment_number=p.payment_number,
            billing_id=p.billing_id,
            amount=p.amount,
            payment_mode=p.payment_mode.value if hasattr(p.payment_mode, 'value') else str(p.payment_mode),
            payment_date=p.payment_date,
            payment_reference=p.payment_reference,
            notes=p.notes,
            recorded_by=p.recorded_by,
            recorded_at=p.recorded_at,
            recorder_name=p.recorder.name if p.recorder else None
        ) for p in payments
    ]


@router.get("/billing/{billing_id}/summary", response_model=PaymentSummary)
async def get_billing_payment_summary(
    billing_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get payment summary for a billing"""
    if not current_user.is_admin and not current_user.can_view_costs:
        raise HTTPException(status_code=403, detail="Not authorized to view billing")
    
    result = await db.execute(select(Billing).where(Billing.id == billing_id))
    billing = result.scalar_one_or_none()
    
    if not billing:
        raise HTTPException(status_code=404, detail="Billing not found")
    
    # Get adjustments
    adjustments_total = await get_billing_adjustments_total(billing_id, db)
    
    # Get payment count
    payments_result = await db.execute(
        select(func.count(Payment.id)).where(Payment.billing_id == billing_id)
    )
    payment_count = payments_result.scalar() or 0
    
    effective_amount = billing.total_amount + adjustments_total
    outstanding = max(Decimal(0), effective_amount - billing.paid_amount)
    
    return PaymentSummary(
        billing_id=billing.id,
        billing_number=billing.billing_number,
        total_amount=billing.total_amount,
        total_paid=billing.paid_amount,
        total_adjustments=adjustments_total,
        effective_amount=effective_amount,
        outstanding_amount=outstanding,
        status=billing.status.value if hasattr(billing.status, 'value') else str(billing.status),
        payment_count=payment_count
    )


# ============ LEGACY PAYMENT ENDPOINT ============
# Keep for backwards compatibility

@router.put("/billing/{billing_id}/payment")
async def update_billing_payment_legacy(
    billing_id: int,
    amount: Decimal,
    reference: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Legacy payment endpoint - creates a payment record instead of direct update.
    Original billing record is NEVER modified directly.
    """
    result = await db.execute(select(Billing).where(Billing.id == billing_id))
    billing = result.scalar_one_or_none()
    
    if not billing:
        raise HTTPException(status_code=404, detail="Billing not found")
    
    # Get current paid amount
    payments_result = await db.execute(
        select(func.sum(Payment.amount)).where(Payment.billing_id == billing_id)
    )
    current_paid = payments_result.scalar() or Decimal(0)
    
    # Calculate the additional payment needed
    payment_amount = amount - current_paid
    
    if payment_amount <= 0:
        # Just update status
        await update_billing_status(billing_id, db)
        await db.commit()
        return {"message": "Payment recorded successfully"}
    
    # Create payment record for the difference
    payment_number = await generate_payment_number(db)
    payment = Payment(
        payment_number=payment_number,
        billing_id=billing.id,
        amount=payment_amount,
        payment_mode=PaymentMode.OTHER,
        payment_reference=reference,
        notes="Legacy payment",
        recorded_by=admin.id
    )
    db.add(payment)
    
    await update_billing_status(billing_id, db)
    await db.commit()
    
    return {"message": "Payment recorded successfully"}


# ============ PDF INVOICE GENERATION ============

@router.get("/billing/{billing_id}/invoice")
async def generate_invoice_pdf(
    billing_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Generate PDF invoice for a billing.
    Includes itemized list, payments received, and outstanding balance.
    """
    if not current_user.is_admin and not current_user.can_view_costs:
        raise HTTPException(status_code=403, detail="Not authorized to view billing")
    
    # Get billing with all relationships
    result = await db.execute(
        select(Billing).options(
            selectinload(Billing.order).selectinload(Order.patient),
            selectinload(Billing.order).selectinload(Order.ipd),
            selectinload(Billing.payments).selectinload(Payment.recorder)
        ).where(Billing.id == billing_id)
    )
    billing = result.scalar_one_or_none()
    
    if not billing:
        raise HTTPException(status_code=404, detail="Billing not found")
    
    # Get billing items
    items_result = await db.execute(
        select(BillingItem).where(BillingItem.billing_id == billing.id)
    )
    items = items_result.scalars().all()
    
    # Get adjustments
    adj_result = await db.execute(
        select(BillingAdjustment).where(BillingAdjustment.original_billing_id == billing_id)
    )
    adjustments = adj_result.scalars().all()
    adjustments_total = sum(a.adjustment_amount for a in adjustments)
    
    effective_amount = billing.total_amount + adjustments_total
    outstanding = max(Decimal(0), effective_amount - billing.paid_amount)
    
    # Generate HTML invoice (will convert to PDF-friendly format)
    patient = billing.order.patient if billing.order else None
    ipd = billing.order.ipd if billing.order else None
    
    html_content = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Invoice - {billing.billing_number}</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: Arial, sans-serif; font-size: 12px; line-height: 1.4; color: #333; padding: 20px; }}
        .header {{ text-align: center; margin-bottom: 20px; border-bottom: 2px solid #f97316; padding-bottom: 15px; }}
        .hospital-name {{ font-size: 24px; font-weight: bold; color: #f97316; }}
        .invoice-title {{ font-size: 16px; margin-top: 5px; color: #666; }}
        .info-section {{ display: flex; justify-content: space-between; margin-bottom: 20px; }}
        .info-box {{ width: 48%; }}
        .info-box h3 {{ background: #f5f5f5; padding: 8px; margin-bottom: 10px; border-left: 3px solid #f97316; }}
        .info-row {{ display: flex; margin-bottom: 5px; }}
        .info-label {{ width: 120px; font-weight: bold; color: #666; }}
        .info-value {{ flex: 1; }}
        table {{ width: 100%; border-collapse: collapse; margin-bottom: 20px; }}
        th {{ background: #f97316; color: white; padding: 10px 8px; text-align: left; }}
        td {{ padding: 8px; border-bottom: 1px solid #ddd; }}
        tr:nth-child(even) {{ background: #f9f9f9; }}
        .amount {{ text-align: right; }}
        .summary {{ width: 300px; margin-left: auto; }}
        .summary-row {{ display: flex; justify-content: space-between; padding: 5px 0; border-bottom: 1px solid #eee; }}
        .summary-row.total {{ font-weight: bold; font-size: 14px; border-top: 2px solid #333; margin-top: 5px; }}
        .summary-row.outstanding {{ color: #dc2626; font-weight: bold; }}
        .summary-row.paid {{ color: #16a34a; }}
        .payments {{ margin-top: 20px; }}
        .payments h3 {{ margin-bottom: 10px; color: #f97316; }}
        .payment-item {{ display: flex; justify-content: space-between; padding: 5px 10px; background: #f5f5f5; margin-bottom: 5px; border-radius: 4px; }}
        .adjustments {{ margin-top: 15px; padding: 10px; background: #fef3cd; border-radius: 4px; }}
        .adjustments h4 {{ color: #856404; margin-bottom: 5px; }}
        .footer {{ margin-top: 30px; text-align: center; font-size: 10px; color: #999; border-top: 1px solid #ddd; padding-top: 10px; }}
        .status-badge {{ display: inline-block; padding: 3px 10px; border-radius: 12px; font-size: 11px; font-weight: bold; }}
        .status-PAID {{ background: #dcfce7; color: #16a34a; }}
        .status-PARTIAL {{ background: #fef9c3; color: #ca8a04; }}
        .status-GENERATED, .status-PENDING {{ background: #fee2e2; color: #dc2626; }}
    </style>
</head>
<body>
    <div class="header">
        <div class="hospital-name">MTH Hospital</div>
        <div class="invoice-title">TAX INVOICE</div>
    </div>
    
    <div class="info-section">
        <div class="info-box">
            <h3>Invoice Details</h3>
            <div class="info-row">
                <span class="info-label">Invoice No:</span>
                <span class="info-value">{billing.billing_number}</span>
            </div>
            <div class="info-row">
                <span class="info-label">Date:</span>
                <span class="info-value">{billing.generated_at.strftime('%d-%b-%Y %H:%M')}</span>
            </div>
            <div class="info-row">
                <span class="info-label">Order ID:</span>
                <span class="info-value">{billing.order.order_number if billing.order else billing.order_id}</span>
            </div>
            <div class="info-row">
                <span class="info-label">Status:</span>
                <span class="info-value">
                    <span class="status-badge status-{billing.status.value if hasattr(billing.status, 'value') else billing.status}">
                        {billing.status.value if hasattr(billing.status, 'value') else billing.status}
                    </span>
                </span>
            </div>
        </div>
        <div class="info-box">
            <h3>Patient Details</h3>
            <div class="info-row">
                <span class="info-label">Name:</span>
                <span class="info-value">{patient.name if patient else 'N/A'}</span>
            </div>
            <div class="info-row">
                <span class="info-label">UHID:</span>
                <span class="info-value">{patient.uhid if patient else 'N/A'}</span>
            </div>
            <div class="info-row">
                <span class="info-label">IPD No:</span>
                <span class="info-value">{ipd.ipd_number if ipd else 'N/A'}</span>
            </div>
            <div class="info-row">
                <span class="info-label">Phone:</span>
                <span class="info-value">{patient.phone if patient and patient.phone else 'N/A'}</span>
            </div>
        </div>
    </div>
    
    <h3 style="margin-bottom: 10px; color: #f97316;">Itemized Charges</h3>
    <table>
        <thead>
            <tr>
                <th style="width: 40px;">#</th>
                <th>Item</th>
                <th style="width: 80px;">Code</th>
                <th style="width: 60px;">Unit</th>
                <th style="width: 60px;" class="amount">Qty</th>
                <th style="width: 80px;" class="amount">Rate</th>
                <th style="width: 100px;" class="amount">Amount</th>
            </tr>
        </thead>
        <tbody>
"""
    
    for idx, item in enumerate(items, 1):
        html_content += f"""
            <tr>
                <td>{idx}</td>
                <td>{item.item_name}</td>
                <td>{item.item_code}</td>
                <td>{item.unit}</td>
                <td class="amount">{item.quantity_dispatched}</td>
                <td class="amount">₹{item.cost_per_unit:,.2f}</td>
                <td class="amount">₹{item.line_amount:,.2f}</td>
            </tr>
"""
    
    html_content += f"""
        </tbody>
    </table>
    
    <div class="summary">
        <div class="summary-row">
            <span>Subtotal:</span>
            <span>₹{billing.total_amount:,.2f}</span>
        </div>
"""
    
    if adjustments_total != 0:
        html_content += f"""
        <div class="summary-row" style="color: #ca8a04;">
            <span>Adjustments:</span>
            <span>₹{adjustments_total:,.2f}</span>
        </div>
"""
    
    html_content += f"""
        <div class="summary-row total">
            <span>Total Amount:</span>
            <span>₹{effective_amount:,.2f}</span>
        </div>
        <div class="summary-row paid">
            <span>Paid:</span>
            <span>₹{billing.paid_amount:,.2f}</span>
        </div>
        <div class="summary-row outstanding">
            <span>Outstanding:</span>
            <span>₹{outstanding:,.2f}</span>
        </div>
    </div>
"""
    
    # Add adjustments section if any
    if adjustments:
        html_content += """
    <div class="adjustments">
        <h4>Billing Adjustments</h4>
"""
        for adj in adjustments:
            adj_type = "Credit" if adj.is_credit else "Deduction"
            html_content += f"""
        <div style="display: flex; justify-content: space-between; margin: 3px 0;">
            <span>{adj.adjustment_number} - {adj_type}: {adj.reason or 'N/A'}</span>
            <span>₹{adj.adjustment_amount:,.2f}</span>
        </div>
"""
        html_content += "    </div>\n"
    
    # Add payments section
    if billing.payments:
        html_content += """
    <div class="payments">
        <h3>Payment History</h3>
"""
        for payment in billing.payments:
            mode = payment.payment_mode.value if hasattr(payment.payment_mode, 'value') else str(payment.payment_mode)
            html_content += f"""
        <div class="payment-item">
            <span>{payment.payment_number} | {mode} | {payment.payment_date.strftime('%d-%b-%Y %H:%M')}</span>
            <span style="color: #16a34a; font-weight: bold;">₹{payment.amount:,.2f}</span>
        </div>
"""
        html_content += "    </div>\n"
    
    html_content += f"""
    <div class="footer">
        <p>This is a computer-generated invoice.</p>
        <p>Generated on {datetime.now(timezone.utc).strftime('%d-%b-%Y %H:%M:%S')} UTC</p>
    </div>
</body>
</html>
"""
    
    # Return as HTML (can be printed as PDF from browser)
    return StreamingResponse(
        io.BytesIO(html_content.encode('utf-8')),
        media_type="text/html",
        headers={
            "Content-Disposition": f"inline; filename=invoice_{billing.billing_number}.html"
        }
    )


# ============ ADMIN BILLING DASHBOARD STATS ============

@router.get("/billing/dashboard/today")
async def get_today_billing_stats(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Get today's billing and payment statistics for admin dashboard"""
    today = datetime.now(timezone.utc).date()
    
    # Today's billing
    billing_result = await db.execute(
        select(
            func.count(Billing.id),
            func.sum(Billing.total_amount)
        ).where(func.date(Billing.generated_at) == today)
    )
    billing_count, billing_total = billing_result.one()
    
    # Today's payments
    payment_result = await db.execute(
        select(
            func.count(Payment.id),
            func.sum(Payment.amount)
        ).where(func.date(Payment.recorded_at) == today)
    )
    payment_count, payment_total = payment_result.one()
    
    # Outstanding billing (all time) - includes both PENDING and GENERATED status
    outstanding_result = await db.execute(
        select(
            func.count(Billing.id),
            func.sum(Billing.total_amount - Billing.paid_amount)
        ).where(Billing.status.in_([BillingStatus.PENDING, BillingStatus.GENERATED, BillingStatus.PARTIAL]))
    )
    outstanding_count, outstanding_total = outstanding_result.one()
    
    # Department-wise billing today
    dept_result = await db.execute(
        select(
            Department.name,
            func.count(Billing.id),
            func.sum(Billing.total_amount)
        )
        .join(Department, Billing.dispatching_department_id == Department.id)
        .where(func.date(Billing.generated_at) == today)
        .group_by(Department.name)
    )
    dept_billing = [
        {"department": name, "count": count, "amount": float(amount or 0)}
        for name, count, amount in dept_result.all()
    ]
    
    return {
        "date": today.isoformat(),
        "billing_today": {
            "count": billing_count or 0,
            "amount": float(billing_total or 0)
        },
        "payments_today": {
            "count": payment_count or 0,
            "amount": float(payment_total or 0)
        },
        "outstanding": {
            "count": outstanding_count or 0,
            "amount": float(outstanding_total or 0)
        },
        "department_billing": dept_billing
    }
