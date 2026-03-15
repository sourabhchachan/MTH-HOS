import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../AuthContext';
import { getDashboard } from '../api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { 
  Plus, Package, CheckCircle2, Clock, TrendingUp,
  AlertTriangle, ChevronRight, User, LogOut, RotateCcw, BarChart3
} from 'lucide-react';

const DashboardPage = () => {
  const { user, logout, isAdmin } = useAuth();
  const navigate = useNavigate();
  const [dashboard, setDashboard] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboard();
  }, []);

  const loadDashboard = async () => {
    try {
      const response = await getDashboard();
      setDashboard(response.data);
    } catch (error) {
      console.error('Failed to load dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full" />
      </div>
    );
  }

  const stats = dashboard?.stats || {};
  const dispatchQueue = dashboard?.pending_dispatch_items || [];
  const pendingReceive = dashboard?.pending_receive_items || [];

  return (
    <div className="min-h-screen bg-background pb-24 safe-area-top">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-background/95 backdrop-blur border-b border-border px-4 py-3">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="font-semibold text-lg">Welcome back</h1>
            <p className="text-sm text-muted-foreground">{user?.name}</p>
          </div>
          <div className="flex items-center gap-2">
            {isAdmin && (
              <Button 
                variant="ghost" 
                size="icon"
                onClick={() => navigate('/admin')}
                data-testid="admin-btn"
              >
                <User className="w-5 h-5" />
              </Button>
            )}
            <Button 
              variant="ghost" 
              size="icon"
              onClick={logout}
              data-testid="logout-btn"
            >
              <LogOut className="w-5 h-5" />
            </Button>
          </div>
        </div>
      </header>

      <main className="px-4 py-4 space-y-6">
        {/* Quick Actions */}
        <section className="grid grid-cols-2 gap-3">
          <Button
            onClick={() => navigate('/create-order')}
            className="h-auto py-4 flex-col gap-2 touch-btn"
            data-testid="create-order-btn"
          >
            <Plus className="w-6 h-6" />
            <span className="font-semibold">Create Order</span>
          </Button>
          <Button
            onClick={() => navigate('/dispatch')}
            variant="secondary"
            className="h-auto py-4 flex-col gap-2 touch-btn relative"
            data-testid="dispatch-queue-btn"
          >
            <Package className="w-6 h-6" />
            <span className="font-semibold">Dispatch Queue</span>
            {stats.pending_dispatch_count > 0 && (
              <Badge className="absolute -top-1 -right-1 bg-amber-500 text-black">
                {stats.pending_dispatch_count}
              </Badge>
            )}
          </Button>
        </section>

        {/* Secondary Actions */}
        <section className="grid grid-cols-2 gap-3">
          <Button
            onClick={() => navigate('/create-return')}
            variant="outline"
            className="h-auto py-3 flex-col gap-1 touch-btn"
            data-testid="create-return-btn"
          >
            <RotateCcw className="w-5 h-5" />
            <span className="text-sm">Return Order</span>
          </Button>
          {isAdmin && (
            <Button
              onClick={() => navigate('/reports')}
              variant="outline"
              className="h-auto py-3 flex-col gap-1 touch-btn"
              data-testid="reports-btn"
            >
              <BarChart3 className="w-5 h-5" />
              <span className="text-sm">Reports</span>
            </Button>
          )}
        </section>

        {/* Stats */}
        <section className="grid grid-cols-2 gap-3">
          <Card className="bg-card/50">
            <CardContent className="p-4">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-amber-500/10">
                  <Clock className="w-5 h-5 text-amber-500" />
                </div>
                <div>
                  <p className="text-2xl font-bold">{stats.pending_receive_count || 0}</p>
                  <p className="text-xs text-muted-foreground">Pending Receive</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card className="bg-card/50">
            <CardContent className="p-4">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-emerald-500/10">
                  <CheckCircle2 className="w-5 h-5 text-emerald-500" />
                </div>
                <div>
                  <p className="text-2xl font-bold">{stats.orders_completed_today || 0}</p>
                  <p className="text-xs text-muted-foreground">Completed Today</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </section>

        {/* Dispatch Queue Preview */}
        {dispatchQueue.length > 0 && (
          <section>
            <div className="flex items-center justify-between mb-3">
              <h2 className="font-semibold">Dispatch Queue</h2>
              <Button 
                variant="ghost" 
                size="sm"
                onClick={() => navigate('/dispatch')}
                className="text-primary"
              >
                View All <ChevronRight className="w-4 h-4 ml-1" />
              </Button>
            </div>
            <div className="space-y-2">
              {dispatchQueue.slice(0, 3).map((item) => (
                <Card 
                  key={item.order_item_id} 
                  className={`bg-card/50 cursor-pointer card-interactive ${
                    item.order_priority === 'URGENT' ? 'border-amber-500/50 urgent-pulse' : ''
                  }`}
                  onClick={() => navigate('/dispatch')}
                >
                  <CardContent className="p-3">
                    <div className="flex items-center justify-between">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <p className="font-medium truncate">{item.item_name}</p>
                          {item.order_priority === 'URGENT' && (
                            <AlertTriangle className="w-4 h-4 text-amber-500 flex-shrink-0" />
                          )}
                        </div>
                        <p className="text-sm text-muted-foreground">
                          {item.ordering_department} • Qty: {item.quantity_pending}
                        </p>
                      </div>
                      <Badge variant="secondary" className="ml-2">
                        {item.order_number}
                      </Badge>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </section>
        )}

        {/* Pending Receive Preview */}
        {pendingReceive.length > 0 && (
          <section>
            <div className="flex items-center justify-between mb-3">
              <h2 className="font-semibold">Pending Receive</h2>
              <Button 
                variant="ghost" 
                size="sm"
                onClick={() => navigate('/receive')}
                className="text-primary"
              >
                View All <ChevronRight className="w-4 h-4 ml-1" />
              </Button>
            </div>
            <div className="space-y-2">
              {pendingReceive.slice(0, 3).map((item) => (
                <Card 
                  key={item.id} 
                  className="bg-card/50 cursor-pointer card-interactive"
                  onClick={() => navigate('/receive')}
                >
                  <CardContent className="p-3">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium">Dispatch #{item.id}</p>
                        <p className="text-sm text-muted-foreground">
                          Qty: {item.quantity_dispatched} • {new Date(item.dispatched_at).toLocaleTimeString()}
                        </p>
                      </div>
                      <ChevronRight className="w-5 h-5 text-muted-foreground" />
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </section>
        )}

        {/* Today's Activity */}
        <section>
          <h2 className="font-semibold mb-3">Today's Activity</h2>
          <Card className="bg-card/50">
            <CardContent className="p-4">
              <div className="flex items-center gap-4">
                <div className="p-3 rounded-xl bg-primary/10">
                  <TrendingUp className="w-6 h-6 text-primary" />
                </div>
                <div className="flex-1">
                  <p className="font-semibold">{stats.orders_created_today || 0} Orders Created</p>
                  <p className="text-sm text-muted-foreground">
                    {stats.orders_completed_today || 0} completed
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </section>
      </main>

      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 bg-background/95 backdrop-blur border-t border-border bottom-nav">
        <div className="grid grid-cols-4 gap-1 px-2 py-2">
          <Button
            variant="ghost"
            className="flex-col h-auto py-2 gap-1"
            onClick={() => navigate('/')}
            data-testid="nav-home"
          >
            <TrendingUp className="w-5 h-5" />
            <span className="text-xs">Home</span>
          </Button>
          <Button
            variant="ghost"
            className="flex-col h-auto py-2 gap-1"
            onClick={() => navigate('/orders')}
            data-testid="nav-orders"
          >
            <Package className="w-5 h-5" />
            <span className="text-xs">Orders</span>
          </Button>
          <Button
            variant="ghost"
            className="flex-col h-auto py-2 gap-1"
            onClick={() => navigate('/dispatch')}
            data-testid="nav-dispatch"
          >
            <Clock className="w-5 h-5" />
            <span className="text-xs">Dispatch</span>
          </Button>
          <Button
            variant="ghost"
            className="flex-col h-auto py-2 gap-1"
            onClick={() => navigate('/receive')}
            data-testid="nav-receive"
          >
            <CheckCircle2 className="w-5 h-5" />
            <span className="text-xs">Receive</span>
          </Button>
        </div>
      </nav>
    </div>
  );
};

export default DashboardPage;
