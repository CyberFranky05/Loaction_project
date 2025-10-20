# Phase 1 Setup Checklist

Use this checklist to track your progress through the setup.

## ✅ Keycloak Setup (COMPLETED)

- [x] Docker container running
- [x] Accessible at http://localhost:8080
- [ ] Logged into admin console (admin/admin)
- [ ] Realm created: location-auth-realm
- [ ] Password policies configured
- [ ] Backend client created: location-auth-backend
- [ ] Backend client secret obtained
- [ ] Frontend client created: location-auth-frontend
- [ ] Test user created (testuser / TestPass123!)

---

## 📦 Supabase Setup (PENDING)

### Account & Project
- [ ] Supabase account created
- [ ] New project created
- [ ] Project name: location-auth-system

### Database Schema
- [ ] Opened SQL Editor
- [ ] Copied contents of `database/schema.sql`
- [ ] Executed schema successfully
- [ ] Verified tables exist:
  - [ ] users table
  - [ ] sign_in_attempts table

### API Credentials
- [ ] Opened Settings → API
- [ ] Copied Project URL
- [ ] Copied Anon (Public) Key
- [ ] Copied Service Role Key

---

## 🔧 Keycloak Configuration Steps

### 1. Create Realm
**Path:** Master dropdown (top-left) → Create Realm

```
Realm name: location-auth-realm
Enabled: ON
```

### 2. Configure Password Policies
**Path:** Authentication → Policies tab → Password Policy

Add these policies:
- Minimum Length: 8
- Uppercase Characters: 1
- Lowercase Characters: 1
- Digits: 1
- Special Characters: 1
- Not Username: ON

### 3. Create Backend Client (Confidential)
**Path:** Clients → Create client

**General Settings:**
- Client type: OpenID Connect
- Client ID: `location-auth-backend`

**Capability config:**
- ✅ Client authentication: ON
- ✅ Standard flow: ON
- ✅ Direct access grants: ON
- ✅ Service accounts roles: ON

**After creation:**
- Go to Credentials tab
- Copy Client Secret → Save for later

### 4. Create Frontend Client (Public)
**Path:** Clients → Create client

**General Settings:**
- Client type: OpenID Connect
- Client ID: `location-auth-frontend`

**Capability config:**
- ❌ Client authentication: OFF
- ✅ Standard flow: ON

**Login settings:**
- Root URL: `http://localhost:5173`
- Valid redirect URIs: `http://localhost:5173/*`
- Web origins: `http://localhost:5173`

**Advanced settings:**
- Proof Key for Code Exchange: S256

### 5. Create Test User
**Path:** Users → Add user

```
Username: testuser
Email: testuser@example.com
First name: Test
Last name: User
Email verified: ON
Enabled: ON
```

**Set Password:**
- Go to Credentials tab
- Password: `TestPass123!`
- Temporary: OFF

---

## 📝 Credentials to Collect

### Supabase
```
SUPABASE_URL=_________________________________
SUPABASE_ANON_KEY=____________________________
SUPABASE_SERVICE_ROLE_KEY=___________________
```

### Keycloak
```
KEYCLOAK_URL=http://localhost:8080
KEYCLOAK_REALM=location-auth-realm
KEYCLOAK_BACKEND_CLIENT_SECRET=______________
```

---

## 🧪 Verification Tests

### Test 1: Keycloak is Running
```powershell
curl http://localhost:8080/realms/location-auth-realm/.well-known/openid-configuration
```
Expected: JSON response with realm configuration

### Test 2: Supabase Tables Exist
In Supabase SQL Editor:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```
Expected: `users` and `sign_in_attempts` tables

### Test 3: Get Access Token from Keycloak
```powershell
curl -X POST "http://localhost:8080/realms/location-auth-realm/protocol/openid-connect/token" `
  -H "Content-Type: application/x-www-form-urlencoded" `
  -d "client_id=location-auth-backend" `
  -d "client_secret=YOUR_CLIENT_SECRET" `
  -d "grant_type=password" `
  -d "username=testuser" `
  -d "password=TestPass123!"
```
Expected: JSON with `access_token` field

---

## 📂 Files to Create

After collecting credentials, create these files:

### backend/.env
```env
SUPABASE_URL=[your-url]
SUPABASE_SERVICE_ROLE_KEY=[your-key]
KEYCLOAK_URL=http://localhost:8080
KEYCLOAK_REALM=location-auth-realm
KEYCLOAK_CLIENT_ID=location-auth-backend
KEYCLOAK_CLIENT_SECRET=[your-secret]
```

### frontend/.env
```env
PUBLIC_SUPABASE_URL=[your-url]
PUBLIC_SUPABASE_ANON_KEY=[your-key]
PUBLIC_KEYCLOAK_URL=http://localhost:8080
PUBLIC_KEYCLOAK_REALM=location-auth-realm
PUBLIC_KEYCLOAK_CLIENT_ID=location-auth-frontend
PUBLIC_API_URL=http://localhost:3000/api/v1
```

---

## ✅ Final Checklist

- [ ] Keycloak container running
- [ ] Keycloak realm and clients configured
- [ ] Test user created in Keycloak
- [ ] Supabase project created
- [ ] Database schema executed
- [ ] backend/.env created with actual values
- [ ] frontend/.env created with actual values
- [ ] All verification tests passed

---

## 🚀 Ready for Phase 2?

Once all items are checked, you're ready to proceed with:
- **Phase 2:** Backend Development (NestJS)
- **Phase 3:** Frontend Development (SvelteKit)

---

## 💡 Quick Commands

### Keycloak Management
```powershell
# Check if running
docker ps | findstr keycloak

# View logs
docker logs location-auth-keycloak

# Restart
docker restart location-auth-keycloak

# Stop
docker stop location-auth-keycloak

# Remove and recreate (fresh start)
docker stop location-auth-keycloak
docker rm location-auth-keycloak
docker run -d --name location-auth-keycloak -p 8080:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin quay.io/keycloak/keycloak:latest start-dev
```

### Access Points
- **Keycloak Admin:** http://localhost:8080
- **Supabase Dashboard:** https://app.supabase.com
- **Keycloak Realm URL:** http://localhost:8080/realms/location-auth-realm

---

**Last Updated:** October 20, 2025
