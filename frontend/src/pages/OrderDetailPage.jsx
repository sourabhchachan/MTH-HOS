import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getOrder, cancelOrder } from '../api';
import { useAuth } from '../AuthContext';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { 
  ArrowLeft, Package, AlertTriangle, Clock, CheckCircle2,
  XCircle, User, Building2, RotateCcw, Link2
} from 'lucide-react';

const statusConfig = {
  CREATED: { label: 'Created', icon: Clock, class: 'status-pending' },
  PARTIALLY_DISPATCHED: { label: 'Partially Dispatched', icon: Package, class: 'status-dispatched' },
  FULLY_DISPATCHED: { label: 'Fully Dispatched', icon: Package, class: 'status-dispatched' },
  COMPLETED: { label: 'Completed', icon: CheckCircle2, class: 'status-completed' },
  CANCELLED: { label: 'Cancelled', icon: XCircle, class: 'status-cancelled' },
};

const itemStatusConfig = {
  PENDING_DISPATCH: { label: 'Pending', class: 'bg-amber-500/20 text-amber-400' },
  PARTIALLY_DISPATCHED: { label: 'Partial', class: 'bg-blue-500/20 text-blue-400' },
  FULLY_DISPATCHED: { label: 'Dispatched', class: 'bg-blue-500/20 text-blue-400' },
  RECEIVED: { label: 'Received', class: 'bg-emerald-500/20 text-emerald-400' },
  CANCELLED: { label: 'Cancelled', class: 'bg-red-500/20 text-red-400' },
};

const OrderDetailPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);
  const [cancelDialogOpen, setCancelDialogOpen] = useState(false);
  const [cancelReason, setCancelReason] = useState('');
  const [cancelling, setCancelling] = useState(false);

  useEffect(() => {
    loadOrder();
  }, [id]);

  const loadOrder = async () => {
    try {
      const response = await getOrder(id);
      setOrder(response.data);
    } catch (error) {
      console.error('Failed to load order:', error);
      navigate('/orders');
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = async () => {
    if (!cancelReason.trim()) {
      alert('Please provide a cancellation reason');
      return;
    }

    setCancelling(true);
    try {
      await cancelOrder(order.id, cancelReason);
      setCancelDialogOpen(false);
      loadOrder();
    } catch (error) {
      alert(error.response?.data?.detail || 'Failed to cancel order');
    } finally {
      setCancelling(false);
    }
  };

  const formatDateTime = (dateString) => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleString([], { 
      month: 'short', day: 'numeric', 
      hour: '2-digit', minute: '2-digit' 
    });
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full" />
      </div>
    );
  }

  if (!order) return null;

  const config = statusConfig[order.status] || statusConfig.CREATED;
  const StatusIcon = config.icon;
  const canCancel = !['COMPLETED', 'CANCELLED'].includes(order.status);
  const canCreateReturn = order.status === 'COMPLETED' && order.order_type === 'REGULAR';
  const isReturnOrder = order.order_type === 'RETURN';

  return (
    <div className="min-h-screen bg-background pb-6 safe-area-top">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-background/95 backdrop-blur border-b border-border px-4 py-3">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate('/orders')}>
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div className="flex-1">
            <h1 className="font-semibold text-lg">{order.order_number}</h1>
            <p className="text-xs text-muted-foreground">{formatDateTime(order.created_at)}</p>
          </div>
          <Badge className={`${config.class} border`}>
            <StatusIcon className="w-3 h-3 mr-1" />
            {config.label}
          </Badge>
        </div>
      </header>

      <main className="px-4 py-4 space-y-4">
        {/* Order Info */}
        <Card className="bg-card/50">
          <CardContent className="p-4 space-y-3">
            {/* Return Order Indicator */}
            {isReturnOrder && (
              <div className="flex items-center gap-2 p-2 rounded-lg bg-orange-500/10 border border-orange-500/30">
                <RotateCcw className="w-4 h-4 text-orange-500" />
                <span className="text-sm font-medium text-orange-500">Return Order</span>
                {order.original_order_id && (
                  <Button
                    variant="ghost"
                    size="sm"
                    className="ml-auto h-6 text-xs"
                    onClick={() => navigate(`/orders/${order.original_order_id}`)}
                    data-testid="view-original-order-btn"
                  >
                    <Link2 className="w-3 h-3 mr-1" />
                    View Original
                  </Button>
                )}
              </div>
            )}

            {/* Return Reason */}
            {isReturnOrder && order.return_reason && (
              <div className="p-2 rounded-lg bg-muted/50">
                <p className="text-sm text-muted-foreground mb-1">Return Reason</p>
                <p className="text-sm font-medium">{order.return_reason}</p>
              </div>
            )}

            {order.priority === 'URGENT' && (
              <div className="flex items-center gap-2 p-2 rounded-lg bg-amber-500/10 border border-amber-500/30">
                <AlertTriangle className="w-4 h-4 text-amber-500" />
                <span className="text-sm font-medium text-amber-500">Urgent Order</span>
              </div>
            )}

            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-secondary">
                <Building2 className="w-5 h-5" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Ordering Department</p>
                <p className="font-medium">{order.ordering_department?.name}</p>
              </div>
            </div>

            {order.patient && (
              <>
                <Separator />
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-primary/10">
                    <User className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Patient</p>
                    <p className="font-medium">{order.patient.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {order.patient.uhid} • IPD: {order.ipd?.ipd_number || '-'}
                    </p>
                  </div>
                </div>
              </>
            )}

            {order.notes && (
              <>
                <Separator />
                <div>
                  <p className="text-sm text-muted-foreground mb-1">Notes</p>
                  <p className="text-sm">{order.notes}</p>
                </div>
              </>
            )}

            {order.cancellation_reason && (
              <>
                <Separator />
                <div className="p-2 rounded-lg bg-red-500/10 border border-red-500/30">
                  <p className="text-sm text-muted-foreground mb-1">Cancellation Reason</p>
                  <p className="text-sm text-red-400">{order.cancellation_reason}</p>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        {/* Order Items */}
        <div>
          <h2 className="font-semibold mb-3">Items ({order.items?.length || 0})</h2>
          <div className="space-y-2">
            {order.items?.map((item) => {
              const itemConfig = itemStatusConfig[item.status] || itemStatusConfig.PENDING_DISPATCH;
              return (
                <Card key={item.id} className="bg-card/50">
                  <CardContent className="p-3">
                    <div className="flex items-start justify-between gap-2 mb-2">
                      <div className="flex-1 min-w-0">
                        <p className="font-medium truncate">{item.item?.name}</p>
                        <p className="text-sm text-muted-foreground">
                          {item.item?.code} • {item.dispatching_department?.name}
                        </p>
                      </div>
                      <Badge className={itemConfig.class}>
                        {itemConfig.label}
                      </Badge>
                    </div>
                    <div className="grid grid-cols-3 gap-2 text-center text-sm">
                      <div className="p-2 rounded bg-secondary/50">
                        <p className="font-bold">{item.quantity_requested}</p>
                        <p className="text-xs text-muted-foreground">Requested</p>
                      </div>
                      <div className="p-2 rounded bg-secondary/50">
                        <p className="font-bold">{item.quantity_dispatched}</p>
                        <p className="text-xs text-muted-foreground">Dispatched</p>
                      </div>
                      <div className="p-2 rounded bg-secondary/50">
                        <p className="font-bold">{item.quantity_received}</p>
                        <p className="text-xs text-muted-foreground">Received</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>

        {/* Timeline */}
        <div>
          <h2 className="font-semibold mb-3">Timeline</h2>
          <Card className="bg-card/50">
            <CardContent className="p-4">
              <div className="space-y-4">
                <TimelineItem
                  label="Created"
                  time={formatDateTime(order.created_at)}
                  user={order.creator?.name}
                  active
                />
                {order.status === 'COMPLETED' && (
                  <TimelineItem
                    label="Completed"
                    time={formatDateTime(order.completed_at)}
                    active
                    success
                  />
                )}
                {order.status === 'CANCELLED' && (
                  <TimelineItem
                    label="Cancelled"
                    time={formatDateTime(order.cancelled_at)}
                    active
                    error
                  />
                )}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Actions */}
        <div className="space-y-2">
          {/* Create Return Button - for completed regular orders */}
          {canCreateReturn && (
            <Button
              className="w-full h-12 touch-btn bg-orange-500 hover:bg-orange-600"
              onClick={() => navigate('/create-return', { state: { orderId: order.id } })}
              data-testid="create-return-btn"
            >
              <RotateCcw className="w-4 h-4 mr-2" />
              Create Return
            </Button>
          )}

          {/* Cancel Button */}
          {canCancel && (
            <Button
              variant="destructive"
              className="w-full touch-btn"
              onClick={() => setCancelDialogOpen(true)}
              data-testid="cancel-order-btn"
            >
              <XCircle className="w-4 h-4 mr-2" />
              Cancel Order
            </Button>
          )}
        </div>
      </main>

      {/* Cancel Dialog */}
      <Dialog open={cancelDialogOpen} onOpenChange={setCancelDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Cancel Order</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Are you sure you want to cancel order {order.order_number}? This action cannot be undone.
            </p>
            <Textarea
              placeholder="Please provide a reason for cancellation..."
              value={cancelReason}
              onChange={(e) => setCancelReason(e.target.value)}
              rows={3}
              data-testid="cancel-reason-input"
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setCancelDialogOpen(false)}>
              Keep Order
            </Button>
            <Button 
              variant="destructive" 
              onClick={handleCancel}
              disabled={cancelling}
              data-testid="confirm-cancel-btn"
            >
              {cancelling ? 'Cancelling...' : 'Cancel Order'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

const TimelineItem = ({ label, time, user, active, success, error }) => (
  <div className="flex items-start gap-3">
    <div className={`w-3 h-3 mt-1.5 rounded-full ${
      error ? 'bg-red-500' :
      success ? 'bg-emerald-500' :
      active ? 'bg-primary' : 'bg-muted'
    }`} />
    <div className="flex-1">
      <p className={`font-medium ${error ? 'text-red-400' : success ? 'text-emerald-400' : ''}`}>
        {label}
      </p>
      <p className="text-sm text-muted-foreground">{time}</p>
      {user && <p className="text-xs text-muted-foreground">by {user}</p>}
    </div>
  </div>
);

export default OrderDetailPage;
