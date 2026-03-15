import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { getPendingReceive, receiveItem } from '../api';
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
  ArrowLeft, CheckCircle2, Package, RefreshCw, Clock
} from 'lucide-react';

const ReceivePage = () => {
  const navigate = useNavigate();
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedItem, setSelectedItem] = useState(null);
  const [receiveQty, setReceiveQty] = useState('');
  const [receiveNotes, setReceiveNotes] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    loadItems();
  }, []);

  const loadItems = async () => {
    setLoading(true);
    try {
      const response = await getPendingReceive();
      setItems(response.data);
    } catch (error) {
      console.error('Failed to load pending receive:', error);
    } finally {
      setLoading(false);
    }
  };

  const openReceiveDialog = (item) => {
    setSelectedItem(item);
    setReceiveQty(item.quantity_dispatched.toString());
    setReceiveNotes('');
  };

  const handleReceive = async () => {
    if (!selectedItem || !receiveQty) return;

    const qty = parseInt(receiveQty);
    if (qty <= 0 || qty > selectedItem.quantity_dispatched) {
      alert(`Quantity must be between 1 and ${selectedItem.quantity_dispatched}`);
      return;
    }

    setSubmitting(true);
    try {
      await receiveItem({
        dispatch_event_id: selectedItem.id,
        quantity_received: qty,
        receipt_notes: receiveNotes || undefined
      });
      setSelectedItem(null);
      loadItems();
    } catch (error) {
      alert(error.response?.data?.detail || 'Failed to receive');
    } finally {
      setSubmitting(false);
    }
  };

  const formatTime = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    const today = new Date();
    if (date.toDateString() === today.toDateString()) {
      return 'Today';
    }
    return date.toLocaleDateString([], { month: 'short', day: 'numeric' });
  };

  return (
    <div className="min-h-screen bg-white pb-20 safe-area-top">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white border-b border-gray-100 px-4 py-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <h1 className="text-xl font-bold text-orange-500">MTH</h1>
            <span className="text-gray-300">|</span>
            <span className="font-semibold text-gray-700">Receive</span>
          </div>
          <Button variant="ghost" size="icon" onClick={loadItems} disabled={loading} className="text-gray-600">
            <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </header>

      <main className="px-4 py-4">
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin w-8 h-8 border-2 border-orange-500 border-t-transparent rounded-full" />
          </div>
        ) : items.length === 0 ? (
          <div className="text-center py-12">
            <CheckCircle2 className="w-16 h-16 mx-auto mb-4 text-gray-300" />
            <h2 className="text-lg font-semibold text-gray-900 mb-2">All Caught Up!</h2>
            <p className="text-gray-500">No items pending receipt</p>
          </div>
        ) : (
          <div className="space-y-2">
            {items.map((item) => (
              <Card 
                key={item.id} 
                className="bg-card/50"
                data-testid={`receive-item-${item.id}`}
              >
                <CardContent className="p-3">
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <Badge variant="outline" className="text-xs">
                          Dispatch #{item.id}
                        </Badge>
                        <span className="text-xs text-muted-foreground">
                          {formatDate(item.dispatched_at)} {formatTime(item.dispatched_at)}
                        </span>
                      </div>
                      <p className="text-sm text-muted-foreground mb-2">
                        From: {item.dispatcher?.name || 'Unknown'}
                      </p>
                      <div className="flex items-center gap-2">
                        <Package className="w-4 h-4 text-primary" />
                        <span className="font-semibold">{item.quantity_dispatched}</span>
                        <span className="text-sm text-muted-foreground">items dispatched</span>
                      </div>
                      {item.dispatch_notes && (
                        <p className="text-sm text-muted-foreground mt-1 italic">
                          "{item.dispatch_notes}"
                        </p>
                      )}
                      {item.batch_number && (
                        <p className="text-xs text-muted-foreground mt-1">
                          Batch: {item.batch_number}
                        </p>
                      )}
                    </div>
                    <Button 
                      size="sm" 
                      className="touch-btn bg-emerald-600 hover:bg-emerald-700"
                      onClick={() => openReceiveDialog(item)}
                      data-testid={`receive-btn-${item.id}`}
                    >
                      <CheckCircle2 className="w-4 h-4 mr-1" />
                      Receive
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </main>

      {/* Receive Dialog */}
      <Dialog open={!!selectedItem} onOpenChange={() => setSelectedItem(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Confirm Receipt</DialogTitle>
          </DialogHeader>
          {selectedItem && (
            <div className="space-y-4">
              <div className="p-3 rounded-lg bg-secondary/50">
                <p className="font-semibold">Dispatch #{selectedItem.id}</p>
                <p className="text-sm text-muted-foreground">
                  From: {selectedItem.dispatcher?.name}
                </p>
                <p className="text-sm text-muted-foreground">
                  Dispatched: {formatDate(selectedItem.dispatched_at)} {formatTime(selectedItem.dispatched_at)}
                </p>
              </div>

              <div className="p-4 rounded-lg bg-primary/10 text-center">
                <p className="text-3xl font-bold text-primary">{selectedItem.quantity_dispatched}</p>
                <p className="text-sm text-muted-foreground">Items Dispatched</p>
              </div>

              <div className="space-y-2">
                <Label>Quantity Received</Label>
                <Input
                  type="number"
                  value={receiveQty}
                  onChange={(e) => setReceiveQty(e.target.value)}
                  min={1}
                  max={selectedItem.quantity_dispatched}
                  className="h-12 text-lg"
                  data-testid="receive-qty-input"
                />
                <p className="text-xs text-muted-foreground">
                  Enter actual quantity received (max: {selectedItem.quantity_dispatched})
                </p>
              </div>

              <div className="space-y-2">
                <Label>Notes (Optional)</Label>
                <Textarea
                  value={receiveNotes}
                  onChange={(e) => setReceiveNotes(e.target.value)}
                  placeholder="Any discrepancies or notes..."
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
              onClick={handleReceive} 
              disabled={submitting}
              className="bg-emerald-600 hover:bg-emerald-700"
              data-testid="confirm-receive-btn"
            >
              {submitting ? 'Confirming...' : 'Confirm Receipt'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default ReceivePage;
