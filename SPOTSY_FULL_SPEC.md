# 🅿️ SPOTSY — Full Product Specification

> **Spotsy** is a parking-space booking platform inspired by Rapido. Parking space owners list their spots; users discover, book, pay, and navigate to them in real-time. The platform consists of **two separate Flutter apps** and a **shared Spring Boot backend**.

---

## 🏗️ TECH STACK

| Layer | Technology |
|---|---|
| **Mobile Apps** | Flutter 3.x (two apps: Spotsy Captain + Spotsy User) |
| **State Management** | Riverpod |
| **Maps** | OpenStreetMap via `flutter_map` |
| **Location** | `geolocator` + `location` packages |
| **Backend** | Spring Boot 3.x (REST API) |
| **Database** | PostgreSQL |
| **Auth** | JWT (Access + Refresh tokens) |
| **Real-time** | WebSockets (Spring WebSocket + STOMP) |
| **Real-time DB** | Supabase (real-time sync for availability) |
| **Payment** | BillDesk Payment API |
| **KYC** | Aadhaar KYC API (fetch name, DOB, gender, address) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **File Storage** | AWS S3 / Firebase Storage (parking photos, profile photos) |

---

## 📱 APP 1: SPOTSY CAPTAIN (Owner App)

This is the app for **parking space owners**. They list their parking spots, manage bookings, view earnings, and accept/reject incoming booking requests.

---

### 🔐 1. Authentication (No OTP for now)

#### Login Screen
- Phone number input field
- Password input field
- "Forgot Password?" link
- "LOG IN" button
- "New here? Create an account" link → navigates to Register

#### Register Screen
- Full Name input
- Phone Number input
- Password input
- "CREATE ACCOUNT" button
- On success → navigate to Dashboard

> **Auth Flow:** Phone + Password → Backend returns JWT access token (15 min) + refresh token (7 days). Token stored locally. All subsequent API calls include the JWT in headers. No OTP verification for now.

---

### 🗺️ 2. Dashboard Screen

The **main screen** the owner sees after login. It has two parts:

#### 2A. Map View (Top Half)
- Full-screen OpenStreetMap background
- **Markers** for every parking space this owner has listed
- Marker color indicates occupancy:
  - 🟢 **Green** = Available (spaces free)
  - 🟡 **Yellow** = 50-80% occupied
  - 🔴 **Red** = Full (0 spaces left)
- Tap a marker → shows a mini popup with the space name and availability count
- "My Location" FAB button → centers map on owner's current GPS location

#### 2B. Parking Spaces List (Below Map / Bottom Sheet)
- Scrollable list of **all parking spaces** this owner has listed
- Each card shows:
  - **Parking space name** (e.g., "MG Road Parking Lot")
  - **Price per hour** (e.g., ₹30/hr) — prominently displayed
  - **Space type icon**: 🏍️ Bike / 🚗 Car / 🔀 Mixed
  - **EV charging available** indicator (⚡ icon if yes)
  - **Live occupancy bar** (e.g., "5/20 spaces available")
  - **Rating** (e.g., ⭐ 4.8)
- Tap a card → navigate to **Edit Parking Space Screen**
- **"+ Add New Space"** floating button at the bottom

---

### 🏢 3. Add / Edit Parking Space Screen

When the owner taps "Add New Space" or edits an existing one:

#### Input Fields
- **Space Name** (text input)
- **Address** (text input + map picker to set exact lat/lng)
- **Total Spaces** (integer input — how many vehicles can park)
- **Price Per Hour** (decimal input — ₹ per hour)
- **Vehicle Type** selector: Bike / Car / Mixed
- **EV Charging** toggle (Yes / No)
- **Other Amenities** toggles: CCTV, Security Guard, Lighting, Covered/Sheltered
- **Operating Hours**:
  - Opening Time picker
  - Closing Time picker
  - OR "24/7" toggle (overrides the above)
- **Description** (multi-line text area)

#### Photo Upload Section
- Upload **multiple photos** of the parking area
- Each photo can be tagged: Full View / Entry Gate / Parking Space / Amenity
- Drag to reorder photos
- Delete photo option
- **These photos will be shown to users** when they browse this parking spot

#### Actions
- **"SAVE"** button → creates/updates the parking space via API
- **"DELETE"** button (only on edit) → soft-deletes the space

---

### 📩 4. Booking Requests (Notifications Tab)

When a user books a parking spot, the owner gets a **real-time notification via WebSocket**.

#### Incoming Requests List
- Show all pending (unconfirmed) booking requests
- Each request card shows:
  - **User's name** and profile photo
  - **User's vehicle**: type (Bike/Car), registration number, color
  - **Which parking space** they want to book
  - **Requested check-in time**
  - **Estimated duration**
  - ✅ **ACCEPT** button (green)
  - ❌ **REJECT** button (red)

#### On tapping a request → Request Detail Screen
- Full user profile (name, phone, Aadhaar verified badge)
- Vehicle photo and full details
- User's booking history with this owner (if any)
- User's rating
- Accept / Reject buttons

#### Accept Flow
1. Owner taps ACCEPT
2. WebSocket sends confirmation to user in real-time
3. Booking status changes to CONFIRMED
4. Booking moves to "Active Bookings" section

#### Reject Flow
1. Owner taps REJECT
2. WebSocket notifies user immediately
3. User sees "Booking Rejected" and can try another spot

---

### 📍 5. Active Bookings

Shows all **currently confirmed and in-progress** bookings.

- Each active booking card shows:
  - User name
  - Vehicle info (type, registration, color)
  - Check-in time
  - Expected check-out time
  - Which parking space
  - **"Track User"** button → shows user's real-time GPS location on map (via WebSocket)
  - Estimated earnings for this booking

---

### 💰 6. Earnings Section

#### 6A. Earnings Overview
- **Total Lifetime Earnings** — big bold number
- **This Month** earnings
- **This Week** earnings
- **Today** earnings
- Average earnings per day

#### 6B. Transaction History
- Scrollable list of all completed bookings with:
  - Date
  - Booking ID
  - Vehicle type
  - Duration
  - Amount earned
  - Payout status (Paid / Processing / Unpaid)
- Filter by date range
- Export option (CSV)

#### 6C. Bank Account Linking
- Owner must link a bank account to receive payouts
- Input fields:
  - Account Holder Name
  - Account Number
  - Confirm Account Number
  - IFSC Code
  - Bank Name (auto-filled from IFSC)
  - Account Type: Savings / Current
- **"Verify Account"** button
- Status indicator: ✅ Verified / ⏳ Pending
- Support for **multiple accounts** (one marked as primary)

---

### 👤 7. Profile Section

#### 7A. Personal Info
- Profile photo (upload/change)
- Full Name
- Phone Number (with verified badge)
- Email
- Business Name

#### 7B. Aadhaar KYC Verification
- **This is mandatory** — owners must verify their identity
- Flow:
  1. Owner enters their 12-digit Aadhaar number
  2. App sends it to the Aadhaar KYC API
  3. API returns: **Full Name, Date of Birth, Gender, Address**
  4. These details are **auto-populated** into the owner's profile
  5. KYC status is marked as ✅ VERIFIED
  6. Aadhaar number stored **encrypted** in the database
- KYC Status display: 🔴 Not Verified / 🟡 Pending / 🟢 Verified
- Re-verify option if previously rejected

#### 7C. Ratings & Reviews
- Average rating display (e.g., ⭐ 4.8)
- Total reviews count
- List of recent reviews from users

#### 7D. Account Settings
- Notification preferences
- Language selection
- Logout button

---

---

## 📱 APP 2: SPOTSY USER (User App)

This is the app for **users who want to find and book parking spaces**. They search nearby, filter, view details, book, pay, and navigate to the parking spot.

---

### 🔐 1. Authentication (No OTP for now)

Same as Captain app:
- Login with Phone + Password
- Register with Name + Phone + Password
- JWT-based auth

---

### 🗺️ 2. Dashboard Screen

#### 2A. Map View (Full Screen Background)
- OpenStreetMap covering the full screen
- **Blue dot** showing the user's current GPS location
- Parking space markers appear when user scans (see below)
- Marker colors:
  - 🟢 Green = Available
  - 🟡 Yellow = Filling up
  - 🔴 Red = Full
- Tap a marker → navigate to **Parking Detail Screen**
- Pinch to zoom, pan to explore

#### 2B. Scan & Filter Panel (Bottom Sheet)

##### Scan Button
- Big prominent **"SCAN NEARBY"** button
- When tapped → scans for all parking spaces within **500m radius** of user's current location
- Results appear as markers on the map
- Optional: Radius slider (100m → 5km) to adjust search area

##### Filter Options (expandable section)
- **Vehicle Type**: Bike / Car / SUV / All
- **EV Charging**: Yes / No / Don't Care
- **Price Range**: Min ₹ — Max ₹ per hour slider
- **Amenities**: CCTV, Security, Lighting, Covered (toggle chips)
- **Minimum Rating**: star rating selector
- **"Apply Filters"** button → re-filters the markers on the map

---

### 🏢 3. Parking Detail Screen

When user taps a parking marker on the map, they see this screen:

#### Top Section — Photo Carousel
- **Full-width image carousel** showing all photos uploaded by the owner
- Swipeable, with dot indicators
- Photos show: full view of parking, entry gate, spaces, amenities

#### Details Section
- **Parking space name** (e.g., "Brigade Road Parking")
- **Location address**
- **Price per hour** — bold, prominent (e.g., ₹30/hr)
- **Vehicle types accepted**: 🏍️ Bike / 🚗 Car / Both
- **EV Charging**: ⚡ Available / Not Available
- **Amenities list**: CCTV, Security, Lighting, Covered, etc.
- **Operating hours**: 9 AM - 10 PM or "24/7"
- **Available spaces**: "5 of 20 spaces available"

#### Owner Info Section
- Owner's name and profile photo
- Owner's rating (e.g., ⭐ 4.8)
- Owner's total reviews count
- Aadhaar Verified badge (if KYC done)

#### Map Preview
- Small embedded map showing exact parking location
- "Open in Maps" button for external navigation

#### Reviews Section
- Recent user reviews with ratings
- "See All Reviews" link

#### Action Button
- **"BOOK NOW"** button — fixed at the bottom of the screen

---

### 🚗 4. Vehicle Selection Screen

After tapping "BOOK NOW", the user must select which vehicle they are parking:

- List of all vehicles the user has registered in their profile
- Each vehicle card shows:
  - Vehicle type icon (🏍️ / 🚗)
  - Vehicle name & model (e.g., "Honda Activa 6G")
  - Registration number (e.g., "KA-01-AB-1234")
  - Vehicle color
  - EV badge (if applicable)
- **"Select"** button on each card
- **"+ Add New Vehicle"** button at the bottom

---

### ✅ 5. Booking Confirmation Screen

After selecting a vehicle:

#### Summary Section
- Parking space name and address
- Selected vehicle info (type, registration, color)
- Expected check-in time (current time or user-selected)

#### Price Calculation Section
- Price per hour: ₹30
- Estimated hours: user selects expected check-out time
- **Total amount** = price × hours (calculated in real-time as user adjusts)
- Discount/Coupon code input (optional)

#### Owner Confirmation Status
- After user confirms, a **real-time request is sent to the owner via WebSocket**
- Screen shows: ⏳ "Awaiting Owner Confirmation..."
- Animated waiting indicator
- When owner accepts → status changes to ✅ "Booking Confirmed!"
- When owner rejects → status changes to ❌ "Booking Rejected" with option to search again

#### Payment Button
- **"PROCEED TO PAYMENT"** button — only enabled after owner confirms

---

### 💳 6. Payment Screen (BillDesk Integration)

- Order summary (parking name, vehicle, duration, amount)
- BillDesk payment gateway UI embedded
- Payment methods: UPI, Credit/Debit Card, Net Banking, Wallet
- Secure checkout
- Loading state while processing
- On success → navigate to **Active Booking Screen**
- On failure → show error with retry option

---

### 🧭 7. Active Booking Screen (Navigation + Live Tracking)

After payment is successful, the user sees this screen:

#### Navigation Section
- **Full map view** showing:
  - User's current location (blue dot, real-time GPS)
  - Parking spot location (destination marker)
  - Route/path between them (if possible)
- **"Navigate"** button → opens the device's default Maps app (Google Maps / Apple Maps) with directions to the parking spot
- Real-time distance and ETA display

#### Booking Info Section
- Parking space name
- Check-in time
- Running timer showing elapsed time
- Running cost calculation (price × elapsed hours)
- Expected check-out time (user can update)

#### Check-Out Section
- When user is done parking:
  - **"CHECK OUT"** button
  - Shows final duration
  - Shows final amount
  - Confirmation dialog
  - On confirm → booking marked as COMPLETED
  - If actual time exceeds estimate → additional payment required

#### Owner Tracking (Owner Side)
- While booking is active, the **owner can see the user's real-time GPS location** on their map via WebSocket
- This helps the owner know when the user is arriving

---

### 📜 8. Booking History Screen

- List of all past bookings (completed and cancelled)
- Each booking card shows:
  - Parking space name
  - Vehicle used
  - Date & time
  - Duration
  - Amount paid
  - Status badge: ✅ Completed / ❌ Cancelled / 💸 Refunded
- Tap a completed booking → option to **leave a review** (1-5 stars + text)

---

### 👤 9. Profile Section

#### 9A. Personal Info
- Profile photo (upload/change)
- Full Name
- Phone Number (verified badge)
- Email

#### 9B. Aadhaar KYC Verification
- **Same flow as the Owner app:**
  1. Enter 12-digit Aadhaar number
  2. API fetches: Name, DOB, Gender, Address
  3. Auto-populate profile
  4. Mark as VERIFIED
- KYC status display

#### 9C. My Vehicles (Instead of Parking Spaces)
- List of all registered vehicles
- Each vehicle shows:
  - Type: Bike / Car / SUV
  - Vehicle Name & Model
  - Registration Number
  - Vehicle Color
  - Parking Height (for clearance — important for covered parking)
  - EV badge (if electric)
  - Active / Inactive toggle
- **"+ Add New Vehicle"** button
- Edit and Delete options per vehicle

#### 9D. Account Settings
- Saved addresses (Home, Work, etc.)
- Preferred payment method
- Notification preferences
- Logout button

---

---

## 🔄 REAL-TIME FLOWS (WebSocket)

### Booking Request Flow
```
1. User taps "BOOK NOW" → selects vehicle → confirms booking
2. Client sends booking request via WebSocket:
     /app/booking/request → {bookingId, parkingSpaceId, userId, vehicleInfo}
3. Server pushes to Owner:
     /topic/owner/{ownerId}/bookings → {type: 'NEW_REQUEST', bookingDetails}
4. Owner sees notification, taps Accept or Reject
5. Owner sends response:
     /app/booking/accept  OR  /app/booking/reject → {bookingId, status}
6. Server pushes to User:
     /topic/user/{userId}/bookings → {type: 'BOOKING_CONFIRMED' or 'BOOKING_REJECTED'}
7. User sees status update in real-time (no page refresh)
```

### Real-Time Parking Availability
```
Whenever a booking is confirmed or a check-out happens:
  Server → /topic/parking/{parkingSpaceId}/availability
  Payload: {availableSpaces, totalSpaces, occupancyRate}
All users viewing the map get live updates.
```

### Live User Location Tracking (During Active Booking)
```
While user is navigating to parking:
  User → /app/booking/{bookingId}/location → {lat, lng, timestamp}
  Server → /topic/booking/{bookingId}/user-location → {lat, lng}
  Owner sees user's live location on their map
```

---

## 🗄️ DATABASE SCHEMA (PostgreSQL)

### Users
```sql
users (
  id UUID PK,
  phone_number VARCHAR UNIQUE,
  email VARCHAR UNIQUE,
  first_name VARCHAR,
  last_name VARCHAR,
  aadhar_number VARCHAR ENCRYPTED,
  kyc_status ENUM('PENDING','VERIFIED','REJECTED'),
  kyc_verified_at TIMESTAMP,
  profile_photo_url TEXT,
  account_type ENUM('OWNER','USER','BOTH'),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

### Aadhaar KYC Details
```sql
user_kyc_details (
  id UUID PK,
  user_id UUID FK → users,
  aadhar_number VARCHAR ENCRYPTED,
  name_from_aadhar VARCHAR,
  dob DATE,
  gender ENUM('MALE','FEMALE','OTHER'),
  address TEXT,
  kyc_response_data JSONB,
  verified_at TIMESTAMP,
  created_at TIMESTAMP
)
```

### User Vehicles
```sql
user_vehicles (
  id UUID PK,
  user_id UUID FK → users,
  vehicle_type ENUM('BIKE','CAR','SUV'),
  registration_number VARCHAR,
  vehicle_name VARCHAR,
  vehicle_model VARCHAR,
  vehicle_color VARCHAR,
  parking_height VARCHAR,
  is_ev BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP
)
```

### Parking Owners
```sql
parking_owners (
  id UUID PK,
  user_id UUID FK → users UNIQUE,
  business_name VARCHAR,
  business_registration_number VARCHAR,
  total_earnings DECIMAL DEFAULT 0,
  account_verified BOOLEAN DEFAULT false,
  kyc_status ENUM('PENDING','VERIFIED','REJECTED'),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

### Bank Accounts
```sql
bank_accounts (
  id UUID PK,
  owner_id UUID FK → parking_owners,
  account_holder_name VARCHAR,
  account_number VARCHAR ENCRYPTED,
  ifsc_code VARCHAR,
  bank_name VARCHAR,
  account_type ENUM('SAVINGS','CURRENT'),
  is_verified BOOLEAN DEFAULT false,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMP
)
```

### Parking Spaces
```sql
parking_spaces (
  id UUID PK,
  owner_id UUID FK → parking_owners,
  space_name VARCHAR,
  address TEXT,
  latitude DECIMAL,
  longitude DECIMAL,
  total_spaces INTEGER,
  available_spaces INTEGER,
  space_type ENUM('BIKE','CAR','MIXED'),
  price_per_hour DECIMAL,
  has_ev_charging BOOLEAN DEFAULT false,
  has_security BOOLEAN DEFAULT false,
  has_cctv BOOLEAN DEFAULT false,
  has_lighting BOOLEAN DEFAULT false,
  is_covered BOOLEAN DEFAULT false,
  description TEXT,
  opening_time TIME,
  closing_time TIME,
  is_24_7 BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  rating DECIMAL DEFAULT 0,
  total_ratings INTEGER DEFAULT 0,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

### Parking Space Photos
```sql
parking_space_photos (
  id UUID PK,
  parking_space_id UUID FK → parking_spaces,
  photo_url TEXT,
  photo_type ENUM('FULL_VIEW','ENTRY','SPACE','AMENITY'),
  display_order INTEGER,
  uploaded_at TIMESTAMP
)
```

### Bookings
```sql
bookings (
  id UUID PK,
  user_id UUID FK → users,
  parking_space_id UUID FK → parking_spaces,
  vehicle_id UUID FK → user_vehicles,
  booking_status ENUM('PENDING_OWNER_CONFIRMATION','CONFIRMED','ACTIVE','COMPLETED','CANCELLED'),
  check_in_time TIMESTAMP,
  check_out_time TIMESTAMP,
  total_hours DECIMAL,
  price_per_hour DECIMAL,
  total_amount DECIMAL,
  payment_status ENUM('PENDING','COMPLETED','FAILED','REFUNDED'),
  payment_id VARCHAR,
  owner_confirmed_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

### Earnings
```sql
earnings (
  id UUID PK,
  owner_id UUID FK → parking_owners,
  booking_id UUID FK → bookings,
  amount DECIMAL,
  transaction_status ENUM('PENDING','COMPLETED','FAILED'),
  payout_status ENUM('UNPAID','PAID','PROCESSING'),
  payout_date TIMESTAMP,
  created_at TIMESTAMP
)
```

### Reviews
```sql
reviews (
  id UUID PK,
  booking_id UUID FK → bookings,
  parking_space_id UUID FK → parking_spaces,
  user_id UUID FK → users,
  rating INTEGER CHECK(1-5),
  review_text TEXT,
  created_at TIMESTAMP
)
```

---

## 🔌 API ENDPOINTS (Spring Boot)

### Auth
```
POST  /api/auth/register          — Register new user/owner
POST  /api/auth/login             — Login (returns JWT tokens)
POST  /api/auth/logout            — Invalidate tokens
POST  /api/auth/refresh-token     — Refresh access token
```

### Users
```
GET   /api/users/profile          — Get own profile
PUT   /api/users/profile          — Update profile
POST  /api/users/kyc/verify       — Submit Aadhaar for KYC
GET   /api/users/kyc/status       — Get KYC status
```

### Vehicles (User App)
```
POST  /api/users/vehicles         — Add a vehicle
GET   /api/users/vehicles         — List my vehicles
PUT   /api/users/vehicles/{id}    — Update vehicle
DELETE /api/users/vehicles/{id}   — Delete vehicle
```

### Parking Owners
```
POST  /api/owners/register        — Register as owner
GET   /api/owners/dashboard       — Dashboard stats
```

### Parking Spaces (Owner App)
```
POST  /api/parking-spaces                  — Create a space
GET   /api/parking-spaces                  — List my spaces (owner)
GET   /api/parking-spaces/{id}             — Get space details
PUT   /api/parking-spaces/{id}             — Update space
DELETE /api/parking-spaces/{id}            — Delete space
GET   /api/parking-spaces/nearby?lat=&lng=&radius=500  — Search nearby (user)
POST  /api/parking-spaces/{id}/photos      — Upload photos
GET   /api/parking-spaces/{id}/photos      — Get photos
DELETE /api/parking-spaces/{id}/photos/{photoId}  — Delete a photo
```

### Bookings
```
POST  /api/bookings                        — Create booking
GET   /api/bookings/user                   — My bookings (user)
GET   /api/bookings/owner                  — Bookings for my spaces (owner)
GET   /api/bookings/{id}                   — Booking detail
PUT   /api/bookings/{id}/status            — Accept/Reject (owner)
POST  /api/bookings/{id}/check-in          — User checks in
POST  /api/bookings/{id}/check-out         — User checks out
DELETE /api/bookings/{id}/cancel           — Cancel booking
```

### Payments
```
POST  /api/bookings/{id}/payment           — Initiate BillDesk payment
GET   /api/bookings/{id}/payment/status    — Check payment status
POST  /api/payments/webhook                — BillDesk webhook callback
```

### Earnings (Owner)
```
GET   /api/owners/earnings                 — Earnings summary
GET   /api/owners/earnings/history         — Transaction history
POST  /api/owners/bank-account             — Link bank account
GET   /api/owners/bank-account             — Get linked accounts
PUT   /api/owners/bank-account/{id}        — Update account
```

### Reviews
```
POST  /api/reviews                         — Submit review
GET   /api/reviews/parking-space/{id}      — Reviews for a space
```

### Search
```
GET   /api/search/parking?lat=&lng=&radius=500&type=CAR&hasEV=true&minRating=4
```

---

## 🔒 SECURITY

| Concern | Implementation |
|---|---|
| Auth | JWT access token (15 min) + refresh token (7 days) |
| Password | Bcrypt hashing via Spring Security |
| Aadhaar | Stored AES-256 encrypted, never exposed in API responses |
| Bank Account | Account numbers stored encrypted |
| API Security | HTTPS only, rate limiting, CORS config |
| Data Privacy | GDPR-compliant, account deletion support |

---

## 💳 PAYMENT FLOW (BillDesk)

```
1. User confirms booking → Owner accepts
2. User taps "Proceed to Payment"
3. Frontend calls POST /api/bookings/{id}/payment
4. Backend creates a BillDesk payment order, returns payment link/token
5. Flutter app opens BillDesk payment UI (UPI, Card, Wallet, Net Banking)
6. User completes payment
7. BillDesk sends webhook to POST /api/payments/webhook
8. Backend verifies payment signature
9. Backend updates booking.payment_status = COMPLETED
10. Backend creates earnings record for the owner
11. WebSocket notifies both user and owner of payment success
12. User redirected to Active Booking Screen
```

---

## 🧭 NAVIGATION ROUTES

### Captain App (Owner)
```
/login           → Login Screen
/register        → Register Screen
/dashboard       → Dashboard (Map + Parking Spaces List)
/parking/add     → Add New Parking Space
/parking/:id     → Edit Parking Space
/bookings        → Booking Requests + Active Bookings
/booking/:id     → Booking Detail
/earnings        → Earnings Dashboard + Bank Account
/profile         → Profile + KYC
```

### User App
```
/login           → Login Screen
/register        → Register Screen
/dashboard       → Dashboard (Map + Scan + Filters)
/parking/:id     → Parking Detail (Photos, Info, Book)
/booking/vehicle → Vehicle Selection
/booking/confirm → Booking Confirmation (+ Owner Accept Wait)
/booking/payment → Payment Screen
/booking/:id     → Active Booking (Navigation + Live Tracking)
/history         → Booking History
/profile         → Profile + KYC + My Vehicles
```

---

## 📐 DEVELOPMENT PHASES

| Phase | What Gets Built | Estimated Duration |
|---|---|---|
| **Phase 1** | Project setup, DB schema, API scaffolding, JWT auth | 1-2 weeks |
| **Phase 2** | Core backend: Parking CRUD, Booking logic, Aadhaar KYC | 3-4 weeks |
| **Phase 3** | BillDesk payment integration, WebSocket real-time events | 2-3 weeks |
| **Phase 4** | Captain App MVP: Dashboard, Space management, Bookings, Earnings | 3-4 weeks |
| **Phase 5** | User App MVP: Dashboard, Scan, Book, Pay, Navigate | 3-4 weeks |
| **Phase 6** | Real-time features: Live tracking, Supabase sync, Notifications | 2-3 weeks |
| **Phase 7** | Testing, QA, bug fixes, performance optimization | 2-3 weeks |
| **Phase 8** | Deployment (Play Store, App Store, backend hosting) | 1-2 weeks |

**Total: ~18-26 weeks (4-6 months)**

---

## 🚀 FUTURE ENHANCEMENTS

1. In-app chat between owner and user
2. Monthly/weekly subscription parking plans
3. Surge pricing based on demand
4. In-app wallet system
5. Referral program (refer & earn)
6. Vehicle damage reporting with photos
7. Premium/featured parking listings
8. Analytics dashboard for owners
9. Multi-language support
10. Parking lot capacity sensors (IoT integration)

---

**This specification is the single source of truth for building Spotsy. Both apps share the same backend. Start with the Captain app, then build the User app.**
