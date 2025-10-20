# Location-Based Authentication System

A full-stack authentication system that tracks user sign-in attempts with geolocation data, using Keycloak for authentication, Supabase as the database, SvelteKit for the frontend, and NestJS for the backend.

## 🏗️ Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | SvelteKit | UI framework with SSR support |
| **Backend** | NestJS | Scalable Node.js API server |
| **Database** | Supabase (PostgreSQL) | Data persistence with RLS |
| **Auth Provider** | Keycloak | Identity & Access Management |
| **Geolocation** | IPApi.co | IP to location conversion |

## 📋 Features

- ✅ User registration with real-time password policy validation
- ✅ Secure authentication via Keycloak (OpenID Connect)
- ✅ Automatic IP detection and geolocation tracking
- ✅ Comprehensive sign-in attempt logging
- ✅ Protected dashboard with detailed sign-in history
- ✅ Row-level security in Supabase
- ✅ Password policy enforcement with visual feedback

## 🚀 Phase 1: Infrastructure Setup (CURRENT)

### What's Included in Phase 1

This phase sets up the foundational infrastructure:

1. **Supabase Database** - Database schema, tables, and security policies
2. **Keycloak Configuration** - Authentication server setup and client configuration
3. **Environment Templates** - Configuration files for both frontend and backend

### Prerequisites

Before starting, ensure you have:

- [ ] Node.js (v18 or higher)
- [ ] Docker Desktop (for Keycloak)
- [ ] Git
- [ ] A Supabase account (free tier works)
- [ ] PowerShell or terminal access

---

## 📖 Setup Instructions

### Step 1: Supabase Setup

Follow the detailed guide: [`docs/SUPABASE_SETUP.md`](docs/SUPABASE_SETUP.md)

**Quick Steps:**
1. Create a new Supabase project
2. Execute the SQL schema from `database/schema.sql`
3. Copy your API credentials (URL, anon key, service role key)
4. Verify tables and RLS policies

**Time Required:** ~10 minutes

---

### Step 2: Keycloak Setup

Follow the detailed guide: [`docs/KEYCLOAK_SETUP.md`](docs/KEYCLOAK_SETUP.md)

**Quick Steps:**

#### Docker Installation (Recommended)
```powershell
# Pull and run Keycloak
docker pull quay.io/keycloak/keycloak:latest

docker run -d `
  --name location-auth-keycloak `
  -p 8080:8080 `
  -e KEYCLOAK_ADMIN=admin `
  -e KEYCLOAK_ADMIN_PASSWORD=admin `
  quay.io/keycloak/keycloak:latest `
  start-dev
```

#### Configuration
1. Access Keycloak at `http://localhost:8080`
2. Login with `admin` / `admin`
3. Create realm: `location-auth-realm`
4. Create backend client: `location-auth-backend` (confidential)
5. Create frontend client: `location-auth-frontend` (public)
6. Configure password policies (min 8 chars, uppercase, lowercase, number, special char)
7. Create a test user

**Time Required:** ~15-20 minutes

---

### Step 3: Environment Configuration

#### Backend Configuration

1. Navigate to `backend/` folder
2. Copy `.env.example` to `.env`:
   ```powershell
   Copy-Item backend\.env.example backend\.env
   ```
3. Edit `backend/.env` and fill in:
   - `SUPABASE_URL` - From Supabase project settings
   - `SUPABASE_SERVICE_ROLE_KEY` - From Supabase API settings
   - `KEYCLOAK_CLIENT_SECRET` - From Keycloak backend client credentials

#### Frontend Configuration

1. Navigate to `frontend/` folder
2. Copy `.env.example` to `.env`:
   ```powershell
   Copy-Item frontend\.env.example frontend\.env
   ```
3. Edit `frontend/.env` and fill in:
   - `PUBLIC_SUPABASE_URL` - From Supabase project settings
   - `PUBLIC_SUPABASE_ANON_KEY` - From Supabase API settings (anon/public key)

**Time Required:** ~5 minutes

---

## 🔍 Verification Checklist

Before proceeding to Phase 2, verify:

### Supabase
- [ ] Project created and accessible
- [ ] Schema executed successfully
- [ ] Tables visible: `users`, `sign_in_attempts`
- [ ] RLS policies configured
- [ ] API keys copied to `.env` files

### Keycloak
- [ ] Docker container running (`docker ps`)
- [ ] Admin console accessible at `http://localhost:8080`
- [ ] Realm created: `location-auth-realm`
- [ ] Backend client created with secret
- [ ] Frontend client created (public)
- [ ] Password policies configured
- [ ] Test user created
- [ ] Client credentials copied to `.env` files

### Environment Files
- [ ] `backend/.env` exists with all values filled
- [ ] `frontend/.env` exists with all values filled
- [ ] No placeholder values remaining (`xxxxx`, `your-key-here`)

---

## 🧪 Testing Phase 1 Setup

### Test Supabase Connection

Run this in Supabase SQL Editor:
```sql
-- Insert test data
INSERT INTO users (keycloak_id, name, email) 
VALUES ('test-123', 'Test User', 'test@example.com');

-- Verify
SELECT * FROM users WHERE email = 'test@example.com';

-- Clean up
DELETE FROM users WHERE email = 'test@example.com';
```

### Test Keycloak

Get an access token:
```powershell
curl -X POST "http://localhost:8080/realms/location-auth-realm/protocol/openid-connect/token" `
  -H "Content-Type: application/x-www-form-urlencoded" `
  -d "client_id=location-auth-backend" `
  -d "client_secret=YOUR_CLIENT_SECRET" `
  -d "grant_type=password" `
  -d "username=testuser" `
  -d "password=TestPass123!"
```

Expected: JSON response with `access_token` field

---

## 📁 Project Structure (After Phase 1)

```
location_project/
├── database/
│   └── schema.sql                 # Supabase database schema
├── docs/
│   ├── KEYCLOAK_SETUP.md         # Keycloak setup guide
│   └── SUPABASE_SETUP.md         # Supabase setup guide
├── backend/
│   └── .env.example              # Backend environment template
├── frontend/
│   └── .env.example              # Frontend environment template
└── README.md                     # This file
```

---

## 🐛 Troubleshooting

### Keycloak Not Starting
```powershell
# Check if port 8080 is in use
netstat -ano | findstr :8080

# Restart container
docker restart location-auth-keycloak

# View logs
docker logs location-auth-keycloak
```

### Supabase Connection Issues
- Verify your IP isn't blocked (check Supabase dashboard)
- Ensure you're using the correct API keys (service role for backend, anon for frontend)
- Check RLS policies aren't blocking your queries

### Environment Variables Not Loading
- Ensure `.env` files are in the correct directories
- Check for syntax errors (no spaces around `=`)
- Restart your development servers after changing `.env`

---

## 🎯 Next Steps

Once Phase 1 is complete, you can proceed to:

### Phase 2: Backend Development (NestJS)
- Initialize NestJS project
- Integrate Keycloak authentication
- Connect to Supabase
- Implement API endpoints:
  - `/auth/signup` - User registration
  - `/auth/signin` - User authentication
  - `/auth/signin-attempts` - Fetch sign-in history
- Add geolocation service

### Phase 3: Frontend Development (SvelteKit)
- Initialize SvelteKit project
- Create authentication flow
- Build UI components:
  - Landing page
  - Sign-up form with password validation
  - Sign-in form
  - Dashboard with sign-in history

---

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [NestJS Documentation](https://docs.nestjs.com/)
- [SvelteKit Documentation](https://kit.svelte.dev/docs)
- [OpenID Connect Specification](https://openid.net/connect/)

---

## 📝 Notes

- All services run locally during development
- Default ports: Backend (3000), Frontend (5173), Keycloak (8080)
- Never commit `.env` files to version control
- Use strong passwords in production
- Enable HTTPS for production deployments

---

## ✅ Phase 1 Complete!

If you've followed all the steps and passed the verification checklist, you're ready to move on to Phase 2! 🎉

---

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review the detailed setup guides in `docs/`
3. Verify all environment variables are correct
4. Check service logs (Docker logs for Keycloak, Supabase logs in dashboard)

---

**Last Updated:** October 20, 2025  
**Phase:** 1 - Infrastructure Setup  
**Status:** ✅ Complete
