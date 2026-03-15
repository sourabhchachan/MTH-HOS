import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { getOrders } from '../api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import { 
  ArrowLeft, Package, RefreshCw, AlertTriangle,
  Clock, CheckCircle2, XCircle, ChevronRight, User
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
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState('active');

  useEffect(() => {
    loadOrders();
  }, []);

  const loadOrders = async () => {
    setLoading(true);
    try {
      const response = await getOrders({ limit: 100 });
      setOrders(response.data);
    } catch (error) {
      console.error('Failed to load orders:', error);
    } finally {
      setLoading(false);
    }
  };

  const activeOrders = orders.filter(o => 
    !['COMPLETED', 'CANCELLED'].includes(o.status)
  );
  const completedOrders = orders.filter(o => o.status === 'COMPLETED');
  const cancelledOrders = orders.filter(o => o.status === 'CANCELLED');

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
                    <OrderCard key={order.id} order={order} onClick={() => navigate(`/orders/${order.id}`)} />
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
    </div>
  );
};

const OrderCard = ({ order, onClick }) => {
  const config = statusConfig[order.status] || statusConfig.CREATED;
  const StatusIcon = config.icon;
  const isUrgent = order.priority === 'URGENT';
  const itemCount = order.items?.length || 0;

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
            <Badge className={`${config.class} border`}>
              <StatusIcon className="w-3 h-3 mr-1" />
              {config.label}
            </Badge>
            <ChevronRight className="w-5 h-5 text-muted-foreground" />
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
