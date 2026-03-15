import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../AuthContext';
import api from '../api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { 
  ArrowLeft, TrendingUp, DollarSign, Package, Users,
  AlertTriangle, Download, RefreshCw, Building2, Clock,
  CheckCircle2, Activity
} from 'lucide-react';

const ReportsPage = () => {
  const navigate = useNavigate();
  const { isAdmin } = useAuth();
  const [tab, setTab] = useState('dashboard');
  const [loading, setLoading] = useState(true);
  const [dashboard, setDashboard] = useState(null);
  const [ordersReport, setOrdersReport] = useState(null);
  const [billingReport, setBillingReport] = useState(null);
  const [pendingOrders, setPendingOrders] = useState(null);
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');

  useEffect(() => {
    if (isAdmin) {
      loadDashboard();
    }
  }, [isAdmin]);

  const loadDashboard = async () => {
    setLoading(true);
    try {
      const response = await api.get('/reports/admin-dashboard');
      setDashboard(response.data);
    } catch (error) {
      console.error('Failed to load dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadOrdersReport = async () => {
    try {
      const params = {};
      if (fromDate) params.from_date = fromDate;
      if (toDate) params.to_date = toDate;
      const response = await api.get('/reports/operational/orders', { params });
      setOrdersReport(response.data);
    } catch (error) {
      console.error('Failed to load orders report:', error);
    }
  };

  const loadBillingReport = async () => {
    try {
      const params = {};
      if (fromDate) params.from_date = fromDate;
      if (toDate) params.to_date = toDate;
      const response = await api.get('/reports/financial/billing', { params });
      setBillingReport(response.data);
    } catch (error) {
      console.error('Failed to load billing report:', error);
    }
  };

  const loadPendingOrders = async () => {
    try {
      const response = await api.get('/reports/operational/pending-orders');
      setPendingOrders(response.data);
    } catch (error) {
      console.error('Failed to load pending orders:', error);
    }
  };

  const exportReport = async (type) => {
    try {
      const params = { format: 'csv' };
      if (fromDate) params.from_date = fromDate;
      if (toDate) params.to_date = toDate;
      
      const response = await api.get(`/reports/export/${type}`, { 
        params,
        responseType: 'blob'
      });
      
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `${type}_report_${new Date().toISOString().split('T')[0]}.csv`);
      document.body.appendChild(link);
      link.click();
      link.remove();
    } catch (error) {
      console.error('Export failed:', error);
    }
  };

  if (!isAdmin) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="w-full max-w-sm">
          <CardContent className="p-6 text-center">
            <p className="text-muted-foreground">Admin access required</p>
            <Button className="mt-4" onClick={() => navigate('/')}>Go Back</Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-6 safe-area-top">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-background/95 backdrop-blur border-b border-border px-4 py-3">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate('/admin')}>
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div className="flex items-center gap-2 flex-1">
            <TrendingUp className="w-5 h-5 text-primary" />
            <h1 className="font-semibold text-lg">Reports & Analytics</h1>
          </div>
          <Button variant="ghost" size="icon" onClick={loadDashboard} disabled={loading}>
            <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </header>

      <main className="px-4 py-4">
        <Tabs value={tab} onValueChange={setTab} className="w-full">
          <TabsList className="w-full grid grid-cols-4 mb-4">
            <TabsTrigger value="dashboard" className="text-xs">Dashboard</TabsTrigger>
            <TabsTrigger value="orders" className="text-xs" onClick={loadOrdersReport}>Orders</TabsTrigger>
            <TabsTrigger value="billing" className="text-xs" onClick={loadBillingReport}>Billing</TabsTrigger>
            <TabsTrigger value="pending" className="text-xs" onClick={loadPendingOrders}>Pending</TabsTrigger>
          </TabsList>

          {/* Dashboard Tab */}
          <TabsContent value="dashboard" className="mt-0 space-y-4">
            {loading ? (
              <div className="text-center py-8">
                <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full mx-auto" />
              </div>
            ) : dashboard && (
              <>
                {/* Key Metrics */}
                <div className="grid grid-cols-2 gap-3">
                  <Card className="bg-card/50">
                    <CardContent className="p-3">
                      <div className="flex items-center gap-2">
                        <Package className="w-5 h-5 text-primary" />
                        <div>
                          <p className="text-2xl font-bold">{dashboard.total_orders_today}</p>
                          <p className="text-xs text-muted-foreground">Orders Today</p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                  <Card className="bg-card/50">
                    <CardContent className="p-3">
                      <div className="flex items-center gap-2">
                        <Clock className="w-5 h-5 text-amber-500" />
                        <div>
                          <p className="text-2xl font-bold">{dashboard.total_orders_pending}</p>
                          <p className="text-xs text-muted-foreground">Pending</p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                  <Card className="bg-card/50">
                    <CardContent className="p-3">
                      <div className="flex items-center gap-2">
                        <CheckCircle2 className="w-5 h-5 text-emerald-500" />
                        <div>
                          <p className="text-2xl font-bold">{dashboard.total_orders_completed_today}</p>
                          <p className="text-xs text-muted-foreground">Completed Today</p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                  <Card className="bg-card/50">
                    <CardContent className="p-3">
                      <div className="flex items-center gap-2">
                        <Users className="w-5 h-5 text-blue-500" />
                        <div>
                          <p className="text-2xl font-bold">{dashboard.active_ipds}</p>
                          <p className="text-xs text-muted-foreground">Active IPDs</p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </div>

                {/* Billing Summary */}
                <Card className="bg-card/50">
                  <CardHeader className="pb-2">
                    <CardTitle className="text-sm flex items-center gap-2">
                      <DollarSign className="w-4 h-4" /> Billing Summary
                    </CardTitle>
                  </CardHeader>
                  <CardContent className="p-3 pt-0">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <p className="text-lg font-bold text-primary">
                          ₹{Number(dashboard.total_billing_today || 0).toLocaleString()}
                        </p>
                        <p className="text-xs text-muted-foreground">Today's Billing</p>
                      </div>
                      <div>
                        <p className="text-lg font-bold text-amber-500">
                          ₹{Number(dashboard.total_billing_pending || 0).toLocaleString()}
                        </p>
                        <p className="text-xs text-muted-foreground">Pending Collection</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                {/* Insights */}
                {dashboard.insights && dashboard.insights.length > 0 && (
                  <Card className="bg-amber-500/10 border-amber-500/30">
                    <CardHeader className="pb-2">
                      <CardTitle className="text-sm flex items-center gap-2 text-amber-500">
                        <AlertTriangle className="w-4 h-4" /> Insights & Alerts
                      </CardTitle>
                    </CardHeader>
                    <CardContent className="p-3 pt-0 space-y-2">
                      {dashboard.insights.map((insight, index) => (
                        <div key={index} className="p-2 rounded bg-background/50">
                          <div className="flex items-center gap-2">
                            <Badge className={
                              insight.severity === 'HIGH' ? 'bg-red-500' :
                              insight.severity === 'MEDIUM' ? 'bg-amber-500' :
                              'bg-blue-500'
                            }>
                              {insight.severity}
                            </Badge>
                            <p className="text-sm font-medium">{insight.title}</p>
                          </div>
                          <p className="text-xs text-muted-foreground mt-1">{insight.message}</p>
                        </div>
                      ))}
                    </CardContent>
                  </Card>
                )}

                {/* Department Stats */}
                <Card className="bg-card/50">
                  <CardHeader className="pb-2">
                    <CardTitle className="text-sm flex items-center gap-2">
                      <Building2 className="w-4 h-4" /> Department Activity
                    </CardTitle>
                  </CardHeader>
                  <CardContent className="p-3 pt-0">
                    <div className="space-y-2">
                      {dashboard.department_stats?.slice(0, 5).map((dept) => (
                        <div key={dept.department_id} className="flex items-center justify-between p-2 rounded bg-secondary/30">
                          <span className="text-sm">{dept.department_name}</span>
                          <div className="flex items-center gap-3 text-xs">
                            <span className="text-muted-foreground">
                              {dept.orders_created} created
                            </span>
                            <span className="text-primary">
                              {dept.orders_completed} done
                            </span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              </>
            )}
          </TabsContent>

          {/* Orders Report Tab */}
          <TabsContent value="orders" className="mt-0 space-y-4">
            {/* Date Filters */}
            <div className="grid grid-cols-2 gap-3">
              <div>
                <Label className="text-xs">From Date</Label>
                <Input
                  type="date"
                  value={fromDate}
                  onChange={(e) => setFromDate(e.target.value)}
                  className="h-10"
                />
              </div>
              <div>
                <Label className="text-xs">To Date</Label>
                <Input
                  type="date"
                  value={toDate}
                  onChange={(e) => setToDate(e.target.value)}
                  className="h-10"
                />
              </div>
            </div>
            <div className="flex gap-2">
              <Button onClick={loadOrdersReport} className="flex-1">Apply Filter</Button>
              <Button variant="outline" onClick={() => exportReport('orders')}>
                <Download className="w-4 h-4" />
              </Button>
            </div>

            {ordersReport && (
              <>
                <Card className="bg-card/50">
                  <CardContent className="p-4">
                    <p className="text-2xl font-bold">{ordersReport.total_orders}</p>
                    <p className="text-sm text-muted-foreground">Total Orders</p>
                  </CardContent>
                </Card>

                <Card className="bg-card/50">
                  <CardHeader className="pb-2">
                    <CardTitle className="text-sm">By Status</CardTitle>
                  </CardHeader>
                  <CardContent className="p-3 pt-0">
                    <div className="flex flex-wrap gap-2">
                      {Object.entries(ordersReport.by_status || {}).map(([status, count]) => (
                        <Badge key={status} variant="outline">
                          {status}: {count}
                        </Badge>
                      ))}
                    </div>
                  </CardContent>
                </Card>

                <Card className="bg-card/50">
                  <CardHeader className="pb-2">
                    <CardTitle className="text-sm">By Department</CardTitle>
                  </CardHeader>
                  <CardContent className="p-3 pt-0">
                    <div className="space-y-2">
                      {Object.entries(ordersReport.by_department || {}).map(([dept, count]) => (
                        <div key={dept} className="flex justify-between items-center">
                          <span className="text-sm">{dept}</span>
                          <Badge>{count}</Badge>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              </>
            )}
          </TabsContent>

          {/* Billing Report Tab */}
          <TabsContent value="billing" className="mt-0 space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <div>
                <Label className="text-xs">From Date</Label>
                <Input
                  type="date"
                  value={fromDate}
                  onChange={(e) => setFromDate(e.target.value)}
                  className="h-10"
                />
              </div>
              <div>
                <Label className="text-xs">To Date</Label>
                <Input
                  type="date"
                  value={toDate}
                  onChange={(e) => setToDate(e.target.value)}
                  className="h-10"
                />
              </div>
            </div>
            <div className="flex gap-2">
              <Button onClick={loadBillingReport} className="flex-1">Apply Filter</Button>
              <Button variant="outline" onClick={() => exportReport('billing')}>
                <Download className="w-4 h-4" />
              </Button>
            </div>

            {billingReport && (
              <>
                <div className="grid grid-cols-2 gap-3">
                  <Card className="bg-card/50">
                    <CardContent className="p-3">
                      <p className="text-xl font-bold text-primary">
                        ₹{Number(billingReport.total_amount || 0).toLocaleString()}
                      </p>
                      <p className="text-xs text-muted-foreground">Total Billing</p>
                    </CardContent>
                  </Card>
                  <Card className="bg-card/50">
                    <CardContent className="p-3">
                      <p className="text-xl font-bold text-emerald-500">
                        ₹{Number(billingReport.paid_amount || 0).toLocaleString()}
                      </p>
                      <p className="text-xs text-muted-foreground">Collected</p>
                    </CardContent>
                  </Card>
                </div>

                <Card className="bg-amber-500/10 border-amber-500/30">
                  <CardContent className="p-3">
                    <p className="text-xl font-bold text-amber-500">
                      ₹{Number(billingReport.pending_amount || 0).toLocaleString()}
                    </p>
                    <p className="text-xs text-muted-foreground">Pending Collection</p>
                  </CardContent>
                </Card>

                <Card className="bg-card/50">
                  <CardHeader className="pb-2">
                    <CardTitle className="text-sm">Recent Bills</CardTitle>
                  </CardHeader>
                  <CardContent className="p-3 pt-0">
                    <div className="space-y-2">
                      {billingReport.recent_bills?.slice(0, 5).map((bill) => (
                        <div key={bill.id} className="flex justify-between items-center p-2 rounded bg-secondary/30">
                          <div>
                            <p className="text-sm font-medium">{bill.billing_number}</p>
                            <p className="text-xs text-muted-foreground">{bill.patient}</p>
                          </div>
                          <div className="text-right">
                            <p className="text-sm font-semibold">₹{bill.amount.toLocaleString()}</p>
                            <Badge className={bill.status === 'PAID' ? 'status-completed' : 'status-pending'}>
                              {bill.status}
                            </Badge>
                          </div>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              </>
            )}
          </TabsContent>

          {/* Pending Orders Tab */}
          <TabsContent value="pending" className="mt-0 space-y-4">
            <Button onClick={loadPendingOrders} className="w-full">
              <RefreshCw className="w-4 h-4 mr-2" /> Refresh
            </Button>

            {pendingOrders && (
              <>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Total Pending</span>
                  <Badge variant="destructive">{pendingOrders.total_pending}</Badge>
                </div>
                {pendingOrders.urgent_count > 0 && (
                  <Card className="bg-amber-500/10 border-amber-500/30">
                    <CardContent className="p-3 flex items-center gap-2">
                      <AlertTriangle className="w-5 h-5 text-amber-500" />
                      <span className="font-medium text-amber-500">
                        {pendingOrders.urgent_count} Urgent Orders Pending
                      </span>
                    </CardContent>
                  </Card>
                )}

                <div className="space-y-2">
                  {pendingOrders.orders?.map((order) => (
                    <Card 
                      key={order.order_id} 
                      className={`bg-card/50 ${order.priority === 'URGENT' ? 'border-amber-500/50' : ''}`}
                    >
                      <CardContent className="p-3">
                        <div className="flex items-start justify-between gap-2">
                          <div>
                            <div className="flex items-center gap-2">
                              <p className="font-medium">{order.order_number}</p>
                              {order.priority === 'URGENT' && (
                                <AlertTriangle className="w-4 h-4 text-amber-500" />
                              )}
                            </div>
                            <p className="text-sm text-muted-foreground">
                              {order.ordering_department} • {order.patient || 'No patient'}
                            </p>
                            <p className="text-xs text-muted-foreground">
                              Age: {order.age_hours}h
                            </p>
                          </div>
                          <Badge className={
                            order.status === 'CREATED' ? 'status-pending' :
                            'status-dispatched'
                          }>
                            {order.status}
                          </Badge>
                        </div>
                        {order.pending_items?.length > 0 && (
                          <div className="mt-2 pt-2 border-t border-border">
                            <p className="text-xs text-muted-foreground mb-1">
                              Pending Items ({order.pending_items.length})
                            </p>
                            <div className="flex flex-wrap gap-1">
                              {order.pending_items.map((item, idx) => (
                                <Badge key={idx} variant="outline" className="text-xs">
                                  {item.quantity_pending} pending at {item.dispatching_department}
                                </Badge>
                              ))}
                            </div>
                          </div>
                        )}
                      </CardContent>
                    </Card>
                  ))}
                </div>
              </>
            )}
          </TabsContent>
        </Tabs>
      </main>
    </div>
  );
};

export default ReportsPage;
