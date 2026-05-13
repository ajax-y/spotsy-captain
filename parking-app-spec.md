# 🅿️ PARKING BOOKING APP - FULL PROJECT SPECIFICATION

## PROJECT OVERVIEW

A comprehensive parking space booking platform similar to Rapido, enabling parking space owners to list their parking spots and users to book available parking in real-time.

---

## TECH STACK & ARCHITECTURE

### Backend
- **Framework**: Spring Boot 3.x
- **Database**: PostgreSQL
- **Real-time Communication**: WebSockets (Spring WebSocket + STOMP)
- **Authentication**: JWT (JSON Web Tokens)
- **Payment Gateway**: BillDesk Payment API
- **KYC Verification**: Aadhar KYC API
- **Real-time Database**: Supabase (for optional sync)

### Mobile Frontend
- **Framework**: Flutter 3.x+
- **State Management**: Provider / Riverpod
- **Maps**: Open Street Map (using `flutter_map` package)
- **Location Services**: `geolocator` + `location` packages
- **Payment**: BillDesk Flutter SDK
- **Real-time**: WebSocket client with `web_socket_channel`

### Infrastructure
- **API Server**: Spring Boot REST API
- **Database**: PostgreSQL (self-hosted or managed)
- **File Storage**: Cloud storage (AWS S3 / Firebase Storage)
- **Push Notifications**: Firebase Cloud Messaging (FCM)

---

## DATABASE SCHEMA

### USER TABLES

#### `users`
```sql
id (UUID, PK)
phone_number (VARCHAR, UNIQUE)
email (VARCHAR, UNIQUE)
first_name (VARCHAR)
last_name (VARCHAR)
aadhar_number (VARCHAR, ENCRYPTED)
kyc_status (ENUM: PENDING, VERIFIED, REJECTED)
kyc_verified_at (TIMESTAMP)
profile_photo_url (TEXT)
account_type (ENUM: OWNER, USER, BOTH)
is_active (BOOLEAN)
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

#### `user_kyc_details`
```sql
id (UUID, PK)
user_id (UUID, FK -> users)
aadhar_number (VARCHAR, ENCRYPTED)
name_from_aadhar (VARCHAR)
dob (DATE)
gender (ENUM: MALE, FEMALE, OTHER)
address (TEXT)
kyc_response_data (JSONB) -- Full Aadhar API response
verified_at (TIMESTAMP)
created_at (TIMESTAMP)
```

#### `user_vehicles`
```sql
id (UUID, PK)
user_id (UUID, FK -> users)
vehicle_type (ENUM: BIKE, CAR, SUV)
registration_number (VARCHAR)
vehicle_name (VARCHAR)
vehicle_model (VARCHAR)
vehicle_color (VARCHAR)
parking_height (VARCHAR) -- For clearance
is_ev (BOOLEAN)
is_active (BOOLEAN)
created_at (TIMESTAMP)
```

---

### PARKING OWNER TABLES

#### `parking_owners`
```sql
id (UUID, PK)
user_id (UUID, FK -> users, UNIQUE)
business_name (VARCHAR)
business_registration_number (VARCHAR)
total_earnings (DECIMAL)
account_verified (BOOLEAN)
account_verified_at (TIMESTAMP)
kyc_status (ENUM: PENDING, VERIFIED, REJECTED)
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

#### `bank_accounts`
```sql
id (UUID, PK)
owner_id (UUID, FK -> parking_owners)
account_holder_name (VARCHAR)
account_number (VARCHAR, ENCRYPTED)
ifsc_code (VARCHAR)
bank_name (VARCHAR)
account_type (ENUM: SAVINGS, CURRENT)
is_verified (BOOLEAN)
verified_at (TIMESTAMP)
is_primary (BOOLEAN)
created_at (TIMESTAMP)
```

#### `earnings`
```sql
id (UUID, PK)
owner_id (UUID, FK -> parking_owners)
booking_id (UUID, FK -> bookings)
amount (DECIMAL)
transaction_status (ENUM: PENDING, COMPLETED, FAILED)
payout_status (ENUM: UNPAID, PAID, PROCESSING)
payout_date (TIMESTAMP)
created_at (TIMESTAMP)
```

---

### PARKING SPACE TABLES

#### `parking_spaces`
```sql
id (UUID, PK)
owner_id (UUID, FK -> parking_owners)
space_name (VARCHAR)
address (TEXT)
latitude (DECIMAL)
longitude (DECIMAL)
total_spaces (INTEGER)
available_spaces (INTEGER)
space_type (ENUM: BIKE, CAR, MIXED)
price_per_hour (DECIMAL)
has_ev_charging (BOOLEAN)
has_security (BOOLEAN)
has_cctv (BOOLEAN)
description (TEXT)
opening_time (TIME)
closing_time (TIME)
is_24_7 (BOOLEAN)
is_active (BOOLEAN)
rating (DECIMAL)
total_ratings (INTEGER)
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

#### `parking_space_photos`
```sql
id (UUID, PK)
parking_space_id (UUID, FK -> parking_spaces)
photo_url (TEXT)
photo_type (ENUM: FULL_VIEW, ENTRY, SPACE, AMENITY)
uploaded_at (TIMESTAMP)
display_order (INTEGER)
```

#### `parking_space_amenities`
```sql
id (UUID, PK)
parking_space_id (UUID, FK -> parking_spaces)
amenity_type (VARCHAR) -- CCTV, SECURITY, LIGHTING, COVERED, etc.
availability (BOOLEAN)
```

---

### BOOKING TABLES

#### `bookings`
```sql
id (UUID, PK)
user_id (UUID, FK -> users)
parking_space_id (UUID, FK -> parking_spaces)
vehicle_id (UUID, FK -> user_vehicles)
booking_status (ENUM: PENDING_OWNER_CONFIRMATION, CONFIRMED, ACTIVE, COMPLETED, CANCELLED)
check_in_time (TIMESTAMP)
check_out_time (TIMESTAMP) -- NULL until user checks out
total_hours (DECIMAL)
price_per_hour (DECIMAL)
total_amount (DECIMAL)
payment_status (ENUM: PENDING, COMPLETED, FAILED, REFUNDED)
payment_id (VARCHAR) -- BillDesk payment ID
owner_confirmed_at (TIMESTAMP)
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

#### `booking_notifications`
```sql
id (UUID, PK)
booking_id (UUID, FK -> bookings)
owner_id (UUID, FK -> parking_owners)
notification_type (ENUM: NEW_REQUEST, ACCEPTED, REJECTED, CHECK_IN, CHECK_OUT)
is_read (BOOLEAN)
created_at (TIMESTAMP)
```

---

### REVIEW & RATING TABLES

#### `reviews`
```sql
id (UUID, PK)
booking_id (UUID, FK -> bookings)
parking_space_id (UUID, FK -> parking_spaces)
user_id (UUID, FK -> users)
rating (INTEGER) -- 1-5
review_text (TEXT)
created_at (TIMESTAMP)
```

---

## SPRING BOOT API ENDPOINTS

### Authentication Endpoints
```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout
POST   /api/auth/refresh-token
POST   /api/auth/verify-phone
```

### User Management Endpoints
```
GET    /api/users/profile
PUT    /api/users/profile
POST   /api/users/kyc/verify-aadhar
GET    /api/users/kyc/status
POST   /api/users/vehicles
GET    /api/users/vehicles
PUT    /api/users/vehicles/{vehicleId}
DELETE /api/users/vehicles/{vehicleId}
```

### Parking Owner Endpoints
```
POST   /api/owners/register
GET    /api/owners/dashboard
GET    /api/owners/earnings
GET    /api/owners/earnings/history
POST   /api/owners/bank-account
GET    /api/owners/bank-account
PUT    /api/owners/bank-account/{accountId}
```

### Parking Space Endpoints
```
POST   /api/parking-spaces
GET    /api/parking-spaces
GET    /api/parking-spaces/{id}
PUT    /api/parking-spaces/{id}
DELETE /api/parking-spaces/{id}
GET    /api/parking-spaces/nearby?lat={lat}&lng={lng}&radius=500
POST   /api/parking-spaces/{id}/photos
GET    /api/parking-spaces/{id}/photos
DELETE /api/parking-spaces/{id}/photos/{photoId}
```

### Booking Endpoints
```
POST   /api/bookings
GET    /api/bookings/user
GET    /api/bookings/owner
GET    /api/bookings/{id}
PUT    /api/bookings/{id}/status
POST   /api/bookings/{id}/payment
POST   /api/bookings/{id}/check-in
POST   /api/bookings/{id}/check-out
DELETE /api/bookings/{id}/cancel
```

### Review & Rating Endpoints
```
POST   /api/reviews
GET    /api/reviews/parking-space/{parkingSpaceId}
GET    /api/reviews/user/{userId}
```

### Search & Filter Endpoints
```
GET    /api/search/parking?lat={lat}&lng={lng}&radius=500&type=CAR&hasEV=true
GET    /api/search/parking/filters
```

---

## WEBSOCKET EVENTS (Real-time Communication)

### Booking Confirmation Flow
```
Client -> Server: /app/booking/request
Message: {bookingId, parkingSpaceId, userId, vehicleInfo}

Server -> Owner: /topic/owner/{ownerId}/bookings
Message: {type: 'NEW_REQUEST', booking details}

Owner -> Server: /app/booking/accept or /app/booking/reject
Message: {bookingId, status}

Server -> User: /topic/user/{userId}/bookings
Message: {type: 'BOOKING_STATUS_UPDATED', status}
```

### Real-time Parking Availability
```
Server -> Clients: /topic/parking/{parkingSpaceId}/availability
Message: {availableSpaces, totalSpaces, occupancyRate}
```

### Live Location Tracking (During Active Booking)
```
User -> Server: /app/booking/{bookingId}/location
Message: {latitude, longitude, timestamp}

Server -> Owner: /topic/booking/{bookingId}/user-location
Message: {latitude, longitude}
```

### Notification Events
```
Server -> User: /topic/user/{userId}/notifications
Server -> Owner: /topic/owner/{ownerId}/notifications
```

---

## FLUTTER USER APP - DETAILED FEATURES

### 1. AUTHENTICATION SCREENS
- **Phone Registration Screen**
  - Phone number input with country code
  - OTP verification
  - Password setup

- **Login Screen**
  - Phone + password login
  - Forgot password option

### 2. DASHBOARD (User App)
#### Map Screen
- Display current user location (blue dot)
- Show parking spaces within 500m radius as markers (different colors for availability)
- Real-time marker updates via WebSocket
- Pinch-to-zoom, pan functionality
- Tap marker to see parking details

#### Scan & Filter Panel (Bottom Sheet)
- **Scan Button**: Radius slider (100m - 5km)
- **Filter Options**:
  - Vehicle Type: Bike / Car / SUV / All
  - EV Charging: Yes / No / Don't Care
  - Price Range: Min - Max per hour
  - Amenities: CCTV, Security, Lighting, Covered, etc.
  - Rating: Minimum rating filter
- **Apply Filters** button

### 3. PARKING DETAIL SCREEN
- Carousel of parking space photos (full view)
- Parking name & location
- Price per hour (bold highlight)
- Vehicle types accepted
- EV charging availability (with indicator)
- Owner name & profile photo
- Owner rating & reviews count
- Description & amenities list
- Map marker showing exact location
- **Book Now** button
- Reviews section with ratings

### 4. VEHICLE SELECTION SCREEN
- List of user's vehicles
- Vehicle image (auto-fetched from registration API)
- Vehicle type badge (Bike/Car)
- Registration number
- Select vehicle button
- Option to add new vehicle

### 5. BOOKING CONFIRMATION SCREEN
- Parking space details summary
- Selected vehicle info
- Expected check-in time
- Estimated price calculation
- Owner information & confirmation status
- **Payment Details Section**:
  - Price per hour
  - Estimated hours (user inputs check-out time)
  - Total amount calculation (real-time)
  - Discount/Coupon section
  - **Proceed to Payment** button
- Status indicator: "Awaiting Owner Confirmation"

### 6. PAYMENT SCREEN (BillDesk Integration)
- Order summary
- BillDesk payment gateway embedded
- Payment method selection (UPI, Card, Wallet, etc.)
- Secure checkout
- Loading state while processing
- Success/failure status

### 7. ACTIVE BOOKING SCREEN (During Parking)
- Map with real-time navigation to parking location
- Navigation button → Opens Maps app with directions
- Parking location on map
- Check-in time display
- Remaining time / Price running calculation
- **Check-out Section**:
  - Check-out time
  - Final amount
  - **Confirm Check-out** button
- Owner can see user location (real-time via WebSocket)

### 8. BOOKING HISTORY SCREEN
- List of past bookings (completed, cancelled)
- Booking card shows:
  - Parking space name
  - Vehicle used
  - Duration
  - Amount paid
  - Status
  - Review option for completed bookings

### 9. PROFILE SCREEN (User)
#### Profile Section
- Profile photo upload
- Full name display
- Phone number (verified badge)
- Email

#### Vehicles Section
- List of registered vehicles
- Add new vehicle button
- Delete vehicle option

#### Aadhar KYC Section
- KYC status indicator
- Aadhar number (partially masked)
- Full details fetched from Aadhar API
- Verify Aadhar button
- Re-verify option if rejected

#### Account Section
- Saved addresses
- Preferred payment method
- Notification preferences
- Logout button

---

## FLUTTER OWNER APP - DETAILED FEATURES

### 1. DASHBOARD (Owner App)
#### Map Screen
- Show all owner's parking spaces as markers
- Marker color changes based on occupancy rate
- Tap marker to see live occupancy
- Green = Available, Yellow = 50-80% occupied, Red = Full

#### Quick Stats Panel
```
Total Earnings Today: ₹XXXXX
Active Bookings: X
Available Spaces: X/Y
Rating: 4.8 ⭐
```

### 2. PARKING SPACES MANAGEMENT
#### Parking Spaces List Screen
- Card view of each parking space
- Space name & location
- Price per hour (editable)
- Vehicle type icon (Bike/Car)
- EV charging indicator
- Live occupancy bar (X/Y spaces available)
- Rating display
- Edit button → Edit parking space details
- Tap card to see more details

#### Edit Parking Space Screen
- Space name
- Address with map picker
- Total spaces (integer)
- Price per hour (decimal)
- Vehicle type selector (Bike, Car, Mixed)
- EV charging toggle
- Other amenities (CCTV, Security, Lighting, Covered)
- Operating hours (opening & closing time)
- 24/7 toggle
- Description text area
- **Photo Upload Section**:
  - Upload multiple photos
  - Reorder photos (drag-drop)
  - Delete photo option
  - Photo type selector (Full View, Entry, Space, Amenity)
- Save button

### 3. BOOKING REQUESTS (Notifications)
#### Incoming Requests List
- Show pending booking requests
- Card displays:
  - User name & profile photo
  - Vehicle type & registration number
  - Vehicle color
  - Requested parking space
  - Requested check-in time
  - Estimated duration
  - **Accept** button (green)
  - **Reject** button (red)

#### Request Details Screen
- Full user profile
- Vehicle photo & details
- Aadhar verified badge
- Booking history with this owner
- User rating
- Accept / Reject buttons
- Chat option (optional for future)

### 4. ACTIVE BOOKINGS
#### Current Active Bookings List
- Show confirmed bookings in progress
- Card displays:
  - User name
  - Vehicle info
  - Check-in time
  - Expected check-out time
  - Parking space
  - **User Location** button → Show user's real-time location on map
  - Estimated earnings

#### Active Booking Details
- Full booking information
- User real-time location (WebSocket updated)
- Map showing user location relative to parking
- Estimated check-out time
- Expected earnings amount

### 5. EARNINGS SECTION
#### Dashboard View
- Total lifetime earnings
- This month earnings
- This week earnings
- Average earnings per day

#### Earnings History
- Transaction list (date, booking, vehicle, amount, status)
- Filter by date range
- Export option

#### Bank Account Linking
- Account holder name
- Account number (input & validation)
- IFSC code
- Bank name (dropdown)
- Account type (Savings/Current)
- **Verify Account** button
- Status indicator (Verified/Pending)
- Multiple account support (primary account indicator)

### 6. PROFILE SCREEN (Owner)
#### Profile Section
- Profile photo upload
- Full name
- Phone number (verified badge)
- Email
- Business name

#### Aadhar KYC Section
- KYC status indicator
- Aadhar details (auto-populated from API)
- Verify button
- Status: Pending / Verified / Rejected

#### Ratings & Reviews
- Average rating display
- Total reviews count
- Recent reviews list
- Review card shows: User name, rating, review text, date

#### Account Settings
- Notification preferences
- Language selection
- Logout button

---

## AUTHENTICATION & SECURITY IMPLEMENTATION

### JWT Token Implementation
```
Access Token (15 minutes):
  - user_id
  - account_type (OWNER/USER)
  - phone_number
  - kyc_status

Refresh Token (7 days):
  - user_id
  - token_version
```

### Aadhar KYC Integration
```
Flow:
1. User enters Aadhar number
2. Send to Aadhar KYC API
3. API returns: Name, DOB, Gender, Address
4. Auto-populate user profile
5. Mark as VERIFIED in database
6. Store encrypted Aadhar number
7. Use VERIFIED status across app
```

### Password Security
- Bcrypt hashing (Spring Security)
- Minimum 8 characters, 1 uppercase, 1 number, 1 special char

---

## PAYMENT INTEGRATION (BillDesk)

### BillDesk Setup
```
1. Create BillDesk merchant account
2. Get Merchant ID & API Key
3. Implement server-side payment verification

Server-side Payment Creation:
POST /api/bookings/{id}/payment
  - Generate unique transaction ID
  - Create payment order with BillDesk API
  - Return payment link to Flutter app

Flutter Payment Processing:
  - Show BillDesk payment UI
  - Handle success/failure callbacks
  - Verify payment status on backend
  - Update booking status

Payment Webhook (Server):
  - Listen for BillDesk payment status updates
  - Update booking payment_status
  - Trigger notifications via WebSocket
  - Create earnings record
```

---

## REAL-TIME FEATURES (WebSocket + Supabase)

### WebSocket Implementation (Spring Boot)
```
Dependencies:
- spring-boot-starter-websocket
- spring-boot-starter-web-socket
- sockjs-client (for fallback)
```

### Connection Flow
```
1. User logs in → Get JWT token
2. Connect WebSocket with token in headers
3. Subscribe to personal topics:
   - /topic/user/{userId}/notifications
   - /topic/user/{userId}/bookings
   - /topic/booking/{bookingId}/updates

4. Subscribe to location topic (during active booking):
   - /topic/booking/{bookingId}/user-location
```

### Heartbeat & Reconnection
- Ping-pong every 30 seconds
- Auto-reconnect with exponential backoff
- Queue messages during disconnection
- Sync on reconnection

### Supabase Integration (Optional)
```
Use for:
- Real-time parking space availability updates
- User presence tracking
- Chat functionality (future enhancement)

Setup:
1. Create Supabase project
2. Enable Real-time feature
3. Create tables for real-time sync
4. Use Supabase Flutter SDK for subscriptions
```

---

## FILE UPLOAD & STORAGE

### Parking Space Photos
```
Flow:
1. User selects photos from gallery (Flutter)
2. Compress images (max 2MB each)
3. Upload to backend with parking_space_id
4. Backend saves to cloud storage (AWS S3 / Firebase Storage)
5. Save URL in database
6. Return success with image URL

Accepted formats: JPG, PNG, WebP
Max file size: 2MB per image
Max images per parking space: 10
```

### Profile Photos
```
Same as above but:
- Max file size: 1MB
- Max 1 profile photo per user
- Auto-crop to 1:1 aspect ratio
```

---

## NAVIGATION & ROUTING (Flutter)

### User App Routes
```
/ → Splash Screen
/auth → Auth screens (Login/Register/OTP)
/dashboard → Dashboard with map
/parking-detail/:id → Parking space details
/booking → Booking flow (vehicle select → confirmation → payment)
/active-booking/:id → Active booking screen
/booking-history → Past bookings
/profile → User profile & KYC
/settings → App settings
```

### Owner App Routes
```
/ → Splash Screen
/auth → Auth screens
/dashboard → Dashboard with map & stats
/parking-spaces → List of parking spaces
/edit-parking/:id → Edit parking space
/bookings → Incoming requests & active bookings
/booking-detail/:id → Booking details
/earnings → Earnings & bank account
/profile → Owner profile & KYC
/settings → App settings
```

---

## ERROR HANDLING & VALIDATION

### Backend Validation
- Phone number format validation
- Aadhar number validation (12 digits)
- Amount validation (positive decimal)
- Time slot validation (check-out > check-in)
- Coordinate validation (valid latitude/longitude)

### Frontend Validation
- Form field validation before submission
- Show user-friendly error messages
- Toast notifications for errors
- Retry button for failed API calls
- Offline mode indicator

### Error Status Codes
```
200 → Success
400 → Bad request (validation error)
401 → Unauthorized (invalid JWT)
403 → Forbidden (permission denied)
404 → Not found
409 → Conflict (duplicate entry)
500 → Server error
```

---

## PUSH NOTIFICATIONS (Firebase Cloud Messaging)

### User App Notifications
- Booking request accepted/rejected
- User check-in reminder
- Check-out reminder (30 mins before)
- Payment status update
- Cancellation notifications

### Owner App Notifications
- New booking request
- Booking payment received
- User check-in notification
- Review posted

### Setup
```
1. Create Firebase project
2. Enable Cloud Messaging
3. Get FCM tokens for each user
4. Store tokens in user profile
5. Send via Firebase Admin SDK from Spring Boot
```

---

## TESTING CHECKLIST

### Backend Testing
- [ ] Authentication flow (register, login, token refresh)
- [ ] Aadhar KYC integration
- [ ] Parking space CRUD operations
- [ ] Booking workflow (create, accept, reject, check-out)
- [ ] Payment integration (BillDesk)
- [ ] WebSocket connections & events
- [ ] Real-time location tracking
- [ ] Earnings calculation
- [ ] Bank account verification
- [ ] Review & rating system

### Frontend Testing (User App)
- [ ] Map display & location accuracy
- [ ] Parking search & filters
- [ ] Booking flow end-to-end
- [ ] Payment gateway integration
- [ ] Active booking tracking
- [ ] Profile & vehicle management
- [ ] Aadhar KYC verification
- [ ] Notification display
- [ ] Offline handling

### Frontend Testing (Owner App)
- [ ] Dashboard map & stats
- [ ] Parking space management (CRUD)
- [ ] Photo upload & ordering
- [ ] Booking request handling
- [ ] Active booking monitoring
- [ ] Real-time location display
- [ ] Earnings calculation
- [ ] Bank account linking
- [ ] Profile & KYC

### Performance Testing
- [ ] API response time < 500ms
- [ ] Map rendering with 50+ markers
- [ ] WebSocket message latency < 100ms
- [ ] Image compression efficiency
- [ ] Battery usage during active tracking

---

## DEPLOYMENT CONSIDERATIONS

### Database Setup
```
PostgreSQL hosted on:
- AWS RDS
- DigitalOcean Managed Database
- Google Cloud SQL
- Self-hosted with backup strategy
```

### Backend Deployment
```
Spring Boot JAR deployment on:
- AWS EC2 + Elastic Load Balancer
- DigitalOcean App Platform
- Google Cloud Run
- Docker containerization recommended
```

### Frontend Distribution
```
iOS:
- TestFlight for beta testing
- App Store for production

Android:
- Google Play Console for beta testing
- Google Play Store for production
```

### Environment Configuration
```
.env variables:
- DATABASE_URL
- JWT_SECRET
- AADHAR_API_KEY
- BILLDESK_MERCHANT_ID
- BILLDESK_API_KEY
- FIREBASE_CONFIG
- MAP_API_KEY
- AWS_S3_CREDENTIALS
- SUPABASE_URL & KEY
```

---

## FUTURE ENHANCEMENTS

1. **In-app Chat**: Owner-User communication
2. **Subscription Plans**: Monthly/weekly parking plans
3. **Surge Pricing**: Dynamic pricing based on demand
4. **Wallet System**: In-app prepaid wallet
5. **Referral Program**: Refer & earn
6. **Insurance Integration**: Parking spot insurance
7. **Vehicle Damage Report**: Photo-based damage documentation
8. **Premium Listings**: Featured parking spaces
9. **Analytics Dashboard**: Owner insights & trends
10. **Multi-language Support**: Regional language support

---

## DEVELOPMENT TIMELINE (ESTIMATION)

| Phase | Tasks | Duration |
|-------|-------|----------|
| **Phase 1: Setup** | Project setup, DB design, API scaffolding | 1-2 weeks |
| **Phase 2: Core Backend** | Auth, Aadhar KYC, Parking CRUD, Booking logic | 3-4 weeks |
| **Phase 3: Payment & WebSocket** | BillDesk integration, WebSocket events | 2-3 weeks |
| **Phase 4: User App MVP** | Dashboard, booking flow, profile | 3-4 weeks |
| **Phase 5: Owner App MVP** | Dashboard, space management, earnings | 3-4 weeks |
| **Phase 6: Real-time Features** | Live tracking, notifications, Supabase | 2-3 weeks |
| **Phase 7: Testing & Bug Fixes** | QA, performance testing, optimization | 2-3 weeks |
| **Phase 8: Deployment** | App store release, backend deployment | 1-2 weeks |

**Total: 18-26 weeks (4-6 months)**

---

## CONTACT & SUPPORT STRUCTURE

### For Technical Implementation Issues
- Use spec as source of truth
- Document all API endpoint behaviors
- Maintain API documentation (Swagger/OpenAPI)
- Version control all code changes

### For Design Decisions
- Mobile-first approach for Flutter apps
- Dark mode support
- Accessibility compliance (WCAG 2.1)
- Performance optimization (lazy loading maps, image caching)

---

## SECURITY & COMPLIANCE

### Data Protection
- Encrypt sensitive fields (Aadhar, bank account)
- Use HTTPS for all API calls
- Implement rate limiting on endpoints
- Add CORS configuration for backend

### Privacy
- GDPR compliance for user data
- Option to delete user account & data
- Privacy policy & terms of service in app
- Data retention policy (30-90 days for logs)

### Fraud Prevention
- Implement CAPTCHA on registration
- Phone number verification via OTP
- Bank account verification before payout
- Monitor suspicious payment patterns
- Flag multiple rejected bookings

---

**This specification is comprehensive and production-ready. Adjust timelines and features based on team capacity and market requirements.**
