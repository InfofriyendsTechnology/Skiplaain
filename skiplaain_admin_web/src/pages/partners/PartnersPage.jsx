import { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { motion } from 'framer-motion';
import { FiSearch, FiEye, FiCheck, FiXCircle, FiUsers, FiTrash2, FiCalendar } from 'react-icons/fi';
import Navbar from '../../components/layout/Navbar';
import { 
  onPartnersSnapshot, 
  updatePartnerStatus, 
  deletePartnerBarber, 
  clearSalonBarbers, 
  deletePartner 
} from '../../services/firebaseService';
import toast from 'react-hot-toast';
import './PartnersPage.scss';

const PartnersPage = () => {
  const [partners, setPartners] = useState([]);
  const [filter, setFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedPartner, setSelectedPartner] = useState(null);
  const { onMenuClick } = useOutletContext() || {};

  useEffect(() => {
    const unsubscribe = onPartnersSnapshot((data) => {
      setPartners(data);
      // Keep selectedPartner updated if modal is open
      if (selectedPartner) {
        const updated = data.find(p => p.id === selectedPartner.id);
        if (updated) setSelectedPartner(updated);
      }
    });
    return () => unsubscribe && unsubscribe();
  }, [selectedPartner?.id]);

  const handleStatusChange = async (partnerId, newStatus) => {
    try {
      await updatePartnerStatus(partnerId, newStatus);
      toast.success(`Partner status updated to ${newStatus}!`);
    } catch (err) {
      toast.error('Failed to update status');
    }
  };

  const handleDeleteBarber = async (partnerId, barberId, barberName) => {
    if (!window.confirm(`Are you sure you want to delete barber "${barberName}"?`)) return;

    try {
      const updated = await deletePartnerBarber(partnerId, barberId);
      toast.success(`Barber "${barberName}" deleted successfully!`);
      if (selectedPartner) {
        setSelectedPartner(prev => ({ ...prev, barbers: updated }));
      }
    } catch (err) {
      toast.error('Failed to delete barber: ' + err.message);
    }
  };

  const handleClearAllBarbers = async (partnerId, salonName) => {
    if (!window.confirm(`Are you sure you want to remove ALL barbers from "${salonName}"?`)) return;

    try {
      await clearSalonBarbers(partnerId);
      toast.success(`All barbers cleared for "${salonName}"!`);
      if (selectedPartner) {
        setSelectedPartner(prev => ({ ...prev, barbers: [] }));
      }
    } catch (err) {
      toast.error('Failed to clear barbers');
    }
  };

  const handleDeletePartner = async (partnerId, salonName) => {
    if (!window.confirm(`⚠️ PERMANENT DELETE: Are you sure you want to delete salon "${salonName}" completely from the platform?`)) return;

    try {
      await deletePartner(partnerId);
      toast.success(`Salon "${salonName}" permanently deleted!`);
      setSelectedPartner(null);
    } catch (err) {
      toast.error('Failed to delete salon: ' + err.message);
    }
  };

  const filters = ['All', 'Active', 'Blocked'];

  const filteredPartners = partners.filter(p => {
    const status = (p.status || 'active').toLowerCase();
    const isMatchedStatus = filter === 'All' 
      ? true 
      : filter === 'Active' 
        ? (status === 'active' || status === 'verified' || status === 'pending') 
        : status === filter.toLowerCase();

    const matchesSearch = searchQuery === '' ||
      (p.salonName || p.businessName || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (p.phone || '').includes(searchQuery);
    return isMatchedStatus && matchesSearch;
  });

  return (
    <>
      <Navbar
        title="Partner Management"
        subtitle={`${partners.length} registered partners (Auto-Live Enabled)`}
        onMenuClick={onMenuClick}
      />
      <div className="page-container">
        <div className="filters-row">
          {filters.map(f => (
            <button key={f} className={`filter-chip ${filter === f ? 'active' : ''}`} onClick={() => setFilter(f)}>
              {f}
            </button>
          ))}
          <div className="filters-spacer" />
          <div className="search-box">
            <FiSearch className="search-icon" />
            <input
              type="text"
              className="search-input"
              placeholder="Search by salon name or phone..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
        </div>

        <motion.div className="card table-card" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
          {filteredPartners.length > 0 ? (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Salon Name</th>
                    <th>Phone</th>
                    <th>Category</th>
                    <th>Barbers</th>
                    <th>Address</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredPartners.map((partner) => {
                    const status = (partner.status || 'active').toLowerCase();
                    const barberCount = partner.barbers?.length || 0;

                    return (
                      <tr key={partner.id}>
                        <td className="td-primary">{partner.salonName || partner.businessName || '—'}</td>
                        <td>{partner.phone || '—'}</td>
                        <td>{partner.category || '—'}</td>
                        <td>
                          <span className={`badge ${barberCount > 0 ? 'active' : 'pending'}`}>
                            {barberCount} {barberCount === 1 ? 'Barber' : 'Barbers'}
                          </span>
                        </td>
                        <td className="td-truncate">{partner.address || partner.location || '—'}</td>
                        <td><span className={`badge ${status}`}>{status}</span></td>
                        <td>
                          <div className="action-btns">
                            <button className="btn btn-ghost btn-sm" onClick={() => setSelectedPartner(partner)} title="View & Manage Barbers">
                              <FiEye /> View
                            </button>
                            {status === 'blocked' ? (
                              <button className="btn btn-primary btn-sm" onClick={() => handleStatusChange(partner.id, 'active')} title="Activate">
                                <FiCheck />
                              </button>
                            ) : (
                              <button className="btn btn-danger btn-sm" onClick={() => handleStatusChange(partner.id, 'blocked')} title="Block">
                                <FiXCircle />
                              </button>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="empty-state">
              <div className="empty-state-icon">
                <FiUsers />
              </div>
              <h4 className="empty-state-title">No Partners Found</h4>
              <p className="empty-state-desc">{partners.length === 0 ? 'Partners will appear here once they register.' : 'No match for your filter/search.'}</p>
            </div>
          )}
        </motion.div>

        {/* Detail & Barber Management Modal */}
        {selectedPartner && (
          <div className="modal-overlay" onClick={() => setSelectedPartner(null)}>
            <motion.div className="modal-card" initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} onClick={(e) => e.stopPropagation()}>
              <div className="partner-detail-header">
                <div className="partner-avatar">{(selectedPartner.salonName || selectedPartner.businessName || 'S')[0].toUpperCase()}</div>
                <div className="partner-info">
                  <h3>{selectedPartner.salonName || selectedPartner.businessName || '—'}</h3>
                  <p>{selectedPartner.phone || '—'} • {selectedPartner.category || '—'}</p>
                </div>
                <span className={`badge ${(selectedPartner.status || 'active').toLowerCase()}`}>{selectedPartner.status || 'active'}</span>
              </div>

              <div className="detail-grid">
                <div className="detail-item"><label>Address</label><span>{selectedPartner.address || selectedPartner.location || 'Not provided'}</span></div>
                <div className="detail-item"><label>Category</label><span>{selectedPartner.category || 'Not set'}</span></div>
                <div className="detail-item"><label>Opening Time</label><span>{selectedPartner.openingTime || '—'}</span></div>
                <div className="detail-item"><label>Closing Time</label><span>{selectedPartner.closingTime || '—'}</span></div>
                <div className="detail-item"><label>Weekly Off</label><span>{selectedPartner.weeklyOff || '—'}</span></div>
                <div className="detail-item"><label>Total Bookings</label><span>{selectedPartner.totalAppointments || 0}</span></div>
              </div>

              {/* SUPER ADMIN BARBER MANAGEMENT SECTION */}
              <div className="detail-barbers-section" style={{ marginTop: 22, borderTop: '1px solid #222', paddingTop: 16 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                  <label style={{ fontSize: 11, textTransform: 'uppercase', color: '#00ff00', letterSpacing: '0.8px', fontWeight: 700 }}>
                    Salon Barbers & Staff ({selectedPartner.barbers?.length || 0})
                  </label>
                  {selectedPartner.barbers?.length > 0 && (
                    <button 
                      className="btn btn-ghost btn-sm" 
                      style={{ color: '#ef4444', fontSize: 11, padding: '2px 8px' }}
                      onClick={() => handleClearAllBarbers(selectedPartner.id, selectedPartner.salonName || selectedPartner.businessName)}
                    >
                      <FiTrash2 size={12} /> Clear All Barbers
                    </button>
                  )}
                </div>

                {selectedPartner.barbers && selectedPartner.barbers.length > 0 ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                    {selectedPartner.barbers.map((barber, bIdx) => {
                      const isAvail = barber.isAvailable !== false;
                      const workingDays = barber.workingDays || ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      const leaveCount = barber.leaveDates?.length || 0;

                      return (
                        <div 
                          key={barber.id || bIdx}
                          style={{
                            background: '#141414',
                            border: '1px solid #262626',
                            borderRadius: 10,
                            padding: '10px 14px',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between'
                          }}
                        >
                          <div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                              <strong style={{ color: '#fff', fontSize: 14 }}>{barber.name || 'Barber'}</strong>
                              <span style={{ 
                                fontSize: 9, 
                                fontWeight: 800, 
                                padding: '2px 6px', 
                                borderRadius: 4,
                                background: isAvail ? '#162b16' : '#2a1a1a',
                                color: isAvail ? '#00ff00' : '#ef4444'
                              }}>
                                {isAvail ? 'ACTIVE' : 'ON LEAVE'}
                              </span>
                            </div>
                            <div style={{ fontSize: 11, color: '#888', marginTop: 3 }}>
                              Days: {workingDays.length === 7 ? 'All 7 Days' : workingDays.join(', ')}
                              {leaveCount > 0 && (
                                <span style={{ color: '#f59e0b', marginLeft: 8 }}>
                                  • 📅 {leaveCount} Planned Leave(s)
                                </span>
                              )}
                            </div>
                          </div>

                          <button 
                            className="btn btn-danger btn-sm"
                            style={{ padding: '6px 10px', fontSize: 11 }}
                            onClick={() => handleDeleteBarber(selectedPartner.id, barber.id, barber.name)}
                            title="Delete Barber"
                          >
                            <FiTrash2 size={13} /> Delete
                          </button>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <div style={{ padding: '12px', background: '#121212', borderRadius: 8, border: '1px dashed #262626', textAlign: 'center', color: '#666', fontSize: 12 }}>
                    No barbers registered yet for this salon.
                  </div>
                )}
              </div>

              {/* Services List */}
              {selectedPartner.services && selectedPartner.services.length > 0 && (
                <div className="detail-services" style={{ marginTop: 18 }}>
                  <label>Services Offered ({selectedPartner.services.length})</label>
                  <div className="service-list">
                    {selectedPartner.services.map((s, i) => (
                      <div key={i} className="service-row">
                        <span>{s.name}</span>
                        <span className="service-price">₹{s.price} ({s.duration || 30} mins)</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Modal Actions */}
              <div className="modal-actions" style={{ marginTop: 24, paddingTop: 16, borderTop: '1px solid #222', display: 'flex', gap: 10, alignItems: 'center' }}>
                {(selectedPartner.status || 'active') === 'blocked' ? (
                  <button className="btn btn-primary" onClick={() => handleStatusChange(selectedPartner.id, 'active')}>
                    <FiCheck /> Activate
                  </button>
                ) : (
                  <button className="btn btn-danger" onClick={() => handleStatusChange(selectedPartner.id, 'blocked')}>
                    <FiXCircle /> Block
                  </button>
                )}

                <button 
                  className="btn btn-danger" 
                  style={{ background: '#3b1111', borderColor: '#ef4444' }}
                  onClick={() => handleDeletePartner(selectedPartner.id, selectedPartner.salonName || selectedPartner.businessName)}
                >
                  <FiTrash2 /> Delete Salon
                </button>

                <button className="btn btn-ghost" onClick={() => setSelectedPartner(null)} style={{ marginLeft: 'auto' }}>Close</button>
              </div>
            </motion.div>
          </div>
        )}
      </div>
    </>
  );
};

export default PartnersPage;
