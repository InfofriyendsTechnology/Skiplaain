# SKIPLAAIN CUSTOMER WEB APP - MEGA PRODUCTION PLAN

**Status**: 🚀 READY TO EXECUTE  
**Approach**: Pixel-perfect, production-grade, Google-quality implementation  
**Timeline**: Parallel execution with multiple tools

---

## BACKEND INTEGRATION SUMMARY

### Authentication
- **Flow**: OTP-based → JWT (30 days) → Bearer token in all requests
- **Endpoints**: POST /auth/send-otp → POST /auth/verify-otp
- **Storage**: JWT in localStorage, user data in session
- **Test OTP**: 111111 (dev mode)

### Core Customer Endpoints
- **GET /partners**: Browse salons (filter: status=approved, city, search)
- **GET /partners/:id**: Salon details (services, barbers, counts)
- **GET /plans?salonId=x**: Check subscription plans
- **GET /subscriptions/status?salonId=x**: Check active subscription
- **POST /subscriptions/order**: Create Razorpay order
- **POST /subscriptions/verify**: Verify payment & activate subscription
- **POST /bookings**: Create booking (returns 402 if subscription required)
- **GET /bookings/customer/:phone**: View booking history
- **PATCH /bookings/:id/status**: Cancel booking

### Data Flow
1. User browses salons → GET /partners
2. Selects salon → GET /partners/:id + GET /plans?salonId
3. If plansEnabled → Purchase plan → Razorpay → POST /subscriptions/verify
4. Book appointment → POST /bookings (enforces subscription)
5. View history → GET /bookings/customer/:phone

### Error Handling
- **401**: Token expired → Re-login
- **402 SUBSCRIPTION_REQUIRED**: Show subscription modal
- **429**: Rate limit → Show retry
- All amounts in paise (divide by 100 for display)

---

## DESIGN SYSTEM (Matching Admin Web)

### Theme (From `_variables.scss`)
```scss
// Dark theme foundation
$bg-primary: #000000;
$bg-secondary: #0a0a0a;
$bg-card: #111111;
$bg-card-hover: #181818;

// Neon green accent
$accent: #00ff00;
$accent-dim: #00cc00;
$accent-bg: rgba(0, 255, 0, 0.08);

// Text
$text-primary: #ffffff;
$text-secondary: #a0a0a0;
$text-muted: #5a5a5a;

// Semantic
$danger: #ff4444;
$warning: #ff9900;
$success: #00ff00;

// Borders & Radius
$border-color: #1e1e1e;
$radius-sm: 6px;
$radius-md: 10px;
$radius-lg: 14px;

// Typography
$font-main: 'Bricolage Grotesque';
```

### Component Patterns
**Buttons**:
- `.btn-primary`: Green background, black text
- `.btn-ghost`: Transparent, border, secondary text
- `.btn-danger`: Red translucent background

**Cards**:
- Background: #111111, border: 1px solid #1e1e1e
- Border-radius: 10px
- Box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4)
- Hover: border-color → accent

**Inputs**:
- Background: #141414, border: 1px solid #262626
- Focus: border-color → accent, box-shadow glow
- Autofill prevention (webkit-box-shadow hack)

**Badges**:
- Active/Success: rgba(0, 255, 0, 0.12) background, #00ff00 text
- Pending: rgba(255, 153, 0, 0.12) background, #ff9900 text
- Cancelled: rgba(255, 68, 68, 0.12) background, #ff4444 text

**Tables**: 
- Header: 11px uppercase, #5a5a5a, background #141414
- Rows: 13px, hover rgba(255, 255, 255, 0.02)

**Modals**:
- Overlay: rgba(0, 0, 0, 0.75), backdrop-filter: blur(4px)
- Card: max-width 400-520px, padding 24px
- Framer Motion: initial scale 0.9, animate to 1

**Responsive**:
- Mobile: < 768px
- Tablet: < 1100px
- Grids collapse: 4 → 2 → 1 columns

---

## PAGE ARCHITECTURE

### 1. **LoginPage** (`/login`)
**Purpose**: OTP-based authentication for customers

**Layout**:
- Centered modal card (max-width 400px)
- Logo at top
- Heading: "Customer Login"
- Two-step flow:
  - Step 1: Phone input + "Send OTP" button
  - Step 2: OTP input (6 digits) + "Verify" button
- "Resend OTP" link (60s cooldown)
- Footer: "New to Skiplaain? Let's get started!"

**Features**:
- Phone validation (10 digits, +91 prefix auto-added)
- OTP input: 6 separate boxes, auto-focus next
- Loading states on buttons
- Error toast for invalid OTP
- Success → Store token → Navigate to /salons

**API Calls**:
- POST /auth/send-otp {phone}
- POST /auth/verify-otp {phone, otp, userType: 'customer', name: 'Guest'}

**SCSS**: `LoginPage.scss` (match admin login styles)

---

### 2. **HomePage** (`/`)
**Purpose**: Landing page for unauthenticated users

**Layout**:
- Hero section: "Find Your Perfect Salon" + CTA "Browse Salons"
- Features grid (3 cards):
  - "Book Instantly" (FiCalendar)
  - "VIP Memberships" (FiAward)
  - "Top Salons" (FiStar)
- How it works (3 steps):
  - Browse → Subscribe → Book
- Footer: Links, social icons

**Features**:
- Framer Motion animations (stagger, fade-in)
- CTA buttons → /login (if not logged in) or /salons (if logged in)
- Responsive: stack on mobile

**SCSS**: `HomePage.scss`

---

### 3. **SalonsPage** (`/salons`)
**Purpose**: Browse and search available salons

**Layout**:
- Navbar: Search bar + City filter dropdown + "Profile" button
- Filters row: Status chips (All, Approved, Pending, Blocked) - **Admin only**
- Salons grid (3 columns → 2 → 1):
  - Salon card: Image, name, address, city, rating (stars)
  - Bottom: "View Details" button (btn-primary)
- Empty state: "No salons found" with icon

**Features**:
- Search debounce (300ms)
- City filter: dropdown with cities from backend
- Salon card click → Navigate to /salons/:id
- Infinite scroll or pagination (20 per page)
- Loading skeleton cards

**API Calls**:
- GET /partners?status=approved&city=${city}&search=${query}

**SCSS**: `SalonsPage.scss`

---

### 4. **SalonDetailPage** (`/salons/:id`)
**Purpose**: View salon details, services, subscription plans, book appointments

**Layout**:
- **Header Section**:
  - Salon image (large), name, address, city, rating
  - "Subscribe" button (btn-primary) - if plansEnabled
  - "Book Now" button (btn-ghost)
  
- **Tabs** (3):
  - **Services Tab**: List of services with name, price, duration
    - Service card: icon, name, ₹price, duration (Xmin)
  - **Barbers Tab**: List of barbers with photo, name, specialty
  - **Plans Tab**: Subscription plans (if plansEnabled)
    - Plan card: name, ₹price, duration, "Subscribe" button

- **Booking Modal** (triggered by "Book Now"):
  - Step 1: Select services (checkbox list)
  - Step 2: Select barber (optional, radio)
  - Step 3: Select date (calendar) + time slot (dropdown)
  - Step 4: Special instructions (textarea)
  - Summary: Total amount, "Confirm Booking" button
  - If 402 error → Show "Subscribe First" modal with plan cards

**Features**:
- Tab switching (local state)
- Service multi-select with total amount calculation
- Date picker (react-datepicker or native)
- Time slots: 9AM-9PM, 30min intervals
- Subscription status check: GET /subscriptions/status?salonId
- If hasActivePlan: Show "Active until {date}" badge
- If !plansEnabled: Hide subscription UI

**API Calls**:
- GET /partners/:id
- GET /plans?salonId=:id
- GET /subscriptions/status?salonId=:id
- POST /bookings (on confirm)

**SCSS**: `SalonDetailPage.scss`

---

### 5. **SubscriptionModal** (Component)
**Purpose**: Purchase subscription plan via Razorpay

**Layout**:
- Modal overlay (backdrop-filter blur)
- Heading: "Choose Your VIP Plan"
- Plan cards (vertical stack):
  - Plan name, ₹price, duration, "Select" button
- Selected plan → Razorpay checkout button
- Footer: "Secure payment powered by Razorpay"

**Features**:
- Plan selection (radio group)
- Razorpay integration:
  - POST /subscriptions/order → get orderId
  - Open Razorpay checkout with orderId, key
  - On success: POST /subscriptions/verify {orderId, paymentId, signature}
  - On success: Close modal, refresh subscription status, show success toast
- Loading states
- Error handling (toast)

**API Calls**:
- GET /plans?salonId (passed as prop)
- POST /subscriptions/order {planId, partnerId}
- POST /subscriptions/verify {orderId, paymentId, signature}

**SCSS**: `SubscriptionModal.scss`

---

### 6. **BookingsPage** (`/bookings`)
**Purpose**: View booking history

**Layout**:
- Navbar: "My Bookings" title + Profile button
- Status filter chips: All / Confirmed / Completed / Cancelled
- Bookings list (card layout):
  - Booking card:
    - Booking ID (SKP-XXX) in monospace
    - Salon name, address
    - Date, time slot
    - Services list (comma-separated)
    - Total amount
    - Status badge (color-coded)
    - "Cancel" button (if status=confirmed)
- Empty state: "No bookings yet" + "Browse Salons" CTA

**Features**:
- Filter by status (local)
- Cancel booking: PATCH /bookings/:id/status {status: 'cancelled', cancelReason: 'Customer cancelled'}
- Confirmation dialog before cancel
- Date formatting: "Dec 25, 2024 at 10:00 AM"

**API Calls**:
- GET /bookings/customer/:phone
- PATCH /bookings/:id/status (on cancel)

**SCSS**: `BookingsPage.scss`

---

### 7. **ProfilePage** (`/profile`)
**Purpose**: View/edit customer profile, logout

**Layout**:
- Header: Avatar (initials), name, phone
- Profile details (read-only for now):
  - Name, phone, email (if provided)
- Active subscription section:
  - "Active Subscriptions" heading
  - Subscription cards (one per salon):
    - Salon name, plan name, expires at, "Active" badge
  - Empty state: "No active subscriptions"
- Logout button (btn-danger) at bottom

**Features**:
- Fetch active memberships: GET /memberships/customer/:phone/:salonId (loop for each salon)
- Logout: Clear localStorage, navigate to /login
- Avatar: First letter of name, accent background

**API Calls**:
- GET /customers/:phone (profile data)
- GET /memberships/customer/:phone/:salonId (for each active subscription)

**SCSS**: `ProfilePage.scss`

---

## COMPONENT ARCHITECTURE

### Reusable Components

**1. Navbar** (`components/common/Navbar.jsx`):
- Logo (left), search bar (center), profile button (right)
- Mobile: hamburger menu
- Props: showSearch, onSearch, currentUser

**2. SalonCard** (`components/salons/SalonCard.jsx`):
- Card layout: image, name, address, city, rating, CTA
- Props: salon, onClick

**3. ServiceCard** (`components/salon/ServiceCard.jsx`):
- Service details: name, price, duration, checkbox (for booking)
- Props: service, selected, onSelect

**4. PlanCard** (`components/subscription/PlanCard.jsx`):
- Plan details: name, price, duration, "Subscribe" button
- Props: plan, selected, onSelect

**5. BookingCard** (`components/bookings/BookingCard.jsx`):
- Booking summary: ID, salon, date, time, services, amount, status, cancel button
- Props: booking, onCancel

**6. Modal** (`components/common/Modal.jsx`):
- Reusable modal wrapper with overlay
- Props: isOpen, onClose, children, maxWidth

**7. Button** (`components/common/Button.jsx`):
- Variants: primary, ghost, danger
- Props: variant, loading, disabled, onClick, children

**8. Badge** (`components/common/Badge.jsx`):
- Status badge with color variants
- Props: variant ('success' | 'warning' | 'danger'), children

**9. EmptyState** (`components/common/EmptyState.jsx`):
- Empty state with icon, title, description, CTA
- Props: icon, title, description, ctaText, onCtaClick

**10. ProtectedRoute** (`components/auth/ProtectedRoute.jsx`):
- Route wrapper that checks authentication
- Redirects to /login if no token

---

## ROUTING STRUCTURE

```jsx
// src/routes/AppRoutes.jsx
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';

<Routes>
  <Route path="/" element={<HomePage />} />
  <Route path="/login" element={<LoginPage />} />
  
  {/* Protected routes */}
  <Route element={<ProtectedRoute />}>
    <Route path="/salons" element={<SalonsPage />} />
    <Route path="/salons/:id" element={<SalonDetailPage />} />
    <Route path="/bookings" element={<BookingsPage />} />
    <Route path="/profile" element={<ProfilePage />} />
  </Route>
  
  {/* Catch-all redirect */}
  <Route path="*" element={<Navigate to="/" replace />} />
</Routes>
```

---

## STATE MANAGEMENT

### Context API Structure

**1. AuthContext** (`context/AuthContext.jsx`):
- State: user, token, loading
- Actions: login, logout, verifyToken
- localStorage persistence

**2. SalonsContext** (optional, for caching):
- State: salons, filters, loading
- Actions: fetchSalons, setFilters

### Local Storage Keys:
- `skiplaain_customer_token`: JWT token
- `skiplaain_customer_user`: User object {id, phone, name}

---

## API SERVICE LAYER

### `services/apiClient.js`:
```js
import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:61026/api';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor: attach token
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('skiplaain_customer_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor: handle 401
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.clear();
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default apiClient;
```

### `services/apiService.js`:
```js
import apiClient from './apiClient';

const apiService = {
  // Auth
  sendOtp: (phone) => apiClient.post('/auth/send-otp', { phone }),
  verifyOtp: (phone, otp, name) => apiClient.post('/auth/verify-otp', { 
    phone, otp, userType: 'customer', name 
  }),
  
  // Salons
  getSalons: (filters) => apiClient.get('/partners', { params: { status: 'approved', ...filters } }),
  getSalonDetails: (id) => apiClient.get(`/partners/${id}`),
  
  // Plans
  getPlans: (salonId) => apiClient.get('/plans', { params: { salonId } }),
  getSubscriptionStatus: (salonId) => apiClient.get('/subscriptions/status', { params: { salonId } }),
  
  // Subscription
  createOrder: (planId, partnerId) => apiClient.post('/subscriptions/order', { planId, partnerId }),
  verifyPayment: (orderId, paymentId, signature) => apiClient.post('/subscriptions/verify', { 
    orderId, paymentId, signature 
  }),
  
  // Bookings
  createBooking: (bookingData) => apiClient.post('/bookings', bookingData),
  getCustomerBookings: (phone) => apiClient.get(`/bookings/customer/${phone}`),
  cancelBooking: (id) => apiClient.patch(`/bookings/${id}/status`, { 
    status: 'cancelled', 
    cancelReason: 'Customer cancelled' 
  }),
  
  // Profile
  getCustomerProfile: (phone) => apiClient.get(`/customers/${phone}`),
};

export default apiService;
```

---

## RAZORPAY INTEGRATION

### Installation:
```bash
npm install razorpay
```

### Usage in SubscriptionModal:
```jsx
const handlePayment = async (planId, partnerId, amount) => {
  try {
    // Step 1: Create order
    const { data } = await apiService.createOrder(planId, partnerId);
    const { orderId, amount: orderAmount } = data.data;
    
    // Step 2: Razorpay checkout
    const options = {
      key: import.meta.env.VITE_RAZORPAY_KEY_ID,
      amount: orderAmount,
      currency: 'INR',
      name: 'Skiplaain',
      description: 'VIP Subscription',
      order_id: orderId,
      handler: async (response) => {
        // Step 3: Verify payment
        try {
          await apiService.verifyPayment(
            response.razorpay_order_id,
            response.razorpay_payment_id,
            response.razorpay_signature
          );
          toast.success('Subscription activated!');
          onSuccess();
        } catch (error) {
          toast.error('Payment verification failed');
        }
      },
      prefill: {
        name: user.name,
        contact: user.phone,
      },
      theme: {
        color: '#00ff00',
      },
    };
    
    const razorpay = new window.Razorpay(options);
    razorpay.open();
  } catch (error) {
    toast.error('Failed to initiate payment');
  }
};
```

### Add Razorpay script to `index.html`:
```html
<script src="https://checkout.razorpay.com/v1/checkout.js"></script>
```

---

## TESTING STRATEGY

### Unit Tests (Jest + React Testing Library):
- **Components**: Button, Badge, Modal, SalonCard, ServiceCard
- **Utils**: formatPrice, formatDate, validatePhone
- **Context**: AuthContext actions

### Integration Tests:
- **Auth flow**: Login → OTP verification → Token storage
- **Salon browsing**: Fetch salons → Filter → Search
- **Booking flow**: Select services → Check subscription → Create booking
- **Payment flow**: Create order → Mock Razorpay → Verify payment

### E2E Tests (Playwright or Cypress):
- **Complete booking journey**: Login → Browse → Subscribe → Book
- **Cancel booking**: View bookings → Cancel → Confirm
- **Subscription required**: Book without plan → Get 402 → Subscribe → Book

---

## PERFORMANCE OPTIMIZATION

### Code Splitting:
```jsx
const SalonDetailPage = lazy(() => import('./pages/SalonDetailPage'));
const BookingsPage = lazy(() => import('./pages/BookingsPage'));
```

### Image Optimization:
- Use Next.js Image or react-lazy-load-image-component
- Serve WebP format with fallback
- Placeholder blur effect

### API Optimizations:
- Debounce search input (300ms)
- Cache salon list (React Query or SWR)
- Pagination for bookings/salons

### Bundle Size:
- Use Vite's tree-shaking
- Analyze with rollup-plugin-visualizer
- Target < 500KB gzipped JS

---

## ACCESSIBILITY (WCAG 2.1 AA)

- **Keyboard navigation**: Tab order, focus states
- **ARIA labels**: Buttons, inputs, modals
- **Semantic HTML**: nav, main, section, article
- **Color contrast**: 4.5:1 minimum (check with WebAIM)
- **Screen reader**: Test with NVDA/JAWS
- **Focus indicators**: Visible :focus styles (accent glow)

---

## DEPLOYMENT

### Build:
```bash
npm run build
# Output: dist/ folder
```

### Serve:
- **Vercel**: Connect GitHub repo, auto-deploy
- **Netlify**: Drag-drop dist/ folder
- **AWS S3 + CloudFront**: Static hosting
- **Docker**: Nginx serving dist/

### Environment Variables:
```
VITE_API_URL=https://api.skiplaain.com/api
VITE_RAZORPAY_KEY_ID=rzp_live_xxxxxxxx
```

---

## FILE STRUCTURE

```
skiplaain_customer_web/
├── public/
│   ├── logo.png
│   ├── favicon.svg
│   └── icons/
├── src/
│   ├── assets/
│   │   ├── hero.png
│   │   └── icons.svg
│   ├── components/
│   │   ├── auth/
│   │   │   └── ProtectedRoute.jsx
│   │   ├── common/
│   │   │   ├── Navbar.jsx
│   │   │   ├── Button.jsx
│   │   │   ├── Badge.jsx
│   │   │   ├── Modal.jsx
│   │   │   └── EmptyState.jsx
│   │   ├── salons/
│   │   │   └── SalonCard.jsx
│   │   ├── salon/
│   │   │   ├── ServiceCard.jsx
│   │   │   └── BarberCard.jsx
│   │   ├── subscription/
│   │   │   ├── PlanCard.jsx
│   │   │   └── SubscriptionModal.jsx
│   │   └── bookings/
│   │       └── BookingCard.jsx
│   ├── context/
│   │   └── AuthContext.jsx
│   ├── pages/
│   │   ├── HomePage.jsx
│   │   ├── LoginPage.jsx
│   │   ├── SalonsPage.jsx
│   │   ├── SalonDetailPage.jsx
│   │   ├── BookingsPage.jsx
│   │   └── ProfilePage.jsx
│   ├── routes/
│   │   └── AppRoutes.jsx
│   ├── services/
│   │   ├── apiClient.js
│   │   └── apiService.js
│   ├── styles/
│   │   ├── _variables.scss
│   │   ├── _common.scss
│   │   ├── _buttons.scss
│   │   ├── main.scss
│   │   └── pages/
│   │       ├── HomePage.scss
│   │       ├── LoginPage.scss
│   │       ├── SalonsPage.scss
│   │       ├── SalonDetailPage.scss
│   │       ├── BookingsPage.scss
│   │       └── ProfilePage.scss
│   ├── utils/
│   │   ├── formatPrice.js
│   │   ├── formatDate.js
│   │   └── validators.js
│   ├── App.jsx
│   └── main.jsx
├── .env.example
├── .gitignore
├── index.html
├── package.json
├── vite.config.js
└── README.md
```

---

## EXECUTION PLAN (PARALLEL TASKS)

### Phase 1: Project Setup (10 min)
1. Create Vite React app: `npm create vite@latest skiplaain_customer_web --template react`
2. Install dependencies: react-router-dom, axios, react-hot-toast, framer-motion, sass, razorpay
3. Setup file structure (folders)
4. Copy design system files from admin web (_variables.scss, _common.scss, _buttons.scss)

### Phase 2: Core Services & Context (15 min)
1. Create apiClient.js with interceptors
2. Create apiService.js with all endpoints
3. Create AuthContext with login/logout/token management
4. Create ProtectedRoute component

### Phase 3: Common Components (20 min)
1. Button, Badge, Modal, EmptyState
2. Navbar (with search, profile)
3. Test each component in Storybook (optional) or inline

### Phase 4: Pages - Parallel Execution (60 min)
**Task A** (30 min):
- HomePage (landing)
- LoginPage (OTP flow)

**Task B** (30 min):
- SalonsPage (browse, search, filter)
- SalonCard component

**Task C** (30 min):
- ProfilePage (view profile, active subscriptions)
- BookingsPage (booking history, cancel)

**Task D** (45 min):
- SalonDetailPage (tabs, services, barbers, plans)
- ServiceCard, BarberCard, PlanCard

**Task E** (30 min):
- SubscriptionModal (Razorpay integration)
- BookingCard component

### Phase 5: Integration & Testing (45 min)
1. Wire up all routes in AppRoutes
2. Test complete user flows:
   - Login → Browse → Subscribe → Book
   - View bookings → Cancel
   - Profile → Logout
3. Fix bugs, adjust styling
4. Test responsive (mobile, tablet)

### Phase 6: Polish & Optimization (30 min)
1. Add loading skeletons
2. Add animations (Framer Motion)
3. Optimize images
4. Test accessibility (keyboard, screen reader)
5. Check performance (Lighthouse)

### Phase 7: Build & Deploy (15 min)
1. Build: `npm run build`
2. Test production build locally: `npm run preview`
3. Deploy to Vercel/Netlify
4. Verify live app

---

## SUCCESS CRITERIA

✅ **Functional**:
- User can login with OTP
- User can browse salons (search, filter)
- User can view salon details (services, barbers, plans)
- User can purchase subscription via Razorpay
- User can create booking (with subscription enforcement)
- User can view booking history
- User can cancel booking
- User can view profile and logout

✅ **Design**:
- Pixel-perfect match with admin web theme
- Neon green accent, dark theme
- Responsive (mobile, tablet, desktop)
- Smooth animations (Framer Motion)
- Consistent spacing, typography, colors

✅ **Performance**:
- Lighthouse score > 90 (Performance, Accessibility, Best Practices)
- Bundle size < 500KB gzipped
- Time to Interactive < 3s

✅ **Code Quality**:
- TypeScript (optional, or JSDoc for types)
- ESLint + Prettier configured
- No console errors in production
- All API calls error-handled
- Loading states on all async operations

✅ **Testing**:
- Unit tests for utils, components
- Integration tests for API service
- E2E test for complete booking flow
- Manual testing on Chrome, Firefox, Safari, Edge

---

## DEPENDENCIES

```json
{
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.29.0",
    "axios": "^1.7.9",
    "react-hot-toast": "^2.6.0",
    "framer-motion": "^13.1.0",
    "razorpay": "^2.9.8"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.0.11",
    "sass": "^1.93.1",
    "eslint": "^9.18.0",
    "@eslint/js": "^9.18.0",
    "eslint-plugin-react": "^7.37.2",
    "eslint-plugin-react-hooks": "^5.0.0",
    "eslint-plugin-react-refresh": "^0.4.16"
  }
}
```

---

## NOTES

- **Test Phone**: Use 90000000XX for testing (backend test OTP: 111111)
- **Razorpay Test Mode**: Use test key for dev, live key for production
- **Backend URL**: http://localhost:61026/api (dev), update for production
- **Images**: Use placeholder images (Unsplash, Lorem Picsum) until real images provided
- **Data**: No seed data in backend yet, will need to create test salons/services via admin panel

---

## FINAL DELIVERABLES

1. **Fully functional customer web app** (7 pages)
2. **Production build** (dist/ folder)
3. **Live deployment** (Vercel/Netlify URL)
4. **Test report** (unit, integration, E2E results)
5. **README.md** (setup, run, deploy instructions)
6. **Video demo** (optional, 2-3 min screencast)

---

**ESTIMATED TOTAL TIME**: 4-5 hours (with parallel execution)

**READY TO START**: ✅

