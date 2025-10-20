# System Architecture Overview

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER BROWSER                             │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  SvelteKit Frontend                      │   │
│  │  • Landing Page                                          │   │
│  │  • Sign Up (with password validation UI)                 │   │
│  │  • Sign In                                               │   │
│  │  • Dashboard (protected)                                 │   │
│  └────────────┬─────────────────────────────┬───────────────┘   │
└───────────────┼─────────────────────────────┼───────────────────┘
                │                             │
                │ HTTP/REST API               │ OpenID Connect
                │                             │ (PKCE Flow)
                ▼                             ▼
    ┌─────────────────────┐       ┌──────────────────────┐
    │   NestJS Backend    │       │      Keycloak        │
    │  (Port 3000)        │◄──────┤   (Port 8080)        │
    │                     │       │                      │
    │  • Auth endpoints   │       │  • Authentication    │
    │  • User management  │       │  • User storage      │
    │  • Location tracker │       │  • Token issuer      │
    │  • Geolocation API  │       │  • Password policy   │
    └──────────┬──────────┘       └──────────────────────┘
               │
               │ PostgreSQL Protocol
               │
               ▼
    ┌─────────────────────┐
    │     Supabase        │
    │   (PostgreSQL)      │
    │                     │
    │  Tables:            │
    │  • users            │
    │  • sign_in_attempts │
    │                     │
    │  Features:          │
    │  • Row Level Sec.   │
    │  • Real-time        │
    │  • REST API         │
    └─────────────────────┘
```

---

## 🔄 Authentication Flow

### Sign Up Flow

```
┌─────────┐                                                      
│ Browser │                                                      
└────┬────┘                                                      
     │                                                           
     │ 1. Fill signup form                                      
     │    (name, email, password)                               
     │                                                           
     ▼                                                           
┌─────────────────┐                                             
│  SvelteKit FE   │                                             
│                 │                                             
│  • Validate     │                                             
│    password     │                                             
│    (real-time)  │                                             
│  • Get user IP  │                                             
│    (automatic)  │                                             
└────┬────────────┘                                             
     │                                                           
     │ 2. POST /api/v1/auth/signup                              
     │    {name, email, password, ip}                           
     │                                                           
     ▼                                                           
┌─────────────────┐         3. Create user          ┌──────────┐
│  NestJS API     │────────────────────────────────►│ Keycloak │
│                 │                                  │          │
│  • Get location │◄─────────────────────────────────┤ Returns  │
│    from IP      │         4. User created          │ user ID  │
│  • Save to DB   │                                  └──────────┘
└────┬────────────┘                                             
     │                                                           
     │ 5. INSERT INTO users                                     
     │    INSERT INTO sign_in_attempts                          
     │                                                           
     ▼                                                           
┌─────────────────┐                                             
│    Supabase     │                                             
│   (Database)    │                                             
└─────────────────┘                                             
```

### Sign In Flow

```
┌─────────┐                                                      
│ Browser │                                                      
└────┬────┘                                                      
     │                                                           
     │ 1. Enter credentials                                     
     │                                                           
     ▼                                                           
┌─────────────────┐                                             
│  SvelteKit FE   │                                             
└────┬────────────┘                                             
     │                                                           
     │ 2. POST /api/v1/auth/signin                              
     │    {username, password}                                  
     │                                                           
     ▼                                                           
┌─────────────────┐      3. Validate       ┌──────────┐        
│  NestJS API     │────────────────────────►│ Keycloak │        
│                 │                         │          │        
│  • Get user IP  │◄────────────────────────┤ Returns  │        
│  • Get location │      4. Success/Fail    │ tokens   │        
│  • Log attempt  │                         └──────────┘        
└────┬────────────┘                                             
     │                                                           
     │ 5. INSERT sign_in_attempt                                
     │    (success/failure + location)                          
     │                                                           
     ▼                                                           
┌─────────────────┐                                             
│    Supabase     │                                             
└─────────────────┘                                             
     │                                                           
     │ 6. Return JWT tokens                                     
     │                                                           
     ▼                                                           
┌─────────────────┐                                             
│  Browser saves  │                                             
│  access_token   │                                             
└─────────────────┘                                             
```

### Dashboard View Flow

```
┌─────────┐                                                      
│ Browser │                                                      
└────┬────┘                                                      
     │                                                           
     │ 1. Navigate to /dashboard                                
     │    (with access_token)                                   
     │                                                           
     ▼                                                           
┌─────────────────┐                                             
│  SvelteKit FE   │                                             
│  (Protected)    │                                             
└────┬────────────┘                                             
     │                                                           
     │ 2. GET /api/v1/auth/signin-attempts                      
     │    Authorization: Bearer {token}                         
     │                                                           
     ▼                                                           
┌─────────────────┐     3. Verify token     ┌──────────┐       
│  NestJS API     │────────────────────────►│ Keycloak │       
│                 │                          │          │       
│  • Extract      │◄─────────────────────────┤ Token OK │       
│    user_id      │      4. Valid            └──────────┘       
└────┬────────────┘                                             
     │                                                           
     │ 5. SELECT sign_in_attempts                               
     │    WHERE user_id = ?                                     
     │                                                           
     ▼                                                           
┌─────────────────┐                                             
│    Supabase     │                                             
│  (RLS applies)  │                                             
└────┬────────────┘                                             
     │                                                           
     │ 6. Return attempts with location data                    
     │                                                           
     ▼                                                           
┌─────────────────┐                                             
│  Browser shows  │                                             
│  • Timestamp    │                                             
│  • IP Address   │                                             
│  • Country/City │                                             
│  • Status       │                                             
└─────────────────┘                                             
```

---

## 📊 Database Schema

```sql
┌─────────────────────────────┐
│          users              │
├─────────────────────────────┤
│ id (UUID, PK)               │
│ keycloak_id (VARCHAR)       │◄─── Links to Keycloak
│ name (VARCHAR)              │
│ email (VARCHAR, UNIQUE)     │
│ created_at (TIMESTAMP)      │
│ updated_at (TIMESTAMP)      │
└──────────┬──────────────────┘
           │
           │ 1:N relationship
           │
           ▼
┌─────────────────────────────┐
│    sign_in_attempts         │
├─────────────────────────────┤
│ id (UUID, PK)               │
│ user_id (UUID, FK)          │
│ email (VARCHAR)             │
│ ip_address (VARCHAR)        │
│ country (VARCHAR)           │◄─── From geolocation API
│ city (VARCHAR)              │◄─── From geolocation API
│ region (VARCHAR)            │
│ latitude (DECIMAL)          │
│ longitude (DECIMAL)         │
│ timezone (VARCHAR)          │
│ isp (VARCHAR)               │
│ user_agent (TEXT)           │
│ browser (VARCHAR)           │
│ device (VARCHAR)            │
│ os (VARCHAR)                │
│ success (BOOLEAN)           │◄─── Login success/failure
│ failure_reason (VARCHAR)    │
│ timestamp (TIMESTAMP)       │
└─────────────────────────────┘
```

---

## 🔐 Security Layers

```
┌────────────────────────────────────────────────────────┐
│ Layer 1: Password Policy (Keycloak)                    │
│  • Minimum 8 characters                                │
│  • 1 uppercase, 1 lowercase, 1 digit, 1 special char  │
└────────────────────────────────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────┐
│ Layer 2: JWT Authentication                            │
│  • Keycloak-issued tokens                              │
│  • Short-lived access tokens (15 min)                  │
│  • Refresh tokens (7 days)                             │
└────────────────────────────────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────┐
│ Layer 3: Row Level Security (Supabase)                 │
│  • Users can only see their own data                   │
│  • Service role for backend operations                 │
└────────────────────────────────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────┐
│ Layer 4: Rate Limiting (NestJS)                        │
│  • 5 auth attempts per 15 min                          │
│  • 100 general requests per minute                     │
└────────────────────────────────────────────────────────┘
```

---

## 🌍 Geolocation Data Flow

```
1. User attempts sign-in from IP: 203.0.113.45

2. NestJS extracts IP from request

3. Call geolocation API (ipapi.co):
   GET https://ipapi.co/203.0.113.45/json/

4. Response:
   {
     "ip": "203.0.113.45",
     "city": "New York",
     "region": "New York",
     "country": "US",
     "country_name": "United States",
     "latitude": 40.7128,
     "longitude": -74.0060,
     "timezone": "America/New_York",
     "org": "Example ISP"
   }

5. Save to sign_in_attempts table

6. Display on user dashboard
```

---

## 🔌 API Endpoints (To Be Built in Phase 2)

```
Backend API (http://localhost:3000/api/v1)

Authentication
├── POST   /auth/signup
│   ├── Body: { name, email, password }
│   ├── Returns: { user, message }
│   └── Creates user in Keycloak + Supabase
│
├── POST   /auth/signin
│   ├── Body: { username, password }
│   ├── Returns: { access_token, refresh_token, user }
│   └── Logs attempt with location
│
├── POST   /auth/refresh
│   ├── Body: { refresh_token }
│   └── Returns: { access_token }
│
├── POST   /auth/logout
│   └── Invalidates tokens
│
└── GET    /auth/signin-attempts
    ├── Headers: Authorization: Bearer {token}
    ├── Query: ?limit=50&offset=0
    └── Returns: Array of sign-in attempts

User Management
└── GET    /user/profile
    ├── Headers: Authorization: Bearer {token}
    └── Returns: User profile data
```

---

## 📁 Project Structure (After Phase 2 & 3)

```
location_project/
├── backend/                    # NestJS API
│   ├── src/
│   │   ├── auth/              # Authentication module
│   │   ├── user/              # User module
│   │   ├── geolocation/       # IP geolocation service
│   │   ├── database/          # Supabase integration
│   │   └── main.ts
│   ├── .env
│   └── package.json
│
├── frontend/                   # SvelteKit UI
│   ├── src/
│   │   ├── routes/
│   │   │   ├── +page.svelte           # Landing
│   │   │   ├── signup/                # Sign up
│   │   │   ├── signin/                # Sign in
│   │   │   └── dashboard/             # Dashboard
│   │   ├── lib/
│   │   │   ├── stores/                # Auth state
│   │   │   ├── components/            # UI components
│   │   │   └── services/              # API calls
│   │   └── app.html
│   ├── .env
│   └── package.json
│
├── database/
│   └── schema.sql
│
└── docs/
    ├── KEYCLOAK_SETUP.md
    ├── SUPABASE_SETUP.md
    └── API_DOCUMENTATION.md
```

---

## 🎯 Data Flow Summary

1. **User Registration**
   - Frontend validates password → Backend creates in Keycloak → Save to Supabase

2. **User Sign In**
   - Keycloak validates credentials → Backend logs attempt with location → Returns JWT

3. **Dashboard Access**
   - Frontend sends JWT → Backend validates with Keycloak → Query Supabase (RLS filters data)

4. **Location Tracking**
   - Every sign-in triggers IP lookup → Geolocation API → Store in database

---

This architecture provides:
- ✅ Secure authentication (Keycloak)
- ✅ Scalable storage (Supabase)
- ✅ Real-time validation (SvelteKit)
- ✅ Comprehensive logging (sign_in_attempts)
- ✅ Fine-grained access control (RLS)
