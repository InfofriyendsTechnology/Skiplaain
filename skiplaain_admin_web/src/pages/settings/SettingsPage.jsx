import { useState, useEffect } from 'react';
import { useNavigate, useOutletContext } from 'react-router-dom';
import Navbar from '../../components/layout/Navbar';
import { FiLogOut, FiSave, FiPlus, FiEdit2, FiTrash2, FiCheck, FiX } from 'react-icons/fi';
import { 
  getAdminSettings, 
  updateAdminSettings,
  getAdminPlans,
  createAdminPlan,
  updateAdminPlan,
  deleteAdminPlan
} from '../../services/apiService';
import toast from 'react-hot-toast';
import './SettingsPage.scss';

const SettingsPage = () => {
  const navigate = useNavigate();
  const { onMenuClick } = useOutletContext() || {};
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  
  // Platform settings
  const [commissionPercent, setCommissionPercent] = useState(10);
  const [payoutCycleDays, setPayoutCycleDays] = useState(14);
  const [minPayoutRupees, setMinPayoutRupees] = useState(0);
  
  // Plans
  const [plans, setPlans] = useState([]);
  const [editingPlanId, setEditingPlanId] = useState(null);
  const [editForm, setEditForm] = useState({});
  const [showAddForm, setShowAddForm] = useState(false);
  const [newPlan, setNewPlan] = useState({ name: '', durationMonths: 3, priceRupees: 33, isActive: true, sortOrder: 1 });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [settings, plansData] = await Promise.all([
        getAdminSettings(),
        getAdminPlans()
      ]);
      
      setCommissionPercent(settings.commissionPercent);
      setPayoutCycleDays(settings.payoutCycleDays);
      setMinPayoutRupees(settings.minPayoutPaise / 100);
      setPlans(plansData.sort((a, b) => a.sortOrder - b.sortOrder));
    } catch (err) {
      toast.error('Failed to load settings: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSaveSettings = async () => {
    if (commissionPercent < 0 || commissionPercent > 100) {
      toast.error('Commission must be between 0-100%');
      return;
    }
    if (payoutCycleDays < 1) {
      toast.error('Payout cycle must be at least 1 day');
      return;
    }

    setSaving(true);
    try {
      await updateAdminSettings({
        commissionPercent: parseFloat(commissionPercent),
        payoutCycleDays: parseInt(payoutCycleDays),
        minPayoutPaise: Math.round(parseFloat(minPayoutRupees) * 100)
      });
      toast.success('Platform settings saved!');
    } catch (err) {
      toast.error('Failed to save: ' + err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleAddPlan = async () => {
    if (!newPlan.name.trim()) {
      toast.error('Plan name is required');
      return;
    }
    if (newPlan.durationMonths < 1) {
      toast.error('Duration must be at least 1 month');
      return;
    }
    if (newPlan.priceRupees < 1) {
      toast.error('Price must be greater than 0');
      return;
    }

    setSaving(true);
    try {
      await createAdminPlan({
        name: newPlan.name,
        durationMonths: parseInt(newPlan.durationMonths),
        pricePaise: Math.round(parseFloat(newPlan.priceRupees) * 100),
        isActive: newPlan.isActive,
        sortOrder: parseInt(newPlan.sortOrder)
      });
      toast.success('Plan created!');
      setShowAddForm(false);
      setNewPlan({ name: '', durationMonths: 3, priceRupees: 33, isActive: true, sortOrder: 1 });
      loadData();
    } catch (err) {
      toast.error('Failed to create plan: ' + err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleEditPlan = (plan) => {
    setEditingPlanId(plan.id);
    setEditForm({
      name: plan.name,
      durationMonths: plan.durationMonths,
      priceRupees: plan.pricePaise / 100,
      isActive: plan.isActive,
      sortOrder: plan.sortOrder
    });
  };

  const handleSavePlan = async (planId) => {
    setSaving(true);
    try {
      await updateAdminPlan(planId, {
        name: editForm.name,
        durationMonths: parseInt(editForm.durationMonths),
        pricePaise: Math.round(parseFloat(editForm.priceRupees) * 100),
        isActive: editForm.isActive,
        sortOrder: parseInt(editForm.sortOrder)
      });
      toast.success('Plan updated!');
      setEditingPlanId(null);
      loadData();
    } catch (err) {
      toast.error('Failed to update: ' + err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDeletePlan = async (planId, planName) => {
    if (!window.confirm(`Delete plan "${planName}"? This will soft-delete it (isActive=false).`)) return;

    setSaving(true);
    try {
      await deleteAdminPlan(planId);
      toast.success('Plan deleted!');
      loadData();
    } catch (err) {
      toast.error('Failed to delete: ' + err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleLogout = () => {
    logout();
    localStorage.removeItem('admin_token');
    sessionStorage.removeItem('skiplaain_admin_auth');
    toast.success('Logged out');
    navigate('/login');
  };

  if (loading) {
    return (
      <>
        <Navbar title="Settings" subtitle="Loading..." onMenuClick={onMenuClick} />
        <div className="page-container" style={{ padding: 40, textAlign: 'center', color: '#666' }}>Loading settings...</div>
      </>
    );
  }

  return (
    <>
      <Navbar title="Platform Settings" subtitle="Configure commission, payouts, and subscription plans" onMenuClick={onMenuClick} />
      <div className="page-container">
        
        {/* Platform Settings */}
        <div className="partner-detail-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <h3 className="detail-card-title">Platform Configuration</h3>
            <button className="btn btn-primary btn-sm" onClick={handleSaveSettings} disabled={saving}>
              <FiSave /> {saving ? 'Saving...' : 'Save Settings'}
            </button>
          </div>
          
          <div className="detail-grid">
            <div className="detail-item">
              <label>Default Commission Rate (%)</label>
              <input 
                type="number" 
                value={commissionPercent} 
                onChange={(e) => setCommissionPercent(e.target.value)}
                step="0.1"
                min="0"
                max="100"
                style={{ background: '#141414', border: '1px solid #262626', padding: '8px 12px', borderRadius: 8, color: '#fff', width: '100%' }}
              />
            </div>
            <div className="detail-item">
              <label>Payout Cycle (days)</label>
              <input 
                type="number" 
                value={payoutCycleDays} 
                onChange={(e) => setPayoutCycleDays(e.target.value)}
                min="1"
                style={{ background: '#141414', border: '1px solid #262626', padding: '8px 12px', borderRadius: 8, color: '#fff', width: '100%' }}
              />
            </div>
            <div className="detail-item">
              <label>Minimum Payout (₹)</label>
              <input 
                type="number" 
                value={minPayoutRupees} 
                onChange={(e) => setMinPayoutRupees(e.target.value)}
                step="1"
                min="0"
                style={{ background: '#141414', border: '1px solid #262626', padding: '8px 12px', borderRadius: 8, color: '#fff', width: '100%' }}
              />
            </div>
          </div>
        </div>

        {/* Subscription Plans */}
        <div className="partner-detail-card" style={{ marginTop: 24 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <h3 className="detail-card-title">Subscription Plans ({plans.length})</h3>
            <button className="btn btn-primary btn-sm" onClick={() => setShowAddForm(!showAddForm)}>
              <FiPlus /> Add Plan
            </button>
          </div>

          {/* Add Form */}
          {showAddForm && (
            <div style={{ background: '#141414', padding: 16, borderRadius: 12, marginBottom: 16, border: '1px solid #00ff00' }}>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: 12, marginBottom: 12 }}>
                <div>
                  <label style={{ fontSize: 11, color: '#888', display: 'block', marginBottom: 4 }}>Name</label>
                  <input 
                    type="text" 
                    value={newPlan.name} 
                    onChange={(e) => setNewPlan({...newPlan, name: e.target.value})}
                    placeholder="3 Months VIP"
                    style={{ background: '#0a0a0a', border: '1px solid #262626', padding: '8px', borderRadius: 6, color: '#fff', width: '100%' }}
                  />
                </div>
                <div>
                  <label style={{ fontSize: 11, color: '#888', display: 'block', marginBottom: 4 }}>Duration (months)</label>
                  <input 
                    type="number" 
                    value={newPlan.durationMonths} 
                    onChange={(e) => setNewPlan({...newPlan, durationMonths: e.target.value})}
                    min="1"
                    style={{ background: '#0a0a0a', border: '1px solid #262626', padding: '8px', borderRadius: 6, color: '#fff', width: '100%' }}
                  />
                </div>
                <div>
                  <label style={{ fontSize: 11, color: '#888', display: 'block', marginBottom: 4 }}>Price (₹)</label>
                  <input 
                    type="number" 
                    value={newPlan.priceRupees} 
                    onChange={(e) => setNewPlan({...newPlan, priceRupees: e.target.value})}
                    min="1"
                    step="1"
                    style={{ background: '#0a0a0a', border: '1px solid #262626', padding: '8px', borderRadius: 6, color: '#fff', width: '100%' }}
                  />
                </div>
                <div>
                  <label style={{ fontSize: 11, color: '#888', display: 'block', marginBottom: 4 }}>Sort Order</label>
                  <input 
                    type="number" 
                    value={newPlan.sortOrder} 
                    onChange={(e) => setNewPlan({...newPlan, sortOrder: e.target.value})}
                    min="0"
                    style={{ background: '#0a0a0a', border: '1px solid #262626', padding: '8px', borderRadius: 6, color: '#fff', width: '100%' }}
                  />
                </div>
              </div>
              <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                <label style={{ fontSize: 12, color: '#fff', display: 'flex', alignItems: 'center', gap: 6 }}>
                  <input 
                    type="checkbox" 
                    checked={newPlan.isActive} 
                    onChange={(e) => setNewPlan({...newPlan, isActive: e.target.checked})}
                  />
                  Active
                </label>
                <button className="btn btn-primary btn-sm" onClick={handleAddPlan} disabled={saving} style={{ marginLeft: 'auto' }}>
                  <FiCheck /> Create
                </button>
                <button className="btn btn-ghost btn-sm" onClick={() => setShowAddForm(false)}>
                  <FiX /> Cancel
                </button>
              </div>
            </div>
          )}

          {/* Plans Table */}
          {plans.length > 0 ? (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Sort</th>
                    <th>Name</th>
                    <th>Duration</th>
                    <th>Price</th>
                    <th>Active</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {plans.map((plan) => (
                    <tr key={plan.id}>
                      {editingPlanId === plan.id ? (
                        <>
                          <td>
                            <input 
                              type="number" 
                              value={editForm.sortOrder} 
                              onChange={(e) => setEditForm({...editForm, sortOrder: e.target.value})}
                              style={{ background: '#0a0a0a', border: '1px solid #262626', padding: '4px 8px', borderRadius: 4, color: '#fff', width: 60 }}
                            />
                          </td>
                          <td>
                            <input 
                              type="text" 
                              value={editForm.name} 
                              onChange={(e) => setEditForm({...editForm, name: e.target.value})}
                              style={{ background: '#0a0a0a', border: '1px solid #262626', padding: '4px 8px', borderRadius: 4, color: '#fff', width: '100%' }}
                            />
                          </td>
                          <td>
                            <input 
                              type="number" 
                              value={editForm.durationMonths} 
                              onChange={(e) => setEditForm({...editForm, durationMonths: e.target.value})}
                              style={{ background: '#0a0a0a', border: '1px solid #262626', padding: '4px 8px', borderRadius: 4, color: '#fff', width: 80 }}
                            /> mo
                          </td>
                          <td>
                            ₹<input 
                              type="number" 
                              value={editForm.priceRupees} 
                              onChange={(e) => setEditForm({...editForm, priceRupees: e.target.value})}
                              style={{ background: '#0a0a0a', border: '1px solid #262626', padding: '4px 8px', borderRadius: 4, color: '#fff', width: 80 }}
                            />
                          </td>
                          <td>
                            <input 
                              type="checkbox" 
                              checked={editForm.isActive} 
                              onChange={(e) => setEditForm({...editForm, isActive: e.target.checked})}
                            />
                          </td>
                          <td>
                            <div className="action-btns">
                              <button className="btn btn-primary btn-sm" onClick={() => handleSavePlan(plan.id)} disabled={saving}>
                                <FiCheck />
                              </button>
                              <button className="btn btn-ghost btn-sm" onClick={() => setEditingPlanId(null)}>
                                <FiX />
                              </button>
                            </div>
                          </td>
                        </>
                      ) : (
                        <>
                          <td>{plan.sortOrder}</td>
                          <td className="td-primary">{plan.name}</td>
                          <td>{plan.durationMonths} months</td>
                          <td>₹{plan.pricePaise / 100}</td>
                          <td><span className={`badge ${plan.isActive ? 'active' : 'pending'}`}>{plan.isActive ? 'Yes' : 'No'}</span></td>
                          <td>
                            <div className="action-btns">
                              <button className="btn btn-ghost btn-sm" onClick={() => handleEditPlan(plan)} title="Edit">
                                <FiEdit2 />
                              </button>
                              <button className="btn btn-danger btn-sm" onClick={() => handleDeletePlan(plan.id, plan.name)} title="Delete">
                                <FiTrash2 />
                              </button>
                            </div>
                          </td>
                        </>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div style={{ padding: 20, textAlign: 'center', color: '#666' }}>No plans configured yet.</div>
          )}
        </div>

        {/* Logout */}
        <button className="btn btn-danger" onClick={handleLogout} style={{ marginTop: 28 }}>
          <FiLogOut /> Logout
        </button>
      </div>
    </>
  );
};

export default SettingsPage;
