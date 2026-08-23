import { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { motion } from 'framer-motion';
import { FiSearch, FiEye, FiCheck, FiXCircle, FiUsers } from 'react-icons/fi';
import Navbar from '../../components/layout/Navbar';
import { onPartnersSnapshot, updatePartnerStatus } from '../../services/firebaseService';
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
    });
    return () => unsubscribe && unsubscribe();
  }, []);

  const handleStatusChange = async (partnerId, newStatus) => {
    try {
      await updatePartnerStatus(partnerId, newStatus);
      toast.success(`Partner status updated to ${newStatus}!`);
      setSelectedPartner(null);
    } catch (err) {
      toast.error('Failed to update status');
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
                    <th>Address</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredPartners.map((partner) => {
                    const status = (partner.status || 'active').toLowerCase();
                    return (
                      <tr key={partner.id}>
                        <td className="td-primary">{partner.salonName || partner.businessName || '—'}</td>
                        <td>{partner.phone || '—'}</td>
                        <td>{partner.category || '—'}</td>
                        <td className="td-truncate">{partner.address || partner.location || '—'}</td>
                        <td><span className={`badge ${status}`}>{status}</span></td>
                        <td>
                          <div className="action-btns">
                            <button className="btn btn-ghost btn-sm" onClick={() => setSelectedPartner(partner)} title="View Details">
                              <FiEye />
                            </button>
                            {status === 'blocked' ? (
                              <button className="btn btn-primary btn-sm" onClick={() => handleStatusChange(partner.id, 'active')} title="Activate">
                                <FiCheck /> Activate
                              </button>
                            ) : (
                              <button className="btn btn-danger btn-sm" onClick={() => handleStatusChange(partner.id, 'blocked')} title="Block">
                                <FiXCircle /> Block
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

        {/* Detail Modal */}
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
                <div className="detail-item"><label>Registered</label><span>{selectedPartner.createdAt?.toDate?.().toLocaleDateString?.() || '—'}</span></div>
              </div>

              {selectedPartner.services && selectedPartner.services.length > 0 && (
                <div className="detail-services">
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

              <div className="modal-actions">
                {(selectedPartner.status || 'active') === 'blocked' ? (
                  <button className="btn btn-primary" onClick={() => handleStatusChange(selectedPartner.id, 'active')}>
                    <FiCheck /> Activate Partner
                  </button>
                ) : (
                  <button className="btn btn-danger" onClick={() => handleStatusChange(selectedPartner.id, 'blocked')}>
                    <FiXCircle /> Block Partner
                  </button>
                )}
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
