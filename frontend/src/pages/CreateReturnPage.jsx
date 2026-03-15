import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { getOrders, getReturnReasons, createOrder } from '../api';
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
  ArrowLeft, Search, RotateCcw, ShoppingCart, 
  Plus, Minus, Trash2, Check
} from 'lucide-react';

const CreateReturnPage = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const preselectedOrderId = location.state?.orderId;
  
  const [orders, setOrders] = useState([]);
  const [returnReasons, setReturnReasons] = useState([]);
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [returnItems, setReturnItems] = useState([]);
  const [returnReason, setReturnReason] = useState('');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [cartOpen, setCartOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [ordersRes, reasonsRes] = await Promise.all([
        getOrders({ status: 'COMPLETED', limit: 100 }),
        getReturnReasons()
      ]);
      setOrders(ordersRes.data);
      setReturnReasons(reasonsRes.data);
      
      // Preselect order if provided
      if (preselectedOrderId) {
        const order = ordersRes.data.find(o => o.id === preselectedOrderId);
        if (order) selectOrder(order);
      }
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setLoading(false);
    }
  };

  const selectOrder = (order) => {
    setSelectedOrder(order);
    // Initialize return items from order items
    setReturnItems(order.items.map(item => ({
      original_order_item_id: item.id,
      item_id: item.item_id,
      item: item.item,
      max_quantity: item.quantity_received || item.quantity_dispatched,
      quantity: 0,
      return_reason: ''
    })));
  };

  const updateReturnQuantity = (itemId, delta) => {
    setReturnItems(returnItems.map(item => {
      if (item.item_id === itemId) {
        const newQty = Math.max(0, Math.min(item.max_quantity, item.quantity + delta));
        return { ...item, quantity: newQty };
      }
      return item;
    }));
  };

  const setItemReturnReason = (itemId, reason) => {
    setReturnItems(returnItems.map(item => {
      if (item.item_id === itemId) {
        return { ...item, return_reason: reason };
      }
      return item;
    }));
  };

  const handleSubmit = async () => {
    const itemsToReturn = returnItems.filter(i => i.quantity > 0);
    
    if (itemsToReturn.length === 0) {
      alert('Please select at least one item to return');
      return;
    }

    if (!returnReason) {
      alert('Please select a return reason');
      return;
    }

    setSubmitting(true);
    try {
      const returnData = {
        order_type: 'RETURN',
        original_order_id: selectedOrder.id,
        return_reason: returnReason,
        patient_id: selectedOrder.patient_id,
        ipd_id: selectedOrder.ipd_id,
        priority: 'NORMAL',
        notes: notes,
        items: itemsToReturn.map(item => ({
          item_id: item.item_id,
          quantity_requested: item.quantity,
          original_order_item_id: item.original_order_item_id,
          return_reason: item.return_reason || returnReason
        }))
      };

      await createOrder(returnData);
      navigate('/orders');
    } catch (error) {
      alert(error.response?.data?.detail || 'Failed to create return order');
    } finally {
      setSubmitting(false);
    }
  };

  const filteredOrders = orders.filter(order =>
    order.order_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (order.patient?.name || '').toLowerCase().includes(searchQuery.toLowerCase())
  );

  const totalReturnItems = returnItems.reduce((sum, i) => sum + (i.quantity > 0 ? 1 : 0), 0);
  const totalReturnQty = returnItems.reduce((sum, i) => sum + i.quantity, 0);

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
          <h1 className="font-semibold text-lg flex-1">Create Return</h1>
          {selectedOrder && (
            <Sheet open={cartOpen} onOpenChange={setCartOpen}>
              <SheetTrigger asChild>
                <Button variant="secondary" size="icon" className="relative" data-testid="return-cart-btn">
                  <RotateCcw className="w-5 h-5" />
                  {totalReturnItems > 0 && (
                    <Badge className="absolute -top-1 -right-1 bg-destructive text-destructive-foreground h-5 w-5 p-0 flex items-center justify-center text-xs">
                      {totalReturnItems}
                    </Badge>
                  )}
                </Button>
              </SheetTrigger>
              <SheetContent side="bottom" className="h-[85vh] rounded-t-2xl">
                <SheetHeader>
                  <SheetTitle>Return Items ({totalReturnItems})</SheetTitle>
                </SheetHeader>
                <div className="mt-4 space-y-4 overflow-auto h-[calc(100%-200px)]">
                  {returnItems.filter(i => i.quantity > 0).length === 0 ? (
                    <div className="text-center py-8 text-muted-foreground">
                      <RotateCcw className="w-12 h-12 mx-auto mb-2 opacity-50" />
                      <p>No items selected for return</p>
                    </div>
                  ) : (
                    returnItems.filter(i => i.quantity > 0).map((item) => (
                      <Card key={item.item_id} className="bg-secondary/30">
                        <CardContent className="p-3">
                          <div className="flex items-start justify-between gap-2">
                            <div className="flex-1 min-w-0">
                              <p className="font-medium truncate">{item.item?.name}</p>
                              <p className="text-sm text-muted-foreground">
                                Max returnable: {item.max_quantity}
                              </p>
                            </div>
                            <Badge variant="destructive">{item.quantity}</Badge>
                          </div>
                          <div className="mt-2">
                            <Input
                              placeholder="Item-specific reason (optional)"
                              value={item.return_reason}
                              onChange={(e) => setItemReturnReason(item.item_id, e.target.value)}
                              className="text-sm h-8"
                            />
                          </div>
                        </CardContent>
                      </Card>
                    ))
                  )}
                </div>

                {/* Return Options */}
                {totalReturnItems > 0 && (
                  <div className="space-y-4 mt-4 border-t border-border pt-4">
                    <div>
                      <Label>Return Reason *</Label>
                      <Select value={returnReason} onValueChange={setReturnReason}>
                        <SelectTrigger data-testid="return-reason-select">
                          <SelectValue placeholder="Select reason" />
                        </SelectTrigger>
                        <SelectContent>
                          {returnReasons.map(reason => (
                            <SelectItem key={reason.id} value={reason.reason}>
                              {reason.reason}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>

                    <div>
                      <Label>Notes (Optional)</Label>
                      <Textarea
                        value={notes}
                        onChange={(e) => setNotes(e.target.value)}
                        placeholder="Additional notes..."
                        rows={2}
                      />
                    </div>

                    <Button
                      className="w-full h-12 touch-btn bg-destructive hover:bg-destructive/90"
                      onClick={handleSubmit}
                      disabled={submitting || !returnReason}
                      data-testid="submit-return-btn"
                    >
                      {submitting ? 'Creating...' : `Create Return (${totalReturnQty} items)`}
                    </Button>
                  </div>
                )}
              </SheetContent>
            </Sheet>
          )}
        </div>
      </header>

      <main className="px-4 py-4 space-y-4">
        {!selectedOrder ? (
          <>
            {/* Order Selection */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                placeholder="Search completed orders..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10 h-12 bg-secondary/50"
              />
            </div>

            <p className="text-sm text-muted-foreground">
              Select a completed order to create a return
            </p>

            <div className="space-y-2">
              {filteredOrders.map((order) => (
                <Card 
                  key={order.id} 
                  className="bg-card/50 cursor-pointer card-interactive"
                  onClick={() => selectOrder(order)}
                  data-testid={`order-select-${order.id}`}
                >
                  <CardContent className="p-3">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-semibold">{order.order_number}</p>
                        <p className="text-sm text-muted-foreground">
                          {order.items?.length || 0} items • {new Date(order.completed_at).toLocaleDateString()}
                        </p>
                        {order.patient && (
                          <p className="text-sm text-primary">{order.patient.name}</p>
                        )}
                      </div>
                      <Badge className="status-completed">Completed</Badge>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </>
        ) : (
          <>
            {/* Selected Order Info */}
            <Card className="bg-primary/10 border-primary/30">
              <CardContent className="p-3">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-semibold">Returning from: {selectedOrder.order_number}</p>
                    {selectedOrder.patient && (
                      <p className="text-sm text-muted-foreground">{selectedOrder.patient.name}</p>
                    )}
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => {
                      setSelectedOrder(null);
                      setReturnItems([]);
                    }}
                  >
                    Change
                  </Button>
                </div>
              </CardContent>
            </Card>

            {/* Items to Return */}
            <h2 className="font-semibold">Select Items to Return</h2>
            <div className="space-y-2">
              {returnItems.map((item) => {
                const isSelected = item.quantity > 0;
                return (
                  <Card 
                    key={item.item_id} 
                    className={`bg-card/50 ${isSelected ? 'border-destructive/50' : ''}`}
                    data-testid={`return-item-${item.item_id}`}
                  >
                    <CardContent className="p-3">
                      <div className="flex items-start justify-between gap-2 mb-2">
                        <div className="flex-1 min-w-0">
                          <p className="font-medium truncate">{item.item?.name}</p>
                          <p className="text-sm text-muted-foreground">
                            Received: {item.max_quantity} {item.item?.unit}
                          </p>
                        </div>
                        {isSelected && (
                          <Badge variant="destructive">
                            <Check className="w-3 h-3 mr-1" /> {item.quantity}
                          </Badge>
                        )}
                      </div>
                      <div className="flex items-center justify-between mt-3">
                        <span className="text-sm text-muted-foreground">Return qty:</span>
                        <div className="flex items-center gap-2">
                          <Button
                            variant="secondary"
                            size="icon"
                            className="h-8 w-8"
                            onClick={() => updateReturnQuantity(item.item_id, -1)}
                            disabled={item.quantity === 0}
                          >
                            <Minus className="w-4 h-4" />
                          </Button>
                          <span className="w-12 text-center font-semibold">{item.quantity}</span>
                          <Button
                            variant="secondary"
                            size="icon"
                            className="h-8 w-8"
                            onClick={() => updateReturnQuantity(item.item_id, 1)}
                            disabled={item.quantity >= item.max_quantity}
                          >
                            <Plus className="w-4 h-4" />
                          </Button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          </>
        )}
      </main>

      {/* Floating Button */}
      {selectedOrder && totalReturnItems > 0 && !cartOpen && (
        <div className="fixed bottom-4 left-4 right-4">
          <Button
            className="w-full h-14 touch-btn text-base bg-destructive hover:bg-destructive/90"
            onClick={() => setCartOpen(true)}
            data-testid="view-return-cart-btn"
          >
            <RotateCcw className="w-5 h-5 mr-2" />
            Review Return ({totalReturnItems} items)
          </Button>
        </div>
      )}
    </div>
  );
};

export default CreateReturnPage;
