# Skiplaain Project Setup Guide

## 📦 Prerequisites

- **Node.js** 18+ (for backend & admin web)
- **Flutter** 3.24+ (for customer & partner apps)
- **PostgreSQL** database (free at [neon.tech](https://neon.tech) or local)
- **Git** installed

---

## 🚀 Quick Start (3 steps)

### 1. Clone & Install

```bash
git clone <your-repo-url>
cd Skiplaain

# Backend
cd skiplaain_backend
npm install
npx prisma generate
npx prisma migrate deploy

# Admin Web
cd ../skiplaain_admin_web
npm install

# Customer App
cd ../skiplaain_customer_app
flutter pub get

# Partner App
cd ../skiplaain_partner_app
flutter pub get
```

---

### 2. Create `.env` Files

Copy these EXACTLY into the right folders:

#### **Backend** → `skiplaain_backend/.env`

```env
# Database (Get a free one at https://neon.tech or use local PostgreSQL)
DATABASE_URL=postgresql://user:password@localhost:5432/skiplaain

# Server Configuration
PORT=61026
NODE_ENV=development

# JWT Secret (change this to any random string)
JWT_SECRET=dev_jwt_secret_change_this_to_anything_12345

# OTP Service (2Factor SMS API - Get from https://2factor.in)
# Leave as-is for dev mode (static OTP 111111 works automatically)
TWO_FACTOR_API_KEY=your_2factor_api_key_here

# CORS Origins (comma-separated frontend URLs)
CORS_ORIGINS=http://localhost:19826,http://localhost:5353,http://localhost:5454

# Admin Allowlist (comma-separated phone numbers for admin login)
ADMIN_PHONES=9999999999,8888888888

# Razorpay Payment Gateway (Test Mode - Get from https://razorpay.com)
RAZORPAY_KEY_ID=rzp_test_your_key_id_here
RAZORPAY_KEY_SECRET=your_secret_here
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret_here
```

#### **Admin Web** → `skiplaain_admin_web/.env`

```env
# Backend API URL
VITE_API_URL=http://localhost:61026/api

# Admin Configuration
VITE_ADMIN_EMAIL=admin@skiplaain.com
```

#### **Customer App** → `skiplaain_customer_app/.env`

```env
# Mapbox API Key (Get a free one at https://account.mapbox.com)
# Optional — only needed for the location picker map widget
MAPBOX_API_KEY=your_mapbox_public_key_here
```

---

### 3. Run Everything

Open 3 separate terminals:

```bash
# Terminal 1: Backend
cd skiplaain_backend
npm run dev
# Should see: "🚀 Skiplaain Backend API is running on http://localhost:61026"

# Terminal 2: Admin Web
cd skiplaain_admin_web
npm run dev
# Should see: "Local: http://localhost:5353"

# Terminal 3: Customer App
cd skiplaain_customer_app
flutter run --dart-define=API_BASE_URL=http://localhost:61026/api
# Should open browser/device
```

---

## 🔧 Configuration Details

### Database Options

**Option 1: Neon (Recommended for dev)**
1. Sign up at [neon.tech](https://neon.tech)
2. Create a new project
3. Copy the connection string
4. Paste into `DATABASE_URL` in backend `.env`

**Option 2: Local PostgreSQL**
```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/skiplaain
```
Then create the database:
```bash
psql -U postgres
CREATE DATABASE skiplaain;
\q
```

---

### OTP Service (Optional for dev)

**Dev Mode**: Works automatically with static OTP `111111` for test phone numbers `9000000xxx`.

**Production**: Get API key from [2factor.in](https://2factor.in) and update `TWO_FACTOR_API_KEY`.

---

### Razorpay Payment Gateway

**Dev/Test Mode**:
1. Sign up at [razorpay.com](https://razorpay.com)
2. Get **Test** API keys from dashboard
3. Update `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` in backend `.env`
4. Test card: `4111 1111 1111 1111`, CVV: any 3 digits, Expiry: any future date

**Customer App**: Pass Razorpay key via command line:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:61026/api --dart-define=RAZORPAY_KEY_ID=rzp_test_your_key
```

---

## 🧪 Testing

### Backend Tests (37 tests)
```bash
cd skiplaain_backend
npm test
# Should see: "Tests: 37 passed, 37 total"
```

### Flutter Tests
```bash
cd skiplaain_customer_app
flutter test
# Should see: "All tests passed!"
```

---

## 📱 Test Accounts

### Admin Login
- **Phone**: `9999999999` (or any number in `ADMIN_PHONES`)
- **OTP**: `111111` (static OTP in dev mode)

### Customer Login
- **Phone**: Any `9000000xxx` number (e.g., `9000000123`)
- **OTP**: `111111`

### Partner Login
- **Phone**: Partner's registered phone (must be approved by admin first)
- **OTP**: `111111`

---

## 🚨 Common Issues

### "Connection refused" error
- Check backend is running on port 61026
- Check `VITE_API_URL` in admin web `.env` matches backend port

### "Database connection error"
- Verify `DATABASE_URL` is correct
- For Neon: Check `sslmode=require` is in the connection string
- For local: Check PostgreSQL is running

### Flutter "SDK not found"
- Run `flutter doctor` to check installation
- Install Android Studio for Android development
- No Android SDK? Use `flutter run -d chrome` for web

### "Razorpay test key invalid"
- Get actual test keys from razorpay.com dashboard (don't use placeholder)
- Ensure you're using **Test** keys, not Live keys

---

## 🎯 What Works Without Keys

### Works Without Any External Services:
✅ Backend API (all endpoints)  
✅ Admin web (all features)  
✅ Customer app login (with static OTP)  
✅ Partner app login (with static OTP)  
✅ Booking creation  
✅ Salon search & QR scanning  

### Requires External Keys:
❌ SMS OTP (needs 2Factor API key)  
❌ Razorpay payments (needs test keys)  
❌ Mapbox location picker (optional, needs API key)  

---

## 📚 Project Structure

```
Skiplaain/
├── skiplaain_backend/          # Node.js + Express + Prisma
│   ├── src/
│   │   ├── controllers/        # Business logic
│   │   ├── routes/             # API endpoints
│   │   ├── middleware/         # Auth, rate limiting
│   │   └── utils/              # Helpers
│   ├── test/                   # Jest tests
│   └── prisma/                 # Database schema & migrations
│
├── skiplaain_admin_web/        # React + Vite
│   └── src/
│       ├── pages/              # Dashboard, Partners, Customers, etc.
│       └── services/           # API client
│
├── skiplaain_customer_app/     # Flutter
│   └── lib/
│       ├── screens/            # UI screens
│       ├── services/           # API services
│       └── widgets/            # Reusable components
│
└── skiplaain_partner_app/      # Flutter
    └── lib/
        ├── screens/            # Partner dashboard
        └── services/           # API services
```

---

## 🚀 Ready to Push?

After setup works locally:

```bash
git push origin master
```

See `PUSH_INSTRUCTIONS.md` for deployment guide.

---

## 💡 Need Help?

1. Check `PHASE3_COMPLETION_REPORT.md` for feature documentation
2. Backend API docs: Start backend, visit `http://localhost:61026/api/health`
3. Run tests to verify everything works: `npm test` in backend

---

**That's it!** Your friend should be able to clone and run the full project in under 10 minutes.
