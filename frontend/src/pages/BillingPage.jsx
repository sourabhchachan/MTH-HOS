import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { 
  getBilling, recordPayment, getTodayBillingStats, downloadInvoice 
} from '../api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
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
import { Textarea } from '@/components/ui/textarea';
import { toast } from 'sonner';
import { 
  ArrowLeft, Receipt, CreditCard, DollarSign, Clock, CheckCircle2,
  AlertCircle, Download, Plus, ChevronRight, User, Building2, Search,
  Calendar, FileText, IndianRupee, RefreshCw
} from 'lucide-react';

const statusConfig = {
  PENDING: { label: 'Pending', class: 'bg-yellow-500/20 text-yellow-600', icon: Clock },
  GENERATED: { label: 'Generated', class: 'bg-yellow-500/20 text-yellow-600', icon: Clock },
  PARTIAL: { label: 'Partial', class: 'bg-blue-500/20 text-blue-600', icon: AlertCircle },
  PAID: { label: 'Paid', class: 'bg-emerald-500/20 text-emerald-600', icon: CheckCircle2 },
  CANCELLED: { label: 'Cancelled', class: 'bg-red-500/20 text-red-600', icon: AlertCircle },
};

const paymentModes = [
  { value: 'CASH', label: 'Cash', icon: '💵' },
  { value: 'CARD', label: 'Card', icon: '💳' },
  { value: 'UPI', label: 'UPI', icon: '📱' },
  { value: 'INSURANCE', label: 'Insurance', icon: '🏥' },
  { value: 'OTHER', label: 'Other', icon: '📋' },
];

const BillingPage = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [billings, setBillings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState(null);
  const [tab, setTab] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  
  // Payment Modal
  const [paymentModalOpen, setPaymentModalOpen] = useState(false);
  const [selectedBilling, setSelectedBilling] = useState(null);
  const [paymentAmount, setPaymentAmount] = useState('');
  const [paymentMode, setPaymentMode] = useState('');
  const [paymentReference, setPaymentReference] = useState('');
  const [paymentNotes, setPaymentNotes] = useState('');
  const [processing, setProcessing] = useState(false);

  // Detail Modal
  const [detailModalOpen, setDetailModalOpen] = useState(false);
  const [detailBilling, setDetailBilling] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [billingsRes, statsRes] = await Promise.all([
        getBilling({ limit: 100 }),
        getTodayBillingStats()
      ]);
      setBillings(billingsRes.data);
      setStats(statsRes.data);
    } catch (error) {
      console.error('Failed to load billing data:', error);
      toast.error('Failed to load billing data');
    } finally {
      setLoading(false);
    }
  };

  const openPaymentModal = (billing) => {
    setSelectedBilling(billing);
    setPaymentAmount(billing.outstanding_amount?.toString() || '');
    setPaymentMode('');
    setPaymentReference('');
    setPaymentNotes('');
    setPaymentModalOpen(true);
  };

  const handleRecordPayment = async () => {
    if (!paymentAmount || parseFloat(paymentAmount) <= 0) {
      toast.error('Please enter a valid amount');
      return;
    }
    if (!paymentMode) {
      toast.error('Please select payment mode');
      return;
    }

    setProcessing(true);
    try {
      await recordPayment({
        billing_id: selectedBilling.id,
        amount: parseFloat(paymentAmount),
        payment_mode: paymentMode,
        payment_reference: paymentReference || null,
        notes: paymentNotes || null
      });
      toast.success('Payment recorded successfully');
      setPaymentModalOpen(false);
      loadData();
    } catch (error) {
      toast.error(error.response?.data?.detail || 'Failed to record payment');
    } finally {
      setProcessing(false);
    }
  };

  const handleDownloadInvoice = async (billing) => {
    try {
      const response = await downloadInvoice(billing.id);
      const blob = new Blob([response.data], { type: 'text/html' });
      const url = window.URL.createObjectURL(blob);
      window.open(url, '_blank');
    } catch (error) {
      toast.error('Failed to generate invoice');
    }
  };

  const openDetailModal = (billing) => {
    setDetailBilling(billing);
    setDetailModalOpen(true);
  };

  // Filter billings
  const filteredBillings = billings.filter(b => {
    const matchesSearch = 
      b.billing_number?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      b.patient_name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      b.patient_uhid?.toLowerCase().includes(searchQuery.toLowerCase());
    
    if (tab === 'pending') return matchesSearch && ['GENERATED', 'PENDING'].includes(b.status);
    if (tab === 'partial') return matchesSearch && b.status === 'PARTIAL';
    if (tab === 'paid') return matchesSearch && b.status === 'PAID';
    return matchesSearch;
  });

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      minimumFractionDigits: 2
    }).format(amount || 0);
  };

  const formatDate = (dateStr) => {
    return new Date(dateStr).toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-2 border-orange-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white pb-20 safe-area-top">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white border-b border-gray-100 px-4 py-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <h1 className="text-xl font-bold text-orange-500">Billing</h1>
          </div>
          <Button variant="ghost" size="icon" onClick={loadData}>
            <RefreshCw className="w-5 h-5" />
          </Button>
        </div>
      </header>

      {/* Stats Cards */}
      {stats && (
        <div className="px-4 py-4 grid grid-cols-2 gap-3">
          <Card className="bg-emerald-50 border-emerald-200">
            <CardContent className="p-3">
              <div className="flex items-center gap-2 text-emerald-600 mb-1">
                <IndianRupee className="w-4 h-4" />
                <span className="text-xs font-medium">Today's Billing</span>
              </div>
              <p className="text-lg font-bold text-emerald-700">
                {formatCurrency(stats.billing_today?.amount)}
              </p>
              <p className="text-xs text-emerald-600">{stats.billing_today?.count || 0} bills</p>
            </CardContent>
          </Card>

          <Card className="bg-blue-50 border-blue-200">
            <CardContent className="p-3">
              <div className="flex items-center gap-2 text-blue-600 mb-1">
                <CreditCard className="w-4 h-4" />
                <span className="text-xs font-medium">Payments Today</span>
              </div>
              <p className="text-lg font-bold text-blue-700">
                {formatCurrency(stats.payments_today?.amount)}
              </p>
              <p className="text-xs text-blue-600">{stats.payments_today?.count || 0} payments</p>
            </CardContent>
          </Card>

          <Card className="col-span-2 bg-amber-50 border-amber-200">
            <CardContent className="p-3">
              <div className="flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-2 text-amber-600 mb-1">
                    <AlertCircle className="w-4 h-4" />
                    <span className="text-xs font-medium">Outstanding</span>
                  </div>
                  <p className="text-lg font-bold text-amber-700">
                    {formatCurrency(stats.outstanding?.amount)}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-2xl font-bold text-amber-600">{stats.outstanding?.count || 0}</p>
                  <p className="text-xs text-amber-600">pending bills</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Search */}
      <div className="px-4 mb-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <Input
            placeholder="Search by bill number, patient..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 h-11 bg-gray-50"
            data-testid="billing-search"
          />
        </div>
      </div>

      {/* Tabs */}
      <div className="px-4">
        <Tabs value={tab} onValueChange={setTab} className="w-full">
          <TabsList className="w-full grid grid-cols-4 mb-4 bg-gray-100">
            <TabsTrigger value="all" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white text-xs">
              All ({billings.length})
            </TabsTrigger>
            <TabsTrigger value="pending" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white text-xs">
              Pending
            </TabsTrigger>
            <TabsTrigger value="partial" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white text-xs">
              Partial
            </TabsTrigger>
            <TabsTrigger value="paid" className="data-[state=active]:bg-orange-500 data-[state=active]:text-white text-xs">
              Paid
            </TabsTrigger>
          </TabsList>

          <div className="space-y-2">
            {filteredBillings.length === 0 ? (
              <div className="text-center py-12 text-gray-500">
                <Receipt className="w-12 h-12 mx-auto mb-2 opacity-50" />
                <p>No billing records found</p>
              </div>
            ) : (
              filteredBillings.map((billing) => (
                <BillingCard
                  key={billing.id}
                  billing={billing}
                  onRecordPayment={() => openPaymentModal(billing)}
                  onViewDetails={() => openDetailModal(billing)}
                  onDownloadInvoice={() => handleDownloadInvoice(billing)}
                  formatCurrency={formatCurrency}
                  formatDate={formatDate}
                />
              ))
            )}
          </div>
        </Tabs>
      </div>

      {/* Payment Modal */}
      <Dialog open={paymentModalOpen} onOpenChange={setPaymentModalOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <CreditCard className="w-5 h-5 text-orange-500" />
              Record Payment
            </DialogTitle>
          </DialogHeader>

          {selectedBilling && (
            <div className="space-y-4">
              {/* Billing Info */}
              <div className="p-3 bg-gray-50 rounded-lg">
                <p className="font-semibold">{selectedBilling.billing_number}</p>
                <p className="text-sm text-gray-500">{selectedBilling.patient_name}</p>
                <div className="mt-2 flex justify-between text-sm">
                  <span>Outstanding:</span>
                  <span className="font-bold text-amber-600">
                    {formatCurrency(selectedBilling.outstanding_amount)}
                  </span>
                </div>
              </div>

              {/* Payment Form */}
              <div className="space-y-3">
                <div>
                  <Label>Payment Amount *</Label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500">₹</span>
                    <Input
                      type="number"
                      value={paymentAmount}
                      onChange={(e) => setPaymentAmount(e.target.value)}
                      placeholder="0.00"
                      className="pl-8"
                      data-testid="payment-amount"
                    />
                  </div>
                </div>

                <div>
                  <Label>Payment Mode *</Label>
                  <Select value={paymentMode} onValueChange={setPaymentMode}>
                    <SelectTrigger data-testid="payment-mode-select">
                      <SelectValue placeholder="Select mode" />
                    </SelectTrigger>
                    <SelectContent>
                      {paymentModes.map((mode) => (
                        <SelectItem key={mode.value} value={mode.value}>
                          {mode.icon} {mode.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label>Reference (Optional)</Label>
                  <Input
                    value={paymentReference}
                    onChange={(e) => setPaymentReference(e.target.value)}
                    placeholder="Transaction ID, Check No..."
                  />
                </div>

                <div>
                  <Label>Notes (Optional)</Label>
                  <Textarea
                    value={paymentNotes}
                    onChange={(e) => setPaymentNotes(e.target.value)}
                    placeholder="Additional notes..."
                    rows={2}
                  />
                </div>
              </div>
            </div>
          )}

          <DialogFooter className="flex gap-2">
            <Button variant="outline" onClick={() => setPaymentModalOpen(false)} disabled={processing}>
              Cancel
            </Button>
            <Button 
              className="flex-1 bg-emerald-500 hover:bg-emerald-600"
              onClick={handleRecordPayment}
              disabled={processing || !paymentAmount || !paymentMode}
              data-testid="confirm-payment-btn"
            >
              {processing ? (
                <RefreshCw className="w-4 h-4 animate-spin mr-2" />
              ) : (
                <CreditCard className="w-4 h-4 mr-2" />
              )}
              Record Payment
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Billing Detail Modal */}
      <Dialog open={detailModalOpen} onOpenChange={setDetailModalOpen}>
        <DialogContent className="max-w-lg max-h-[85vh] overflow-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Receipt className="w-5 h-5 text-orange-500" />
              Billing Details
            </DialogTitle>
          </DialogHeader>

          {detailBilling && (
            <div className="space-y-4">
              {/* Header Info */}
              <div className="flex justify-between items-start">
                <div>
                  <p className="font-bold text-lg">{detailBilling.billing_number}</p>
                  <p className="text-sm text-gray-500">{formatDate(detailBilling.generated_at)}</p>
                </div>
                <Badge className={statusConfig[detailBilling.status]?.class}>
                  {statusConfig[detailBilling.status]?.label || detailBilling.status}
                </Badge>
              </div>

              {/* Patient Info */}
              <div className="p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                  <User className="w-4 h-4 text-gray-500" />
                  <span className="font-medium">{detailBilling.patient_name}</span>
                </div>
                <div className="text-sm text-gray-500">
                  <span>UHID: {detailBilling.patient_uhid}</span>
                  {detailBilling.ipd_number && <span> | IPD: {detailBilling.ipd_number}</span>}
                </div>
              </div>

              {/* Items */}
              <div>
                <h4 className="font-medium mb-2">Items</h4>
                <div className="space-y-1">
                  {detailBilling.items?.map((item, idx) => (
                    <div key={idx} className="flex justify-between text-sm p-2 bg-gray-50 rounded">
                      <div>
                        <span>{item.item_name}</span>
                        <span className="text-gray-500 ml-2">x{item.quantity_dispatched}</span>
                      </div>
                      <span className="font-medium">{formatCurrency(item.line_amount)}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Summary */}
              <div className="border-t pt-3 space-y-1">
                <div className="flex justify-between text-sm">
                  <span>Subtotal</span>
                  <span>{formatCurrency(detailBilling.total_amount)}</span>
                </div>
                {detailBilling.total_adjustments !== 0 && (
                  <div className="flex justify-between text-sm text-amber-600">
                    <span>Adjustments</span>
                    <span>{formatCurrency(detailBilling.total_adjustments)}</span>
                  </div>
                )}
                <div className="flex justify-between font-bold">
                  <span>Total</span>
                  <span>{formatCurrency(detailBilling.effective_amount)}</span>
                </div>
                <div className="flex justify-between text-emerald-600">
                  <span>Paid</span>
                  <span>{formatCurrency(detailBilling.paid_amount)}</span>
                </div>
                <div className="flex justify-between font-bold text-amber-600">
                  <span>Outstanding</span>
                  <span>{formatCurrency(detailBilling.outstanding_amount)}</span>
                </div>
              </div>

              {/* Payment History */}
              {detailBilling.payments?.length > 0 && (
                <div>
                  <h4 className="font-medium mb-2">Payment History</h4>
                  <div className="space-y-2">
                    {detailBilling.payments.map((payment, idx) => (
                      <div key={idx} className="flex justify-between items-center p-2 bg-emerald-50 rounded text-sm">
                        <div>
                          <p className="font-medium">{payment.payment_number}</p>
                          <p className="text-xs text-gray-500">
                            {payment.payment_mode} | {formatDate(payment.payment_date)}
                          </p>
                          {payment.recorder_name && (
                            <p className="text-xs text-gray-400">by {payment.recorder_name}</p>
                          )}
                        </div>
                        <span className="font-bold text-emerald-600">
                          {formatCurrency(payment.amount)}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          <DialogFooter className="flex gap-2">
            {detailBilling && detailBilling.outstanding_amount > 0 && (
              <Button 
                className="flex-1 bg-emerald-500 hover:bg-emerald-600"
                onClick={() => {
                  setDetailModalOpen(false);
                  openPaymentModal(detailBilling);
                }}
              >
                <Plus className="w-4 h-4 mr-2" />
                Record Payment
              </Button>
            )}
            <Button 
              variant="outline"
              onClick={() => detailBilling && handleDownloadInvoice(detailBilling)}
            >
              <Download className="w-4 h-4 mr-2" />
              Invoice
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

// Billing Card Component
const BillingCard = ({ billing, onRecordPayment, onViewDetails, onDownloadInvoice, formatCurrency, formatDate }) => {
  const config = statusConfig[billing.status] || statusConfig.PENDING;
  const StatusIcon = config.icon;
  const showPayButton = ['GENERATED', 'PENDING', 'PARTIAL'].includes(billing.status);

  return (
    <Card 
      className="bg-white cursor-pointer hover:shadow-md transition-shadow"
      onClick={onViewDetails}
      data-testid={`billing-${billing.id}`}
    >
      <CardContent className="p-3">
        <div className="flex items-start justify-between gap-2">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <span className="font-semibold">{billing.billing_number}</span>
              <Badge className={`${config.class} text-xs`}>
                <StatusIcon className="w-3 h-3 mr-1" />
                {config.label}
              </Badge>
            </div>
            <div className="flex items-center gap-1 text-sm text-gray-500">
              <User className="w-3 h-3" />
              <span className="truncate">{billing.patient_name || 'N/A'}</span>
              <span className="text-gray-300">|</span>
              <span>{billing.patient_uhid || 'N/A'}</span>
            </div>
            <div className="flex items-center gap-2 mt-2 text-sm">
              <span className="text-gray-500">Total:</span>
              <span className="font-medium">{formatCurrency(billing.effective_amount)}</span>
              {billing.outstanding_amount > 0 && (
                <>
                  <span className="text-gray-300">|</span>
                  <span className="text-amber-600 font-medium">
                    Due: {formatCurrency(billing.outstanding_amount)}
                  </span>
                </>
              )}
            </div>
          </div>
          <div className="flex flex-col gap-1">
            {showPayButton && (
              <Button
                size="sm"
                className="bg-emerald-500 hover:bg-emerald-600 h-8"
                onClick={(e) => {
                  e.stopPropagation();
                  onRecordPayment();
                }}
                data-testid={`pay-btn-${billing.id}`}
              >
                <CreditCard className="w-3 h-3 mr-1" />
                Pay
              </Button>
            )}
            <Button
              size="sm"
              variant="outline"
              className="h-8"
              onClick={(e) => {
                e.stopPropagation();
                onDownloadInvoice();
              }}
              data-testid={`invoice-btn-${billing.id}`}
            >
              <Download className="w-3 h-3 mr-1" />
              Invoice
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default BillingPage;
