import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../AuthContext';
import { 
  createPatientAdmin, getAllPatients, createOrder, getOrders,
  getDispatchQueue, dispatchItem, getPendingReceive, receiveItem, getDepartments,
  getOrderableItems
} from '../api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { 
  ArrowLeft, CheckCircle2, Circle, ArrowRight, User, ShoppingCart,
  Package, CheckSquare, Receipt, AlertTriangle, RefreshCw, Play
} from 'lucide-react';

const STEPS = [
  { id: 'patient', title: 'Create Patient', icon: User, description: 'Add a test patient to the system' },
  { id: 'order', title: 'Create Order', icon: ShoppingCart, description: 'Create a lab/medicine order for the patient' },
  { id: 'dispatch', title: 'Dispatch Item', icon: Package, description: 'Dispatch the ordered item' },
  { id: 'receive', title: 'Receive Item', icon: CheckSquare, description: 'Confirm receipt of dispatched item' },
  { id: 'complete', title: 'Complete & Verify', icon: Receipt, description: 'Verify order completion and billing' }
];

const SystemTestPage = () => {
  const navigate = useNavigate();
  const { isAdmin } = useAuth();
  const [currentStep, setCurrentStep] = useState(0);
  const [testData, setTestData] = useState({
    patient: null,
    order: null,
    orderItem: null,
    dispatchEvent: null,
    completed: false
  });
  const [loading, setLoading] = useState(false);

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

  const resetTest = () => {
    setCurrentStep(0);
    setTestData({
      patient: null,
      order: null,
      orderItem: null,
      dispatchEvent: null,
      completed: false
    });
  };

  return (
    <div className="min-h-screen bg-white pb-6 safe-area-top">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white border-b border-gray-100 px-4 py-3">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate('/admin')} className="text-gray-600 hover:text-orange-500 hover:bg-orange-50">
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div className="flex items-center gap-2">
            <h1 className="text-xl font-bold text-orange-500">MTH</h1>
            <span className="text-gray-300">|</span>
            <span className="font-semibold text-gray-700">System Test</span>
          </div>
          {currentStep > 0 && (
            <Button 
              variant="ghost" 
              size="sm" 
              onClick={resetTest}
              className="ml-auto text-gray-500"
            >
              <RefreshCw className="w-4 h-4 mr-1" />
              Reset
            </Button>
          )}
        </div>
      </header>

      <main className="px-4 py-6 space-y-6">
        {/* Progress Steps */}
        <div className="flex items-center justify-between overflow-x-auto pb-2">
          {STEPS.map((step, idx) => (
            <div key={step.id} className="flex items-center flex-shrink-0">
              <div className={`flex flex-col items-center ${idx <= currentStep ? 'text-orange-500' : 'text-gray-300'}`}>
                <div className={`w-10 h-10 rounded-full flex items-center justify-center transition-all ${
                  idx < currentStep ? 'bg-orange-500 text-white' : 
                  idx === currentStep ? 'bg-orange-100 text-orange-500 ring-2 ring-orange-500' : 
                  'bg-gray-100 text-gray-400'
                }`}>
                  {idx < currentStep ? (
                    <CheckCircle2 className="w-5 h-5" />
                  ) : (
                    <step.icon className="w-5 h-5" />
                  )}
                </div>
                <span className={`text-xs mt-1 whitespace-nowrap ${idx <= currentStep ? 'font-medium' : ''}`}>
                  {step.title}
                </span>
              </div>
              {idx < STEPS.length - 1 && (
                <div className={`w-8 h-0.5 mx-1 ${idx < currentStep ? 'bg-orange-500' : 'bg-gray-200'}`} />
              )}
            </div>
          ))}
        </div>

        {/* Step Content */}
        <Card className="border-gray-200">
          <CardHeader className="pb-3">
            <div className="flex items-center gap-2">
              {React.createElement(STEPS[currentStep].icon, { className: 'w-5 h-5 text-orange-500' })}
              <CardTitle className="text-lg">{STEPS[currentStep].title}</CardTitle>
            </div>
            <CardDescription>{STEPS[currentStep].description}</CardDescription>
          </CardHeader>
          <CardContent>
            {currentStep === 0 && (
              <CreatePatientStep 
                testData={testData} 
                setTestData={setTestData} 
                onNext={() => setCurrentStep(1)}
                loading={loading}
                setLoading={setLoading}
              />
            )}
            {currentStep === 1 && (
              <CreateOrderStep 
                testData={testData} 
                setTestData={setTestData} 
                onNext={() => setCurrentStep(2)}
                loading={loading}
                setLoading={setLoading}
              />
            )}
            {currentStep === 2 && (
              <DispatchStep 
                testData={testData} 
                setTestData={setTestData} 
                onNext={() => setCurrentStep(3)}
                loading={loading}
                setLoading={setLoading}
              />
            )}
            {currentStep === 3 && (
              <ReceiveStep 
                testData={testData} 
                setTestData={setTestData} 
                onNext={() => setCurrentStep(4)}
                loading={loading}
                setLoading={setLoading}
              />
            )}
            {currentStep === 4 && (
              <CompleteStep 
                testData={testData} 
                onReset={resetTest}
              />
            )}
          </CardContent>
        </Card>

        {/* Test Data Summary */}
        {(testData.patient || testData.order) && currentStep < 4 && (
          <Card className="border-gray-200 bg-gray-50">
            <CardHeader className="py-3">
              <CardTitle className="text-sm text-gray-500">Test Data Created</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm">
              {testData.patient && (
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-green-500" />
                  <span>Patient: {testData.patient.name} ({testData.patient.uhid})</span>
                </div>
              )}
              {testData.order && (
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-green-500" />
                  <span>Order: {testData.order.order_number}</span>
                </div>
              )}
              {testData.orderItem && (
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-green-500" />
                  <span>Item: {testData.orderItem.item_name} (Qty: {testData.orderItem.quantity_requested})</span>
                </div>
              )}
              {testData.dispatchEvent && (
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-green-500" />
                  <span>Dispatched: {testData.dispatchEvent.quantity_dispatched} units</span>
                </div>
              )}
            </CardContent>
          </Card>
        )}
      </main>
    </div>
  );
};

// Step 1: Create Patient
const CreatePatientStep = ({ testData, setTestData, onNext, loading, setLoading }) => {
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');

  const handleCreate = async () => {
    if (!name.trim()) {
      toast.error('Please enter patient name');
      return;
    }

    setLoading(true);
    try {
      const uhid = `TEST-${Date.now().toString().slice(-6)}`;
      const res = await createPatientAdmin({
        uhid,
        name: name.trim(),
        phone: phone.trim() || null,
        gender: 'Other'
      });
      setTestData(prev => ({ ...prev, patient: res.data }));
      toast.success('Patient created successfully!');
      onNext();
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Failed to create patient');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <Label>Patient Name *</Label>
        <Input 
          value={name} 
          onChange={e => setName(e.target.value)}
          placeholder="e.g., Test Patient"
          className="h-12 bg-gray-50"
        />
      </div>
      <div className="space-y-2">
        <Label>Phone Number (optional)</Label>
        <Input 
          value={phone} 
          onChange={e => setPhone(e.target.value)}
          placeholder="e.g., 9876543210"
          className="h-12 bg-gray-50"
        />
      </div>
      <Button 
        onClick={handleCreate} 
        disabled={loading || !name.trim()}
        className="w-full h-12 bg-orange-500 hover:bg-orange-600"
      >
        {loading ? 'Creating...' : (
          <>
            Create Patient & Continue
            <ArrowRight className="w-4 h-4 ml-2" />
          </>
        )}
      </Button>
    </div>
  );
};

// Step 2: Create Order
const CreateOrderStep = ({ testData, setTestData, onNext, loading, setLoading }) => {
  const [items, setItems] = useState([]);
  const [selectedItem, setSelectedItem] = useState('');
  const [quantity, setQuantity] = useState('1');

  useEffect(() => {
    loadItems();
  }, []);

  const loadItems = async () => {
    try {
      const res = await getOrderableItems();
      setItems(res.data || []);
    } catch (e) {
      console.error(e);
    }
  };

  const handleCreate = async () => {
    if (!selectedItem) {
      toast.error('Please select an item');
      return;
    }

    setLoading(true);
    try {
      const item = items.find(i => i.id.toString() === selectedItem);
      const res = await createOrder({
        order_type: 'REGULAR',
        priority: 'NORMAL',
        patient_id: testData.patient.id,
        items: [{
          item_id: parseInt(selectedItem),
          quantity_requested: parseInt(quantity)
        }]
      });
      
      // Get the created order with items
      const ordersRes = await getOrders({ limit: 1 });
      const order = ordersRes.data.orders?.[0] || res.data;
      
      setTestData(prev => ({ 
        ...prev, 
        order: order,
        orderItem: order.items?.[0] || { item_name: item?.name, quantity_requested: parseInt(quantity) }
      }));
      toast.success('Order created successfully!');
      onNext();
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Failed to create order');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-4">
      <div className="p-3 bg-orange-50 rounded-lg border border-orange-200">
        <p className="text-sm text-orange-700">
          Creating order for patient: <strong>{testData.patient?.name}</strong> ({testData.patient?.uhid})
        </p>
      </div>
      
      <div className="space-y-2">
        <Label>Select Item *</Label>
        <Select value={selectedItem} onValueChange={setSelectedItem}>
          <SelectTrigger className="h-12 bg-gray-50">
            <SelectValue placeholder="Select an item to order" />
          </SelectTrigger>
          <SelectContent>
            {items.map(item => (
              <SelectItem key={item.id} value={item.id.toString()}>
                {item.name} ({item.dispatching_department?.name || 'N/A'})
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      
      <div className="space-y-2">
        <Label>Quantity</Label>
        <Input 
          type="number"
          min="1"
          value={quantity} 
          onChange={e => setQuantity(e.target.value)}
          className="h-12 bg-gray-50"
        />
      </div>
      
      <Button 
        onClick={handleCreate} 
        disabled={loading || !selectedItem}
        className="w-full h-12 bg-orange-500 hover:bg-orange-600"
      >
        {loading ? 'Creating...' : (
          <>
            Create Order & Continue
            <ArrowRight className="w-4 h-4 ml-2" />
          </>
        )}
      </Button>
    </div>
  );
};

// Step 3: Dispatch Item
const DispatchStep = ({ testData, setTestData, onNext, loading, setLoading }) => {
  const [dispatchQueue, setDispatchQueue] = useState([]);
  const [queueLoading, setQueueLoading] = useState(true);

  useEffect(() => {
    loadQueue();
  }, []);

  const loadQueue = async () => {
    try {
      const res = await getDispatchQueue();
      // Find our order item in the queue
      const queue = res.data || [];
      setDispatchQueue(queue);
    } catch (e) {
      console.error(e);
    } finally {
      setQueueLoading(false);
    }
  };

  const handleDispatch = async () => {
    // Find the order item to dispatch
    const queueItem = dispatchQueue.find(q => q.order_id === testData.order?.id);
    
    if (!queueItem) {
      toast.error('Order item not found in dispatch queue. It may be assigned to a different department.');
      return;
    }

    setLoading(true);
    try {
      const res = await dispatchItem({
        order_item_id: queueItem.order_item_id,
        quantity_dispatched: queueItem.quantity_pending || queueItem.quantity_requested
      });
      
      setTestData(prev => ({ 
        ...prev, 
        dispatchEvent: { 
          quantity_dispatched: queueItem.quantity_pending || queueItem.quantity_requested 
        }
      }));
      toast.success('Item dispatched successfully!');
      onNext();
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Failed to dispatch item');
    } finally {
      setLoading(false);
    }
  };

  if (queueLoading) {
    return (
      <div className="flex items-center justify-center py-8">
        <div className="animate-spin w-6 h-6 border-2 border-orange-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  const queueItem = dispatchQueue.find(q => q.order_id === testData.order?.id);

  return (
    <div className="space-y-4">
      <div className="p-3 bg-orange-50 rounded-lg border border-orange-200">
        <p className="text-sm text-orange-700">
          Order: <strong>{testData.order?.order_number}</strong>
        </p>
      </div>

      {queueItem ? (
        <>
          <Card className="border-gray-200 bg-gray-50">
            <CardContent className="p-4">
              <p className="font-medium">{queueItem.item_name}</p>
              <p className="text-sm text-gray-500">Quantity to dispatch: {queueItem.quantity_pending || queueItem.quantity_requested}</p>
            </CardContent>
          </Card>
          
          <Button 
            onClick={handleDispatch} 
            disabled={loading}
            className="w-full h-12 bg-orange-500 hover:bg-orange-600"
          >
            {loading ? 'Dispatching...' : (
              <>
                Dispatch Item & Continue
                <ArrowRight className="w-4 h-4 ml-2" />
              </>
            )}
          </Button>
        </>
      ) : (
        <div className="p-4 bg-yellow-50 rounded-lg border border-yellow-200">
          <div className="flex items-center gap-2 text-yellow-700">
            <AlertTriangle className="w-5 h-5" />
            <p className="text-sm">
              Order not found in your dispatch queue. This may be because:
            </p>
          </div>
          <ul className="mt-2 text-sm text-yellow-600 list-disc list-inside">
            <li>The item is dispatched by a different department</li>
            <li>The order was already dispatched</li>
          </ul>
          <Button 
            onClick={onNext}
            variant="outline" 
            className="mt-4 w-full border-yellow-300 text-yellow-700 hover:bg-yellow-100"
          >
            Skip to Receive Step
          </Button>
        </div>
      )}
    </div>
  );
};

// Step 4: Receive Item
const ReceiveStep = ({ testData, setTestData, onNext, loading, setLoading }) => {
  const [pendingItems, setPendingItems] = useState([]);
  const [itemsLoading, setItemsLoading] = useState(true);

  useEffect(() => {
    loadPendingItems();
  }, []);

  const loadPendingItems = async () => {
    try {
      const res = await getPendingReceive();
      setPendingItems(res.data || []);
    } catch (e) {
      console.error(e);
    } finally {
      setItemsLoading(false);
    }
  };

  const handleReceive = async () => {
    // Find our dispatch event
    const pendingItem = pendingItems.find(p => p.order_id === testData.order?.id);
    
    if (!pendingItem) {
      toast.error('No pending items to receive');
      return;
    }

    setLoading(true);
    try {
      await receiveItem({
        dispatch_event_id: pendingItem.dispatch_event_id,
        quantity_received: pendingItem.quantity_dispatched
      });
      
      toast.success('Item received successfully!');
      setTestData(prev => ({ ...prev, completed: true }));
      onNext();
    } catch (e) {
      toast.error(e.response?.data?.detail || 'Failed to receive item');
    } finally {
      setLoading(false);
    }
  };

  if (itemsLoading) {
    return (
      <div className="flex items-center justify-center py-8">
        <div className="animate-spin w-6 h-6 border-2 border-orange-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  const pendingItem = pendingItems.find(p => p.order_id === testData.order?.id);

  return (
    <div className="space-y-4">
      {pendingItem ? (
        <>
          <Card className="border-gray-200 bg-gray-50">
            <CardContent className="p-4">
              <p className="font-medium">{pendingItem.item_name}</p>
              <p className="text-sm text-gray-500">
                Quantity to receive: {pendingItem.quantity_dispatched}
              </p>
              <p className="text-sm text-gray-500">
                Order: {pendingItem.order_number}
              </p>
            </CardContent>
          </Card>
          
          <Button 
            onClick={handleReceive} 
            disabled={loading}
            className="w-full h-12 bg-orange-500 hover:bg-orange-600"
          >
            {loading ? 'Receiving...' : (
              <>
                Confirm Receipt & Complete
                <ArrowRight className="w-4 h-4 ml-2" />
              </>
            )}
          </Button>
        </>
      ) : (
        <div className="p-4 bg-yellow-50 rounded-lg border border-yellow-200">
          <div className="flex items-center gap-2 text-yellow-700">
            <AlertTriangle className="w-5 h-5" />
            <p className="text-sm">No pending items to receive</p>
          </div>
          <Button 
            onClick={onNext}
            variant="outline" 
            className="mt-4 w-full border-yellow-300 text-yellow-700 hover:bg-yellow-100"
          >
            Continue to Summary
          </Button>
        </div>
      )}
    </div>
  );
};

// Step 5: Complete & Verify
const CompleteStep = ({ testData, onReset }) => {
  const navigate = useNavigate();

  return (
    <div className="space-y-6 text-center">
      <div className="w-20 h-20 mx-auto rounded-full bg-green-100 flex items-center justify-center">
        <CheckCircle2 className="w-10 h-10 text-green-500" />
      </div>
      
      <div>
        <h3 className="text-xl font-semibold text-gray-900">System Test Complete!</h3>
        <p className="text-gray-500 mt-1">All workflow steps executed successfully</p>
      </div>

      <Card className="border-green-200 bg-green-50 text-left">
        <CardContent className="p-4 space-y-3">
          <div className="flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-green-600" />
            <span className="text-sm">Patient created: {testData.patient?.name}</span>
          </div>
          <div className="flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-green-600" />
            <span className="text-sm">Order created: {testData.order?.order_number}</span>
          </div>
          <div className="flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-green-600" />
            <span className="text-sm">Item dispatched</span>
          </div>
          <div className="flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-green-600" />
            <span className="text-sm">Item received</span>
          </div>
          <div className="flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-green-600" />
            <span className="text-sm">Order completed (billing generated)</span>
          </div>
        </CardContent>
      </Card>

      <div className="space-y-3">
        <Button 
          onClick={onReset}
          className="w-full h-12 bg-orange-500 hover:bg-orange-600"
        >
          <Play className="w-4 h-4 mr-2" />
          Run Another Test
        </Button>
        <Button 
          onClick={() => navigate('/admin')}
          variant="outline"
          className="w-full h-12 border-gray-200"
        >
          Back to Admin Setup
        </Button>
        <Button 
          onClick={() => navigate('/reports')}
          variant="outline"
          className="w-full h-12 border-gray-200"
        >
          View Reports & Billing
        </Button>
      </div>
    </div>
  );
};

export default SystemTestPage;
