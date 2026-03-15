import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../AuthContext';
import { 
  getUsers, createUser, getDepartments, createDepartment,
  getItems, createItem, getVendors, createVendor,
  getItemCategories, createItemCategory
} from '../api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import { Switch } from '@/components/ui/switch';
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
  ArrowLeft, Users, Building2, Package, Truck,
  Plus, Settings
} from 'lucide-react';

const AdminPage = () => {
  const navigate = useNavigate();
  const { isAdmin } = useAuth();
  const [tab, setTab] = useState('users');

  if (!isAdmin) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="w-full max-w-sm">
          <CardContent className="p-6 text-center">
            <p className="text-muted-foreground">Admin access required</p>
            <Button className="mt-4" onClick={() => navigate('/')}>
              Go Back
            </Button>
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
          <Button variant="ghost" size="icon" onClick={() => navigate('/')}>
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div className="flex items-center gap-2">
            <Settings className="w-5 h-5 text-primary" />
            <h1 className="font-semibold text-lg">Admin Panel</h1>
          </div>
        </div>
      </header>

      <main className="px-4 py-4">
        <Tabs value={tab} onValueChange={setTab} className="w-full">
          <TabsList className="w-full grid grid-cols-4 mb-4">
            <TabsTrigger value="users" className="text-xs">
              <Users className="w-4 h-4" />
            </TabsTrigger>
            <TabsTrigger value="departments" className="text-xs">
              <Building2 className="w-4 h-4" />
            </TabsTrigger>
            <TabsTrigger value="items" className="text-xs">
              <Package className="w-4 h-4" />
            </TabsTrigger>
            <TabsTrigger value="vendors" className="text-xs">
              <Truck className="w-4 h-4" />
            </TabsTrigger>
          </TabsList>

          <TabsContent value="users" className="mt-0">
            <UsersTab />
          </TabsContent>

          <TabsContent value="departments" className="mt-0">
            <DepartmentsTab />
          </TabsContent>

          <TabsContent value="items" className="mt-0">
            <ItemsTab />
          </TabsContent>

          <TabsContent value="vendors" className="mt-0">
            <VendorsTab />
          </TabsContent>
        </Tabs>
      </main>
    </div>
  );
};

// Users Tab
const UsersTab = () => {
  const [users, setUsers] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState({
    phone: '', name: '', password: '', primary_department_id: '', is_admin: false
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [usersRes, deptsRes] = await Promise.all([getUsers(), getDepartments()]);
      setUsers(usersRes.data);
      setDepartments(deptsRes.data);
    } catch (error) {
      console.error('Failed to load users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async () => {
    try {
      await createUser({
        ...form,
        primary_department_id: parseInt(form.primary_department_id)
      });
      setDialogOpen(false);
      setForm({ phone: '', name: '', password: '', primary_department_id: '', is_admin: false });
      loadData();
    } catch (error) {
      alert(error.response?.data?.detail || 'Failed to create user');
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="font-semibold">Users ({users.length})</h2>
        <Button size="sm" onClick={() => setDialogOpen(true)} data-testid="add-user-btn">
          <Plus className="w-4 h-4 mr-1" /> Add User
        </Button>
      </div>

      {loading ? (
        <div className="text-center py-8">Loading...</div>
      ) : (
        <div className="space-y-2">
          {users.map(user => (
            <Card key={user.id} className="bg-card/50">
              <CardContent className="p-3">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium">{user.name}</p>
                    <p className="text-sm text-muted-foreground">{user.phone}</p>
                    <p className="text-xs text-muted-foreground">{user.primary_department?.name}</p>
                  </div>
                  <div className="flex gap-2">
                    {user.is_admin && <Badge>Admin</Badge>}
                    {!user.is_active && <Badge variant="destructive">Inactive</Badge>}
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
            <DialogTitle>Add User</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Phone Number</Label>
              <Input
                value={form.phone}
                onChange={e => setForm({...form, phone: e.target.value})}
                placeholder="10-digit phone"
              />
            </div>
            <div>
              <Label>Name</Label>
              <Input
                value={form.name}
                onChange={e => setForm({...form, name: e.target.value})}
                placeholder="Full name"
              />
            </div>
            <div>
              <Label>Password</Label>
              <Input
                type="password"
                value={form.password}
                onChange={e => setForm({...form, password: e.target.value})}
                placeholder="Password"
              />
            </div>
            <div>
              <Label>Primary Department</Label>
              <Select value={form.primary_department_id} onValueChange={v => setForm({...form, primary_department_id: v})}>
                <SelectTrigger>
                  <SelectValue placeholder="Select department" />
                </SelectTrigger>
                <SelectContent>
                  {departments.map(d => (
                    <SelectItem key={d.id} value={d.id.toString()}>{d.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="flex items-center gap-2">
              <Switch checked={form.is_admin} onCheckedChange={v => setForm({...form, is_admin: v})} />
              <Label>Admin Access</Label>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSubmit}>Create User</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

// Departments Tab
const DepartmentsTab = () => {
  const [departments, setDepartments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState({ name: '', code: '', description: '' });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const response = await getDepartments();
      setDepartments(response.data);
    } catch (error) {
      console.error('Failed to load departments:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async () => {
    try {
      await createDepartment(form);
      setDialogOpen(false);
      setForm({ name: '', code: '', description: '' });
      loadData();
    } catch (error) {
      alert(error.response?.data?.detail || 'Failed to create department');
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="font-semibold">Departments ({departments.length})</h2>
        <Button size="sm" onClick={() => setDialogOpen(true)} data-testid="add-dept-btn">
          <Plus className="w-4 h-4 mr-1" /> Add
        </Button>
      </div>

      {loading ? (
        <div className="text-center py-8">Loading...</div>
      ) : (
        <div className="space-y-2">
          {departments.map(dept => (
            <Card key={dept.id} className="bg-card/50">
              <CardContent className="p-3">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium">{dept.name}</p>
                    <p className="text-sm text-muted-foreground">{dept.code}</p>
                  </div>
                  <Badge variant={dept.is_active ? 'default' : 'secondary'}>
                    {dept.is_active ? 'Active' : 'Inactive'}
                  </Badge>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Department</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Name</Label>
              <Input
                value={form.name}
                onChange={e => setForm({...form, name: e.target.value})}
                placeholder="Department name"
              />
            </div>
            <div>
              <Label>Code</Label>
              <Input
                value={form.code}
                onChange={e => setForm({...form, code: e.target.value})}
                placeholder="Short code (e.g., PHRM)"
              />
            </div>
            <div>
              <Label>Description</Label>
              <Input
                value={form.description}
                onChange={e => setForm({...form, description: e.target.value})}
                placeholder="Description (optional)"
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSubmit}>Create</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

// Items Tab
const ItemsTab = () => {
  const [items, setItems] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState({
    name: '', code: '', unit: '', dispatching_department_id: '',
    category_id: '', all_departments_allowed: true, cost_per_unit: '0'
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [itemsRes, deptsRes, catsRes] = await Promise.all([
        getItems({ active_only: false }),
        getDepartments(),
        getItemCategories()
      ]);
      setItems(itemsRes.data);
      setDepartments(deptsRes.data);
      setCategories(catsRes.data);
    } catch (error) {
      console.error('Failed to load items:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async () => {
    try {
      await createItem({
        ...form,
        dispatching_department_id: parseInt(form.dispatching_department_id),
        category_id: form.category_id ? parseInt(form.category_id) : null,
        cost_per_unit: parseFloat(form.cost_per_unit) || 0
      });
      setDialogOpen(false);
      setForm({
        name: '', code: '', unit: '', dispatching_department_id: '',
        category_id: '', all_departments_allowed: true, cost_per_unit: '0'
      });
      loadData();
    } catch (error) {
      alert(error.response?.data?.detail || 'Failed to create item');
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="font-semibold">Items ({items.length})</h2>
        <Button size="sm" onClick={() => setDialogOpen(true)} data-testid="add-item-btn">
          <Plus className="w-4 h-4 mr-1" /> Add
        </Button>
      </div>

      {loading ? (
        <div className="text-center py-8">Loading...</div>
      ) : (
        <div className="space-y-2">
          {items.map(item => (
            <Card key={item.id} className="bg-card/50">
              <CardContent className="p-3">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium">{item.name}</p>
                    <p className="text-sm text-muted-foreground">
                      {item.code} • {item.unit} • {item.dispatching_department?.name}
                    </p>
                  </div>
                  <Badge variant={item.is_active ? 'default' : 'secondary'}>
                    {item.is_active ? 'Active' : 'Inactive'}
                  </Badge>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Add Item</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Name</Label>
              <Input
                value={form.name}
                onChange={e => setForm({...form, name: e.target.value})}
                placeholder="Item name"
              />
            </div>
            <div>
              <Label>Code</Label>
              <Input
                value={form.code}
                onChange={e => setForm({...form, code: e.target.value})}
                placeholder="Item code (e.g., MED001)"
              />
            </div>
            <div>
              <Label>Unit</Label>
              <Input
                value={form.unit}
                onChange={e => setForm({...form, unit: e.target.value})}
                placeholder="tablet, ml, piece, test"
              />
            </div>
            <div>
              <Label>Category</Label>
              <Select value={form.category_id} onValueChange={v => setForm({...form, category_id: v})}>
                <SelectTrigger>
                  <SelectValue placeholder="Select category" />
                </SelectTrigger>
                <SelectContent>
                  {categories.map(c => (
                    <SelectItem key={c.id} value={c.id.toString()}>{c.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>Dispatching Department</Label>
              <Select value={form.dispatching_department_id} onValueChange={v => setForm({...form, dispatching_department_id: v})}>
                <SelectTrigger>
                  <SelectValue placeholder="Select department" />
                </SelectTrigger>
                <SelectContent>
                  {departments.map(d => (
                    <SelectItem key={d.id} value={d.id.toString()}>{d.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>Cost per Unit</Label>
              <Input
                type="number"
                value={form.cost_per_unit}
                onChange={e => setForm({...form, cost_per_unit: e.target.value})}
                placeholder="0.00"
              />
            </div>
            <div className="flex items-center gap-2">
              <Switch 
                checked={form.all_departments_allowed} 
                onCheckedChange={v => setForm({...form, all_departments_allowed: v})} 
              />
              <Label>All Departments Can Order</Label>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSubmit}>Create Item</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

// Vendors Tab
const VendorsTab = () => {
  const [vendors, setVendors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState({ name: '', code: '', contact_person: '', phone: '' });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const response = await getVendors();
      setVendors(response.data);
    } catch (error) {
      console.error('Failed to load vendors:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async () => {
    try {
      await createVendor(form);
      setDialogOpen(false);
      setForm({ name: '', code: '', contact_person: '', phone: '' });
      loadData();
    } catch (error) {
      alert(error.response?.data?.detail || 'Failed to create vendor');
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="font-semibold">Vendors ({vendors.length})</h2>
        <Button size="sm" onClick={() => setDialogOpen(true)} data-testid="add-vendor-btn">
          <Plus className="w-4 h-4 mr-1" /> Add
        </Button>
      </div>

      {loading ? (
        <div className="text-center py-8">Loading...</div>
      ) : (
        <div className="space-y-2">
          {vendors.map(vendor => (
            <Card key={vendor.id} className="bg-card/50">
              <CardContent className="p-3">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium">{vendor.name}</p>
                    <p className="text-sm text-muted-foreground">
                      {vendor.code} • {vendor.contact_person || 'No contact'}
                    </p>
                  </div>
                  <Badge variant={vendor.is_active ? 'default' : 'secondary'}>
                    {vendor.is_active ? 'Active' : 'Inactive'}
                  </Badge>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Vendor</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Name</Label>
              <Input
                value={form.name}
                onChange={e => setForm({...form, name: e.target.value})}
                placeholder="Vendor name"
              />
            </div>
            <div>
              <Label>Code</Label>
              <Input
                value={form.code}
                onChange={e => setForm({...form, code: e.target.value})}
                placeholder="Vendor code"
              />
            </div>
            <div>
              <Label>Contact Person</Label>
              <Input
                value={form.contact_person}
                onChange={e => setForm({...form, contact_person: e.target.value})}
                placeholder="Contact name"
              />
            </div>
            <div>
              <Label>Phone</Label>
              <Input
                value={form.phone}
                onChange={e => setForm({...form, phone: e.target.value})}
                placeholder="Phone number"
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSubmit}>Create Vendor</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default AdminPage;
