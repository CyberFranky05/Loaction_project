# Quick Start Guide - Phase 1

This is a condensed version of the setup process. For detailed instructions, see the main README.md and docs folder.

## 🚀 Quick Setup (30 minutes)

### 1. Supabase Setup (10 min)

1. Go to https://app.supabase.com/
2. Create new project → Save credentials
3. SQL Editor → Run `database/schema.sql`
4. Settings → API → Copy URL and keys
5. Save to `backend/.env` and `frontend/.env`

### 2. Keycloak Setup (15 min)

```powershell
# Run Keycloak
docker run -d --name location-auth-keycloak -p 8080:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin quay.io/keycloak/keycloak:latest start-dev
```

1. Open http://localhost:8080
2. Login: admin/admin
3. Create realm: `location-auth-realm`
4. Create clients:
   - Backend: `location-auth-backend` (confidential) → Save secret
   - Frontend: `location-auth-frontend` (public)
5. Authentication → Policies → Password Policy:
   - Min 8 chars, 1 uppercase, 1 lowercase, 1 digit, 1 special char
6. Create test user: testuser / TestPass123!

### 3. Environment Setup (5 min)

```powershell
# Backend
Copy-Item backend\.env.example backend\.env
# Edit backend/.env with your credentials

# Frontend
Copy-Item frontend\.env.example frontend\.env
# Edit frontend/.env with your credentials
```

### 4. Verify

✅ Supabase: Tables exist (users, sign_in_attempts)
✅ Keycloak: Running at http://localhost:8080
✅ Environment: All `.env` files configured

## 🎯 You're Ready!

Phase 1 complete! Proceed to Phase 2 for backend development.

## 📚 Need Help?

- Detailed guides in `docs/` folder
- Full README.md for comprehensive instructions
- Check troubleshooting sections
