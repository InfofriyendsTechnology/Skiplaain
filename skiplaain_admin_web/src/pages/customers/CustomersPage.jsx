import { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import { motion } from 'framer-motion';
import { FiUsers, FiSearch, FiRepeat, FiAward, FiDollarSign, FiClock, FiX, FiTrash2 } from 'react-icons/fi';
import Navbar from '../../components/layout/Navbar';
import StatCard from '../../components/common/StatCard';
import { onCustomersSnapshot, onBookingsSnapshot, onMembershipsSnapshot, clearAllCustomers } from '../../services/firebaseService';
import toast from 'react-hot-toast';
import './CustomersPage.scss';

const CustomersPage = () => {
  const [customers, setCustomers] = useState([]);
  const [bookings, setBookings] = useState([]);
  const [memberships, setMemberships] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedFilter, setSelectedFilter] = useState('All');
  const [selectedCustomer, setSelectedCustomer] = useState(null);
  const { onMenuClick } = useOutletContext() || {};

  useEffect(() => {
    const unsubCust = onCustomersSnapshot(setCustomers);
    const unsubBook = onBookingsSnapshot(setBookings);
    const unsubMemb = onMembershipsSnapshot(setMemberships);

    return () => {
      unsubCust && unsubCust();
      unsubBook && unsubBook();
      unsubMemb && unsubMemb();
    };
  }, []);

  // Aggregate customer directory with visit stats across all salons
  const clientMap = {};

  // 1. Ingest registered customers
  customers.forEach(c => {
    const phone = c.phone || c.id || '';
    const cleanPhone = phone.replace(/\D/g, '');
    if (cleanPhone) {
      clientMap[cleanPhone] = {
        id: c.id,
        phone: phone,
        name: c.name || 'Client',
        activeSalon: c.activeSalonName || c.activeSalonId || '—',
        visitCount: 0,
        totalSpent: 0,
        salonsVisited: new Set(),
        lastVisit: c.lastActive ? new Date(c.lastActive.toDate?.() || c.lastActive).toLocaleDateString('en-IN') : 'Recently',
        isVip: false,
        vipPlans: [],
      };
    }
  });

  // 2. Ingest bookings
  bookings.forEach(b => {
    const rawPhone = b.customerPhone || '';
    const cleanPhone = rawPhone.replace(/\D/g, '');
    const name = b.customerName || 'Client';
    const amount = Number(b.totalAmount || parseFloat(b.price?.toString().replace(/[^0-9.]/g, '') || 0)) || 0;
    const salonName = b.salonName || 'Salon';
    const bDate = b.bookingDate || (b.createdAt ? new Date(b.createdAt.toDate?.() || b.createdAt).toLocaleDateString('en-IN') : 'Recently');

    if (cleanPhone) {
      if (!clientMap[cleanPhone]) {
        clientMap[cleanPhone] = {
          id: cleanPhone,
          phone: rawPhone || cleanPhone,
          name: name,
          activeSalon: salonName,
          visitCount: 1,
          totalSpent: amount,
          salonsVisited: new Set([salonName]),
          lastVisit: bDate,
          isVip: false,
          vipPlans: [],
        };
      } else {
        clientMap[cleanPhone].visitCount += 1;
        clientMap[cleanPhone].totalSpent += amount;
        clientMap[cleanPhone].salonsVisited.add(salonName);
        clientMap[cleanPhone].lastVisit = bDate;
        if ((!clientMap[cleanPhone].name || clientMap[cleanPhone].name === 'Client') && name) {
          clientMap[cleanPhone].name = name;
        }
      }
    }
  });

  // 3. Ingest VIP memberships
  memberships.forEach(m => {
    const rawPhone = m.customerPhone || '';
    const cleanPhone = rawPhone.replace(/\D/g, '');
    if (cleanPhone && (m.status === 'active' || !m.status)) {
      if (clientMap[cleanPhone]) {
        clientMap[cleanPhone].isVip = true;
        clientMap[cleanPhone].vipPlans.push({
          salonName: m.salonName || 'Salon',
          planName: m.planName || 'VIP Pass',
          expiry: m.expiryDisplay || 'Active',
        });
      }
    }
  });

  const directory = Object.values(clientMap);

  // Overall counters
  const totalCustomers = directory.length;
  const totalVisits = directory.reduce((acc, c) => acc + c.visitCount, 0);
  const vipMembers = directory.filter(c => c.isVip).length;
  const repeatClients = directory.filter(c => c.visitCount >= 2).length;

  // Filter & Search
  const filtered = directory.filter(c => {
    const matchesSearch = !searchQuery || 
      c.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
      c.phone.includes(searchQuery) ||
      c.activeSalon.toLowerCase().includes(searchQuery.toLowerCase());

    if (!matchesSearch) return false;

    if (selectedFilter === 'VIP') return c.isVip;
    if (selectedFilter === 'Repeat') return c.visitCount >= 2;
    return true;
  });

  filtered.sort((a, b) => b.visitCount - a.visitCount);

  // Get specific customer's bookings for details modal
  const selectedCustomerBookings = selectedCustomer ? bookings.filter(b => {
    const bClean = (b.customerPhone || '').replace(/\D/g, '');
    const cClean = selectedCustomer.phone.replace(/\D/g, '');
    return bClean && (bClean.includes(cClean) || cClean.includes(bClean));
  }) : [];

  return (
    <>
      <Navbar
        title="Registered Customers & Visits"
        subtitle="Track customer directory, salon visit counts, and active VIP passes"
        onMenuClick={onMenuClick}
      />
      <div className="page-container customers-page">
        {/* Top 4 Stats */}
        <div className="stats-grid">
          <StatCard
            icon={<FiUsers />}
            label="Total Customers"
            value={totalCustomers}
          />
          <StatCard
            icon={<FiRepeat />}
            label="Total Salon Visits"
            value={totalVisits}
          />
          <StatCard
            icon={<FiAward />}
            label="Active VIP Members"
            value={vipMembers}
          />
          <StatCard
            icon={<FiDollarSign />}
            label="Repeat Clients (2+)"
            value={repeatClients}
          />
        </div>

        {/* Search & Filters */}
        <div className="customers-controls">
          <div className="search-bar">
            <FiSearch className="search-icon" />
            <input
              type="text"
              placeholder="Search customer by name, mobile number, or salon..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>

          <div className="filter-pills">
            <button
              className={`pill ${selectedFilter === 'All' ? 'active' : ''}`}
              onClick={() => setSelectedFilter('All')}
            >
              All ({totalCustomers})
            </button>
            <button
              className={`pill ${selectedFilter === 'VIP' ? 'active' : ''}`}
              onClick={() => setSelectedFilter('VIP')}
            >
              <FiAward style={{ marginRight: 6, verticalAlign: 'middle' }} /> VIP Members ({vipMembers})
            </button>
            <button
              className={`pill ${selectedFilter === 'Repeat' ? 'active' : ''}`}
              onClick={() => setSelectedFilter('Repeat')}
            >
              <FiRepeat style={{ marginRight: 6, verticalAlign: 'middle' }} /> Repeat Clients ({repeatClients})
            </button>
          </div>

          {totalCustomers > 0 && (
            <button 
              className="btn btn-danger btn-sm" 
              onClick={async () => {
                if (!window.confirm(`⚠️ Delete all ${totalCustomers} customer account(s)? This cannot be undone.`)) return;
                try {
                  const count = await clearAllCustomers();
                  toast.success(`Cleared ${count} customer record(s)!`);
                } catch (e) {
                  toast.error('Failed to clear customers: ' + e.message);
                }
              }}
              style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 6, padding: '6px 12px', fontSize: 12 }}
            >
              <FiTrash2 /> Clear All Customers
            </button>
          )}
        </div>

        {/* Customers Table */}
        <motion.div
          className="data-table-wrapper"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
        >
          <div className="data-table-header">
            <h3 className="data-table-title">Customer Directory</h3>
            <span className="data-table-count">{filtered.length} customers</span>
          </div>

          {filtered.length > 0 ? (
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Customer Name</th>
                    <th>Mobile Phone</th>
                    <th>Connected / Active Salon</th>
                    <th>Total Visits</th>
                    <th>Total Spent</th>
                    <th>VIP Status</th>
                    <th>Last Visit</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((client) => (
                    <tr key={client.phone}>
                      <td className="td-primary">
                        <div className="customer-cell">
                          <div className={`avatar ${client.isVip ? 'avatar-vip' : ''}`}>
                            {client.name ? client.name[0].toUpperCase() : 'C'}
                          </div>
                          <span className="name">{client.name}</span>
                        </div>
                      </td>
                      <td>{client.phone}</td>
                      <td>
                        <span className="salon-pill">{client.activeSalon}</span>
                      </td>
                      <td>
                        <span className={`visit-badge ${client.visitCount >= 2 ? 'repeat' : ''}`}>
                          {client.visitCount} {client.visitCount === 1 ? 'Visit' : 'Visits'}
                        </span>
                      </td>
                      <td className="td-accent">₹{client.totalSpent.toFixed(0)}</td>
                      <td>
                        {client.isVip ? (
                          <span className="badge vip"><FiAward style={{ marginRight: 4 }} /> ACTIVE VIP</span>
                        ) : (
                          <span className="badge regular">Standard</span>
                        )}
                      </td>
                      <td className="td-date">{client.lastVisit}</td>
                      <td>
                        <button
                          className="action-btn-view"
                          onClick={() => setSelectedCustomer(client)}
                        >
                          View History
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="empty-state">
              <div className="empty-state-icon">
                <FiUsers />
              </div>
              <h4 className="empty-state-title">No Customers Found</h4>
              <p className="empty-state-desc">
                Customers will appear here in real-time as they connect to salons or book queue passes.
              </p>
            </div>
          )}
        </motion.div>

        {/* Customer Details Modal */}
        {selectedCustomer && (
          <div className="modal-backdrop" onClick={() => setSelectedCustomer(null)}>
            <div className="customer-modal" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <div className="header-info">
                  <div className={`avatar-large ${selectedCustomer.isVip ? 'avatar-vip' : ''}`}>
                    {selectedCustomer.name ? selectedCustomer.name[0].toUpperCase() : 'C'}
                  </div>
                  <div>
                    <h3>{selectedCustomer.name}</h3>
                    <p>{selectedCustomer.phone}</p>
                  </div>
                </div>
                <button className="close-btn" onClick={() => setSelectedCustomer(null)}>
                  <FiX />
                </button>
              </div>

              <div className="modal-stats">
                <div className="stat">
                  <span className="val">{selectedCustomer.visitCount}</span>
                  <span className="lbl">Total Visits</span>
                </div>
                <div className="stat">
                  <span className="val">{selectedCustomer.salonsVisited.size}</span>
                  <span className="lbl">Salons Visited</span>
                </div>
                <div className="stat">
                  <span className="val">₹{selectedCustomer.totalSpent.toFixed(0)}</span>
                  <span className="lbl">Total Spent</span>
                </div>
                <div className="stat">
                  <span className="val">{selectedCustomer.isVip ? 'VIP PASS' : 'Standard'}</span>
                  <span className="lbl">Status</span>
                </div>
              </div>

              {selectedCustomer.vipPlans.length > 0 && (
                <div className="vip-plans-list">
                  <h4>Active VIP Memberships</h4>
                  {selectedCustomer.vipPlans.map((vp, idx) => (
                    <div key={idx} className="vip-plan-card">
                      <span className="vp-salon">{vp.salonName}</span>
                      <span className="vp-name">{vp.planName} • Valid until {vp.expiry}</span>
                    </div>
                  ))}
                </div>
              )}

              <div className="modal-history">
                <h4>All Past Passes & Appointments</h4>
                {selectedCustomerBookings.length > 0 ? (
                  <div className="history-table-wrapper">
                    <table className="mini-table">
                      <thead>
                        <tr>
                          <th>Salon</th>
                          <th>Service</th>
                          <th>Date / Time</th>
                          <th>Amount</th>
                          <th>Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        {selectedCustomerBookings.map((b) => (
                          <tr key={b.id}>
                            <td>{b.salonName || 'Salon'}</td>
                            <td>{b.service || '—'}</td>
                            <td>{b.bookingDate} {b.timeSlot || b.time}</td>
                            <td className="accent">₹{b.totalAmount || b.price || '0'}</td>
                            <td><span className={`badge ${(b.status || 'confirmed').toLowerCase()}`}>{b.status || 'Confirmed'}</span></td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <p className="no-history">No queue passes found for this client yet.</p>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </>
  );
};

export default CustomersPage;
