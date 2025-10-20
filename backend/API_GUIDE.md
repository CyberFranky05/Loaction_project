# Backend API - Location Auth System

NestJS backend with Keycloak authentication, Supabase database, and geolocation tracking.

## 🚀 Quick Start

```powershell
# Start the development server
cd backend
npm run start:dev
```

Server runs on: **http://localhost:3000/api/v1**

## 📋 API Endpoints

### Public
- `GET /api/v1/health` - Health check
- `POST /api/v1/auth/signup` - Register new user
- `POST /api/v1/auth/signin` - Login
- `POST /api/v1/auth/refresh` - Refresh token
- `POST /api/v1/auth/logout` - Logout

### Protected (Require Bearer Token)
- `GET /api/v1/auth/profile` - Get user profile
- `GET /api/v1/auth/signin-attempts` - Get login history

## 🧪 Testing

Run the comprehensive test script:
```powershell
.\test-backend.ps1
```

For detailed API documentation, see the full README in the backend folder.

## ✅ Status

All endpoints are implemented and working with:
- ✅ Keycloak authentication
- ✅ Supabase database integration
- ✅ IP geolocation tracking
- ✅ Sign-in attempt logging
