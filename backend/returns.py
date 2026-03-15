"""
Return Order Workflow - Complete return management with billing adjustments

Key Rules:
1. Billing records are NEVER modified or deleted once generated
2. Returns create separate billing adjustment records
3. For unpaid orders: Create negative billing adjustment
4. For paid orders: Create credit adjustment record
5. Full audit traceability through adjustments
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, timezone
from decimal import Decimal
from pydantic import BaseModel, ConfigDict

from database import get_db
from models import (
    Order, OrderItem, Item, Billing, BillingItem, BillingStatus,
    BillingAdjustment, BillingAdjustmentItem, BillingAdjustmentType,
    OrderType, OrderStatus, OrderItemStatus, Patient, IPD, Department,
    ReturnReason
)
from schemas import (
    OrderResponse, ReturnOrderCreate, ReturnableItemResponse,
    BillingAdjustmentResponse, BillingAdjustmentItemResponse
)
from auth import get_current_user, get_admin_user, get_user_departments

router = APIRouter(prefix="/returns", tags=["Returns"])


# ============ SCHEMAS ============

class ReturnableOrderResponse(BaseModel):
    """Completed orders that can have returns created"""
    model_config = ConfigDict(from_attributes=True)
    
    order_id: int
    order_number: str
    completed_at: datetime
    patient_name: Optional[str] = None
    patient_uhid: Optional[str] = None
    ipd_number: Optional[str] = None
    total_items: int
    billing_status: Optional[str] = None
    billing_amount: Optional[Decimal] = None


class ReturnSummaryResponse(BaseModel):
    """Summary of return for a completed order"""
    order_id: int
    order_number: str
    patient_name: Optional[str] = None
    billing_id: Optional[int] = None
    billing_number: Optional[str] = None
    billing_status: Optional[str] = None
    billing_total: Optional[Decimal] = None
    billing_paid: Optional[Decimal] = None
    items: List[ReturnableItemResponse]
    total_returnable_value: Decimal


# ============ HELPER FUNCTIONS ============

async def generate_adjustment_number(db: AsyncSession) -> str:
    """Generate unique adjustment number"""
    date_str = datetime.now(timezone.utc).strftime("%Y%m%d")
    result = await db.execute(
        select(func.count(BillingAdjustment.id)).where(
            BillingAdjustment.adjustment_number.like(f"ADJ-{date_str}%")
        )
    )
    count = result.scalar() + 1
    return f"ADJ-{date_str}-{count:04d}"


async def generate_return_order_number(db: AsyncSession) -> str:
    """Generate unique return order number"""
    date_str = datetime.now(timezone.utc).strftime("%Y%m%d")
    result = await db.execute(
        select(func.count(Order.id)).where(
            Order.order_number.like(f"RET-{date_str}%")
        )
    )
    count = result.scalar() + 1
    return f"RET-{date_str}-{count:04d}"


async def get_already_returned_quantities(order_id: int, db: AsyncSession) -> dict:
    """Get quantities already returned for each order item"""
    # Find all return orders for this original order
    result = await db.execute(
        select(Order)
        .options(selectinload(Order.items))
        .where(
            Order.original_order_id == order_id,
            Order.order_type == OrderType.RETURN,
            Order.status != OrderStatus.CANCELLED
        )
    )
    return_orders = result.scalars().all()
    
    # Sum up returned quantities by original_order_item_id
    returned_qty = {}
    for return_order in return_orders:
        for item in return_order.items:
            if item.original_order_item_id:
                returned_qty[item.original_order_item_id] = (
                    returned_qty.get(item.original_order_item_id, 0) + 
                    item.quantity_requested
                )
    return returned_qty


# ============ API ENDPOINTS ============

@router.get("/returnable-orders", response_model=List[ReturnableOrderResponse])
async def get_returnable_orders(
    skip: int = 0,
    limit: int = 50,
    search: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get list of completed orders that can have returns created.
    Only shows orders from user's department (or all for admins).
    """
    user_depts = get_user_departments(current_user)
    
    # Build query for completed orders
    query = (
        select(Order, Billing, Patient, IPD)
        .outerjoin(Billing, Billing.order_id == Order.id)
        .outerjoin(Patient, Order.patient_id == Patient.id)
        .outerjoin(IPD, Order.ipd_id == IPD.id)
        .where(
            Order.status == OrderStatus.COMPLETED,
            Order.order_type == OrderType.REGULAR
        )
    )
    
    # Department filter for non-admins
    if not current_user.is_admin:
        query = query.where(Order.ordering_department_id.in_(user_depts))
    
    # Search filter
    if search:
        query = query.where(
            (Order.order_number.ilike(f"%{search}%")) |
            (Patient.name.ilike(f"%{search}%")) |
            (Patient.uhid.ilike(f"%{search}%"))
        )
    
    query = query.order_by(Order.completed_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    
    orders = []
    for row in result.all():
        order, billing, patient, ipd = row
        
        # Count items in the order
        items_result = await db.execute(
            select(func.count(OrderItem.id)).where(OrderItem.order_id == order.id)
        )
        item_count = items_result.scalar() or 0
        
        orders.append(ReturnableOrderResponse(
            order_id=order.id,
            order_number=order.order_number,
            completed_at=order.completed_at,
            patient_name=patient.name if patient else None,
            patient_uhid=patient.uhid if patient else None,
            ipd_number=ipd.ipd_number if ipd else None,
            total_items=item_count,
            billing_status=billing.status.value if billing and hasattr(billing.status, 'value') else (str(billing.status) if billing else None),
            billing_amount=billing.total_amount if billing else None
        ))
    
    return orders


@router.get("/order/{order_id}/returnable-items", response_model=ReturnSummaryResponse)
async def get_returnable_items(
    order_id: int,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get items that can be returned from a completed order.
    Shows quantities already received minus any already returned.
    """
    # Get the order with all relationships
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.item),
            selectinload(Order.patient),
            selectinload(Order.ipd),
            selectinload(Order.billing)
        )
        .where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if order.status != OrderStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Only completed orders can have returns")
    
    if order.order_type != OrderType.REGULAR:
        raise HTTPException(status_code=400, detail="Cannot create return from a return order")
    
    # Check permission
    user_depts = get_user_departments(current_user)
    if not current_user.is_admin and order.ordering_department_id not in user_depts:
        raise HTTPException(status_code=403, detail="Not authorized to create return for this order")
    
    # Get already returned quantities
    returned_qty = await get_already_returned_quantities(order_id, db)
    
    # Build returnable items list
    items = []
    total_returnable_value = Decimal(0)
    
    for order_item in order.items:
        if order_item.status == OrderItemStatus.CANCELLED:
            continue
        
        already_returned = returned_qty.get(order_item.id, 0)
        returnable = order_item.quantity_received - already_returned
        
        if returnable > 0:
            cost = order_item.item.cost_per_unit or Decimal(0)
            total_returnable_value += cost * returnable
            
            items.append(ReturnableItemResponse(
                order_item_id=order_item.id,
                item_id=order_item.item_id,
                item_name=order_item.item.name,
                item_code=order_item.item.code,
                unit=order_item.item.unit,
                quantity_dispatched=order_item.quantity_dispatched,
                quantity_received=order_item.quantity_received,
                quantity_already_returned=already_returned,
                quantity_returnable=returnable,
                cost_per_unit=cost,
                billing_id=order.billing.id if order.billing else None,
                billing_paid=(
                    order.billing.status == BillingStatus.PAID 
                    if order.billing else False
                )
            ))
    
    billing = order.billing
    return ReturnSummaryResponse(
        order_id=order.id,
        order_number=order.order_number,
        patient_name=order.patient.name if order.patient else None,
        billing_id=billing.id if billing else None,
        billing_number=billing.billing_number if billing else None,
        billing_status=billing.status.value if billing and hasattr(billing.status, 'value') else (str(billing.status) if billing else None),
        billing_total=billing.total_amount if billing else None,
        billing_paid=billing.paid_amount if billing else None,
        items=items,
        total_returnable_value=total_returnable_value
    )


@router.post("/create", response_model=OrderResponse)
async def create_return_order(
    data: ReturnOrderCreate,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Create a return order from a completed regular order.
    This creates:
    1. A new RETURN type order
    2. A billing adjustment (deduction for unpaid, credit for paid orders)
    """
    # Validate original order
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.item),
            selectinload(Order.patient),
            selectinload(Order.ipd),
            selectinload(Order.billing)
        )
        .where(Order.id == data.original_order_id)
    )
    original_order = result.scalar_one_or_none()
    
    if not original_order:
        raise HTTPException(status_code=404, detail="Original order not found")
    
    if original_order.status != OrderStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Only completed orders can have returns")
    
    if original_order.order_type != OrderType.REGULAR:
        raise HTTPException(status_code=400, detail="Cannot create return from a return order")
    
    # Check permission
    user_depts = get_user_departments(current_user)
    if not current_user.is_admin and original_order.ordering_department_id not in user_depts:
        raise HTTPException(status_code=403, detail="Not authorized to create return for this order")
    
    # Validate items
    if not data.items:
        raise HTTPException(status_code=400, detail="Return order must have at least one item")
    
    # Get already returned quantities
    returned_qty = await get_already_returned_quantities(data.original_order_id, db)
    
    # Build map of original order items
    original_items = {item.id: item for item in original_order.items}
    
    # Validate each return item
    return_items_data = []
    total_return_amount = Decimal(0)
    
    for return_item in data.items:
        original_item = original_items.get(return_item.original_order_item_id)
        if not original_item:
            raise HTTPException(
                status_code=400, 
                detail=f"Original order item {return_item.original_order_item_id} not found"
            )
        
        already_returned = returned_qty.get(original_item.id, 0)
        max_returnable = original_item.quantity_received - already_returned
        
        if return_item.quantity_requested > max_returnable:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot return more than {max_returnable} of {original_item.item.name}"
            )
        
        if return_item.quantity_requested <= 0:
            continue
        
        cost = original_item.item.cost_per_unit or Decimal(0)
        line_amount = cost * return_item.quantity_requested
        total_return_amount += line_amount
        
        return_items_data.append({
            'original_item': original_item,
            'item': original_item.item,
            'quantity': return_item.quantity_requested,
            'return_reason': return_item.return_reason or data.return_reason,
            'line_amount': line_amount,
            'cost_per_unit': cost
        })
    
    if not return_items_data:
        raise HTTPException(status_code=400, detail="No valid items to return")
    
    # Create return order
    return_order_number = await generate_return_order_number(db)
    return_order = Order(
        order_number=return_order_number,
        order_type=OrderType.RETURN,
        original_order_id=original_order.id,
        return_reason=data.return_reason,
        patient_id=original_order.patient_id,
        ipd_id=original_order.ipd_id,
        ordering_department_id=current_user.primary_department_id,
        priority=original_order.priority,
        notes=data.notes,
        created_by=current_user.id
    )
    db.add(return_order)
    await db.flush()
    
    # Create return order items
    for item_data in return_items_data:
        return_order_item = OrderItem(
            order_id=return_order.id,
            item_id=item_data['item'].id,
            original_order_item_id=item_data['original_item'].id,
            quantity_requested=item_data['quantity'],
            return_reason=item_data['return_reason'],
            dispatching_department_id=item_data['original_item'].dispatching_department_id,
            notes=f"Return from order {original_order.order_number}"
        )
        db.add(return_order_item)
    
    # Create billing adjustment if there's a billing record
    if original_order.billing and total_return_amount > 0:
        billing = original_order.billing
        
        # Determine adjustment type
        is_credit = billing.status == BillingStatus.PAID
        adjustment_type = (
            BillingAdjustmentType.RETURN_CREDIT if is_credit 
            else BillingAdjustmentType.RETURN_DEDUCTION
        )
        
        # Create adjustment record
        adjustment_number = await generate_adjustment_number(db)
        adjustment = BillingAdjustment(
            adjustment_number=adjustment_number,
            original_billing_id=billing.id,
            return_order_id=return_order.id,
            adjustment_type=adjustment_type,
            adjustment_amount=-total_return_amount,  # Negative for returns
            reason=f"Return: {data.return_reason}",
            is_credit=is_credit,
            created_by=current_user.id
        )
        db.add(adjustment)
        await db.flush()
        
        # Create adjustment line items
        for item_data in return_items_data:
            adj_item = BillingAdjustmentItem(
                adjustment_id=adjustment.id,
                item_id=item_data['item'].id,
                item_name=item_data['item'].name,
                item_code=item_data['item'].code,
                unit=item_data['item'].unit,
                cost_per_unit=item_data['cost_per_unit'],
                quantity_returned=item_data['quantity'],
                line_amount=-item_data['line_amount']  # Negative
            )
            db.add(adj_item)
    
    await db.commit()
    
    # Reload return order with relationships
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.patient),
            selectinload(Order.ipd),
            selectinload(Order.ordering_department),
            selectinload(Order.creator),
            selectinload(Order.items).selectinload(OrderItem.item),
            selectinload(Order.items).selectinload(OrderItem.dispatching_department)
        )
        .where(Order.id == return_order.id)
    )
    return result.scalar_one()


@router.get("/billing-adjustments", response_model=List[BillingAdjustmentResponse])
async def list_billing_adjustments(
    billing_id: Optional[int] = None,
    return_order_id: Optional[int] = None,
    adjustment_type: Optional[str] = None,
    is_credit: Optional[bool] = None,
    skip: int = 0,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    List billing adjustments with filters.
    Only admins and users with cost view permission can see this.
    """
    if not current_user.is_admin and not current_user.can_view_costs:
        raise HTTPException(status_code=403, detail="Not authorized to view billing adjustments")
    
    query = select(BillingAdjustment)
    
    if billing_id:
        query = query.where(BillingAdjustment.original_billing_id == billing_id)
    if return_order_id:
        query = query.where(BillingAdjustment.return_order_id == return_order_id)
    if adjustment_type:
        query = query.where(BillingAdjustment.adjustment_type == adjustment_type)
    if is_credit is not None:
        query = query.where(BillingAdjustment.is_credit == is_credit)
    
    query = query.order_by(BillingAdjustment.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    adjustments = result.scalars().all()
    
    response = []
    for adj in adjustments:
        # Get adjustment items
        items_result = await db.execute(
            select(BillingAdjustmentItem).where(
                BillingAdjustmentItem.adjustment_id == adj.id
            )
        )
        items = items_result.scalars().all()
        
        response.append(BillingAdjustmentResponse(
            id=adj.id,
            adjustment_number=adj.adjustment_number,
            original_billing_id=adj.original_billing_id,
            return_order_id=adj.return_order_id,
            adjustment_type=adj.adjustment_type.value if hasattr(adj.adjustment_type, 'value') else str(adj.adjustment_type),
            adjustment_amount=adj.adjustment_amount,
            reason=adj.reason,
            is_credit=adj.is_credit,
            credit_utilized=adj.credit_utilized,
            created_at=adj.created_at,
            items=[BillingAdjustmentItemResponse(
                id=item.id,
                item_name=item.item_name,
                item_code=item.item_code,
                unit=item.unit,
                cost_per_unit=item.cost_per_unit,
                quantity_returned=item.quantity_returned,
                line_amount=item.line_amount
            ) for item in items]
        ))
    
    return response


@router.get("/billing/{billing_id}/effective-amount")
async def get_billing_effective_amount(
    billing_id: int,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get the effective billing amount after all adjustments.
    Original billing + Sum of all adjustments = Effective amount
    """
    if not current_user.is_admin and not current_user.can_view_costs:
        raise HTTPException(status_code=403, detail="Not authorized to view billing")
    
    # Get billing
    result = await db.execute(select(Billing).where(Billing.id == billing_id))
    billing = result.scalar_one_or_none()
    if not billing:
        raise HTTPException(status_code=404, detail="Billing not found")
    
    # Get sum of adjustments
    adj_result = await db.execute(
        select(func.sum(BillingAdjustment.adjustment_amount)).where(
            BillingAdjustment.original_billing_id == billing_id
        )
    )
    total_adjustments = adj_result.scalar() or Decimal(0)
    
    # Get credit adjustments (paid orders)
    credit_result = await db.execute(
        select(func.sum(BillingAdjustment.adjustment_amount)).where(
            BillingAdjustment.original_billing_id == billing_id,
            BillingAdjustment.is_credit.is_(True)
        )
    )
    total_credits = abs(credit_result.scalar() or Decimal(0))
    
    # Get deduction adjustments (unpaid orders)
    deduction_result = await db.execute(
        select(func.sum(BillingAdjustment.adjustment_amount)).where(
            BillingAdjustment.original_billing_id == billing_id,
            BillingAdjustment.is_credit.is_(False)
        )
    )
    total_deductions = abs(deduction_result.scalar() or Decimal(0))
    
    effective_amount = billing.total_amount + total_adjustments
    
    return {
        "billing_id": billing_id,
        "billing_number": billing.billing_number,
        "original_amount": billing.total_amount,
        "total_adjustments": total_adjustments,
        "total_credits": total_credits,
        "total_deductions": total_deductions,
        "effective_amount": effective_amount,
        "paid_amount": billing.paid_amount,
        "outstanding_amount": max(Decimal(0), effective_amount - billing.paid_amount),
        "status": billing.status.value if hasattr(billing.status, 'value') else str(billing.status)
    }


@router.get("/orders", response_model=List[OrderResponse])
async def list_return_orders(
    skip: int = 0,
    limit: int = 50,
    status: Optional[str] = None,
    original_order_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    List return orders with optional filters.
    """
    user_depts = get_user_departments(current_user)
    
    query = select(Order).options(
        selectinload(Order.patient),
        selectinload(Order.ipd),
        selectinload(Order.ordering_department),
        selectinload(Order.creator),
        selectinload(Order.items).selectinload(OrderItem.item),
        selectinload(Order.items).selectinload(OrderItem.dispatching_department)
    ).where(Order.order_type == OrderType.RETURN)
    
    if not current_user.is_admin:
        query = query.where(Order.ordering_department_id.in_(user_depts))
    
    if status:
        query = query.where(Order.status == status)
    if original_order_id:
        query = query.where(Order.original_order_id == original_order_id)
    
    query = query.order_by(Order.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()
