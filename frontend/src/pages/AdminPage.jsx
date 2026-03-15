import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../AuthContext';
import { 
  getAllUsers, createUser, updateUser, resetUserPassword,
  getAllDepartments, getDepartments, createDepartment, updateDepartment,
  getAllItems, createItem, updateItem, getItemCSVTemplate, uploadItemsCSV,
  getAllVendors, createVendor, updateVendor, toggleVendorActive,
  getItemCategories, createItemCategory, seedCategories,
  getAssets, createAsset, updateAsset, recordMaintenance,
  getAllPatients, createPatientAdmin, updatePatientAdmin
} from '../api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import { Switch } from '@/components/ui/switch';
import { Textarea } from '@/components/ui/textarea';
import { toast } from 'sonner';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { 
  ArrowLeft, Users, Building2, Package, Truck, Wrench, UserPlus,
  Plus, Settings, Edit2, Power, Upload, Download, Search, RefreshCw, Play, Database
} from 'lucide-react';

const AdminPage = () => {
  const navigate = useNavigate();
  const { isAdmin } = useAuth();
  const [tab, setTab] = useState('departments');

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

  return (
    <div className="min-h-screen bg-white pb-6 safe-area-top">
      <header className="sticky top-0 z-40 bg-white border-b border-gray-100 px-4 py-3">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate('/')} className="text-gray-600 hover:text-orange-500 hover:bg-orange-50">
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div className="flex items-center gap-2">
            <h1 className="text-xl font-bold text-orange-500">MTH</h1>
            <span className="text-gray-300">|</span>
            <span className="font-semibold text-gray-700">Admin Setup</span>
          </div>
        </div>
      </header>

      <main className="px-4 py-4">
        <Tabs value={tab} onValueChange={setTab} className="w-full">
          <TabsList className="w-full grid grid-cols-6 mb-4 bg-gray-100">
            <TabsTrigger value="departments" className="text-xs px-1 data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              <Building2 className="w-4 h-4" />
            </TabsTrigger>
            <TabsTrigger value="users" className="text-xs px-1 data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              <Users className="w-4 h-4" />
            </TabsTrigger>
            <TabsTrigger value="vendors" className="text-xs px-1 data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              <Truck className="w-4 h-4" />
            </TabsTrigger>
            <TabsTrigger value="items" className="text-xs px-1 data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              <Package className="w-4 h-4" />
            </TabsTrigger>
            <TabsTrigger value="assets" className="text-xs px-1 data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              <Wrench className="w-4 h-4" />
            </TabsTrigger>
            <TabsTrigger value="patients" className="text-xs px-1 data-[state=active]:bg-orange-500 data-[state=active]:text-white">
              <UserPlus className="w-4 h-4" />
            </TabsTrigger>
          </TabsList>

          <TabsContent value="departments"><DepartmentsTab /></TabsContent>
          <TabsContent value="users"><UsersTab /></TabsContent>
          <TabsContent value="vendors"><VendorsTab /></TabsContent>
          <TabsContent value="items"><ItemsTab /></TabsContent>
          <TabsContent value="assets"><AssetsTab /></TabsContent>
          <TabsContent value="patients"><PatientsTab /></TabsContent>
        </Tabs>

        {/* Data Seed Card */}
        <Card className="border-blue-200 bg-blue-50 mt-6">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium text-blue-700">Quick Data Setup</p>
                <p className="text-sm text-blue-600">Populate system with hospital operational data</p>
              </div>
              <Button 
                onClick={() => navigate('/data-seed')}
                className="bg-blue-500 hover:bg-blue-600"
                data-testid="data-seed-btn"
              >
                <Database className="w-4 h-4 mr-2" />
                Seed Data
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* System Test Button */}
        <Card className="border-orange-200 bg-orange-50 mt-4">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium text-orange-700">System Test Workflow</p>
                <p className="text-sm text-orange-600">Run end-to-end test: Patient → Order → Dispatch → Receive</p>
              </div>
              <Button 
                onClick={() => navigate('/system-test')}
                className="bg-orange-500 hover:bg-orange-600"
                data-testid="system-test-btn"
              >
                <Play className="w-4 h-4 mr-2" />
                Run Test
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Operational Simulation */}
        <Card className="border-purple-200 bg-purple-50 mt-4">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium text-purple-700">Operational Simulation</p>
                <p className="text-sm text-purple-600">Run hospital workflow simulations to validate operations</p>
              </div>
              <Button 
                onClick={() => navigate('/simulation')}
                className="bg-purple-500 hover:bg-purple-600"
                data-testid="simulation-btn"
              >
                <Play className="w-4 h-4 mr-2" />
                Simulate
              </Button>
            </div>
          </CardContent>
        </Card>
      </main>
    </div>
  );
};

// ============ DEPARTMENTS TAB ============
const DepartmentsTab = () => {
  const [departments, setDepartments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentId, setCurrentId] = useState(null);
  const [form, setForm] = useState({ name: '', code: '', description: '' });

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    try {
      const res = await getAllDepartments();
      setDepartments(res.data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const openCreate = () => {
    setEditMode(false);
    setCurrentId(null);
    setForm({ name: '', code: '', description: '' });
    setDialogOpen(true);
  };

  const openEdit = (dept) => {
    setEditMode(true);
    setCurrentId(dept.id);
    setForm({ name: dept.name, code: dept.code, description: dept.description || '' });
    setDialogOpen(true);
  };

  const handleSubmit = async () => {
    try {
      if (editMode) {
        await updateDepartment(currentId, form);
        toast.success('Department updated');
      } else {
        await createDepartment(form);
        toast.success('Department created');
      }
      setDialogOpen(false);
      loadData();
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Failed');
    }
  };

  const handleToggle = async (id) => {
    try {
      const dept = departments.find(d => d.id === id);
      await updateDepartment(id, { is_active: !dept.is_active });
      toast.success(`Department ${dept.is_active ? 'deactivated' : 'activated'}`);
      loadData();
    } catch (e) {
      toast.error('Failed to toggle');
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="font-semibold">Departments ({departments.length})</h2>
        <Button size="sm" onClick={openCreate} data-testid="add-dept-btn">
          <Plus className="w-4 h-4 mr-1" /> Add
        </Button>
      </div>

      {loading ? <div className="text-center py-8">Loading...</div> : (
        <div className="space-y-2">
          {departments.map(dept => (
            <Card key={dept.id} className={`bg-card/50 ${!dept.is_active ? 'opacity-50' : ''}`}>
              <CardContent className="p-3">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <p className="font-medium">{dept.name}</p>
                    <p className="text-sm text-muted-foreground">{dept.code}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant={dept.is_active ? 'default' : 'secondary'}>
                      {dept.is_active ? 'Active' : 'Inactive'}
                    </Badge>
                    <Button size="icon" variant="ghost" onClick={() => openEdit(dept)}>
                      <Edit2 className="w-4 h-4" />
                    </Button>
                    <Button size="icon" variant="ghost" onClick={() => handleToggle(dept.id)}>
                      <Power className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editMode ? 'Edit' : 'Add'} Department</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Name</Label>
              <Input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder="Department name" />
            </div>
            <div>
              <Label>Code</Label>
              <Input value={form.code} onChange={e => setForm({...form, code: e.target.value})} placeholder="Short code (e.g., PHRM)" disabled={editMode} />
            </div>
            <div>
              <Label>Description</Label>
              <Textarea value={form.description} onChange={e => setForm({...form, description: e.target.value})} placeholder="Description (optional)" />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSubmit}>{editMode ? 'Update' : 'Create'}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

// ============ USERS TAB ============
const UsersTab = () => {
  const [users, setUsers] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentId, setCurrentId] = useState(null);
  const [form, setForm] = useState({
    phone: '', name: '', password: '', primary_department_id: '', 
    is_admin: false, can_view_costs: false, designation: '', employee_code: ''
  });

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    try {
      const [usersRes, deptsRes] = await Promise.all([getAllUsers(), getDepartments()]);
      setUsers(usersRes.data);
      setDepartments(deptsRes.data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const openCreate = () => {
    setEditMode(false);
    setCurrentId(null);
    setForm({ phone: '', name: '', password: 'password123', primary_department_id: '', is_admin: false, can_view_costs: false, designation: '', employee_code: '' });
    setDialogOpen(true);
  };

  const openEdit = (user) => {
    setEditMode(true);
    setCurrentId(user.id);
    setForm({
      phone: user.phone, name: user.name, password: '',
      primary_department_id: user.primary_department_id?.toString() || '',
      is_admin: user.is_admin, can_view_costs: user.can_view_costs,
      designation: user.designation || '', employee_code: user.employee_code || ''
    });
    setDialogOpen(true);
  };

  const handleSubmit = async () => {
    try {
      if (editMode) {
        await updateUser(currentId, {
          name: form.name,
          primary_department_id: parseInt(form.primary_department_id),
          is_admin: form.is_admin,
          can_view_costs: form.can_view_costs,
          designation: form.designation,
          employee_code: form.employee_code
        });
        toast.success('User updated');
      } else {
        await createUser({
          ...form,
          primary_department_id: parseInt(form.primary_department_id)
        });
        toast.success('User created');
      }
      setDialogOpen(false);
      loadData();
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Failed');
    }
  };

  const handleToggle = async (id) => {
    try {
      const user = users.find(u => u.id === id);
      await updateUser(id, { is_active: !user.is_active });
      toast.success(`User ${user.is_active ? 'deactivated' : 'activated'}`);
      loadData();
    } catch (e) {
      toast.error('Failed to toggle');
    }
  };

  const handleResetPassword = async (id) => {
    if (!confirm('Reset password to "password123"?')) return;
    try {
      await resetUserPassword(id, 'password123');
      toast.success('Password reset to: password123');
    } catch (e) {
      toast.error('Failed to reset password');
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="font-semibold">Users ({users.length})</h2>
        <Button size="sm" onClick={openCreate} data-testid="add-user-btn">
          <Plus className="w-4 h-4 mr-1" /> Add User
        </Button>
      </div>

      {loading ? <div className="text-center py-8">Loading...</div> : (
        <div className="space-y-2">
          {users.map(user => (
            <Card key={user.id} className={`bg-card/50 ${!user.is_active ? 'opacity-50' : ''}`}>
              <CardContent className="p-3">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <p className="font-medium">{user.name}</p>
                    <p className="text-sm text-muted-foreground">{user.phone}</p>
                    <p className="text-xs text-muted-foreground">{user.primary_department} • {user.designation || 'Staff'}</p>
                  </div>
                  <div className="flex flex-col items-end gap-1">
                    <div className="flex gap-1">
                      {user.is_admin && <Badge variant="default">Admin</Badge>}
                      {!user.is_active && <Badge variant="destructive">Inactive</Badge>}
                    </div>
                    <div className="flex items-center gap-1">
                      <Button size="icon" variant="ghost" onClick={() => openEdit(user)}><Edit2 className="w-4 h-4" /></Button>
                      <Button size="icon" variant="ghost" onClick={() => handleToggle(user.id)}><Power className="w-4 h-4" /></Button>
                      <Button size="icon" variant="ghost" onClick={() => handleResetPassword(user.id)}><RefreshCw className="w-4 h-4" /></Button>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editMode ? 'Edit' : 'Add'} User</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Phone Number</Label>
              <Input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} placeholder="10-digit phone" disabled={editMode} />
            </div>
            <div>
              <Label>Name</Label>
              <Input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder="Full name" />
            </div>
            {!editMode && (
              <div>
                <Label>Password</Label>
                <Input type="password" value={form.password} onChange={e => setForm({...form, password: e.target.value})} placeholder="Default: password123" />
              </div>
            )}
            <div>
              <Label>Employee Code</Label>
              <Input value={form.employee_code} onChange={e => setForm({...form, employee_code: e.target.value})} placeholder="EMP001" />
            </div>
            <div>
              <Label>Designation</Label>
              <Input value={form.designation} onChange={e => setForm({...form, designation: e.target.value})} placeholder="Doctor, Nurse, etc." />
            </div>
            <div>
              <Label>Primary Department</Label>
              <Select value={form.primary_department_id} onValueChange={v => setForm({...form, primary_department_id: v})}>
                <SelectTrigger><SelectValue placeholder="Select department" /></SelectTrigger>
                <SelectContent>
                  {departments.map(d => <SelectItem key={d.id} value={d.id.toString()}>{d.name}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div className="flex items-center gap-2">
              <Switch checked={form.is_admin} onCheckedChange={v => setForm({...form, is_admin: v})} />
              <Label>Admin Access</Label>
            </div>
            <div className="flex items-center gap-2">
              <Switch checked={form.can_view_costs} onCheckedChange={v => setForm({...form, can_view_costs: v})} />
              <Label>Can View Costs</Label>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSubmit}>{editMode ? 'Update' : 'Create'}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

// ============ VENDORS TAB ============
const VendorsTab = () => {
  const [vendors, setVendors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentId, setCurrentId] = useState(null);
  const [form, setForm] = useState({ name: '', code: '', contact_person: '', phone: '', email: '', address: '', gst_number: '' });

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    try {
      const res = await getAllVendors();
      setVendors(res.data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const openCreate = () => {
    setEditMode(false);
    setCurrentId(null);
    setForm({ name: '', code: '', contact_person: '', phone: '', email: '', address: '', gst_number: '' });
    setDialogOpen(true);
  };

  const openEdit = (v) => {
    setEditMode(true);
    setCurrentId(v.id);
    setForm({
      name: v.name, code: v.code, contact_person: v.contact_person || '',
      phone: v.phone || '', email: v.email || '', address: v.address || '', gst_number: v.gst_number || ''
    });
    setDialogOpen(true);
  };

  const handleSubmit = async () => {
    try {
      if (editMode) {
        await updateVendor(currentId, form);
        toast.success('Vendor updated');
      } else {
        await createVendor(form);
        toast.success('Vendor created');
      }
      setDialogOpen(false);
      loadData();
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Failed');
    }
  };

  const handleToggle = async (id) => {
    try {
      await toggleVendorActive(id);
      toast.success('Vendor status toggled');
      loadData();
    } catch (e) {
      toast.error('Failed to toggle');
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="font-semibold">Vendors ({vendors.length})</h2>
        <Button size="sm" onClick={openCreate} data-testid="add-vendor-btn">
          <Plus className="w-4 h-4 mr-1" /> Add
        </Button>
      </div>

      {loading ? <div className="text-center py-8">Loading...</div> : (
        <div className="space-y-2">
          {vendors.map(v => (
            <Card key={v.id} className={`bg-card/50 ${!v.is_active ? 'opacity-50' : ''}`}>
              <CardContent className="p-3">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <p className="font-medium">{v.name}</p>
                    <p className="text-sm text-muted-foreground">{v.code} • {v.contact_person || 'No contact'}</p>
                    {v.phone && <p className="text-xs text-muted-foreground">{v.phone}</p>}
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant={v.is_active ? 'default' : 'secondary'}>
                      {v.is_active ? 'Active' : 'Inactive'}
                    </Badge>
                    <Button size="icon" variant="ghost" onClick={() => openEdit(v)}><Edit2 className="w-4 h-4" /></Button>
                    <Button size="icon" variant="ghost" onClick={() => handleToggle(v.id)}><Power className="w-4 h-4" /></Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editMode ? 'Edit' : 'Add'} Vendor</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div><Label>Name</Label><Input value={form.name} onChange={e => setForm({...form, name: e.target.value})} placeholder="Vendor name" /></div>
            <div><Label>Code</Label><Input value={form.code} onChange={e => setForm({...form, code: e.target.value})} placeholder="VEND001" disabled={editMode} /></div>
            <div><Label>Contact Person</Label><Input value={form.contact_person} onChange={e => setForm({...form, contact_person: e.target.value})} placeholder="Name" /></div>
            <div><Label>Phone</Label><Input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} placeholder="Phone" /></div>
            <div><Label>Email</Label><Input value={form.email} onChange={e => setForm({...form, email: e.target.value})} placeholder="Email" /></div>
            <div><Label>Address</Label><Textarea value={form.address} onChange={e => setForm({...form, address: e.target.value})} placeholder="Address" /></div>
            <div><Label>GST Number</Label><Input value={form.gst_number} onChange={e => setForm({...form, gst_number: e.target.value})} placeholder="GST" /></div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSubmit}>{editMode ? 'Update' : 'Create'}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

// ============ ITEMS TAB ============
const ItemsTab = () => {
  const [items, setItems] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [categories, setCategories] = useState([]);
  const [vendors, setVendors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [uploadDialogOpen, setUploadDialogOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentId, setCurrentId] = useState(null);
  const [uploadResult, setUploadResult] = useState(null);
  const fileInputRef = useRef(null);
  
  const defaultForm = {
    name: '', code: '', unit: '', category_id: '', dispatching_department_id: '',
    vendor_id: '', all_departments_allowed: true, ordering_department_ids: [],
    workflow_phase: '', priority_requirement: 'NON_MANDATORY',
    patient_ipd_requirement: 'NON_MANDATORY', ipd_status_allowed: 'BOTH', cost_per_unit: '0'
  };
  const [form, setForm] = useState(defaultForm);

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    try {
      const [itemsRes, deptsRes, catsRes, vendorsRes] = await Promise.all([
        getAllItems(), getDepartments(), getItemCategories(), getAllVendors()
      ]);
      setItems(itemsRes.data);
      setDepartments(deptsRes.data);
      setCategories(catsRes.data);
      setVendors(vendorsRes.data.filter(v => v.is_active));
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const openCreate = () => {
    setEditMode(false);
    setCurrentId(null);
    setForm(defaultForm);
    setDialogOpen(true);
  };

  const openEdit = (item) => {
    setEditMode(true);
    setCurrentId(item.id);
    setForm({
      name: item.name, code: item.code, unit: item.unit,
      category_id: item.category_id?.toString() || '',
      dispatching_department_id: item.dispatching_department_id?.toString() || '',
      vendor_id: item.vendor_id?.toString() || '',
      all_departments_allowed: item.all_departments_allowed,
      ordering_department_ids: item.ordering_department_ids || [],
      workflow_phase: item.workflow_phase || '',
      priority_requirement: item.priority_requirement || 'NON_MANDATORY',
      patient_ipd_requirement: item.patient_ipd_requirement || 'NON_MANDATORY',
      ipd_status_allowed: item.ipd_status_allowed || 'BOTH',
      cost_per_unit: item.cost_per_unit?.toString() || '0'
    });
    setDialogOpen(true);
  };

  const handleSubmit = async () => {
    try {
      const payload = {
        name: form.name,
        code: form.code,
        unit: form.unit,
        dispatching_department_id: parseInt(form.dispatching_department_id),
        category_id: form.category_id ? parseInt(form.category_id) : null,
        vendor_id: form.vendor_id ? parseInt(form.vendor_id) : null,
        all_departments_allowed: form.all_departments_allowed,
        ordering_department_ids: form.all_departments_allowed ? [] : form.ordering_department_ids,
        workflow_phase: form.workflow_phase || null,
        priority_requirement: form.priority_requirement,
        patient_ipd_requirement: form.patient_ipd_requirement,
        ipd_status_allowed: form.ipd_status_allowed,
        cost_per_unit: parseFloat(form.cost_per_unit) || 0
      };
      
      if (editMode) {
        await updateItem(currentId, payload);
        toast.success('Item updated');
      } else {
        await createItem(payload);
        toast.success('Item created');
      }
      setDialogOpen(false);
      loadData();
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Failed');
    }
  };

  const handleToggle = async (id) => {
    try {
      const item = items.find(i => i.id === id);
      await updateItem(id, { is_active: !item.is_active });
      toast.success(`Item ${item.is_active ? 'deactivated' : 'activated'}`);
      loadData();
    } catch (e) {
      toast.error('Failed to toggle');
    }
  };

  const downloadTemplate = async () => {
    try {
      const res = await getItemCSVTemplate();
      const { columns, sample_rows } = res.data;
      
      let csv = columns.join(',') + '\n';
      sample_rows.forEach(row => {
        csv += columns.map(col => `"${row[col] || ''}"`).join(',') + '\n';
      });
      
      const blob = new Blob([csv], { type: 'text/csv' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'item_template.csv';
      a.click();
    } catch (e) {
      toast.error('Failed to download template');
    }
  };

  const handleUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    
    try {
      const res = await uploadItemsCSV(file);
      setUploadResult(res.data);
      setUploadDialogOpen(true);
      loadData();
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Upload failed');
    }
    fileInputRef.current.value = '';
  };

  const handleSeedCategories = async () => {
    try {
      await seedCategories();
      toast.success('Categories seeded');
      loadData();
    } catch (e) {
      toast.error('Failed to seed categories');
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-2 flex-wrap">
        <h2 className="font-semibold">Item Master ({items.length})</h2>
        <div className="flex gap-2 flex-wrap">
          <Button size="sm" variant="outline" onClick={handleSeedCategories}>Seed Categories</Button>
          <Button size="sm" variant="outline" onClick={downloadTemplate}><Download className="w-4 h-4 mr-1" />Template</Button>
          <Button size="sm" variant="outline" onClick={() => fileInputRef.current?.click()}><Upload className="w-4 h-4 mr-1" />Upload CSV</Button>
          <input type="file" ref={fileInputRef} className="hidden" accept=".csv" onChange={handleUpload} />
          <Button size="sm" onClick={openCreate} data-testid="add-item-btn"><Plus className="w-4 h-4 mr-1" />Add</Button>
        </div>
      </div>

      {loading ? <div className="text-center py-8">Loading...</div> : (
        <div className="space-y-2">
          {items.map(item => (
            <Card key={item.id} className={`bg-card/50 ${!item.is_active ? 'opacity-50' : ''}`}>
              <CardContent className="p-3">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <p className="font-medium">{item.name}</p>
                    <p className="text-sm text-muted-foreground">{item.code} • {item.unit} • {item.dispatching_department}</p>
                    <p className="text-xs text-muted-foreground">{item.category || 'No category'} • Cost: ₹{item.cost_per_unit}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant={item.is_active ? 'default' : 'secondary'}>{item.is_active ? 'Active' : 'Inactive'}</Badge>
                    <Button size="icon" variant="ghost" onClick={() => openEdit(item)}><Edit2 className="w-4 h-4" /></Button>
                    <Button size="icon" variant="ghost" onClick={() => handleToggle(item.id)}><Power className="w-4 h-4" /></Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Item Form Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-h-[90vh] overflow-y-auto max-w-lg">
          <DialogHeader>
            <DialogTitle>{editMode ? 'Edit' : 'Add'} Item</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div><Label>Name*</Label><Input value={form.name} onChange={e => setForm({...form, name: e.target.value})} /></div>
              <div><Label>Code*</Label><Input value={form.code} onChange={e => setForm({...form, code: e.target.value})} disabled={editMode} /></div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div><Label>Unit*</Label><Input value={form.unit} onChange={e => setForm({...form, unit: e.target.value})} placeholder="tablet, test, ml" /></div>
              <div><Label>Cost per Unit</Label><Input type="number" value={form.cost_per_unit} onChange={e => setForm({...form, cost_per_unit: e.target.value})} /></div>
            </div>
            <div><Label>Category</Label>
              <Select value={form.category_id} onValueChange={v => setForm({...form, category_id: v})}>
                <SelectTrigger><SelectValue placeholder="Select category" /></SelectTrigger>
                <SelectContent>{categories.map(c => <SelectItem key={c.id} value={c.id.toString()}>{c.name}</SelectItem>)}</SelectContent>
              </Select>
            </div>
            <div><Label>Dispatching Department*</Label>
              <Select value={form.dispatching_department_id} onValueChange={v => setForm({...form, dispatching_department_id: v})}>
                <SelectTrigger><SelectValue placeholder="Select department" /></SelectTrigger>
                <SelectContent>{departments.map(d => <SelectItem key={d.id} value={d.id.toString()}>{d.name}</SelectItem>)}</SelectContent>
              </Select>
            </div>
            <div><Label>Vendor</Label>
              <Select value={form.vendor_id || "none"} onValueChange={v => setForm({...form, vendor_id: v === "none" ? "" : v})}>
                <SelectTrigger><SelectValue placeholder="Select vendor" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">None</SelectItem>
                  {vendors.map(v => <SelectItem key={v.id} value={v.id.toString()}>{v.name}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div className="flex items-center gap-2">
              <Switch checked={form.all_departments_allowed} onCheckedChange={v => setForm({...form, all_departments_allowed: v})} />
              <Label>All Departments Can Order</Label>
            </div>
            {!form.all_departments_allowed && (
              <div><Label>Departments Allowed to Order</Label>
                <div className="flex flex-wrap gap-2 mt-2">
                  {departments.map(d => (
                    <Badge key={d.id} variant={form.ordering_department_ids.includes(d.id) ? 'default' : 'outline'}
                      className="cursor-pointer"
                      onClick={() => {
                        const ids = form.ordering_department_ids.includes(d.id)
                          ? form.ordering_department_ids.filter(id => id !== d.id)
                          : [...form.ordering_department_ids, d.id];
                        setForm({...form, ordering_department_ids: ids});
                      }}>
                      {d.name}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
            <div><Label>Workflow Phase</Label>
              <Select value={form.workflow_phase || "any"} onValueChange={v => setForm({...form, workflow_phase: v === "any" ? "" : v})}>
                <SelectTrigger><SelectValue placeholder="Any phase" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="any">Any Phase</SelectItem>
                  <SelectItem value="PRE_ADMISSION">Pre-Admission</SelectItem>
                  <SelectItem value="ADMISSION">Admission</SelectItem>
                  <SelectItem value="IPD">IPD</SelectItem>
                  <SelectItem value="DISCHARGE">Discharge</SelectItem>
                  <SelectItem value="POST_DISCHARGE">Post-Discharge</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div><Label>Priority Requirement</Label>
                <Select value={form.priority_requirement} onValueChange={v => setForm({...form, priority_requirement: v})}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="NON_MANDATORY">Non-Mandatory</SelectItem>
                    <SelectItem value="MANDATORY">Mandatory (Urgent Only)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div><Label>Patient IPD Requirement</Label>
                <Select value={form.patient_ipd_requirement} onValueChange={v => setForm({...form, patient_ipd_requirement: v})}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="NON_MANDATORY">Non-Mandatory</SelectItem>
                    <SelectItem value="MANDATORY">Mandatory</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            {form.patient_ipd_requirement === 'MANDATORY' && (
              <div><Label>IPD Status Allowed</Label>
                <Select value={form.ipd_status_allowed} onValueChange={v => setForm({...form, ipd_status_allowed: v})}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="BOTH">Both Active & Inactive</SelectItem>
                    <SelectItem value="ACTIVE_ONLY">Active Only</SelectItem>
                    <SelectItem value="INACTIVE_ONLY">Inactive Only</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSubmit}>{editMode ? 'Update' : 'Create'}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Upload Result Dialog */}
      <Dialog open={uploadDialogOpen} onOpenChange={setUploadDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>CSV Upload Result</DialogTitle>
          </DialogHeader>
          {uploadResult && (
            <div className="space-y-4">
              <div className="grid grid-cols-3 gap-4 text-center">
                <div><p className="text-2xl font-bold text-green-500">{uploadResult.successful}</p><p className="text-sm text-muted-foreground">Successful</p></div>
                <div><p className="text-2xl font-bold text-red-500">{uploadResult.failed}</p><p className="text-sm text-muted-foreground">Failed</p></div>
                <div><p className="text-2xl font-bold">{uploadResult.total_rows}</p><p className="text-sm text-muted-foreground">Total Rows</p></div>
              </div>
              {uploadResult.errors.length > 0 && (
                <div className="max-h-48 overflow-y-auto">
                  <p className="font-medium mb-2">Errors:</p>
                  {uploadResult.errors.map((err, idx) => (
                    <div key={idx} className="text-sm text-red-500 mb-1">
                      Row {err.row} ({err.item_code}): {err.errors.join(', ')}
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
          <DialogFooter>
            <Button onClick={() => setUploadDialogOpen(false)}>Close</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

// ============ ASSETS TAB ============
const AssetsTab = () => {
  const [assets, setAssets] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [vendors, setVendors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentId, setCurrentId] = useState(null);
  
  const defaultForm = {
    asset_code: '', name: '', description: '', category: '',
    current_department_id: '', vendor_id: '', purchase_date: '', purchase_price: '', warranty_expiry: ''
  };
  const [form, setForm] = useState(defaultForm);

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    try {
      const [assetsRes, deptsRes, vendorsRes] = await Promise.all([
        getAssets(), getDepartments(), getAllVendors()
      ]);
      setAssets(assetsRes.data);
      setDepartments(deptsRes.data);
      setVendors(vendorsRes.data.filter(v => v.is_active));
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const openCreate = () => {
    setEditMode(false);
    setCurrentId(null);
    setForm(defaultForm);
    setDialogOpen(true);
  };

  const openEdit = (asset) => {
    setEditMode(true);
    setCurrentId(asset.id);
    setForm({
      asset_code: asset.asset_code, name: asset.name, description: asset.description || '',
      category: asset.category || '', current_department_id: asset.current_department_id?.toString() || '',
      vendor_id: asset.vendor_id?.toString() || '', purchase_date: asset.purchase_date || '',
      purchase_price: asset.purchase_price?.toString() || '', warranty_expiry: asset.warranty_expiry || ''
    });
    setDialogOpen(true);
  };

  const handleSubmit = async () => {
    try {
      const payload = {
        asset_code: form.asset_code,
        name: form.name,
        description: form.description || null,
        category: form.category || null,
        current_department_id: form.current_department_id ? parseInt(form.current_department_id) : null,
        vendor_id: form.vendor_id ? parseInt(form.vendor_id) : null,
        purchase_date: form.purchase_date || null,
        purchase_price: form.purchase_price ? parseFloat(form.purchase_price) : null,
        warranty_expiry: form.warranty_expiry || null
      };
      
      if (editMode) {
        await updateAsset(currentId, payload);
        toast.success('Asset updated');
      } else {
        await createAsset(payload);
        toast.success('Asset created');
      }
      setDialogOpen(false);
      loadData();
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Failed');
    }
  };

  const assetCategories = ['Medical Equipment', 'IT Equipment', 'Furniture', 'Vehicle', 'Building', 'Other'];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="font-semibold">Assets ({assets.length})</h2>
        <Button size="sm" onClick={openCreate} data-testid="add-asset-btn">
          <Plus className="w-4 h-4 mr-1" /> Add
        </Button>
      </div>

      {loading ? <div className="text-center py-8">Loading...</div> : (
        <div className="space-y-2">
          {assets.map(asset => (
            <Card key={asset.id} className="bg-card/50">
              <CardContent className="p-3">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <p className="font-medium">{asset.name}</p>
                    <p className="text-sm text-muted-foreground">{asset.asset_code} • {asset.category || 'No category'}</p>
                    <p className="text-xs text-muted-foreground">{asset.department_name || 'Unassigned'}</p>
                    {asset.next_maintenance_date && (
                      <p className="text-xs text-amber-500">Next maintenance: {asset.next_maintenance_date}</p>
                    )}
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant={asset.status === 'AVAILABLE' ? 'default' : 'secondary'}>{asset.status}</Badge>
                    <Button size="icon" variant="ghost" onClick={() => openEdit(asset)}><Edit2 className="w-4 h-4" /></Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editMode ? 'Edit' : 'Add'} Asset</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div><Label>Asset Code*</Label><Input value={form.asset_code} onChange={e => setForm({...form, asset_code: e.target.value})} placeholder="AST001" disabled={editMode} /></div>
              <div><Label>Name*</Label><Input value={form.name} onChange={e => setForm({...form, name: e.target.value})} /></div>
            </div>
            <div><Label>Description</Label><Textarea value={form.description} onChange={e => setForm({...form, description: e.target.value})} /></div>
            <div><Label>Category</Label>
              <Select value={form.category} onValueChange={v => setForm({...form, category: v})}>
                <SelectTrigger><SelectValue placeholder="Select category" /></SelectTrigger>
                <SelectContent>{assetCategories.map(c => <SelectItem key={c} value={c}>{c}</SelectItem>)}</SelectContent>
              </Select>
            </div>
            <div><Label>Department</Label>
              <Select value={form.current_department_id || "none"} onValueChange={v => setForm({...form, current_department_id: v === "none" ? "" : v})}>
                <SelectTrigger><SelectValue placeholder="Select department" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">None</SelectItem>
                  {departments.map(d => <SelectItem key={d.id} value={d.id.toString()}>{d.name}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div><Label>Vendor</Label>
              <Select value={form.vendor_id || "none"} onValueChange={v => setForm({...form, vendor_id: v === "none" ? "" : v})}>
                <SelectTrigger><SelectValue placeholder="Select vendor" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">None</SelectItem>
                  {vendors.map(v => <SelectItem key={v.id} value={v.id.toString()}>{v.name}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div><Label>Purchase Date</Label><Input type="date" value={form.purchase_date} onChange={e => setForm({...form, purchase_date: e.target.value})} /></div>
              <div><Label>Purchase Cost</Label><Input type="number" value={form.purchase_price} onChange={e => setForm({...form, purchase_price: e.target.value})} /></div>
            </div>
            <div><Label>Warranty Expiry</Label><Input type="date" value={form.warranty_expiry} onChange={e => setForm({...form, warranty_expiry: e.target.value})} /></div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSubmit}>{editMode ? 'Update' : 'Create'}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

// ============ PATIENTS TAB ============
const PatientsTab = () => {
  const [patients, setPatients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentId, setCurrentId] = useState(null);
  
  const defaultForm = { uhid: '', name: '', phone: '', address: '', gender: '', blood_group: '' };
  const [form, setForm] = useState(defaultForm);

  useEffect(() => { loadData(); }, [search]);

  const loadData = async () => {
    try {
      const res = await getAllPatients(search);
      setPatients(res.data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const openCreate = () => {
    setEditMode(false);
    setCurrentId(null);
    setForm({ ...defaultForm, uhid: `UHID-${Date.now().toString().slice(-6)}` });
    setDialogOpen(true);
  };

  const openEdit = (patient) => {
    setEditMode(true);
    setCurrentId(patient.id);
    setForm({
      uhid: patient.uhid, name: patient.name, phone: patient.phone || '',
      address: patient.address || '', gender: patient.gender || '', blood_group: patient.blood_group || ''
    });
    setDialogOpen(true);
  };

  const handleSubmit = async () => {
    try {
      if (editMode) {
        await updatePatientAdmin(currentId, form);
        toast.success('Patient updated');
      } else {
        await createPatientAdmin(form);
        toast.success('Patient created');
      }
      setDialogOpen(false);
      loadData();
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Failed');
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-2">
        <h2 className="font-semibold">Patients ({patients.length})</h2>
        <Button size="sm" onClick={openCreate} data-testid="add-patient-btn">
          <Plus className="w-4 h-4 mr-1" /> Add
        </Button>
      </div>
      
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <Input 
          placeholder="Search by UHID, name or phone..." 
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="pl-9"
        />
      </div>

      {loading ? <div className="text-center py-8">Loading...</div> : (
        <div className="space-y-2">
          {patients.map(patient => (
            <Card key={patient.id} className="bg-card/50">
              <CardContent className="p-3">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <p className="font-medium">{patient.name}</p>
                    <p className="text-sm text-muted-foreground">{patient.uhid}</p>
                    <p className="text-xs text-muted-foreground">{patient.phone || 'No phone'} • {patient.gender || 'N/A'} • {patient.blood_group || 'N/A'}</p>
                  </div>
                  <Button size="icon" variant="ghost" onClick={() => openEdit(patient)}><Edit2 className="w-4 h-4" /></Button>
                </div>
              </CardContent>
            </Card>
          ))}
          {patients.length === 0 && <p className="text-center text-muted-foreground py-8">No patients found</p>}
        </div>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editMode ? 'Edit' : 'Add'} Patient</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div><Label>UHID*</Label><Input value={form.uhid} onChange={e => setForm({...form, uhid: e.target.value})} disabled={editMode} /></div>
            <div><Label>Name*</Label><Input value={form.name} onChange={e => setForm({...form, name: e.target.value})} /></div>
            <div><Label>Phone</Label><Input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} /></div>
            <div className="grid grid-cols-2 gap-4">
              <div><Label>Gender</Label>
                <Select value={form.gender} onValueChange={v => setForm({...form, gender: v})}>
                  <SelectTrigger><SelectValue placeholder="Select" /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Male">Male</SelectItem>
                    <SelectItem value="Female">Female</SelectItem>
                    <SelectItem value="Other">Other</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div><Label>Blood Group</Label>
                <Select value={form.blood_group} onValueChange={v => setForm({...form, blood_group: v})}>
                  <SelectTrigger><SelectValue placeholder="Select" /></SelectTrigger>
                  <SelectContent>
                    {['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map(bg => (
                      <SelectItem key={bg} value={bg}>{bg}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div><Label>Address</Label><Textarea value={form.address} onChange={e => setForm({...form, address: e.target.value})} /></div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSubmit}>{editMode ? 'Update' : 'Create'}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default AdminPage;
