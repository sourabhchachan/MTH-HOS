import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { toast } from 'sonner';
import { 
  ArrowLeft, AlertTriangle, AlertCircle, Activity, RefreshCw,
  Search, Clock, User, Server, Database, Shield, ChevronRight,
  Terminal, FileText, Download, Zap, HardDrive, Play
} from 'lucide-react';

const levelConfig = {
  DEBUG: { label: 'Debug', class: 'bg-gray-100 text-gray-600', icon: Terminal },
  INFO: { label: 'Info', class: 'bg-blue-100 text-blue-600', icon: FileText },
  WARNING: { label: 'Warning', class: 'bg-amber-100 text-amber-600', icon: AlertTriangle },
  ERROR: { label: 'Error', class: 'bg-red-100 text-red-600', icon: AlertCircle },
  CRITICAL: { label: 'Critical', class: 'bg-red-200 text-red-700', icon: AlertCircle },
};

const errorTypeConfig = {
  API: { label: 'API', icon: Server },
  DATABASE: { label: 'Database', icon: Database },
  AUTH: { label: 'Auth', icon: Shield },
  ORDER: { label: 'Order', icon: FileText },
  BILLING: { label: 'Billing', icon: FileText },
  PERFORMANCE: { label: 'Performance', icon: Zap },
  SYSTEM: { label: 'System', icon: HardDrive },
};

const SystemLogsPage = () => {
  const navigate = useNavigate();
  const [tab, setTab] = useState('errors');
  const [systemLogs, setSystemLogs] = useState([]);
  const [activityLogs, setActivityLogs] = useState([]);
  const [systemStats, setSystemStats] = useState(null);
  const [activityStats, setActivityStats] = useState(null);
  const [healthSummary, setHealthSummary] = useState(null);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [levelFilter, setLevelFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  
  // Detail Modal
  const [detailLog, setDetailLog] = useState(null);
  const [detailModalOpen, setDetailModalOpen] = useState(false);
  
  // Backup State
  const [backupStatus, setBackupStatus] = useState(null);
  const [backupRunning, setBackupRunning] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [
        logsRes, activitiesRes, sysStatsRes, actStatsRes, healthRes, backupRes
      ] = await Promise.all([
        api.get('/system-logs', { params: { limit: 100 } }),
        api.get('/activity-logs', { params: { limit: 100 } }),
        api.get('/system-logs/stats'),
        api.get('/activity-logs/stats'),
        api.get('/system-health/summary'),
        api.get('/backups/status')
      ]);
      
      setSystemLogs(logsRes.data);
      setActivityLogs(activitiesRes.data);
      setSystemStats(sysStatsRes.data);
      setActivityStats(actStatsRes.data);
      setHealthSummary(healthRes.data);
      setBackupStatus(backupRes.data);
    } catch (error) {
      console.error('Failed to load logs:', error);
      toast.error('Failed to load system logs');
    } finally {
      setLoading(false);
    }
  };

  const handleBackup = async () => {
    setBackupRunning(true);
    try {
      const res = await api.post('/backups/create');
      if (res.data.success) {
        toast.success(`Backup created: ${res.data.filename}`);
        loadData();
      } else {
        toast.error(res.data.message);
      }
    } catch (error) {
      toast.error('Backup failed');
    } finally {
      setBackupRunning(false);
    }
  };

  const formatDate = (dateStr) => {
    return new Date(dateStr).toLocaleString('en-IN', {
      day: '2-digit',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  };

  // Filter system logs
  const filteredSystemLogs = systemLogs.filter(log => {
    const matchesSearch = 
      (log.endpoint || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (log.error_message || '').toLowerCase().includes(searchQuery.toLowerCase());
    
    const matchesLevel = levelFilter === 'all' || log.level === levelFilter;
    const matchesType = typeFilter === 'all' || log.error_type === typeFilter;
    
    return matchesSearch && matchesLevel && matchesType;
  });

  // Filter activity logs
  const filteredActivityLogs = activityLogs.filter(log => {
    return (
      (log.action_type || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (log.entity_identifier || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (log.user_name || '').toLowerCase().includes(searchQuery.toLowerCase())
    );
  });

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-2 border-orange-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white pb-20 safe-area-top">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white border-b border-gray-100 px-4 py-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <h1 className="text-xl font-bold text-orange-500">System Logs</h1>
          </div>
          <Button variant="ghost" size="icon" onClick={loadData}>
            <RefreshCw className="w-5 h-5" />
          </Button>
        </div>
      </header>

      {/* Health Summary Cards */}
      {healthSummary && (
        <div className="px-4 py-4 grid grid-cols-2 gap-3">
          <Card className={`${healthSummary.api_errors_today > 0 ? 'bg-red-50 border-red-200' : 'bg-emerald-50 border-emerald-200'}`}>
            <CardContent className="p-3">
              <div className="flex items-center gap-2 mb-1">
                <AlertCircle className={`w-4 h-4 ${healthSummary.api_errors_today > 0 ? 'text-red-500' : 'text-emerald-500'}`} />
                <span className="text-xs font-medium">API Errors Today</span>
              </div>
              <p className="text-2xl font-bold">{healthSummary.api_errors_today}</p>
            </CardContent>
          </Card>

          <Card className="bg-blue-50 border-blue-200">
            <CardContent className="p-3">
              <div className="flex items-center gap-2 mb-1">
                <Activity className="w-4 h-4 text-blue-500" />
                <span className="text-xs font-medium">Activities Today</span>
              </div>
              <p className="text-2xl font-bold">{healthSummary.activities_today}</p>
            </CardContent>
          </Card>

          <Card className={`${healthSummary.orders_pending_dispatch_critical > 0 ? 'bg-amber-50 border-amber-200' : 'bg-gray-50 border-gray-200'}`}>
            <CardContent className="p-3">
              <div className="flex items-center gap-2 mb-1">
                <Clock className={`w-4 h-4 ${healthSummary.orders_pending_dispatch_critical > 0 ? 'text-amber-500' : 'text-gray-500'}`} />
                <span className="text-xs font-medium">Critical Delays (&gt;2hr)</span>
              </div>
              <p className="text-2xl font-bold">{healthSummary.orders_pending_dispatch_critical}</p>
            </CardContent>
          </Card>

          <Card className={`${backupStatus?.has_recent_backup ? 'bg-emerald-50 border-emerald-200' : 'bg-amber-50 border-amber-200'}`}>
            <CardContent className="p-3">
              <div className="flex items-center gap-2 mb-1">
                <Database className={`w-4 h-4 ${backupStatus?.has_recent_backup ? 'text-emerald-500' : 'text-amber-500'}`} />
                <span className="text-xs font-medium">Backup Status</span>
              </div>
              <p className="text-sm font-bold">{backupStatus?.status || 'Unknown'}</p>
              <Button 
                size="sm" 
                variant="outline" 
                className="mt-2 h-7 text-xs"
                onClick={handleBackup}
                disabled={backupRunning}
              >
                {backupRunning ? 'Running...' : 'Run Backup'}
              </Button>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Search & Filters */}
      <div className="px-4 mb-4 space-y-2">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <Input
            placeholder="Search logs..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 h-11 bg-gray-50"
          />
        </div>
        
        {tab === 'errors' && (
          <div className="flex gap-2">
            <Select value={levelFilter} onValueChange={setLevelFilter}>
              <SelectTrigger className="w-[120px] h-9">
                <SelectValue placeholder="Level" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Levels</SelectItem>
                <SelectItem value="ERROR">Error</SelectItem>
                <SelectItem value="WARNING">Warning</SelectItem>
                <SelectItem value="CRITICAL">Critical</SelectItem>
              </SelectContent>
            </Select>

            <Select value={typeFilter} onValueChange={setTypeFilter}>
              <SelectTrigger className="w-[120px] h-9">
                <SelectValue placeholder="Type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Types</SelectItem>
                <SelectItem value="API">API</SelectItem>
                <SelectItem value="DATABASE">Database</SelectItem>
                <SelectItem value="AUTH">Auth</SelectItem>
                <SelectItem value="PERFORMANCE">Performance</SelectItem>
              </SelectContent>
            </Select>
          </div>
        )}
      </div>

      {/* Tabs */}
      <div className="px-4">
        <Tabs value={tab} onValueChange={setTab} className="w-full">
          <TabsList className="w-full grid grid-cols-2 mb-4 bg-gray-100">
            <TabsTrigger value="errors" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              System Logs ({systemStats?.total_errors_today || 0})
            </TabsTrigger>
            <TabsTrigger value="activity" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              Activity ({activityStats?.total_activities_today || 0})
            </TabsTrigger>
          </TabsList>

          <TabsContent value="errors" className="space-y-2 mt-0">
            {filteredSystemLogs.length === 0 ? (
              <div className="text-center py-12 text-gray-500">
                <AlertCircle className="w-12 h-12 mx-auto mb-2 opacity-50" />
                <p>No system logs found</p>
              </div>
            ) : (
              filteredSystemLogs.map((log) => {
                const config = levelConfig[log.level] || levelConfig.INFO;
                const typeConf = errorTypeConfig[log.error_type] || errorTypeConfig.SYSTEM;
                const LevelIcon = config.icon;
                const TypeIcon = typeConf.icon;
                
                return (
                  <Card 
                    key={log.id} 
                    className="bg-white cursor-pointer hover:shadow-md transition-shadow"
                    onClick={() => { setDetailLog(log); setDetailModalOpen(true); }}
                  >
                    <CardContent className="p-3">
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <Badge className={config.class}>
                              <LevelIcon className="w-3 h-3 mr-1" />
                              {config.label}
                            </Badge>
                            <Badge variant="outline" className="text-xs">
                              <TypeIcon className="w-3 h-3 mr-1" />
                              {typeConf.label}
                            </Badge>
                          </div>
                          <p className="text-sm font-medium truncate">{log.endpoint || 'System'}</p>
                          <p className="text-xs text-gray-500 truncate">{log.error_message}</p>
                          <div className="flex items-center gap-2 mt-1 text-xs text-gray-400">
                            <Clock className="w-3 h-3" />
                            <span>{formatDate(log.timestamp)}</span>
                            {log.duration_ms && (
                              <>
                                <span>•</span>
                                <span>{log.duration_ms}ms</span>
                              </>
                            )}
                          </div>
                        </div>
                        <ChevronRight className="w-5 h-5 text-gray-400" />
                      </div>
                    </CardContent>
                  </Card>
                );
              })
            )}
          </TabsContent>

          <TabsContent value="activity" className="space-y-2 mt-0">
            {filteredActivityLogs.length === 0 ? (
              <div className="text-center py-12 text-gray-500">
                <Activity className="w-12 h-12 mx-auto mb-2 opacity-50" />
                <p>No activity logs found</p>
              </div>
            ) : (
              filteredActivityLogs.map((log) => (
                <Card key={log.id} className="bg-white">
                  <CardContent className="p-3">
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <Badge variant="outline">{log.action_type?.replace(/_/g, ' ')}</Badge>
                          <Badge className="bg-gray-100 text-gray-600">{log.entity_type}</Badge>
                        </div>
                        {log.entity_identifier && (
                          <p className="text-sm font-medium">{log.entity_identifier}</p>
                        )}
                        <div className="flex items-center gap-2 mt-1 text-xs text-gray-400">
                          <User className="w-3 h-3" />
                          <span>{log.user_name || 'System'}</span>
                          <span>•</span>
                          <Clock className="w-3 h-3" />
                          <span>{formatDate(log.timestamp)}</span>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </TabsContent>
        </Tabs>
      </div>

      {/* Log Detail Modal */}
      <Dialog open={detailModalOpen} onOpenChange={setDetailModalOpen}>
        <DialogContent className="max-w-lg max-h-[85vh] overflow-auto">
          <DialogHeader>
            <DialogTitle>Log Details</DialogTitle>
          </DialogHeader>

          {detailLog && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <p className="text-xs text-gray-500">Level</p>
                  <Badge className={levelConfig[detailLog.level]?.class}>
                    {detailLog.level}
                  </Badge>
                </div>
                <div>
                  <p className="text-xs text-gray-500">Type</p>
                  <p className="font-medium">{detailLog.error_type}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">Endpoint</p>
                  <p className="font-medium">{detailLog.endpoint || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">Method</p>
                  <p className="font-medium">{detailLog.method || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">Status</p>
                  <p className="font-medium">{detailLog.response_status || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">Duration</p>
                  <p className="font-medium">{detailLog.duration_ms ? `${detailLog.duration_ms}ms` : 'N/A'}</p>
                </div>
              </div>

              <div>
                <p className="text-xs text-gray-500 mb-1">Error Message</p>
                <p className="text-sm bg-gray-50 p-2 rounded">{detailLog.error_message || 'N/A'}</p>
              </div>

              {detailLog.stack_trace && (
                <div>
                  <p className="text-xs text-gray-500 mb-1">Stack Trace</p>
                  <pre className="text-xs bg-gray-900 text-gray-100 p-3 rounded overflow-auto max-h-48">
                    {detailLog.stack_trace}
                  </pre>
                </div>
              )}

              <div className="grid grid-cols-2 gap-3 text-sm">
                <div>
                  <p className="text-xs text-gray-500">IP Address</p>
                  <p>{detailLog.ip_address || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">User</p>
                  <p>{detailLog.user_name || 'Anonymous'}</p>
                </div>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default SystemLogsPage;
