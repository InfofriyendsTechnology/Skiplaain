import { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { motion } from 'framer-motion';
import { FiDollarSign, FiDownload, FiCheck, FiAlertCircle, FiFilter, FiRefreshCw, FiInbox } from 'react-icons/fi';
import Navbar from '../../components/layout/Navbar';
import { getPayouts, generatePayouts, markPayoutPaid } from '../../services/apiService';
import toast from 'react-hot-toast';
import './PayoutsPage.scss';

const PayoutsPage = () => {
  const [payouts, setPayouts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('All');
  const [partnerFilter, setPartnerFilter] = useState('');
  const [selectedPayout, setSelectedPayout] = useState(null);
  const [paymentReference, setPaymentReference] = useState('');
  const [notes, setNotes] = useState('');
  const [processing, setProcessing] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [forceGenerate, setForceGenerate] = useState(false);
  const { onMenuClick } = useOutletContext() || {};

  useEffect(() => {
    fetchPayouts();
  }, []);

  const fetchPayouts = async () => {
    setLoading(true);
    try {
      const data = await getPayouts();
      setPayouts(data || []);
    } catch (err) {
      toast.error('Failed to load payouts: ' + err.message);
      setPayouts([]);
    } finally {
      setLoading(false);
    }
  };

  const handleGeneratePayouts = async () => {
    const confirmMsg = forceGenerate
      ? '⚠️ FORCE GENERATE will create payouts even if some exist. Proceed?'
      : 'Generate new payouts for all partners with pending commissions?';

    if (!window.confirm(confirmMsg)) return;

    setGenerating(true);
    try {
      const result = await generatePayouts(forceGenerate);
      toast.success(`Generated ${result.generated || 0} payout(s) successfully!`);
      setForceGenerate(false);
      fetchPayouts();
    } catch (err) {
      toast.error('Failed to generate payouts: ' + err.message);
    } finally {
      setGenerating(false);
    }
  };

  const handleMarkAsPaid = async () => {
    if (!selectedPayout) return;

    if (!paymentReference.trim()) {
      toast.error('Payment reference is required');
      return;
    }

    setProcessing(true);
    try {
      await markPayoutPaid(selectedPayout.id, {
        paymentReference: paymentReference.trim(),
        notes: notes.trim() || undefined
      });
      toast.success('Payout marked as paid!');
      setSelectedPayout(null);
      setPaymentReference('');
      setNotes('');
      fetchPayouts();
    } catch (err) {
      toast.error('Failed to mark as paid: ' + err.message);
    } finally {
      setProcessing(false);
    }
  };

  const handleExportCSV = () => {
    const filtered = getFilteredPayouts();
    if (filtered.length === 0) {
      toast.error('No payouts to export');
      return;
    }

    const headers = ['Payout ID', 'Partner Name', 'Amount (₹)', 'Status', 'Generated Date', 'Paid Date', 'Payment Reference', 'Notes'];
    const rows = filtered.map(p => [
      p.id,
      p.partner?.salonName || '—',
      (p.amount / 100).toFixed(2),
      p.status,
      new Date(p.generatedAt).toLocaleDateString('en-IN'),
      p.paidAt ? new Date(p.paidAt).toLocaleDateString('en-IN') : '—',
      p.paymentReference || '—',
      p.notes || '—'
    ]);

    const csvContent = [headers, ...rows].map(row => row.map(cell => `"${cell}"`).join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `payouts_export_${new Date().toISOString().split('T')[0]}.csv`;
    link.click();
    toast.success('CSV exported successfully!');
  };

  const getFilteredPayouts = () => {
    return payouts.filter(p => {
      const matchesStatus = statusFilter === 'All' || p.status === statusFilter.toLowerCase();
      const matchesPartner = !partnerFilter || (p.partner?.salonName || '').toLowerCase().includes(partnerFilter.toLowerCase());
      return matchesStatus && matchesPartner;
    });
  };

  const filteredPayouts = getFilteredPayouts();

  const pendingBalance = payouts
    .filter(p => p.status === 'pending')
    .reduce((sum, p) => sum + (p.amount || 0), 0);

  const formatCurrency = (paise) => {
    if (paise == null || isNaN(paise)) return '₹0.00';
    return `₹${(paise / 100).toFixed(2)}`;
  };

  const statusFilters = ['All', 'Pending', 'Paid'];

  return (
    <>
      <Navbar
        title="Payouts Management"
        subtitle={`${payouts.length} total payouts • ${formatCurrency(pendingBalance)} pending`}
        onMenuClick={onMenuClick}
      />
      <div className="page-container">
        {/* Action Bar */}
        <motion.div
          className="card"
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          style={{ padding: '16px 20px', marginBottom: 20 }}
        >
          <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
              <div>
                <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: '#888', marginBottom: 4 }}>
                  <input
                    type="checkbox"
                    checked={forceGenerate}
                    onChange={(e) => setForceGenerate(e.target.checked)}
                  />
                  Force Generate (bypass existing check)
                </label>
                <button
                  className="btn btn-primary"
                  onClick={handleGeneratePayouts}
                  disabled={generating}
                >
                  <FiRefreshCw /> {generating ? 'Generating...' : 'Generate Payouts'}
                </button>
              </div>
              <button
                className="btn btn-ghost"
                onClick={handleExportCSV}
                disabled={filteredPayouts.length === 0}
              >
                <FiDownload /> Export CSV
              </button>
            </div>
          </div>
        </motion.div>

        {/* Filters */}
        <div className="filters-row" style={{ marginBottom: 16 }}>
          {statusFilters.map(f => (
            <button
              key={f}
              className={`filter-chip ${statusFilter === f ? 'active' : ''}`}
              onClick={() => setStatusFilter(f)}
            >
              {f}
            </button>
          ))}
          <div className="filters-spacer" />
          <input
            type="text"
            className="form-input"
            placeholder="Filter by partner name..."
            value={partnerFilter}
            onChange={(e) => setPartnerFilter(e.target.value)}
            style={{ width: 240, fontSize: 13 }}
          />
        </div>

        {/* Payouts Table */}
        <motion.div className="card table-card" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
          {loading ? (
            <div style={{ textAlign: 'center', padding: '40px 20px', color: '#888' }}>
              Loading payouts...
            </div>
          ) : filteredPayouts.length > 0 ? (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Payout ID</th>
                    <th>Partner Name</th>
                    <th>Amount</th>
                    <th>Status</th>
                    <th>Generated Date</th>
                    <th>Paid Date</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredPayouts.map((payout) => (
                    <tr key={payout.id}>
                      <td className="td-mono">{payout.id}</td>
                      <td className="td-primary">{payout.partner?.salonName || '—'}</td>
                      <td style={{ fontWeight: 600, color: '#00ff00' }}>{formatCurrency(payout.amount)}</td>
                      <td>
                        <span className={`badge ${payout.status}`}>
                          {payout.status === 'pending' ? 'Pending' : 'Paid'}
                        </span>
                      </td>
                      <td>{new Date(payout.generatedAt).toLocaleDateString('en-IN')}</td>
                      <td>
                        {payout.paidAt ? new Date(payout.paidAt).toLocaleDateString('en-IN') : '—'}
                      </td>
                      <td>
                        {payout.status === 'pending' ? (
                          <button
                            className="btn btn-primary btn-sm"
                            onClick={() => setSelectedPayout(payout)}
                          >
                            <FiCheck /> Mark Paid
                          </button>
                        ) : (
                          <span style={{ fontSize: 11, color: '#666' }}>
                            Ref: {payout.paymentReference || '—'}
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="empty-state">
              <div className="empty-state-icon">
                <FiInbox />
              </div>
              <h4 className="empty-state-title">No Payouts Found</h4>
              <p className="empty-state-desc">
                {payouts.length === 0
                  ? 'Click "Generate Payouts" to create payouts for pending commissions.'
                  : 'No payouts match your current filters.'}
              </p>
            </div>
          )}
        </motion.div>

        {/* Mark Paid Modal */}
        {selectedPayout && (
          <div className="modal-overlay" onClick={() => setSelectedPayout(null)}>
            <motion.div
              className="modal-card"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              onClick={(e) => e.stopPropagation()}
              style={{ maxWidth: 500 }}
            >
              <h3 style={{ fontSize: 18, fontWeight: 700, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
                <FiCheck /> Mark Payout as Paid
              </h3>

              <div style={{ background: '#141414', border: '1px solid #262626', borderRadius: 8, padding: '12px 16px', marginBottom: 16 }}>
                <div style={{ fontSize: 12, color: '#888', marginBottom: 4 }}>Partner</div>
                <div style={{ fontSize: 14, fontWeight: 600, color: '#fff' }}>{selectedPayout.partner?.salonName || '—'}</div>
                <div style={{ fontSize: 12, color: '#888', marginTop: 8, marginBottom: 4 }}>Amount</div>
                <div style={{ fontSize: 16, fontWeight: 700, color: '#00ff00' }}>{formatCurrency(selectedPayout.amount)}</div>
              </div>

              <div style={{ marginBottom: 12 }}>
                <label style={{ display: 'block', fontSize: 12, color: '#888', marginBottom: 6, fontWeight: 600 }}>
                  Payment Reference <span style={{ color: '#ef4444' }}>*</span>
                </label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="e.g., UTR, Transaction ID, Check Number"
                  value={paymentReference}
                  onChange={(e) => setPaymentReference(e.target.value)}
                  style={{ fontSize: 13 }}
                />
              </div>

              <div style={{ marginBottom: 20 }}>
                <label style={{ display: 'block', fontSize: 12, color: '#888', marginBottom: 6, fontWeight: 600 }}>
                  Notes (optional)
                </label>
                <textarea
                  className="form-input"
                  placeholder="Any additional notes..."
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  rows={3}
                  style={{ fontSize: 13, resize: 'vertical' }}
                />
              </div>

              <div className="modal-actions" style={{ display: 'flex', gap: 10 }}>
                <button
                  className="btn btn-primary"
                  onClick={handleMarkAsPaid}
                  disabled={processing || !paymentReference.trim()}
                >
                  {processing ? 'Updating...' : 'Confirm Payment'}
                </button>
                <button
                  className="btn btn-ghost"
                  onClick={() => {
                    setSelectedPayout(null);
                    setPaymentReference('');
                    setNotes('');
                  }}
                  disabled={processing}
                >
                  Cancel
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </div>
    </>
  );
};

export default PayoutsPage;
