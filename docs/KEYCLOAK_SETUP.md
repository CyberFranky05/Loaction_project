# Keycloak Setup Guide

## Overview
Keycloak will handle authentication and authorization for our application. This guide covers local setup and configuration.

---

## Option 1: Local Docker Installation (Recommended for Development)

### Prerequisites
- Docker Desktop installed and running
- Available ports: 8080 (Keycloak)

### Step 1: Run Keycloak with Docker

```powershell
# Pull Keycloak image
docker pull quay.io/keycloak/keycloak:latest

# Run Keycloak container
docker run -d `
  --name location-auth-keycloak `
  -p 8080:8080 `
  -e KEYCLOAK_ADMIN=admin `
  -e KEYCLOAK_ADMIN_PASSWORD=admin `
  quay.io/keycloak/keycloak:latest `
  start-dev
```

### Step 2: Access Keycloak Admin Console

1. Wait 30-60 seconds for Keycloak to start
2. Open browser: `http://localhost:8080`
3. Click **"Administration Console"**
4. Login:
   - **Username**: `admin`
   - **Password**: `admin`

---

## Option 2: Standalone Installation

### Download and Install

1. Download from [Keycloak Downloads](https://www.keycloak.org/downloads)
2. Extract to a folder (e.g., `C:\keycloak`)
3. Open PowerShell in that folder
4. Run:
```powershell
# Set admin credentials
$env:KEYCLOAK_ADMIN='admin'
$env:KEYCLOAK_ADMIN_PASSWORD='admin'

# Start Keycloak
.\bin\kc.bat start-dev
```

5. Access at `http://localhost:8080`

---

## Keycloak Configuration

### Step 1: Create a New Realm

1. In Keycloak Admin Console, hover over **"master"** (top-left dropdown)
2. Click **"Create Realm"**
3. Fill in:
   - **Realm name**: `location-auth-realm`
   - **Enabled**: ON
4. Click **"Create"**

### Step 2: Configure Realm Settings

1. Go to **Realm Settings** (left sidebar)
2. Navigate to **"Login"** tab:
   - ✅ **User registration**: ON
   - ✅ **Forgot password**: ON
   - ✅ **Remember me**: ON
   - ✅ **Verify email**: OFF (for development)
   - ✅ **Login with email**: ON

3. Navigate to **"Email"** tab (optional for production):
   - Configure SMTP settings for email verification

4. Navigate to **"Tokens"** tab:
   - **Access Token Lifespan**: 5 minutes (default)
   - **Refresh Token Max Reuse**: 0
   - **SSO Session Idle**: 30 minutes
   - **SSO Session Max**: 10 hours

### Step 3: Configure Password Policies

1. Go to **Authentication** → **Policies** tab
2. Click **"Password Policy"**
3. Add these policies:
   - **Minimum Length**: 8
   - **Uppercase Characters**: 1
   - **Lowercase Characters**: 1
   - **Digits**: 1
   - **Special Characters**: 1
   - **Not Username**: ON
   - **Password History**: 3 (optional)
   - **Expire Password**: 90 days (optional)

4. Click **"Save"**

### Step 4: Create Backend Client (Confidential)

1. Go to **Clients** (left sidebar)
2. Click **"Create client"**
3. **General Settings**:
   - **Client type**: OpenID Connect
   - **Client ID**: `location-auth-backend`
   - Click **"Next"**

4. **Capability config**:
   - ✅ **Client authentication**: ON
   - ✅ **Authorization**: OFF
   - ✅ **Standard flow**: ON
   - ✅ **Direct access grants**: ON
   - ✅ **Service accounts roles**: ON
   - Click **"Next"**

5. **Login settings**:
   - Leave default for now
   - Click **"Save"**

6. Go to **"Credentials"** tab:
   - Copy **Client Secret** → Save as `KEYCLOAK_CLIENT_SECRET`

### Step 5: Create Frontend Client (Public)

1. Go to **Clients** → **"Create client"**
2. **General Settings**:
   - **Client type**: OpenID Connect
   - **Client ID**: `location-auth-frontend`
   - Click **"Next"**

3. **Capability config**:
   - ❌ **Client authentication**: OFF (public client)
   - ✅ **Authorization**: OFF
   - ✅ **Standard flow**: ON
   - ✅ **Direct access grants**: OFF (more secure)
   - Click **"Next"**

4. **Login settings**:
   - **Root URL**: `http://localhost:5173` (SvelteKit dev server)
   - **Home URL**: `http://localhost:5173`
   - **Valid redirect URIs**: 
     - `http://localhost:5173/*`
     - `http://localhost:5173/auth/callback`
   - **Valid post logout redirect URIs**: `http://localhost:5173/*`
   - **Web origins**: `http://localhost:5173`
   - Click **"Save"**

5. Go to **"Advanced"** tab:
   - **Proof Key for Code Exchange Code Challenge Method**: S256
   - Click **"Save"**

### Step 6: Configure User Attributes (Optional)

1. Go to **Realm Settings** → **"User Profile"** tab
2. Add custom attributes if needed:
   - Click **"Create attribute"**
   - Add fields like `country`, `registration_ip`, etc.

### Step 7: Create Client Scopes

1. Go to **Client Scopes** (left sidebar)
2. Default scopes are sufficient, but you can create custom ones:
   - Click **"Create client scope"**
   - **Name**: `user-profile`
   - **Type**: Optional
   - **Protocol**: openid-connect
   - Click **"Save"**

3. Add mappers:
   - Go to **"Mappers"** tab
   - Click **"Add mapper"** → **"By configuration"**
   - Select **"User Attribute"**
   - Configure mapper for custom claims

### Step 8: Create Test User

1. Go to **Users** (left sidebar)
2. Click **"Add user"**
3. Fill in:
   - **Username**: `testuser`
   - **Email**: `testuser@example.com`
   - **First name**: `Test`
   - **Last name**: `User`
   - ✅ **Email verified**: ON (for testing)
   - ✅ **Enabled**: ON
4. Click **"Create"**

5. Go to **"Credentials"** tab:
   - Click **"Set password"**
   - **Password**: `TestPass123!`
   - **Temporary**: OFF
   - Click **"Save"**

---

## Environment Variables Configuration

### Backend `.env`:
```env
# Keycloak Configuration
KEYCLOAK_URL=http://localhost:8080
KEYCLOAK_REALM=location-auth-realm
KEYCLOAK_CLIENT_ID=location-auth-backend
KEYCLOAK_CLIENT_SECRET=your-client-secret-from-step-4

# Alternative format (some libraries)
KEYCLOAK_AUTH_SERVER_URL=http://localhost:8080/auth
KEYCLOAK_BEARER_ONLY=true
```

### Frontend `.env`:
```env
# Keycloak Configuration
PUBLIC_KEYCLOAK_URL=http://localhost:8080
PUBLIC_KEYCLOAK_REALM=location-auth-realm
PUBLIC_KEYCLOAK_CLIENT_ID=location-auth-frontend
```

---

## Testing Keycloak Setup

### Test 1: Access Token Endpoint

```powershell
# Get access token using password grant
curl -X POST "http://localhost:8080/realms/location-auth-realm/protocol/openid-connect/token" `
  -H "Content-Type: application/x-www-form-urlencoded" `
  -d "client_id=location-auth-backend" `
  -d "client_secret=YOUR_CLIENT_SECRET" `
  -d "grant_type=password" `
  -d "username=testuser" `
  -d "password=TestPass123!"
```

Expected response:
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "Bearer",
  "expires_in": 300,
  "refresh_token": "eyJhbGc...",
  "scope": "openid profile email"
}
```

### Test 2: Validate Password Policy

Try to create a user with weak password:
1. Go to **Users** → **"Add user"**
2. Set password to `weak` 
3. Should see error: "Password policy not met"

---

## Keycloak Endpoints Reference

Replace `{realm}` with `location-auth-realm`:

| Endpoint | URL |
|----------|-----|
| **Token** | `http://localhost:8080/realms/{realm}/protocol/openid-connect/token` |
| **UserInfo** | `http://localhost:8080/realms/{realm}/protocol/openid-connect/userinfo` |
| **Logout** | `http://localhost:8080/realms/{realm}/protocol/openid-connect/logout` |
| **Authorization** | `http://localhost:8080/realms/{realm}/protocol/openid-connect/auth` |
| **Certs** | `http://localhost:8080/realms/{realm}/protocol/openid-connect/certs` |
| **Well-Known** | `http://localhost:8080/realms/{realm}/.well-known/openid-configuration` |

---

## Production Considerations

### For Production Deployment:

1. **Change Admin Password**:
   - Go to **Users** → Find **admin** → **Credentials**
   - Set strong password

2. **Enable HTTPS**:
   - Keycloak requires HTTPS in production
   - Use reverse proxy (nginx/Apache) or cloud service

3. **Database**:
   - Switch from H2 (dev) to PostgreSQL/MySQL
   - Configure in Keycloak settings

4. **Update Redirect URIs**:
   - Replace `localhost` with production domains
   - Add all valid redirect URIs

5. **Rate Limiting**:
   - Enable brute force detection
   - Go to **Realm Settings** → **Security Defenses**

6. **Email Configuration**:
   - Configure SMTP for email verification
   - Set up email templates

---

## Troubleshooting

### Issue: Keycloak not starting
**Solution**: Check if port 8080 is available
```powershell
netstat -ano | findstr :8080
```

### Issue: Cannot login to admin console
**Solution**: 
- Verify credentials (default: admin/admin)
- Restart Keycloak container
- Check Keycloak logs

### Issue: Invalid redirect URI
**Solution**: 
- Ensure frontend URL is added to Valid Redirect URIs
- Include wildcards: `http://localhost:5173/*`

### Issue: CORS errors
**Solution**: 
- Add frontend URL to Web Origins in client settings
- Use `*` for development (not recommended for production)

### Issue: Token expired
**Solution**: 
- Implement token refresh logic
- Adjust token lifespan in Realm Settings → Tokens

---

## Docker Commands Reference

```powershell
# Start Keycloak
docker start location-auth-keycloak

# Stop Keycloak
docker stop location-auth-keycloak

# View logs
docker logs location-auth-keycloak

# Remove container
docker rm location-auth-keycloak

# Restart with fresh data
docker stop location-auth-keycloak
docker rm location-auth-keycloak
# Then run the initial docker run command again
```

---

## Next Steps

✅ Keycloak is configured!

Now proceed to:
- Set up environment variables
- Build NestJS backend with Keycloak integration
- Create SvelteKit frontend with authentication flow

---

## Additional Resources

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Keycloak Admin REST API](https://www.keycloak.org/docs-api/latest/rest-api/)
- [OpenID Connect Specs](https://openid.net/connect/)
