import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../AuthContext';
import {
  getMainDashboard, getDepartmentWorkload, getPatientDashboard,
  getPatientOrders, getBillingDashboard, exportBillingDashboard,
  exportDepartmentWorkload, exportPatientDashboard
} from '../api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { toast } from 'sonner';
import {
  ArrowLeft, Activity, Package, Users, Clock, CheckCircle2,
  AlertTriangle, Building2, DollarSign, RefreshCw, Download,
  UserPlus, TrendingUp, FileText, Search, ChevronRight, Loader2
} from 'lucide-react';

// Metric Card Component - Now clickable with drill-down
const MetricCard = ({ label, value, icon: Icon, color = 'blue', subtitle, onClick, testId }) => (
  <Card 
    className={`bg-white border-gray-100 ${onClick ? 'cursor-pointer hover:border-orange-300 hover:shadow-md transition-all' : ''}`}
    onClick={onClick}
    data-testid={testId}
  >
    <CardContent className="p-4">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-3xl font-bold text-gray-900">{value}</p>
          <p className="text-sm text-gray-500 mt-1">{label}</p>
          {subtitle && <p className="text-xs text-gray-400">{subtitle}</p>}
        </div>
        <div className={`p-2 rounded-lg bg-${color}-50`}>
          <Icon className={`w-5 h-5 text-${color}-500`} />
        </div>
      </div>
      {onClick && (
        <div className="mt-2 flex items-center text-xs text-orange-500">
          <span>Click to view details</span>
          <ChevronRight className="w-3 h-3 ml-1" />
        </div>
      )}
    </CardContent>
  </Card>
);

// Department Row Component
const DepartmentRow = ({ dept, onClick }) => (
  <div
    className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-orange-50 cursor-pointer transition-colors"
    onClick={onClick}
    data-testid={`dept-row-${dept.department_id}`}
  >
    <div>
      <p className="font-medium text-gray-800">{dept.department_name}</p>
      <p className="text-xs text-gray-500">{dept.department_code}</p>
    </div>
    <div className="flex items-center gap-3">
      <div className="text-right">
        <p className="text-lg font-semibold text-orange-600">{dept.orders_pending || dept.pending_dispatch}</p>
        <p className="text-xs text-gray-500">Pending</p>
      </div>
      <ChevronRight className="w-4 h-4 text-gray-400" />
    </div>
  </div>
);

// Patient Row Component
const PatientRow = ({ patient, onClick }) => (
  <div
    className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-orange-50 cursor-pointer transition-colors"
    onClick={onClick}
    data-testid={`patient-row-${patient.patient_id}`}
  >
    <div>
      <p className="font-medium text-gray-800">{patient.patient_name}</p>
      <p className="text-xs text-gray-500">{patient.patient_uhid} • {patient.ipd_number}</p>
    </div>
    <div className="flex items-center gap-3">
      <Badge className={
        patient.current_phase === 'IPD' ? 'bg-blue-100 text-blue-700' :
        patient.current_phase === 'DISCHARGE' ? 'bg-green-100 text-green-700' :
        'bg-gray-100 text-gray-700'
      }>
        {patient.current_phase}
      </Badge>
      <div className="text-right">
        <p className="text-sm font-medium">{patient.total_orders} orders</p>
        <p className="text-xs text-gray-500">{patient.length_of_stay_days || 0} days</p>
      </div>
      <ChevronRight className="w-4 h-4 text-gray-400" />
    </div>
  </div>
);

const AdminDashboardPage = () => {
  const navigate = useNavigate();
  const { isAdmin } = useAuth();
  const [tab, setTab] = useState('main');
  const [loading, setLoading] = useState(true);
  
  // Dashboard data
  const [mainData, setMainData] = useState(null);
  const [deptData, setDeptData] = useState(null);
  const [patientData, setPatientData] = useState(null);
  const [billingData, setBillingData] = useState(null);
  
  // Filters
  const [dateFilter, setDateFilter] = useState('');
  const [deptFilter, setDeptFilter] = useState('');
  const [patientSearch, setPatientSearch] = useState('');
  const [billingFromDate, setBillingFromDate] = useState('');
  const [billingToDate, setBillingToDate] = useState('');
  
  // Patient orders modal
  const [selectedPatient, setSelectedPatient] = useState(null);
  const [patientOrders, setPatientOrders] = useState(null);
  const [showPatientModal, setShowPatientModal] = useState(false);

  const loadMainDashboard = useCallback(async () => {
    try {
      const params = {};
      if (dateFilter) params.date_filter = dateFilter;
      if (deptFilter) params.department_id = deptFilter;
      const res = await getMainDashboard(params);
      setMainData(res.data);
    } catch (e) {
      console.error(e);
      toast.error('Failed to load main dashboard');
    }
  }, [dateFilter, deptFilter]);

  const loadDepartmentWorkload = useCallback(async () => {
    try {
      const res = await getDepartmentWorkload();
      setDeptData(res.data);
    } catch (e) {
      console.error(e);
      toast.error('Failed to load department workload');
    }
  }, []);

  const loadPatientDashboard = useCallback(async () => {
    try {
      const params = { status: 'ACTIVE' };
      if (patientSearch) params.search = patientSearch;
      const res = await getPatientDashboard(params);
      setPatientData(res.data);
    } catch (e) {
      console.error(e);
      toast.error('Failed to load patient dashboard');
    }
  }, [patientSearch]);

  const loadBillingDashboard = useCallback(async () => {
    try {
      const params = {};
      if (billingFromDate) params.from_date = billingFromDate;
      if (billingToDate) params.to_date = billingToDate;
      const res = await getBillingDashboard(params);
      setBillingData(res.data);
    } catch (e) {
      console.error(e);
      toast.error('Failed to load billing dashboard');
    }
  }, [billingFromDate, billingToDate]);

  const loadPatientOrders = async (ipdId, patient) => {
    try {
      setSelectedPatient(patient);
      const res = await getPatientOrders(ipdId);
      setPatientOrders(res.data);
      setShowPatientModal(true);
    } catch (e) {
      console.error(e);
      toast.error('Failed to load patient orders');
    }
  };

  const handleExport = async (type) => {
    try {
      let response;
      let filename;
      
      if (type === 'billing') {
        const params = { format: 'csv' };
        if (billingFromDate) params.from_date = billingFromDate;
        if (billingToDate) params.to_date = billingToDate;
        response = await exportBillingDashboard(params);
        filename = `billing_report_${new Date().toISOString().split('T')[0]}.csv`;
      } else if (type === 'department') {
        response = await exportDepartmentWorkload();
        filename = `department_workload_${new Date().toISOString().split('T')[0]}.csv`;
      } else if (type === 'patient') {
        response = await exportPatientDashboard('ACTIVE');
        filename = `patient_report_${new Date().toISOString().split('T')[0]}.csv`;
      }
      
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', filename);
      document.body.appendChild(link);
      link.click();
      link.remove();
      toast.success('Export downloaded successfully');
    } catch (e) {
      console.error(e);
      toast.error('Export failed');
    }
  };

  useEffect(() => {
    const loadAll = async () => {
      setLoading(true);
      await Promise.all([
        loadMainDashboard(),
        loadDepartmentWorkload(),
        loadPatientDashboard(),
        loadBillingDashboard()
      ]);
      setLoading(false);
    };
    
    if (isAdmin) {
      loadAll();
    }
  }, [isAdmin, loadMainDashboard, loadDepartmentWorkload, loadPatientDashboard, loadBillingDashboard]);

  if (!isAdmin) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-white">
        <Card className="w-full max-w-sm border-gray-200">
          <CardContent className="p-6 text-center">
            <p className="text-gray-500">Admin access required</p>
            <Button className="mt-4 bg-orange-500 hover:bg-orange-600" onClick={() => navigate('/')}>Go Back</Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white">
        <div className="text-center">
          <Loader2 className="w-8 h-8 animate-spin text-orange-500 mx-auto" />
          <p className="mt-2 text-gray-500">Loading dashboards...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 pb-6 safe-area-top">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white border-b border-gray-200 px-4 py-3">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate('/admin')} data-testid="back-btn">
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div className="flex items-center gap-2 flex-1">
            <span className="text-orange-500 font-bold text-lg">MTH</span>
            <span className="text-gray-300">|</span>
            <h1 className="font-semibold text-gray-800">Operational Dashboards</h1>
          </div>
          <Button variant="ghost" size="icon" onClick={() => {
            loadMainDashboard();
            loadDepartmentWorkload();
            loadPatientDashboard();
            loadBillingDashboard();
          }} data-testid="refresh-btn">
            <RefreshCw className="w-5 h-5" />
          </Button>
        </div>
      </header>

      <main className="px-4 py-4">
        <Tabs value={tab} onValueChange={setTab} className="w-full">
          <TabsList className="w-full grid grid-cols-4 mb-4 bg-gray-100">
            <TabsTrigger value="main" className="text-xs data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              Overview
            </TabsTrigger>
            <TabsTrigger value="department" className="text-xs data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              Departments
            </TabsTrigger>
            <TabsTrigger value="patient" className="text-xs data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              Patients
            </TabsTrigger>
            <TabsTrigger value="billing" className="text-xs data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              Billing
            </TabsTrigger>
          </TabsList>

          {/* MAIN DASHBOARD TAB */}
          <TabsContent value="main" className="mt-0 space-y-4">
            {/* Filters */}
            <Card className="border-gray-100 bg-white">
              <CardContent className="p-3">
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <Label className="text-xs text-gray-500">Date</Label>
                    <Input
                      type="date"
                      value={dateFilter}
                      onChange={(e) => setDateFilter(e.target.value)}
                      className="h-9"
                      data-testid="date-filter"
                    />
                  </div>
                  <div>
                    <Label className="text-xs text-gray-500">Department</Label>
                    <Select value={deptFilter || "all"} onValueChange={(v) => setDeptFilter(v === "all" ? "" : v)}>
                      <SelectTrigger className="h-9" data-testid="dept-filter">
                        <SelectValue placeholder="All" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">All Departments</SelectItem>
                        {mainData?.department_workload?.map((d) => (
                          <SelectItem key={d.department_id} value={String(d.department_id)}>
                            {d.department_name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>
                <Button
                  onClick={loadMainDashboard}
                  className="w-full mt-2 h-9 bg-orange-500 hover:bg-orange-600"
                  data-testid="apply-filter-btn"
                >
                  Apply Filters
                </Button>
              </CardContent>
            </Card>

            {mainData && (
              <>
                {/* Order Metrics */}
                <div className="grid grid-cols-2 gap-3">
                  <MetricCard
                    label="Orders Today"
                    value={mainData.order_metrics.orders_created_today}
                    icon={Package}
                    color="blue"
                    onClick={() => navigate('/orders')}
                    testId="metric-orders-today"
                  />
                  <MetricCard
                    label="Pending Dispatch"
                    value={mainData.order_metrics.orders_pending_dispatch}
                    icon={Clock}
                    color="orange"
                    onClick={() => navigate('/dispatch?status=PENDING')}
                    testId="metric-pending-dispatch"
                  />
                  <MetricCard
                    label="Partially Dispatched"
                    value={mainData.order_metrics.orders_partially_dispatched}
                    icon={Activity}
                    color="amber"
                    onClick={() => navigate('/dispatch?status=PARTIAL')}
                    testId="metric-partial-dispatch"
                  />
                  <MetricCard
                    label="Awaiting Receipt"
                    value={mainData.order_metrics.orders_awaiting_receipt}
                    icon={FileText}
                    color="purple"
                    onClick={() => navigate('/orders?status=FULLY_DISPATCHED')}
                    testId="metric-awaiting-receipt"
                  />
                  <MetricCard
                    label="Completed Today"
                    value={mainData.order_metrics.orders_completed_today}
                    icon={CheckCircle2}
                    color="green"
                    onClick={() => navigate('/orders?status=COMPLETED')}
                    testId="metric-completed-today"
                  />
                  <MetricCard
                    label="Urgent Pending"
                    value={mainData.order_metrics.urgent_orders_pending}
                    icon={AlertTriangle}
                    color="red"
                    onClick={() => navigate('/orders?priority=URGENT')}
                    testId="metric-urgent-pending"
                  />
                </div>

                {/* Patient Metrics - clickable */}
                <Card 
                  className="border-gray-100 bg-white cursor-pointer hover:border-blue-300 hover:shadow-md transition-all"
                  onClick={() => setTab('patient')}
                  data-testid="patient-metrics-card"
                >
                  <CardHeader className="pb-2">
                    <CardTitle className="text-base flex items-center gap-2">
                      <Users className="w-5 h-5 text-blue-500" />
                      Patient Metrics
                      <ChevronRight className="w-4 h-4 text-gray-400 ml-auto" />
                    </CardTitle>
                  </CardHeader>
                  <CardContent className="p-4 pt-0">
                    <div className="flex items-center justify-between mb-3">
                      <span className="text-gray-600">Active IPD Patients</span>
                      <span className="text-2xl font-bold text-blue-600">
                        {mainData.patient_metrics.active_ipd_patients}
                      </span>
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {Object.entries(mainData.patient_metrics.patients_by_phase || {}).map(([phase, count]) => (
                        <Badge key={phase} variant="outline" className="text-xs">
                          {phase}: {count}
                        </Badge>
                      ))}
                    </div>
                  </CardContent>
                </Card>

                {/* Department Workload Preview */}
                <Card className="border-gray-100 bg-white">
                  <CardHeader className="pb-2">
                    <CardTitle className="text-base flex items-center gap-2">
                      <Building2 className="w-5 h-5 text-orange-500" />
                      Department Workload
                    </CardTitle>
                    <CardDescription className="text-xs">Click a department to view dispatch queue</CardDescription>
                  </CardHeader>
                  <CardContent className="p-4 pt-0 space-y-2">
                    {mainData.department_workload.slice(0, 5).map((dept) => (
                      <DepartmentRow
                        key={dept.department_id}
                        dept={dept}
                        onClick={() => navigate(`/dispatch?department=${dept.department_id}`)}
                      />
                    ))}
                    {mainData.department_workload.length > 5 && (
                      <Button
                        variant="ghost"
                        className="w-full text-orange-600"
                        onClick={() => setTab('department')}
                      >
                        View All Departments
                      </Button>
                    )}
                  </CardContent>
                </Card>
              </>
            )}
          </TabsContent>

          {/* DEPARTMENT WORKLOAD TAB */}
          <TabsContent value="department" className="mt-0 space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-semibold text-gray-800">Department Workload</h2>
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleExport('department')}
                data-testid="export-dept-btn"
              >
                <Download className="w-4 h-4 mr-1" /> Export
              </Button>
            </div>

            {deptData && (
              <>
                {/* Summary */}
                <div className="grid grid-cols-3 gap-2">
                  <Card className="bg-orange-50 border-orange-100">
                    <CardContent className="p-3 text-center">
                      <p className="text-2xl font-bold text-orange-600">{deptData.summary.total_pending}</p>
                      <p className="text-xs text-orange-700">Total Pending</p>
                    </CardContent>
                  </Card>
                  <Card className="bg-green-50 border-green-100">
                    <CardContent className="p-3 text-center">
                      <p className="text-2xl font-bold text-green-600">{deptData.summary.total_completed_today}</p>
                      <p className="text-xs text-green-700">Completed Today</p>
                    </CardContent>
                  </Card>
                  <Card className="bg-blue-50 border-blue-100">
                    <CardContent className="p-3 text-center">
                      <p className="text-2xl font-bold text-blue-600">{deptData.summary.total_departments}</p>
                      <p className="text-xs text-blue-700">Departments</p>
                    </CardContent>
                  </Card>
                </div>

                {/* Department List */}
                <Card className="border-gray-100 bg-white">
                  <CardContent className="p-4 space-y-2">
                    {deptData.departments.map((dept) => (
                      <div 
                        key={dept.department_id} 
                        className="p-3 bg-gray-50 rounded-lg hover:bg-orange-50 cursor-pointer transition-colors"
                        onClick={() => navigate(`/dispatch?department=${dept.department_id}`)}
                        data-testid={`dept-detail-${dept.department_id}`}
                      >
                        <div className="flex items-center justify-between mb-2">
                          <div>
                            <p className="font-medium text-gray-800">{dept.department_name}</p>
                            <p className="text-xs text-gray-500">{dept.department_code}</p>
                          </div>
                          <div className="flex items-center gap-2">
                            {dept.avg_dispatch_time_hours && (
                              <Badge variant="outline" className="text-xs">
                                Avg: {dept.avg_dispatch_time_hours}h
                              </Badge>
                            )}
                            <ChevronRight className="w-4 h-4 text-gray-400" />
                          </div>
                        </div>
                        <div className="grid grid-cols-4 gap-2 text-center">
                          <div>
                            <p className="text-lg font-semibold text-gray-700">{dept.total_orders_assigned}</p>
                            <p className="text-xs text-gray-500">Total</p>
                          </div>
                          <div>
                            <p className="text-lg font-semibold text-orange-600">{dept.pending_dispatch}</p>
                            <p className="text-xs text-gray-500">Pending</p>
                          </div>
                          <div>
                            <p className="text-lg font-semibold text-amber-600">{dept.partially_dispatched}</p>
                            <p className="text-xs text-gray-500">Partial</p>
                          </div>
                          <div>
                            <p className="text-lg font-semibold text-green-600">{dept.completed_today}</p>
                            <p className="text-xs text-gray-500">Done</p>
                          </div>
                        </div>
                        {dept.urgent_orders_handled > 0 && (
                          <div className="mt-2 flex items-center gap-1 text-red-600 text-xs">
                            <AlertTriangle className="w-3 h-3" />
                            {dept.urgent_orders_handled} urgent handled today
                          </div>
                        )}
                        <p className="mt-2 text-xs text-orange-500">Click to view dispatch queue →</p>
                      </div>
                    ))}
                  </CardContent>
                </Card>
              </>
            )}
          </TabsContent>

          {/* PATIENT DASHBOARD TAB */}
          <TabsContent value="patient" className="mt-0 space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-semibold text-gray-800">Patient Operations</h2>
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleExport('patient')}
                data-testid="export-patient-btn"
              >
                <Download className="w-4 h-4 mr-1" /> Export
              </Button>
            </div>

            {/* Search */}
            <div className="flex gap-2">
              <div className="flex-1 relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <Input
                  placeholder="Search UHID or Name..."
                  value={patientSearch}
                  onChange={(e) => setPatientSearch(e.target.value)}
                  className="pl-9 h-10"
                  data-testid="patient-search"
                />
              </div>
              <Button onClick={loadPatientDashboard} className="bg-orange-500 hover:bg-orange-600">
                Search
              </Button>
            </div>

            {patientData && (
              <>
                {/* Summary */}
                <Card className="border-blue-100 bg-blue-50">
                  <CardContent className="p-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-3xl font-bold text-blue-600">{patientData.summary.total_active_ipd}</p>
                        <p className="text-sm text-blue-700">Active IPD Patients</p>
                      </div>
                      <Users className="w-10 h-10 text-blue-400" />
                    </div>
                    <div className="flex flex-wrap gap-2 mt-3">
                      {Object.entries(patientData.summary.patients_by_phase || {}).map(([phase, count]) => (
                        <Badge key={phase} className="bg-white text-blue-700 border-blue-200">
                          {phase}: {count}
                        </Badge>
                      ))}
                    </div>
                  </CardContent>
                </Card>

                {/* Patient List */}
                <Card className="border-gray-100 bg-white">
                  <CardContent className="p-4 space-y-2">
                    {patientData.patients.length === 0 ? (
                      <p className="text-center text-gray-500 py-4">No patients found</p>
                    ) : (
                      patientData.patients.map((patient) => (
                        <PatientRow
                          key={patient.patient_id}
                          patient={patient}
                          onClick={() => loadPatientOrders(patient.ipd_id, patient)}
                        />
                      ))
                    )}
                  </CardContent>
                </Card>
              </>
            )}
          </TabsContent>

          {/* BILLING DASHBOARD TAB */}
          <TabsContent value="billing" className="mt-0 space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-semibold text-gray-800">Billing Summary</h2>
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleExport('billing')}
                data-testid="export-billing-btn"
              >
                <Download className="w-4 h-4 mr-1" /> Export
              </Button>
            </div>

            {/* Date Filters */}
            <Card className="border-gray-100 bg-white">
              <CardContent className="p-3">
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <Label className="text-xs text-gray-500">From Date</Label>
                    <Input
                      type="date"
                      value={billingFromDate}
                      onChange={(e) => setBillingFromDate(e.target.value)}
                      className="h-9"
                    />
                  </div>
                  <div>
                    <Label className="text-xs text-gray-500">To Date</Label>
                    <Input
                      type="date"
                      value={billingToDate}
                      onChange={(e) => setBillingToDate(e.target.value)}
                      className="h-9"
                    />
                  </div>
                </div>
                <Button
                  onClick={loadBillingDashboard}
                  className="w-full mt-2 h-9 bg-orange-500 hover:bg-orange-600"
                >
                  Apply Filters
                </Button>
              </CardContent>
            </Card>

            {billingData && (
              <>
                {/* Key Financial Metrics */}
                <div className="grid grid-cols-2 gap-3">
                  <Card className="bg-green-50 border-green-100">
                    <CardContent className="p-4">
                      <p className="text-2xl font-bold text-green-600">
                        ₹{billingData.total_billing_today.toLocaleString()}
                      </p>
                      <p className="text-sm text-green-700">Today's Billing</p>
                    </CardContent>
                  </Card>
                  <Card className="bg-blue-50 border-blue-100">
                    <CardContent className="p-4">
                      <p className="text-2xl font-bold text-blue-600">
                        ₹{billingData.total_billing_this_month.toLocaleString()}
                      </p>
                      <p className="text-sm text-blue-700">This Month</p>
                    </CardContent>
                  </Card>
                </div>

                {/* Period Summary */}
                <Card className="border-gray-100 bg-white">
                  <CardHeader className="pb-2">
                    <CardTitle className="text-base flex items-center gap-2">
                      <DollarSign className="w-5 h-5 text-orange-500" />
                      Period Summary
                    </CardTitle>
                    <CardDescription className="text-xs">
                      {billingData.period.from} to {billingData.period.to}
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="p-4 pt-0">
                    <div className="grid grid-cols-3 gap-2 text-center">
                      <div className="p-2 bg-gray-50 rounded">
                        <p className="text-lg font-bold text-gray-800">
                          ₹{billingData.period.total_amount.toLocaleString()}
                        </p>
                        <p className="text-xs text-gray-500">Total</p>
                      </div>
                      <div className="p-2 bg-green-50 rounded">
                        <p className="text-lg font-bold text-green-600">
                          ₹{billingData.period.paid_amount.toLocaleString()}
                        </p>
                        <p className="text-xs text-gray-500">Paid</p>
                      </div>
                      <div className="p-2 bg-amber-50 rounded">
                        <p className="text-lg font-bold text-amber-600">
                          ₹{billingData.period.pending_amount.toLocaleString()}
                        </p>
                        <p className="text-xs text-gray-500">Pending</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                {/* Billing by Department */}
                <Card className="border-gray-100 bg-white">
                  <CardHeader className="pb-2">
                    <CardTitle className="text-base flex items-center gap-2">
                      <Building2 className="w-5 h-5 text-blue-500" />
                      By Department
                    </CardTitle>
                    <CardDescription className="text-xs">Click to view orders from department</CardDescription>
                  </CardHeader>
                  <CardContent className="p-4 pt-0 space-y-2">
                    {Object.entries(billingData.billing_by_department || {}).map(([dept, info]) => (
                      <div 
                        key={dept} 
                        className="flex items-center justify-between p-2 bg-gray-50 rounded hover:bg-blue-50 cursor-pointer transition-colors"
                        onClick={() => navigate(`/orders?status=COMPLETED`)}
                        data-testid={`billing-dept-${dept}`}
                      >
                        <div className="flex items-center gap-2">
                          <span className="text-sm text-gray-700">{dept}</span>
                          <ChevronRight className="w-3 h-3 text-gray-400" />
                        </div>
                        <div className="text-right">
                          <p className="text-sm font-semibold">₹{info.amount.toLocaleString()}</p>
                          <p className="text-xs text-gray-500">{info.count} bills</p>
                        </div>
                      </div>
                    ))}
                  </CardContent>
                </Card>

                {/* Billing by Item (Top 10) */}
                <Card className="border-gray-100 bg-white">
                  <CardHeader className="pb-2">
                    <CardTitle className="text-base flex items-center gap-2">
                      <Package className="w-5 h-5 text-purple-500" />
                      Top Items
                    </CardTitle>
                  </CardHeader>
                  <CardContent className="p-4 pt-0 space-y-2">
                    {billingData.billing_by_item.slice(0, 10).map((item, idx) => (
                      <div key={idx} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                        <span className="text-sm text-gray-700 truncate flex-1">{item.item_name}</span>
                        <div className="text-right ml-2">
                          <p className="text-sm font-semibold">₹{item.amount.toLocaleString()}</p>
                          <p className="text-xs text-gray-500">{item.quantity} units</p>
                        </div>
                      </div>
                    ))}
                  </CardContent>
                </Card>

                {/* Billing by Consultant */}
                <Card className="border-gray-100 bg-white">
                  <CardHeader className="pb-2">
                    <CardTitle className="text-base flex items-center gap-2">
                      <UserPlus className="w-5 h-5 text-teal-500" />
                      By Consultant/Staff
                    </CardTitle>
                  </CardHeader>
                  <CardContent className="p-4 pt-0 space-y-2">
                    {billingData.billing_by_consultant.slice(0, 10).map((cons, idx) => (
                      <div key={idx} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                        <div>
                          <p className="text-sm text-gray-700">{cons.name}</p>
                          <p className="text-xs text-gray-500">{cons.designation}</p>
                        </div>
                        <div className="text-right">
                          <p className="text-sm font-semibold">₹{cons.amount.toLocaleString()}</p>
                          <p className="text-xs text-gray-500">{cons.orders_count} orders</p>
                        </div>
                      </div>
                    ))}
                  </CardContent>
                </Card>
              </>
            )}
          </TabsContent>
        </Tabs>
      </main>

      {/* Patient Orders Modal */}
      <Dialog open={showPatientModal} onOpenChange={setShowPatientModal}>
        <DialogContent className="max-w-lg max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-lg">
              {selectedPatient?.patient_name} - Orders
            </DialogTitle>
          </DialogHeader>
          
          {patientOrders && (
            <div className="space-y-4">
              {/* Patient Info */}
              <div className="p-3 bg-blue-50 rounded-lg">
                <p className="text-sm text-blue-700">
                  <strong>UHID:</strong> {patientOrders.patient.uhid}
                </p>
                <p className="text-sm text-blue-700">
                  <strong>IPD:</strong> {patientOrders.ipd.ipd_number} ({patientOrders.ipd.status})
                </p>
                <p className="text-sm text-blue-700">
                  <strong>Phase:</strong> {patientOrders.ipd.current_phase}
                </p>
              </div>

              {/* Summary */}
              <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                <span className="text-gray-600">Total Orders</span>
                <span className="text-xl font-bold">{patientOrders.summary.total_orders}</span>
              </div>
              <div className="flex justify-between items-center p-3 bg-green-50 rounded-lg">
                <span className="text-green-700">Total Billing</span>
                <span className="text-xl font-bold text-green-600">
                  ₹{patientOrders.summary.total_billing.toLocaleString()}
                </span>
              </div>

              {/* Orders List */}
              <div className="space-y-2">
                {patientOrders.orders.map((order) => (
                  <div key={order.order_id} className="p-3 bg-white border border-gray-200 rounded-lg">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium">{order.order_number}</p>
                        <p className="text-xs text-gray-500">
                          {order.items_count} items • {order.order_type}
                        </p>
                      </div>
                      <div className="text-right">
                        <Badge className={
                          order.status === 'COMPLETED' ? 'bg-green-100 text-green-700' :
                          order.status === 'CANCELLED' ? 'bg-red-100 text-red-700' :
                          'bg-orange-100 text-orange-700'
                        }>
                          {order.status}
                        </Badge>
                        {order.total_amount && (
                          <p className="text-sm font-semibold mt-1">
                            ₹{Number(order.total_amount).toLocaleString()}
                          </p>
                        )}
                      </div>
                    </div>
                    <p className="text-xs text-gray-400 mt-2">
                      Created: {new Date(order.created_at).toLocaleString()}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default AdminDashboardPage;
