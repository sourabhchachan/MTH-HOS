import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { getOrderableItems, getIPDs, createOrder, getReturnReasons } from '../api';
import { useAuth } from '../AuthContext';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from '@/components/ui/sheet';
import { 
  ArrowLeft, Search, Plus, Minus, ShoppingCart, 
  AlertTriangle, Trash2, Check, User
} from 'lucide-react';

const CreateOrderPage = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [items, setItems] = useState([]);
  const [ipds, setIpds] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedItems, setSelectedItems] = useState([]);
  const [priority, setPriority] = useState('NORMAL');
  const [selectedIPD, setSelectedIPD] = useState(null);
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [cartOpen, setCartOpen] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [itemsRes, ipdsRes] = await Promise.all([
        getOrderableItems(),
        getIPDs({ status: 'ACTIVE' })
      ]);
      setItems(itemsRes.data);
      setIpds(ipdsRes.data);
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredItems = items.filter(item =>
    item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    item.code.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const addItem = (item) => {
    const existing = selectedItems.find(i => i.item_id === item.id);
    if (existing) {
      setSelectedItems(selectedItems.map(i =>
        i.item_id === item.id ? { ...i, quantity: i.quantity + 1 } : i
      ));
    } else {
      setSelectedItems([...selectedItems, {
        item_id: item.id,
        item: item,
        quantity: 1,
        notes: ''
      }]);
    }
  };

  const updateQuantity = (itemId, delta) => {
    setSelectedItems(selectedItems.map(i => {
      if (i.item_id === itemId) {
        const newQty = Math.max(1, i.quantity + delta);
        return { ...i, quantity: newQty };
      }
      return i;
    }));
  };

  const removeItem = (itemId) => {
    setSelectedItems(selectedItems.filter(i => i.item_id !== itemId));
  };

  const handleSubmit = async () => {
    if (selectedItems.length === 0) return;

    // Check if any item requires IPD
    const requiresIPD = selectedItems.some(i => 
      i.item.patient_ipd_requirement === 'MANDATORY'
    );
    
    if (requiresIPD && !selectedIPD) {
      alert('Some items require patient IPD selection');
      return;
    }

    setSubmitting(true);
    try {
      const orderData = {
        order_type: 'REGULAR',
        priority: priority,
        patient_id: selectedIPD?.patient_id || null,
        ipd_id: selectedIPD?.id || null,
        notes: notes,
        items: selectedItems.map(i => ({
          item_id: i.item_id,
          quantity_requested: i.quantity,
          notes: i.notes
        }))
      };

      await createOrder(orderData);
      navigate('/orders');
    } catch (error) {
      alert(error.response?.data?.detail || 'Failed to create order');
    } finally {
      setSubmitting(false);
    }
  };

  const totalItems = selectedItems.reduce((sum, i) => sum + i.quantity, 0);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-24 safe-area-top">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-background/95 backdrop-blur border-b border-border px-4 py-3">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <h1 className="font-semibold text-lg flex-1">Create Order</h1>
          <Sheet open={cartOpen} onOpenChange={setCartOpen}>
            <SheetTrigger asChild>
              <Button variant="secondary" size="icon" className="relative" data-testid="cart-btn">
                <ShoppingCart className="w-5 h-5" />
                {totalItems > 0 && (
                  <Badge className="absolute -top-1 -right-1 bg-primary text-primary-foreground h-5 w-5 p-0 flex items-center justify-center text-xs">
                    {totalItems}
                  </Badge>
                )}
              </Button>
            </SheetTrigger>
            <SheetContent side="bottom" className="h-[85vh] rounded-t-2xl">
              <SheetHeader>
                <SheetTitle>Order Cart ({totalItems} items)</SheetTitle>
              </SheetHeader>
              <div className="mt-4 space-y-4 overflow-auto h-[calc(100%-180px)]">
                {selectedItems.length === 0 ? (
                  <div className="text-center py-8 text-muted-foreground">
                    <ShoppingCart className="w-12 h-12 mx-auto mb-2 opacity-50" />
                    <p>Your cart is empty</p>
                  </div>
                ) : (
                  selectedItems.map((item) => (
                    <Card key={item.item_id} className="bg-secondary/30">
                      <CardContent className="p-3">
                        <div className="flex items-start justify-between gap-2">
                          <div className="flex-1 min-w-0">
                            <p className="font-medium truncate">{item.item.name}</p>
                            <p className="text-sm text-muted-foreground">
                              {item.item.unit} • {item.item.dispatching_department?.name}
                            </p>
                          </div>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="text-destructive h-8 w-8"
                            onClick={() => removeItem(item.item_id)}
                          >
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </div>
                        <div className="flex items-center justify-between mt-3">
                          <div className="flex items-center gap-2">
                            <Button
                              variant="secondary"
                              size="icon"
                              className="h-8 w-8"
                              onClick={() => updateQuantity(item.item_id, -1)}
                            >
                              <Minus className="w-4 h-4" />
                            </Button>
                            <span className="w-12 text-center font-semibold">{item.quantity}</span>
                            <Button
                              variant="secondary"
                              size="icon"
                              className="h-8 w-8"
                              onClick={() => updateQuantity(item.item_id, 1)}
                            >
                              <Plus className="w-4 h-4" />
                            </Button>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))
                )}
              </div>

              {/* Order Options */}
              {selectedItems.length > 0 && (
                <div className="space-y-4 mt-4 border-t border-border pt-4">
                  {/* Priority */}
                  <div className="flex items-center gap-3">
                    <Label className="w-20">Priority</Label>
                    <Select value={priority} onValueChange={setPriority}>
                      <SelectTrigger className="flex-1" data-testid="priority-select">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="NORMAL">Normal</SelectItem>
                        <SelectItem value="URGENT">
                          <span className="flex items-center gap-2">
                            <AlertTriangle className="w-4 h-4 text-amber-500" />
                            Urgent
                          </span>
                        </SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  {/* Patient/IPD Selection */}
                  <div className="flex items-center gap-3">
                    <Label className="w-20">Patient</Label>
                    <Select value={selectedIPD?.id?.toString() || ''} onValueChange={(v) => {
                      const ipd = ipds.find(i => i.id.toString() === v);
                      setSelectedIPD(ipd || null);
                    }}>
                      <SelectTrigger className="flex-1" data-testid="ipd-select">
                        <SelectValue placeholder="Select patient (optional)" />
                      </SelectTrigger>
                      <SelectContent>
                        {ipds.map(ipd => (
                          <SelectItem key={ipd.id} value={ipd.id.toString()}>
                            {ipd.patient?.name} - {ipd.ipd_number}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <Button
                    className="w-full h-12 touch-btn"
                    onClick={handleSubmit}
                    disabled={submitting || selectedItems.length === 0}
                    data-testid="submit-order-btn"
                  >
                    {submitting ? 'Creating...' : `Create Order (${totalItems} items)`}
                  </Button>
                </div>
              )}
            </SheetContent>
          </Sheet>
        </div>
      </header>

      <main className="px-4 py-4 space-y-4">
        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            placeholder="Search items..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 h-12 bg-secondary/50"
            data-testid="search-items-input"
          />
        </div>

        {/* Items List */}
        <div className="space-y-2">
          {filteredItems.map((item) => {
            const inCart = selectedItems.find(i => i.item_id === item.id);
            return (
              <Card 
                key={item.id} 
                className={`bg-card/50 cursor-pointer card-interactive ${
                  inCart ? 'border-primary/50' : ''
                }`}
                onClick={() => addItem(item)}
                data-testid={`item-${item.id}`}
              >
                <CardContent className="p-3">
                  <div className="flex items-center justify-between">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="font-medium truncate">{item.name}</p>
                        {item.patient_ipd_requirement === 'MANDATORY' && (
                          <User className="w-4 h-4 text-blue-400 flex-shrink-0" />
                        )}
                      </div>
                      <p className="text-sm text-muted-foreground">
                        {item.code} • {item.unit} • {item.dispatching_department?.name}
                      </p>
                    </div>
                    {inCart ? (
                      <Badge className="bg-primary text-primary-foreground">
                        <Check className="w-3 h-3 mr-1" /> {inCart.quantity}
                      </Badge>
                    ) : (
                      <Plus className="w-5 h-5 text-muted-foreground" />
                    )}
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      </main>

      {/* Floating Cart Button */}
      {totalItems > 0 && !cartOpen && (
        <div className="fixed bottom-4 left-4 right-4">
          <Button
            className="w-full h-14 touch-btn text-base"
            onClick={() => setCartOpen(true)}
            data-testid="view-cart-btn"
          >
            <ShoppingCart className="w-5 h-5 mr-2" />
            View Cart ({totalItems} items)
          </Button>
        </div>
      )}
    </div>
  );
};

export default CreateOrderPage;
