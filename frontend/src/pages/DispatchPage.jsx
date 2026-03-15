import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { getDispatchQueue, dispatchItem } from '../api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { 
  ArrowLeft, Package, AlertTriangle, Send, Clock,
  User, RefreshCw
} from 'lucide-react';

const DispatchPage = () => {
  const navigate = useNavigate();
  const [queue, setQueue] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedItem, setSelectedItem] = useState(null);
  const [dispatchQty, setDispatchQty] = useState('');
  const [dispatchNotes, setDispatchNotes] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    loadQueue();
  }, []);

  const loadQueue = async () => {
    setLoading(true);
    try {
      const response = await getDispatchQueue();
      setQueue(response.data);
    } catch (error) {
      console.error('Failed to load dispatch queue:', error);
    } finally {
      setLoading(false);
    }
  };

  const openDispatchDialog = (item) => {
    setSelectedItem(item);
    setDispatchQty(item.quantity_pending.toString());
    setDispatchNotes('');
  };

  const handleDispatch = async () => {
    if (!selectedItem || !dispatchQty) return;

    const qty = parseInt(dispatchQty);
    if (qty <= 0 || qty > selectedItem.quantity_pending) {
      alert(`Quantity must be between 1 and ${selectedItem.quantity_pending}`);
      return;
    }

    setSubmitting(true);
    try {
      await dispatchItem({
        order_item_id: selectedItem.order_item_id,
        quantity_dispatched: qty,
        dispatch_notes: dispatchNotes || undefined
      });
      setSelectedItem(null);
      loadQueue();
    } catch (error) {
      alert(error.response?.data?.detail || 'Failed to dispatch');
    } finally {
      setSubmitting(false);
    }
  };

  const urgentItems = queue.filter(i => i.order_priority === 'URGENT');
  const normalItems = queue.filter(i => i.order_priority === 'NORMAL');

  return (
    <div className="min-h-screen bg-background pb-6 safe-area-top">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-background/95 backdrop-blur border-b border-border px-4 py-3">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate('/')}>
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <h1 className="font-semibold text-lg flex-1">Dispatch Queue</h1>
          <Button variant="ghost" size="icon" onClick={loadQueue} disabled={loading}>
            <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </header>

      <main className="px-4 py-4 space-y-6">
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin w-8 h-8 border-2 border-primary border-t-transparent rounded-full" />
          </div>
        ) : queue.length === 0 ? (
          <div className="text-center py-12">
            <Package className="w-16 h-16 mx-auto mb-4 text-muted-foreground opacity-50" />
            <h2 className="text-lg font-semibold mb-2">No Pending Items</h2>
            <p className="text-muted-foreground">All items have been dispatched</p>
          </div>
        ) : (
          <>
            {/* Urgent Section */}
            {urgentItems.length > 0 && (
              <section>
                <div className="flex items-center gap-2 mb-3">
                  <AlertTriangle className="w-5 h-5 text-amber-500" />
                  <h2 className="font-semibold text-amber-500">Urgent ({urgentItems.length})</h2>
                </div>
                <div className="space-y-2">
                  {urgentItems.map((item) => (
                    <DispatchCard 
                      key={item.order_item_id} 
                      item={item} 
                      onDispatch={() => openDispatchDialog(item)}
                      isUrgent
                    />
                  ))}
                </div>
              </section>
            )}

            {/* Normal Section */}
            {normalItems.length > 0 && (
              <section>
                <div className="flex items-center gap-2 mb-3">
                  <Clock className="w-5 h-5 text-muted-foreground" />
                  <h2 className="font-semibold">Normal ({normalItems.length})</h2>
                </div>
                <div className="space-y-2">
                  {normalItems.map((item) => (
                    <DispatchCard 
                      key={item.order_item_id} 
                      item={item} 
                      onDispatch={() => openDispatchDialog(item)}
                    />
                  ))}
                </div>
              </section>
            )}
          </>
        )}
      </main>

      {/* Dispatch Dialog */}
      <Dialog open={!!selectedItem} onOpenChange={() => setSelectedItem(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Dispatch Item</DialogTitle>
          </DialogHeader>
          {selectedItem && (
            <div className="space-y-4">
              <div className="p-3 rounded-lg bg-secondary/50">
                <p className="font-semibold">{selectedItem.item_name}</p>
                <p className="text-sm text-muted-foreground">
                  Order: {selectedItem.order_number} • To: {selectedItem.ordering_department}
                </p>
                {selectedItem.patient_name && (
                  <p className="text-sm text-primary mt-1">
                    Patient: {selectedItem.patient_name} ({selectedItem.ipd_number})
                  </p>
                )}
              </div>

              <div className="grid grid-cols-3 gap-3 text-center">
                <div className="p-2 rounded-lg bg-secondary/30">
                  <p className="text-lg font-bold">{selectedItem.quantity_requested}</p>
                  <p className="text-xs text-muted-foreground">Requested</p>
                </div>
                <div className="p-2 rounded-lg bg-secondary/30">
                  <p className="text-lg font-bold">{selectedItem.quantity_dispatched}</p>
                  <p className="text-xs text-muted-foreground">Dispatched</p>
                </div>
                <div className="p-2 rounded-lg bg-primary/10">
                  <p className="text-lg font-bold text-primary">{selectedItem.quantity_pending}</p>
                  <p className="text-xs text-muted-foreground">Pending</p>
                </div>
              </div>

              <div className="space-y-2">
                <Label>Quantity to Dispatch</Label>
                <Input
                  type="number"
                  value={dispatchQty}
                  onChange={(e) => setDispatchQty(e.target.value)}
                  min={1}
                  max={selectedItem.quantity_pending}
                  className="h-12 text-lg"
                  data-testid="dispatch-qty-input"
                />
              </div>

              <div className="space-y-2">
                <Label>Notes (Optional)</Label>
                <Textarea
                  value={dispatchNotes}
                  onChange={(e) => setDispatchNotes(e.target.value)}
                  placeholder="Batch number, expiry date, etc."
                  rows={2}
                />
              </div>
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => setSelectedItem(null)}>
              Cancel
            </Button>
            <Button 
              onClick={handleDispatch} 
              disabled={submitting}
              data-testid="confirm-dispatch-btn"
            >
              {submitting ? 'Dispatching...' : 'Dispatch'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

const DispatchCard = ({ item, onDispatch, isUrgent = false }) => (
  <Card 
    className={`bg-card/50 ${isUrgent ? 'border-amber-500/50 urgent-pulse' : ''}`}
    data-testid={`dispatch-item-${item.order_item_id}`}
  >
    <CardContent className="p-3">
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <p className="font-medium truncate">{item.item_name}</p>
            {isUrgent && <AlertTriangle className="w-4 h-4 text-amber-500 flex-shrink-0" />}
          </div>
          <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
            <Badge variant="outline" className="text-xs">{item.order_number}</Badge>
            <span>•</span>
            <span>{item.ordering_department}</span>
          </div>
          {item.patient_name && (
            <div className="flex items-center gap-1 text-sm text-primary">
              <User className="w-3 h-3" />
              <span>{item.patient_name}</span>
            </div>
          )}
          <div className="flex items-center gap-4 mt-2 text-sm">
            <span>Qty: <strong>{item.quantity_pending}</strong> pending</span>
            <span className="text-muted-foreground">of {item.quantity_requested}</span>
          </div>
        </div>
        <Button 
          size="sm" 
          className="touch-btn"
          onClick={onDispatch}
          data-testid={`dispatch-btn-${item.order_item_id}`}
        >
          <Send className="w-4 h-4 mr-1" />
          Dispatch
        </Button>
      </div>
    </CardContent>
  </Card>
);

export default DispatchPage;
