import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { getOrders, receiveItem, getPendingReceive } from '../api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { toast } from 'sonner';
import { 
  ArrowLeft, Package, RefreshCw, AlertTriangle,
  Clock, CheckCircle2, XCircle, ChevronRight, User, X, Filter, PackageCheck
} from 'lucide-react';

const statusConfig = {
  CREATED: { label: 'Created', icon: Clock, class: 'status-pending' },
  PARTIALLY_DISPATCHED: { label: 'Partial', icon: Package, class: 'status-dispatched' },
  FULLY_DISPATCHED: { label: 'Dispatched', icon: Package, class: 'status-dispatched' },
  COMPLETED: { label: 'Completed', icon: CheckCircle2, class: 'status-completed' },
  CANCELLED: { label: 'Cancelled', icon: XCircle, class: 'status-cancelled' },
};

const OrdersPage = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState('active');
  
  // Quick Receive Modal State
  const [receiveModalOpen, setReceiveModalOpen] = useState(false);
  const [selectedOrderForReceive, setSelectedOrderForReceive] = useState(null);
  const [receiving, setReceiving] = useState(false);
  
  // Get filter params from URL
  const statusFilter = searchParams.get('status');
  const priorityFilter = searchParams.get('priority');
  const departmentFilter = searchParams.get('department');
  const hasFilters = statusFilter || priorityFilter || departmentFilter;

  useEffect(() => {
    loadOrders();
    // Set initial tab based on status filter
    if (statusFilter === 'COMPLETED') {
      setTab('completed');
    } else if (statusFilter === 'CANCELLED') {
      setTab('cancelled');
    } else {
      setTab('active');
    }
  }, [statusFilter]);

  const loadOrders = async () => {
    setLoading(true);
    try {
      const params = { limit: 100 };
      if (statusFilter) params.status = statusFilter;
      if (priorityFilter) params.priority = priorityFilter;
      if (departmentFilter) params.department_id = departmentFilter;
      const response = await getOrders(params);
      setOrders(response.data);
    } catch (error) {
      console.error('Failed to load orders:', error);
    } finally {
      setLoading(false);
    }
  };

  const clearFilters = () => {
    setSearchParams({});
  };

  // Quick Receive Handler
  const handleQuickReceive = (order, e) => {
    e.stopPropagation(); // Prevent card click
    setSelectedOrderForReceive(order);
    setReceiveModalOpen(true);
  };

  const confirmReceive = async () => {
    if (!selectedOrderForReceive) return;
    
    setReceiving(true);
    try {
      // First get pending receive items (dispatch events)
      const pendingRes = await getPendingReceive();
      const pendingReceive = pendingRes.data || [];
      
      // Filter dispatch events for this order
      const orderDispatchEvents = pendingReceive.filter(
        event => event.order_id === selectedOrderForReceive.id
      );
      
      if (orderDispatchEvents.length === 0) {
        toast.error('No items to receive for this order');
        return;
      }
      
      // Receive each dispatch event
      for (const event of orderDispatchEvents) {
        if (event.quantity_pending > 0) {
          await receiveItem({
            dispatch_event_id: event.dispatch_event_id,
            quantity_received: event.quantity_pending
          });
        }
      }
      
      toast.success('Order received successfully!');
      setReceiveModalOpen(false);
      setSelectedOrderForReceive(null);
      loadOrders(); // Refresh the list
    } catch (error) {
      console.error('Receive failed:', error);
      toast.error('Failed to receive order');
    } finally {
      setReceiving(false);
    }
  };

  // Apply filters to orders
  let filteredOrders = orders;
  if (statusFilter) {
    filteredOrders = orders.filter(o => o.status === statusFilter);
  }
  if (priorityFilter) {
    filteredOrders = filteredOrders.filter(o => o.priority === priorityFilter);
  }

  const activeOrders = filteredOrders.filter(o => 
    !['COMPLETED', 'CANCELLED'].includes(o.status)
  );
  const completedOrders = filteredOrders.filter(o => o.status === 'COMPLETED');
  const cancelledOrders = filteredOrders.filter(o => o.status === 'CANCELLED');

  // Get filter label for display
  const getFilterLabel = () => {
    const labels = [];
    if (statusFilter) labels.push(`Status: ${statusFilter.replace('_', ' ')}`);
    if (priorityFilter) labels.push(`Priority: ${priorityFilter}`);
    if (departmentFilter) labels.push(`Dept: ${departmentFilter}`);
    return labels.join(' • ');
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className="min-h-screen bg-white pb-20 safe-area-top">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white border-b border-gray-100 px-4 py-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <h1 className="text-xl font-bold text-orange-500">MTH</h1>
            <span className="text-gray-300">|</span>
            <span className="font-semibold text-gray-700">Orders</span>
          </div>
          <Button
            onClick={() => navigate('/create-order')}
            size="sm"
            className="bg-orange-500 hover:bg-orange-600"
          >
            + New Order
          </Button>
        </div>
        {/* Filter indicator */}
        {hasFilters && (
          <div className="mt-2 flex items-center gap-2 p-2 bg-orange-50 rounded-lg">
            <Filter className="w-4 h-4 text-orange-500" />
            <span className="text-sm text-orange-700 flex-1">{getFilterLabel()}</span>
            <Button
              variant="ghost"
              size="sm"
              onClick={clearFilters}
              className="h-6 px-2 text-orange-600 hover:text-orange-800"
              data-testid="clear-filters-btn"
            >
              <X className="w-4 h-4" />
              Clear
            </Button>
          </div>
        )}
      </header>

      <main className="px-4 py-4">
        <Tabs value={tab} onValueChange={setTab} className="w-full">
          <TabsList className="w-full grid grid-cols-3 mb-4 bg-gray-100">
            <TabsTrigger value="active" data-testid="tab-active" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              Active ({activeOrders.length})
            </TabsTrigger>
            <TabsTrigger value="completed" data-testid="tab-completed" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              Done ({completedOrders.length})
            </TabsTrigger>
            <TabsTrigger value="cancelled" data-testid="tab-cancelled" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              Cancelled ({cancelledOrders.length})
            </TabsTrigger>
          </TabsList>

          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin w-8 h-8 border-2 border-orange-500 border-t-transparent rounded-full" />
            </div>
          ) : (
            <>
              <TabsContent value="active" className="space-y-2 mt-0">
                {activeOrders.length === 0 ? (
                  <EmptyState message="No active orders" />
                ) : (
                  activeOrders.map(order => (
                    <OrderCard 
                      key={order.id} 
                      order={order} 
                      onClick={() => navigate(`/orders/${order.id}`)} 
                      onQuickReceive={order.status === 'FULLY_DISPATCHED' ? (e) => handleQuickReceive(order, e) : null}
                    />
                  ))
                )}
              </TabsContent>

              <TabsContent value="completed" className="space-y-2 mt-0">
                {completedOrders.length === 0 ? (
                  <EmptyState message="No completed orders" />
                ) : (
                  completedOrders.map(order => (
                    <OrderCard key={order.id} order={order} onClick={() => navigate(`/orders/${order.id}`)} />
                  ))
                )}
              </TabsContent>

              <TabsContent value="cancelled" className="space-y-2 mt-0">
                {cancelledOrders.length === 0 ? (
                  <EmptyState message="No cancelled orders" />
                ) : (
                  cancelledOrders.map(order => (
                    <OrderCard key={order.id} order={order} onClick={() => navigate(`/orders/${order.id}`)} />
                  ))
                )}
              </TabsContent>
            </>
          )}
        </Tabs>
      </main>

      {/* Quick Receive Modal */}
      <Dialog open={receiveModalOpen} onOpenChange={setReceiveModalOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-lg">
              <PackageCheck className="w-5 h-5 text-green-500" />
              Confirm Receive
            </DialogTitle>
          </DialogHeader>
          
          {selectedOrderForReceive && (
            <div className="space-y-4">
              <div className="p-3 bg-gray-50 rounded-lg">
                <p className="font-medium">{selectedOrderForReceive.order_number}</p>
                {selectedOrderForReceive.patient && (
                  <p className="text-sm text-gray-500">Patient: {selectedOrderForReceive.patient.name}</p>
                )}
              </div>
              
              <div className="space-y-2">
                <p className="text-sm font-medium text-gray-700">Items to receive:</p>
                {selectedOrderForReceive.items?.map((item, idx) => (
                  <div key={idx} className="flex items-center justify-between p-2 bg-green-50 rounded text-sm">
                    <span className="truncate flex-1">{item.item_name || `Item ${idx + 1}`}</span>
                    <span className="font-semibold text-green-700">
                      Qty: {item.quantity_dispatched - (item.quantity_received || 0)}
                    </span>
                  </div>
                ))}
              </div>
              
              <p className="text-sm text-gray-500 text-center">
                Tap confirm to receive all dispatched items
              </p>
            </div>
          )}
          
          <DialogFooter className="flex gap-2">
            <Button 
              variant="outline" 
              onClick={() => setReceiveModalOpen(false)}
              disabled={receiving}
            >
              Cancel
            </Button>
            <Button 
              className="bg-green-500 hover:bg-green-600 flex-1"
              onClick={confirmReceive}
              disabled={receiving}
              data-testid="confirm-receive-btn"
            >
              {receiving ? (
                <RefreshCw className="w-4 h-4 animate-spin mr-2" />
              ) : (
                <PackageCheck className="w-4 h-4 mr-2" />
              )}
              Confirm Receive
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

const OrderCard = ({ order, onClick, onQuickReceive }) => {
  const config = statusConfig[order.status] || statusConfig.CREATED;
  const StatusIcon = config.icon;
  const isUrgent = order.priority === 'URGENT';
  const itemCount = order.items?.length || 0;
  const showQuickReceive = order.status === 'FULLY_DISPATCHED' && onQuickReceive;

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
  };

  return (
    <Card 
      className={`bg-card/50 cursor-pointer card-interactive ${isUrgent ? 'border-amber-500/30' : ''}`}
      onClick={onClick}
      data-testid={`order-${order.id}`}
    >
      <CardContent className="p-3">
        <div className="flex items-start justify-between gap-2">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <span className="font-semibold">{order.order_number}</span>
              {isUrgent && <AlertTriangle className="w-4 h-4 text-amber-500" />}
              {order.order_type === 'RETURN' && (
                <Badge variant="outline" className="text-xs">Return</Badge>
              )}
            </div>
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <span>{itemCount} item{itemCount !== 1 ? 's' : ''}</span>
              <span>•</span>
              <span>{formatDate(order.created_at)}</span>
            </div>
            {order.patient && (
              <div className="flex items-center gap-1 text-sm text-primary mt-1">
                <User className="w-3 h-3" />
                <span>{order.patient.name}</span>
              </div>
            )}
          </div>
          <div className="flex items-center gap-2">
            {showQuickReceive ? (
              /* Quick Receive Button - Large Touch Target */
              <Button 
                className="h-14 w-24 bg-green-500 hover:bg-green-600 text-white font-semibold shadow-md flex flex-col items-center justify-center gap-0.5"
                onClick={onQuickReceive}
                data-testid={`quick-receive-btn-${order.id}`}
              >
                <PackageCheck className="w-5 h-5" />
                <span className="text-xs">Receive</span>
              </Button>
            ) : (
              <>
                <Badge className={`${config.class} border`}>
                  <StatusIcon className="w-3 h-3 mr-1" />
                  {config.label}
                </Badge>
                <ChevronRight className="w-5 h-5 text-muted-foreground" />
              </>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

const EmptyState = ({ message }) => (
  <div className="text-center py-12">
    <Package className="w-12 h-12 mx-auto mb-3 text-muted-foreground opacity-50" />
    <p className="text-muted-foreground">{message}</p>
  </div>
);

export default OrdersPage;
