import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { getReturnableOrders, getReturnableItems, createReturnOrder, getReturnReasons } from '../api';
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
  ArrowLeft, Search, RotateCcw, 
  Plus, Minus, Check, AlertCircle, DollarSign
} from 'lucide-react';

const CreateReturnPage = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const preselectedOrderId = location.state?.orderId;
  
  const [orders, setOrders] = useState([]);
  const [returnReasons, setReturnReasons] = useState([]);
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [returnSummary, setReturnSummary] = useState(null);
  const [returnItems, setReturnItems] = useState([]);
  const [returnReason, setReturnReason] = useState('');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(true);
  const [loadingItems, setLoadingItems] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [cartOpen, setCartOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    loadData();
  }, []);

  useEffect(() => {
    if (preselectedOrderId && orders.length > 0) {
      const order = orders.find(o => o.order_id === preselectedOrderId);
      if (order) {
        selectOrder(order);
      }
    }
  }, [preselectedOrderId, orders]);

  const loadData = async () => {
    try {
      const [ordersRes, reasonsRes] = await Promise.all([
        getReturnableOrders({ limit: 100 }),
        getReturnReasons()
      ]);
      setOrders(ordersRes.data);
      setReturnReasons(reasonsRes.data);
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setLoading(false);
    }
  };

  const selectOrder = async (order) => {
    setSelectedOrder(order);
    setLoadingItems(true);
    try {
      const response = await getReturnableItems(order.order_id);
      const summary = response.data;
      setReturnSummary(summary);
      
      // Initialize return items with 0 quantity
      setReturnItems(summary.items.map(item => ({
        ...item,
        return_quantity: 0,
        item_return_reason: ''
      })));
    } catch (error) {
      console.error('Failed to load returnable items:', error);
      alert(error.response?.data?.detail || 'Failed to load returnable items');
      setSelectedOrder(null);
    } finally {
      setLoadingItems(false);
    }
  };

  const updateReturnQuantity = (orderItemId, delta) => {
    setReturnItems(returnItems.map(item => {
      if (item.order_item_id === orderItemId) {
        const newQty = Math.max(0, Math.min(item.quantity_returnable, item.return_quantity + delta));
        return { ...item, return_quantity: newQty };
      }
      return item;
    }));
  };

  const setItemReturnReason = (orderItemId, reason) => {
    setReturnItems(returnItems.map(item => {
      if (item.order_item_id === orderItemId) {
        return { ...item, item_return_reason: reason };
      }
      return item;
    }));
  };

  const handleSubmit = async () => {
    const itemsToReturn = returnItems.filter(i => i.return_quantity > 0);
    
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
        original_order_id: selectedOrder.order_id,
        return_reason: returnReason,
        notes: notes,
        items: itemsToReturn.map(item => ({
          item_id: item.item_id,
          quantity_requested: item.return_quantity,
          original_order_item_id: item.order_item_id,
          return_reason: item.item_return_reason || returnReason
        }))
      };

      await createReturnOrder(returnData);
      navigate('/orders', { state: { returnCreated: true } });
    } catch (error) {
      alert(error.response?.data?.detail || 'Failed to create return order');
    } finally {
      setSubmitting(false);
    }
  };

  const filteredOrders = orders.filter(order =>
    order.order_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (order.patient_name || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
    (order.patient_uhid || '').toLowerCase().includes(searchQuery.toLowerCase())
  );

  const totalReturnItems = returnItems.filter(i => i.return_quantity > 0).length;
  const totalReturnQty = returnItems.reduce((sum, i) => sum + i.return_quantity, 0);
  const totalReturnValue = returnItems.reduce((sum, i) => 
    sum + (i.return_quantity * parseFloat(i.cost_per_unit || 0)), 0
  );

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
                    <Badge className="absolute -top-1 -right-1 bg-orange-500 text-white h-5 w-5 p-0 flex items-center justify-center text-xs">
                      {totalReturnItems}
                    </Badge>
                  )}
                </Button>
              </SheetTrigger>
              <SheetContent side="bottom" className="h-[85vh] rounded-t-2xl flex flex-col">
                <SheetHeader>
                  <SheetTitle>Return Items ({totalReturnItems})</SheetTitle>
                </SheetHeader>
                <div className="mt-4 space-y-4 overflow-auto flex-1 min-h-0">
                  {returnItems.filter(i => i.return_quantity > 0).length === 0 ? (
                    <div className="text-center py-8 text-muted-foreground">
                      <RotateCcw className="w-12 h-12 mx-auto mb-2 opacity-50" />
                      <p>No items selected for return</p>
                    </div>
                  ) : (
                    returnItems.filter(i => i.return_quantity > 0).map((item) => (
                      <Card key={item.order_item_id} className="bg-secondary/30">
                        <CardContent className="p-3">
                          <div className="flex items-start justify-between gap-2">
                            <div className="flex-1 min-w-0">
                              <p className="font-medium truncate">{item.item_name}</p>
                              <p className="text-sm text-muted-foreground">
                                Max returnable: {item.quantity_returnable} {item.unit}
                              </p>
                            </div>
                            <Badge className="bg-orange-500/20 text-orange-400">{item.return_quantity}</Badge>
                          </div>
                          <div className="mt-2">
                            <Select 
                              value={item.item_return_reason} 
                              onValueChange={(val) => setItemReturnReason(item.order_item_id, val)}
                            >
                              <SelectTrigger className="text-sm h-8">
                                <SelectValue placeholder="Item reason (optional)" />
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
                        </CardContent>
                      </Card>
                    ))
                  )}
                </div>

                {/* Return Summary & Submission */}
                {totalReturnItems > 0 && (
                  <div className="space-y-4 mt-4 border-t border-border pt-4 flex-shrink-0">
                    {/* Billing Impact Notice */}
                    {returnSummary?.billing_id && (
                      <div className="p-3 rounded-lg bg-blue-500/10 border border-blue-500/30">
                        <div className="flex items-start gap-2">
                          <DollarSign className="w-4 h-4 text-blue-500 mt-0.5" />
                          <div className="text-sm">
                            <p className="font-medium text-blue-400">Billing Adjustment</p>
                            {returnSummary.billing_status === 'PAID' ? (
                              <p className="text-muted-foreground">
                                Credit of ₹{totalReturnValue.toFixed(2)} will be created
                              </p>
                            ) : (
                              <p className="text-muted-foreground">
                                Outstanding will reduce by ₹{totalReturnValue.toFixed(2)}
                              </p>
                            )}
                          </div>
                        </div>
                      </div>
                    )}

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
                      className="w-full h-12 touch-btn bg-orange-500 hover:bg-orange-600"
                      onClick={handleSubmit}
                      disabled={submitting || !returnReason}
                      data-testid="submit-return-btn"
                    >
                      {submitting ? 'Creating...' : `Create Return (${totalReturnQty} items • ₹${totalReturnValue.toFixed(2)})`}
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
                data-testid="search-orders-input"
              />
            </div>

            <p className="text-sm text-muted-foreground">
              Select a completed order to create a return
            </p>

            {filteredOrders.length === 0 ? (
              <div className="text-center py-12 text-muted-foreground">
                <RotateCcw className="w-12 h-12 mx-auto mb-2 opacity-50" />
                <p>No completed orders available for return</p>
              </div>
            ) : (
              <div className="space-y-2">
                {filteredOrders.map((order) => (
                  <Card 
                    key={order.order_id} 
                    className="bg-card/50 cursor-pointer card-interactive"
                    onClick={() => selectOrder(order)}
                    data-testid={`order-select-${order.order_id}`}
                  >
                    <CardContent className="p-3">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="font-semibold">{order.order_number}</p>
                          <p className="text-sm text-muted-foreground">
                            {order.total_items} items • {new Date(order.completed_at).toLocaleDateString()}
                          </p>
                          {order.patient_name && (
                            <p className="text-sm text-primary">{order.patient_name} ({order.patient_uhid})</p>
                          )}
                        </div>
                        <div className="text-right">
                          <Badge className="bg-emerald-500/20 text-emerald-400">Completed</Badge>
                          {order.billing_amount && (
                            <p className="text-xs text-muted-foreground mt-1">
                              ₹{parseFloat(order.billing_amount).toFixed(2)}
                            </p>
                          )}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </>
        ) : loadingItems ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full" />
          </div>
        ) : (
          <>
            {/* Selected Order Info */}
            <Card className="bg-orange-500/10 border-orange-500/30">
              <CardContent className="p-3">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-semibold">Return from: {selectedOrder.order_number}</p>
                    {returnSummary?.patient_name && (
                      <p className="text-sm text-muted-foreground">{returnSummary.patient_name}</p>
                    )}
                    {returnSummary?.billing_number && (
                      <p className="text-xs text-muted-foreground">
                        Bill: {returnSummary.billing_number} • 
                        {returnSummary.billing_status === 'PAID' ? ' Paid' : ' Pending'}
                      </p>
                    )}
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => {
                      setSelectedOrder(null);
                      setReturnSummary(null);
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
            
            {returnItems.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                <AlertCircle className="w-12 h-12 mx-auto mb-2 opacity-50" />
                <p>No items available for return</p>
                <p className="text-sm">All items may have been returned already</p>
              </div>
            ) : (
              <div className="space-y-2">
                {returnItems.map((item) => {
                  const isSelected = item.return_quantity > 0;
                  return (
                    <Card 
                      key={item.order_item_id} 
                      className={`bg-card/50 ${isSelected ? 'border-orange-500/50' : ''}`}
                      data-testid={`return-item-${item.item_id}`}
                    >
                      <CardContent className="p-3">
                        <div className="flex items-start justify-between gap-2 mb-2">
                          <div className="flex-1 min-w-0">
                            <p className="font-medium truncate">{item.item_name}</p>
                            <p className="text-xs text-muted-foreground">{item.item_code}</p>
                            <p className="text-sm text-muted-foreground">
                              Received: {item.quantity_received} {item.unit}
                              {item.quantity_already_returned > 0 && (
                                <span className="text-orange-400 ml-1">
                                  (Returned: {item.quantity_already_returned})
                                </span>
                              )}
                            </p>
                          </div>
                          {isSelected && (
                            <Badge className="bg-orange-500/20 text-orange-400">
                              <Check className="w-3 h-3 mr-1" /> {item.return_quantity}
                            </Badge>
                          )}
                        </div>
                        <div className="flex items-center justify-between mt-3">
                          <div>
                            <span className="text-sm text-muted-foreground">Return qty:</span>
                            <span className="text-xs text-muted-foreground ml-2">
                              (max: {item.quantity_returnable})
                            </span>
                          </div>
                          <div className="flex items-center gap-2">
                            <Button
                              variant="secondary"
                              size="icon"
                              className="h-8 w-8"
                              onClick={() => updateReturnQuantity(item.order_item_id, -1)}
                              disabled={item.return_quantity === 0}
                            >
                              <Minus className="w-4 h-4" />
                            </Button>
                            <span className="w-12 text-center font-semibold">{item.return_quantity}</span>
                            <Button
                              variant="secondary"
                              size="icon"
                              className="h-8 w-8"
                              onClick={() => updateReturnQuantity(item.order_item_id, 1)}
                              disabled={item.return_quantity >= item.quantity_returnable}
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
            )}
          </>
        )}
      </main>

      {/* Floating Button */}
      {selectedOrder && totalReturnItems > 0 && !cartOpen && (
        <div className="fixed bottom-4 left-4 right-4">
          <Button
            className="w-full h-14 touch-btn text-base bg-orange-500 hover:bg-orange-600"
            onClick={() => setCartOpen(true)}
            data-testid="view-return-cart-btn"
          >
            <RotateCcw className="w-5 h-5 mr-2" />
            Review Return ({totalReturnItems} items • ₹{totalReturnValue.toFixed(2)})
          </Button>
        </div>
      )}
    </div>
  );
};

export default CreateReturnPage;
