import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../AuthContext';
import { 
  getSimulationMetrics, getSimulationSummary, runAllScenarios,
  runPatientAdmissionScenario, runClinicalOrderScenario,
  runPharmacyOrderScenario, runReturnOrderScenario, runPartialDispatchScenario,
  resetSimulationData
} from '../api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { toast } from 'sonner';
import { 
  ArrowLeft, Activity, Play, CheckCircle2, XCircle, Clock, 
  Package, Users, AlertTriangle, TrendingUp, RefreshCw,
  Loader2, ChevronDown, ChevronUp, UserPlus, TestTube,
  Pill, RotateCcw, Layers, Zap
} from 'lucide-react';

const SimulationPage = () => {
  const navigate = useNavigate();
  const { isAdmin } = useAuth();
  const [metrics, setMetrics] = useState(null);
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);
  const [runningScenario, setRunningScenario] = useState(null);
  const [scenarioResults, setScenarioResults] = useState({});
  const [expandedScenario, setExpandedScenario] = useState(null);
  const [runAllResult, setRunAllResult] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [metricsRes, summaryRes] = await Promise.all([
        getSimulationMetrics(),
        getSimulationSummary()
      ]);
      setMetrics(metricsRes.data);
      setSummary(summaryRes.data);
    } catch (e) {
      console.error(e);
      toast.error('Failed to load metrics');
    } finally {
      setLoading(false);
    }
  };

  const runScenario = async (scenarioKey, scenarioFn, scenarioName) => {
    setRunningScenario(scenarioKey);
    try {
      const res = await scenarioFn();
      setScenarioResults(prev => ({ ...prev, [scenarioKey]: res.data }));
      if (res.data.success) {
        toast.success(`${scenarioName} completed successfully!`);
      } else {
        toast.error(`${scenarioName} failed: ${res.data.errors.join(', ')}`);
      }
      loadData(); // Refresh metrics
    } catch (e) {
      toast.error(`Failed to run ${scenarioName}`);
      setScenarioResults(prev => ({ 
        ...prev, 
        [scenarioKey]: { success: false, errors: [e.message] } 
      }));
    } finally {
      setRunningScenario(null);
    }
  };

  const handleRunAll = async () => {
    setRunningScenario('all');
    setRunAllResult(null);
    try {
      const res = await runAllScenarios();
      setRunAllResult(res.data);
      if (res.data.all_passed) {
        toast.success('All scenarios passed!');
      } else {
        toast.warning(`${res.data.summary}`);
      }
      loadData();
    } catch (e) {
      toast.error('Failed to run all scenarios');
    } finally {
      setRunningScenario(null);
    }
  };

  const handleReset = async () => {
    if (!window.confirm('This will delete all simulation-generated data (orders with SIM/LAB/PHR/PRT/RET prefixes). Continue?')) {
      return;
    }
    setRunningScenario('reset');
    try {
      const res = await resetSimulationData();
      if (res.data.success) {
        toast.success(`Reset complete! Deleted: ${res.data.deleted.orders} orders, ${res.data.deleted.patients} patients`);
        setScenarioResults({});
        setRunAllResult(null);
        loadData();
      } else {
        toast.error(`Reset failed: ${res.data.message}`);
      }
    } catch (e) {
      toast.error('Failed to reset simulation data');
    } finally {
      setRunningScenario(null);
    }
  };

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
        <div className="animate-spin w-8 h-8 border-2 border-orange-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  const scenarios = [
    {
      key: 'admission',
      name: 'Patient Admission Flow',
      icon: UserPlus,
      color: 'blue',
      description: 'Create patient → Generate IPD → Admission order → Move to IPD phase',
      fn: runPatientAdmissionScenario
    },
    {
      key: 'clinical',
      name: 'Clinical Order Flow (Lab)',
      icon: TestTube,
      color: 'purple',
      description: 'Create Lab order → Route to Lab → Dispatch → Receive → Complete → Bill',
      fn: runClinicalOrderScenario
    },
    {
      key: 'pharmacy',
      name: 'Pharmacy Order Flow',
      icon: Pill,
      color: 'green',
      description: 'Ward orders medicine → Pharmacy dispatches → Ward receives → Complete',
      fn: runPharmacyOrderScenario
    },
    {
      key: 'partial',
      name: 'Partial Dispatch Flow',
      icon: Layers,
      color: 'orange',
      description: 'Order 100 units → Dispatch 40 → Dispatch 60 → Receive all → Complete',
      fn: runPartialDispatchScenario
    },
    {
      key: 'return',
      name: 'Return Order Flow',
      icon: RotateCcw,
      color: 'red',
      description: 'Find completed order → Create return → Dispatch back → Receive return',
      fn: runReturnOrderScenario
    },
  ];

  return (
    <div className="min-h-screen bg-gray-50 pb-6 safe-area-top">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white border-b border-gray-100 px-4 py-3">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate('/admin')} className="text-gray-600 hover:text-orange-500 hover:bg-orange-50">
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div className="flex items-center gap-2">
            <h1 className="text-xl font-bold text-orange-500">MTH</h1>
            <span className="text-gray-300">|</span>
            <span className="font-semibold text-gray-700">Simulation</span>
          </div>
          <Button 
            variant="ghost" 
            size="icon" 
            onClick={loadData} 
            disabled={runningScenario !== null}
            className="ml-auto text-gray-600"
          >
            <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </header>

      <main className="px-4 py-4 space-y-4">
        {/* Real-time Metrics */}
        <Card className="border-gray-200 bg-white">
          <CardHeader className="pb-2">
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg flex items-center gap-2">
                <Activity className="w-5 h-5 text-orange-500" />
                Live Operational Metrics
              </CardTitle>
              <Badge variant="outline" className="text-green-600 border-green-300">
                <span className="w-2 h-2 rounded-full bg-green-500 mr-1 animate-pulse" />
                Live
              </Badge>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-3">
              <MetricCard 
                label="Orders Today" 
                value={metrics?.orders_created_today || 0} 
                icon={Package}
                color="blue"
              />
              <MetricCard 
                label="Dispatched" 
                value={metrics?.orders_dispatched_today || 0} 
                icon={TrendingUp}
                color="green"
              />
              <MetricCard 
                label="Pending" 
                value={metrics?.orders_pending || 0} 
                icon={Clock}
                color="orange"
              />
              <MetricCard 
                label="Urgent" 
                value={metrics?.urgent_orders_pending || 0} 
                icon={AlertTriangle}
                color="red"
              />
              <MetricCard 
                label="Completed" 
                value={metrics?.orders_completed_today || 0} 
                icon={CheckCircle2}
                color="emerald"
              />
              <MetricCard 
                label="Admissions" 
                value={metrics?.patients_admitted_today || 0} 
                icon={Users}
                color="purple"
              />
            </div>
            
            {/* Billing */}
            <div className="mt-4 p-3 bg-green-50 rounded-lg border border-green-200">
              <div className="flex items-center justify-between">
                <span className="text-sm text-green-700">Billing Generated Today</span>
                <span className="text-lg font-bold text-green-700">
                  ₹{(metrics?.billing_generated_today || 0).toLocaleString()}
                </span>
              </div>
            </div>
            
            {/* Department Workload */}
            {metrics?.department_workload && Object.keys(metrics.department_workload).length > 0 && (
              <div className="mt-4">
                <p className="text-sm font-medium text-gray-500 mb-2">Department Workload (Pending)</p>
                <div className="space-y-2">
                  {Object.entries(metrics.department_workload).map(([dept, count]) => (
                    <div key={dept} className="flex items-center justify-between text-sm">
                      <span className="text-gray-600">{dept}</span>
                      <Badge variant="outline" className="text-orange-600 border-orange-300">{count}</Badge>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Run All Scenarios */}
        <Card className="border-orange-200 bg-gradient-to-br from-orange-50 to-amber-50">
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Zap className="w-5 h-5 text-orange-500" />
              Full Workflow Simulation
            </CardTitle>
            <CardDescription>
              Run all 5 scenarios to validate the complete operational engine
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex gap-2">
              <Button
                onClick={handleRunAll}
                disabled={runningScenario !== null}
                className="flex-1 h-14 text-base bg-orange-500 hover:bg-orange-600 shadow-lg"
                data-testid="run-all-scenarios-btn"
              >
                {runningScenario === 'all' ? (
                  <>
                    <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                    Running All...
                  </>
                ) : (
                  <>
                    <Play className="w-5 h-5 mr-2" />
                    Run All Scenarios
                  </>
                )}
              </Button>
              <Button
                onClick={handleReset}
                disabled={runningScenario !== null}
                variant="outline"
                className="h-14 px-4 border-red-300 text-red-600 hover:bg-red-50"
                data-testid="reset-simulation-btn"
              >
                {runningScenario === 'reset' ? (
                  <Loader2 className="w-5 h-5 animate-spin" />
                ) : (
                  <RotateCcw className="w-5 h-5" />
                )}
              </Button>
            </div>
            
            {runAllResult && (
              <div className={`mt-4 p-4 rounded-lg ${runAllResult.all_passed ? 'bg-green-100 border border-green-300' : 'bg-amber-100 border border-amber-300'}`}>
                <div className="flex items-center gap-2 mb-2">
                  {runAllResult.all_passed ? (
                    <CheckCircle2 className="w-5 h-5 text-green-600" />
                  ) : (
                    <AlertTriangle className="w-5 h-5 text-amber-600" />
                  )}
                  <span className={`font-semibold ${runAllResult.all_passed ? 'text-green-700' : 'text-amber-700'}`}>
                    {runAllResult.summary}
                  </span>
                </div>
                <div className="space-y-1">
                  {runAllResult.results.map((r, idx) => (
                    <div key={idx} className="flex items-center justify-between text-sm">
                      <span className="text-gray-600">{r.scenario}</span>
                      {r.success ? (
                        <Badge className="bg-green-100 text-green-700 border-0">
                          <CheckCircle2 className="w-3 h-3 mr-1" />
                          {r.steps} steps
                        </Badge>
                      ) : (
                        <Badge className="bg-red-100 text-red-700 border-0">
                          <XCircle className="w-3 h-3 mr-1" />
                          Failed
                        </Badge>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Individual Scenarios */}
        <Card className="border-gray-200 bg-white">
          <CardHeader>
            <CardTitle className="text-base">Individual Scenarios</CardTitle>
            <CardDescription className="text-xs">Run and verify specific workflow paths</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {scenarios.map((scenario) => (
              <ScenarioCard
                key={scenario.key}
                scenario={scenario}
                result={scenarioResults[scenario.key]}
                isRunning={runningScenario === scenario.key}
                isDisabled={runningScenario !== null}
                isExpanded={expandedScenario === scenario.key}
                onRun={() => runScenario(scenario.key, scenario.fn, scenario.name)}
                onToggleExpand={() => setExpandedScenario(expandedScenario === scenario.key ? null : scenario.key)}
              />
            ))}
          </CardContent>
        </Card>

        {/* Recent Activity */}
        {summary?.recent_orders?.length > 0 && (
          <Card className="border-gray-200 bg-white">
            <CardHeader className="pb-2">
              <CardTitle className="text-base">Recent Orders</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {summary.recent_orders.slice(0, 5).map((order) => (
                  <div key={order.id} className="flex items-center justify-between text-sm p-2 bg-gray-50 rounded">
                    <div>
                      <p className="font-medium text-gray-900">{order.order_number}</p>
                      <p className="text-xs text-gray-500">{order.patient_name} • {order.department}</p>
                    </div>
                    <Badge 
                      variant="outline"
                      className={
                        order.status === 'COMPLETED' ? 'text-green-600 border-green-300' :
                        order.status === 'CANCELLED' ? 'text-red-600 border-red-300' :
                        'text-orange-600 border-orange-300'
                      }
                    >
                      {order.status}
                    </Badge>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}

        {/* Verification Checklist */}
        <Card className="border-gray-200 bg-white">
          <CardHeader>
            <CardTitle className="text-base">Verification Checklist</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2 text-sm">
              <CheckItem label="Order routing works correctly" checked={runAllResult?.results?.some(r => r.scenario === 'Clinical Order (Lab)' && r.success)} />
              <CheckItem label="Dispatch queues behave correctly" checked={runAllResult?.results?.some(r => r.scenario === 'Pharmacy Order' && r.success)} />
              <CheckItem label="Partial dispatch works" checked={runAllResult?.results?.some(r => r.scenario === 'Partial Dispatch' && r.success)} />
              <CheckItem label="Returns work" checked={runAllResult?.results?.some(r => r.scenario === 'Return Order' && r.success)} />
              <CheckItem label="Billing triggers correctly" checked={metrics?.billing_generated_today > 0} />
              <CheckItem label="Audit trail is correct" checked={summary?.recent_dispatches?.length > 0} />
            </div>
          </CardContent>
        </Card>
      </main>
    </div>
  );
};

// Helper Components
const MetricCard = ({ label, value, icon: Icon, color }) => {
  const colors = {
    blue: 'bg-blue-100 text-blue-600',
    green: 'bg-green-100 text-green-600',
    orange: 'bg-orange-100 text-orange-600',
    red: 'bg-red-100 text-red-600',
    emerald: 'bg-emerald-100 text-emerald-600',
    purple: 'bg-purple-100 text-purple-600',
  };
  
  return (
    <div className="p-3 bg-gray-50 rounded-lg">
      <div className="flex items-center gap-2 mb-1">
        <div className={`p-1.5 rounded ${colors[color]}`}>
          <Icon className="w-4 h-4" />
        </div>
        <span className="text-xs text-gray-500">{label}</span>
      </div>
      <p className="text-2xl font-bold text-gray-900">{value}</p>
    </div>
  );
};

const ScenarioCard = ({ scenario, result, isRunning, isDisabled, isExpanded, onRun, onToggleExpand }) => {
  const colors = {
    blue: 'bg-blue-100 text-blue-600',
    purple: 'bg-purple-100 text-purple-600',
    green: 'bg-green-100 text-green-600',
    orange: 'bg-orange-100 text-orange-600',
    red: 'bg-red-100 text-red-600',
  };
  
  return (
    <div className={`border rounded-lg overflow-hidden ${result?.success === true ? 'border-green-300' : result?.success === false ? 'border-red-300' : 'border-gray-200'}`}>
      <div className="p-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className={`p-2 rounded ${colors[scenario.color]}`}>
              <scenario.icon className="w-4 h-4" />
            </div>
            <div>
              <p className="font-medium text-gray-900 text-sm">{scenario.name}</p>
              <p className="text-xs text-gray-500">{scenario.description}</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {result && (
              result.success ? (
                <CheckCircle2 className="w-5 h-5 text-green-500" />
              ) : (
                <XCircle className="w-5 h-5 text-red-500" />
              )
            )}
            <Button
              size="sm"
              onClick={onRun}
              disabled={isDisabled}
              className="bg-orange-500 hover:bg-orange-600"
            >
              {isRunning ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Play className="w-4 h-4" />
              )}
            </Button>
          </div>
        </div>
        
        {result && (
          <button 
            onClick={onToggleExpand}
            className="flex items-center gap-1 mt-2 text-xs text-gray-500 hover:text-gray-700"
          >
            {isExpanded ? <ChevronUp className="w-3 h-3" /> : <ChevronDown className="w-3 h-3" />}
            {result.steps_completed?.length || 0} steps
          </button>
        )}
      </div>
      
      {isExpanded && result?.steps_completed && (
        <div className="border-t border-gray-100 p-3 bg-gray-50">
          <div className="space-y-1">
            {result.steps_completed.map((step, idx) => (
              <div key={idx} className="flex items-center gap-2 text-xs">
                <span className="w-5 h-5 rounded-full bg-green-100 text-green-600 flex items-center justify-center font-medium">
                  {step.step}
                </span>
                <span className="text-gray-600">{step.action}</span>
                {step.data && (
                  <span className="text-gray-400">
                    ({Object.entries(step.data).map(([k, v]) => `${k}: ${v}`).join(', ')})
                  </span>
                )}
              </div>
            ))}
          </div>
          {result.errors?.length > 0 && (
            <div className="mt-2 p-2 bg-red-50 rounded text-xs text-red-600">
              Errors: {result.errors.join(', ')}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

const CheckItem = ({ label, checked }) => (
  <div className="flex items-center gap-2">
    {checked ? (
      <CheckCircle2 className="w-4 h-4 text-green-500" />
    ) : (
      <div className="w-4 h-4 rounded-full border-2 border-gray-300" />
    )}
    <span className={checked ? 'text-gray-900' : 'text-gray-500'}>{label}</span>
  </div>
);

export default SimulationPage;
