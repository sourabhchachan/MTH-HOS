import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
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
  User, RefreshCw, X, Filter
} from 'lucide-react';

const DispatchPage = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const [queue, setQueue] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedItem, setSelectedItem] = useState(null);
  const [dispatchQty, setDispatchQty] = useState('');
  const [dispatchNotes, setDispatchNotes] = useState('');
  const [submitting, setSubmitting] = useState(false);

  // Get filter params from URL
  const statusFilter = searchParams.get('status'); // PENDING, PARTIAL
  const departmentFilter = searchParams.get('department');
  const priorityFilter = searchParams.get('priority');
  const hasFilters = statusFilter || departmentFilter || priorityFilter;

  useEffect(() => {
    loadQueue();
  }, []);

  const loadQueue = async () => {
    setLoading(true);
    try {
      const params = {};
      if (departmentFilter) params.department_id = departmentFilter;
      const response = await getDispatchQueue(params);
      setQueue(response.data);
    } catch (error) {
      console.error('Failed to load dispatch queue:', error);
    } finally {
      setLoading(false);
    }
  };

  const clearFilters = () => {
    setSearchParams({});
  };

  // Apply client-side filters
  let filteredQueue = queue;
  if (statusFilter === 'PENDING') {
    filteredQueue = queue.filter(i => i.quantity_dispatched === 0);
  } else if (statusFilter === 'PARTIAL') {
    filteredQueue = queue.filter(i => i.quantity_dispatched > 0 && i.quantity_pending > 0);
  }
  if (priorityFilter) {
    filteredQueue = filteredQueue.filter(i => i.order_priority === priorityFilter);
  }

  // Get filter label for display
  const getFilterLabel = () => {
    const labels = [];
    if (statusFilter === 'PENDING') labels.push('Pending Dispatch');
    if (statusFilter === 'PARTIAL') labels.push('Partially Dispatched');
    if (priorityFilter) labels.push(`Priority: ${priorityFilter}`);
    if (departmentFilter) labels.push(`Dept: ${departmentFilter}`);
    return labels.join(' • ');
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

  const urgentItems = filteredQueue.filter(i => i.order_priority === 'URGENT');
  const normalItems = filteredQueue.filter(i => i.order_priority === 'NORMAL');

  return (
    <div className="min-h-screen bg-white pb-20 safe-area-top">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white border-b border-gray-100 px-4 py-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <h1 className="text-xl font-bold text-orange-500">MTH</h1>
            <span className="text-gray-300">|</span>
            <span className="font-semibold text-gray-700">Dispatch</span>
          </div>
          <Button variant="ghost" size="icon" onClick={loadQueue} disabled={loading} className="text-gray-600">
            <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
          </Button>
        </div>
        {/* Filter indicator */}
        {hasFilters && (
          <div className="mt-2 flex items-center gap-2 p-2 bg-orange-50 rounded-lg">
            <Filter className="w-4 h-4 text-orange-500" />
            <span className="text-sm text-orange-700 flex-1">{getFilterLabel()}</span>
            <Button
              variant="ghost"
              size="sm"
              onClick={clearFilters}
              className="h-6 px-2 text-orange-600 hover:text-orange-800"
              data-testid="clear-filters-btn"
            >
              <X className="w-4 h-4" />
              Clear
            </Button>
          </div>
        )}
      </header>

      <main className="px-4 py-4 space-y-6">
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin w-8 h-8 border-2 border-orange-500 border-t-transparent rounded-full" />
          </div>
        ) : filteredQueue.length === 0 ? (
          <div className="text-center py-12">
            <Package className="w-16 h-16 mx-auto mb-4 text-gray-300" />
            <h2 className="text-lg font-semibold text-gray-900 mb-2">
              {hasFilters ? 'No Matching Items' : 'No Pending Items'}
            </h2>
            <p className="text-gray-500">
              {hasFilters ? 'Try clearing filters to see all items' : 'All items have been dispatched'}
            </p>
            {hasFilters && (
              <Button variant="outline" onClick={clearFilters} className="mt-4">
                Clear Filters
              </Button>
            )}
          </div>
        ) : (
          <>
            {/* Urgent Section */}
            {urgentItems.length > 0 && (
              <section>
                <div className="flex items-center gap-2 mb-3">
                  <AlertTriangle className="w-5 h-5 text-orange-500" />
                  <h2 className="font-semibold text-orange-500">Urgent ({urgentItems.length})</h2>
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
            <span>Qty: <strong className="text-orange-600">{item.quantity_pending}</strong> pending</span>
            <span className="text-muted-foreground">of {item.quantity_requested}</span>
          </div>
        </div>
        {/* Quick Action Button - Large Touch Target */}
        <Button 
          className="h-14 w-24 bg-orange-500 hover:bg-orange-600 text-white font-semibold shadow-md flex flex-col items-center justify-center gap-0.5"
          onClick={onDispatch}
          data-testid={`quick-dispatch-btn-${item.order_item_id}`}
        >
          <Send className="w-5 h-5" />
          <span className="text-xs">Dispatch</span>
        </Button>
      </div>
    </CardContent>
  </Card>
);

export default DispatchPage;
