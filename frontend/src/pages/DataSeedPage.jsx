import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../AuthContext';
import { getSeedStatus, seedAllData, seedDepartments, seedVendors, seedCategoriesData } from '../api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { toast } from 'sonner';
import { 
  ArrowLeft, Database, Building2, Truck, Package, Wrench, Users,
  CheckCircle2, AlertCircle, Loader2, Sparkles, RefreshCw
} from 'lucide-react';

const DataSeedPage = () => {
  const navigate = useNavigate();
  const { isAdmin } = useAuth();
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(true);
  const [seeding, setSeeding] = useState(false);
  const [seedResult, setSeedResult] = useState(null);

  useEffect(() => {
    loadStatus();
  }, []);

  const loadStatus = async () => {
    try {
      const res = await getSeedStatus();
      setStatus(res.data);
    } catch (e) {
      console.error(e);
      toast.error('Failed to load seed status');
    } finally {
      setLoading(false);
    }
  };

  const handleSeedAll = async () => {
    if (!confirm('This will populate the system with hospital operational data. Continue?')) {
      return;
    }
    
    setSeeding(true);
    setSeedResult(null);
    
    try {
      const res = await seedAllData();
      setSeedResult(res.data);
      toast.success('Data seeding complete!');
      loadStatus();
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Seeding failed');
    } finally {
      setSeeding(false);
    }
  };

  const handleSeedModule = async (module, seedFn) => {
    setSeeding(true);
    try {
      const res = await seedFn();
      toast.success(`${module}: ${res.data.message}`);
      loadStatus();
    } catch (e) {
      toast.error(`Failed to seed ${module}`);
    } finally {
      setSeeding(false);
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

  const dataModules = [
    { key: 'departments', label: 'Departments', icon: Building2, count: status?.departments || 0, expected: 14, color: 'blue' },
    { key: 'vendors', label: 'Vendors', icon: Truck, count: status?.vendors || 0, expected: 8, color: 'purple' },
    { key: 'categories', label: 'Categories', icon: Package, count: status?.categories || 0, expected: 7, color: 'green' },
    { key: 'items', label: 'Items', icon: Package, count: status?.items || 0, expected: 45, color: 'orange' },
    { key: 'assets', label: 'Assets', icon: Wrench, count: status?.assets || 0, expected: 20, color: 'red' },
    { key: 'users', label: 'Users', icon: Users, count: status?.users || 0, expected: 22, color: 'indigo' },
  ];

  const totalExpected = dataModules.reduce((sum, m) => sum + m.expected, 0);
  const totalCurrent = dataModules.reduce((sum, m) => sum + m.count, 0);
  const progress = Math.min(100, Math.round((totalCurrent / totalExpected) * 100));

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
            <span className="font-semibold text-gray-700">Data Setup</span>
          </div>
          <Button 
            variant="ghost" 
            size="icon" 
            onClick={loadStatus} 
            disabled={seeding}
            className="ml-auto text-gray-600"
          >
            <RefreshCw className={`w-5 h-5 ${seeding ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </header>

      <main className="px-4 py-4 space-y-4">
        {/* Status Card */}
        <Card className="border-gray-200 bg-white">
          <CardHeader className="pb-2">
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg flex items-center gap-2">
                <Database className="w-5 h-5 text-orange-500" />
                System Data Status
              </CardTitle>
              {status?.is_seeded ? (
                <Badge className="bg-green-100 text-green-700 border-0">
                  <CheckCircle2 className="w-3 h-3 mr-1" />
                  Ready
                </Badge>
              ) : (
                <Badge className="bg-amber-100 text-amber-700 border-0">
                  <AlertCircle className="w-3 h-3 mr-1" />
                  Setup Required
                </Badge>
              )}
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-500">Overall Progress</span>
                <span className="font-medium">{progress}%</span>
              </div>
              <Progress value={progress} className="h-2" />
              
              <div className="grid grid-cols-3 gap-2 pt-2">
                {dataModules.map((mod) => (
                  <div key={mod.key} className="text-center p-2 rounded-lg bg-gray-50">
                    <mod.icon className="w-5 h-5 mx-auto text-gray-400 mb-1" />
                    <p className="text-lg font-bold text-gray-900">{mod.count}</p>
                    <p className="text-xs text-gray-500">{mod.label}</p>
                  </div>
                ))}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Quick Setup Card */}
        <Card className="border-orange-200 bg-gradient-to-br from-orange-50 to-amber-50">
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-orange-500" />
              Quick Setup
            </CardTitle>
            <CardDescription>
              Populate the system with operational hospital data in one click
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button
              onClick={handleSeedAll}
              disabled={seeding}
              className="w-full h-14 text-base bg-orange-500 hover:bg-orange-600 shadow-lg"
            >
              {seeding ? (
                <>
                  <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                  Seeding Data...
                </>
              ) : (
                <>
                  <Database className="w-5 h-5 mr-2" />
                  Seed All Operational Data
                </>
              )}
            </Button>
            <p className="text-xs text-gray-500 text-center mt-3">
              Creates 14 departments, 8 vendors, 45 items, 20 assets, and 22 staff users
            </p>
          </CardContent>
        </Card>

        {/* Seed Result */}
        {seedResult && (
          <Card className="border-green-200 bg-green-50">
            <CardHeader className="pb-2">
              <CardTitle className="text-base flex items-center gap-2 text-green-700">
                <CheckCircle2 className="w-5 h-5" />
                Seeding Complete!
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-600">Departments:</span>
                  <span className="font-medium text-green-700">+{seedResult.departments_created}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Vendors:</span>
                  <span className="font-medium text-green-700">+{seedResult.vendors_created}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Categories:</span>
                  <span className="font-medium text-green-700">+{seedResult.categories_created}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Items:</span>
                  <span className="font-medium text-green-700">+{seedResult.items_created}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Assets:</span>
                  <span className="font-medium text-green-700">+{seedResult.assets_created}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Users:</span>
                  <span className="font-medium text-green-700">+{seedResult.users_created}</span>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Data Included */}
        <Card className="border-gray-200 bg-white">
          <CardHeader>
            <CardTitle className="text-base">Data Included</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Departments */}
            <div>
              <div className="flex items-center gap-2 mb-2">
                <Building2 className="w-4 h-4 text-blue-500" />
                <span className="font-medium text-sm">14 Departments</span>
              </div>
              <div className="flex flex-wrap gap-1">
                {['Admin', 'Emergency', 'OPD', 'IPD Ward', 'ICU', 'Laboratory', 'Radiology', 'Pharmacy', 'Central Store', 'Billing', 'Accounts', 'Housekeeping', 'Maintenance', 'Biomedical'].map(d => (
                  <Badge key={d} variant="outline" className="text-xs">{d}</Badge>
                ))}
              </div>
            </div>

            {/* Items */}
            <div>
              <div className="flex items-center gap-2 mb-2">
                <Package className="w-4 h-4 text-orange-500" />
                <span className="font-medium text-sm">45+ Items</span>
              </div>
              <div className="text-xs text-gray-500 space-y-1">
                <p><strong>Lab Tests:</strong> CBC, Blood Sugar, LFT, KFT, Thyroid, Urine Routine, Blood Culture</p>
                <p><strong>Radiology:</strong> X-Ray, USG, CT Scan, MRI, ECG, 2D Echo</p>
                <p><strong>Medicines:</strong> Paracetamol, Amoxicillin, Omeprazole, Metformin, IV Fluids</p>
                <p><strong>Consumables:</strong> Syringes, Cannulas, Gloves, Cotton, Gauze, Masks</p>
                <p><strong>Services:</strong> Bed Cleaning, Sanitization, AC Maintenance, Equipment Service</p>
              </div>
            </div>

            {/* Vendors */}
            <div>
              <div className="flex items-center gap-2 mb-2">
                <Truck className="w-4 h-4 text-purple-500" />
                <span className="font-medium text-sm">8 Vendors</span>
              </div>
              <div className="text-xs text-gray-500">
                Medical suppliers, Diagnostic labs, Radiology centers, Biomedical maintenance, Equipment suppliers, Housekeeping/Laundry services
              </div>
            </div>

            {/* Assets */}
            <div>
              <div className="flex items-center gap-2 mb-2">
                <Wrench className="w-4 h-4 text-red-500" />
                <span className="font-medium text-sm">20 Assets</span>
              </div>
              <div className="text-xs text-gray-500">
                Ventilators, Patient Monitors, Infusion Pumps, Defibrillators, ECG Machines, Wheelchairs, Beds, AC Units, Computers
              </div>
            </div>

            {/* Users */}
            <div>
              <div className="flex items-center gap-2 mb-2">
                <Users className="w-4 h-4 text-indigo-500" />
                <span className="font-medium text-sm">22 Staff Users</span>
              </div>
              <div className="text-xs text-gray-500">
                Admins, Doctors, Nurses, Lab Technicians, Radiographers, Pharmacists, Store Staff, Housekeeping, Maintenance, Biomedical, Billing
              </div>
              <div className="mt-2 p-2 bg-amber-50 rounded border border-amber-200">
                <p className="text-xs text-amber-700">
                  <strong>Default Password:</strong> 1234 (for all seeded users)
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Individual Seed Buttons */}
        <Card className="border-gray-200 bg-white">
          <CardHeader>
            <CardTitle className="text-base">Seed Individual Modules</CardTitle>
            <CardDescription className="text-xs">Add data for specific modules only</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            <Button
              variant="outline"
              className="w-full justify-start"
              onClick={() => handleSeedModule('Departments', seedDepartments)}
              disabled={seeding}
            >
              <Building2 className="w-4 h-4 mr-2 text-blue-500" />
              Seed Departments Only
            </Button>
            <Button
              variant="outline"
              className="w-full justify-start"
              onClick={() => handleSeedModule('Vendors', seedVendors)}
              disabled={seeding}
            >
              <Truck className="w-4 h-4 mr-2 text-purple-500" />
              Seed Vendors Only
            </Button>
            <Button
              variant="outline"
              className="w-full justify-start"
              onClick={() => handleSeedModule('Categories', seedCategoriesData)}
              disabled={seeding}
            >
              <Package className="w-4 h-4 mr-2 text-green-500" />
              Seed Categories Only
            </Button>
          </CardContent>
        </Card>

        {/* Next Steps */}
        <Card className="border-gray-200 bg-white">
          <CardHeader>
            <CardTitle className="text-base">After Seeding</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Button
              variant="outline"
              className="w-full justify-start"
              onClick={() => navigate('/admin')}
            >
              <Building2 className="w-4 h-4 mr-2" />
              Review & Edit Master Data
            </Button>
            <Button
              variant="outline"
              className="w-full justify-start"
              onClick={() => navigate('/system-test')}
            >
              <CheckCircle2 className="w-4 h-4 mr-2" />
              Run System Test Workflow
            </Button>
          </CardContent>
        </Card>
      </main>
    </div>
  );
};

export default DataSeedPage;
