# 🚀 Complete Testing Guide - Location Auth System

## ⚠️ IMPORTANT: Keep Terminals Open!

The backend and frontend servers MUST keep running in their terminals. **Do NOT close them or press Ctrl+C**.

---

## Step 1: Start All Services

### Terminal 1: Start Backend (Keep Open!)
```powershell
cd u:\web_projects\location_project\backend
npm run start:dev
```
✅ Wait for: `🚀 Application is running on: http://localhost:3000/api/v1`
✅ **LEAVE THIS TERMINAL OPEN**

### Terminal 2: Start Frontend (Keep Open!)
```powershell
cd u:\web_projects\location_project\frontend
npx vite dev
```
✅ Wait for: `➜  Local:   http://localhost:5173/`
✅ **LEAVE THIS TERMINAL OPEN**

### Terminal 3: Verify Keycloak is Running
```powershell
docker ps | findstr keycloak
```
If not running, start it:
```powershell
docker run -d -p 8080:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin123 quay.io/keycloak/keycloak:26.4.1 start-dev
```

---

## Step 2: Run Quick Test (Terminal 4)

Open a **NEW PowerShell window** and run:
```powershell
cd u:\web_projects\location_project
.\quick-test.ps1
```

This will:
- ✅ Check if all services are running
- ✅ Create a test user
- ✅ Sign in
- ✅ Fetch sign-in attempts
- ✅ Display location data

---

## Step 3: Manual Browser Testing

### Test 3.1: Landing Page
1. Open browser to: **http://localhost:5173**
2. ✅ Verify landing page loads
3. ✅ Click "Get Started"

### Test 3.2: Sign-Up Page
1. Fill in the form:
   - **Name**: John Doe
   - **Email**: john.doe@example.com
   - **Password**: Start typing...
2. ✅ Watch password indicators:
   - Type `test` → All RED ❌
   - Type `Test` → Uppercase turns GREEN ✅
   - Type `Test1` → Digit turns GREEN ✅  
   - Type `Test12` → Still need length + special
   - Type `Test123!` → ALL GREEN ✅✅✅✅✅
3. **Confirm Password**: Test123!
4. ✅ See green checkmark "Passwords match"
5. Click **Sign Up**
6. ✅ See success message
7. ✅ Auto-redirect to sign-in page

### Test 3.3: Sign-In Page
1. Enter credentials:
   - **Email**: john.doe@example.com
   - **Password**: Test123!
2. Click **Sign In**
3. ✅ Redirect to dashboard

### Test 3.4: Dashboard
1. ✅ See welcome message: "Welcome back, John Doe!"
2. ✅ See sign-in attempts table
3. ✅ Verify table shows:
   - **Status** column (✓ Success / ✗ Failed)
   - **Date & Time**
   - **IP Address** (127.0.0.1)
   - **Location** (may show Unknown for localhost)
   - **Browser** (Chrome/Edge/Firefox)
   - **Device** (Desktop)
   - **OS** (Windows)
4. ✅ Should see 2 attempts:
   - Sign-up attempt
   - Sign-in attempt
5. Click **Refresh** button
6. ✅ Table reloads
7. Click **Logout**
8. ✅ Redirected to sign-in page

### Test 3.5: Protected Route
1. Open **new incognito/private window**
2. Go to: **http://localhost:5173/dashboard**
3. ✅ Should auto-redirect to **/signin**

### Test 3.6: Failed Login
1. On sign-in page, enter:
   - Email: john.doe@example.com
   - Password: **WrongPassword123!**
2. Click Sign In
3. ✅ See error: "Invalid email or password"
4. Sign in with correct password
5. Go to dashboard
6. ✅ See failed attempt in table (RED ✗ status)

---

## Step 4: API Testing (Terminal 4)

Use the **same PowerShell window** from Step 2.

### Test 4.1: Health Check
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/health"
```
✅ Expected: `{ status: "ok", timestamp: "..." }`

### Test 4.2: Create User
```powershell
$email = "api.test@example.com"
$body = @{
    name = "API Test User"
    email = $email
    password = "TestPass123!"
} | ConvertTo-Json

$signup = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signup" -Method POST -Body $body -ContentType "application/json"
$signup | ConvertTo-Json -Depth 3

# Save tokens
$accessToken = $signup.accessToken
$refreshToken = $signup.refreshToken
```
✅ Expected: User object with tokens

### Test 4.3: Get Profile
```powershell
$headers = @{ "Authorization" = "Bearer $accessToken" }
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/profile" -Headers $headers | ConvertTo-Json
```
✅ Expected: User profile data

### Test 4.4: Get Sign-In Attempts
```powershell
$headers = @{ "Authorization" = "Bearer $accessToken" }
$attempts = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signin-attempts" -Headers $headers
$attempts | ConvertTo-Json -Depth 3
```
✅ Expected: Array of attempts with location data

### Test 4.5: Sign In
```powershell
$body = @{
    email = $email
    password = "TestPass123!"
} | ConvertTo-Json

$signin = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signin" -Method POST -Body $body -ContentType "application/json"
$signin | ConvertTo-Json
```
✅ Expected: New tokens

### Test 4.6: Refresh Token
```powershell
$body = @{ refreshToken = $refreshToken } | ConvertTo-Json
$refresh = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/refresh" -Method POST -Body $body -ContentType "application/json"
$refresh | ConvertTo-Json
```
✅ Expected: New access token

### Test 4.7: Logout
```powershell
$headers = @{ "Authorization" = "Bearer $accessToken" }
$body = @{ refreshToken = $refreshToken } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/logout" -Method POST -Headers $headers -Body $body -ContentType "application/json"
```
✅ Expected: Success message

---

## Test Results Checklist

### ✅ Backend API (7 tests)
- [ ] Health check responds
- [ ] Sign-up creates user
- [ ] Sign-in authenticates user
- [ ] Get profile returns user data
- [ ] Get signin-attempts returns array
- [ ] Refresh token generates new token
- [ ] Logout invalidates session

### ✅ Frontend UI (6 tests)
- [ ] Landing page loads
- [ ] Sign-up form with password validation
- [ ] Password indicators turn green
- [ ] Sign-in page works
- [ ] Dashboard displays attempts table
- [ ] Protected routes redirect

### ✅ Integration (5 tests)
- [ ] Complete signup → signin → dashboard flow
- [ ] Geolocation data appears in table
- [ ] Failed login creates failed attempt
- [ ] Logout works
- [ ] Token auto-refresh works

### ✅ Security (3 tests)
- [ ] Invalid credentials rejected
- [ ] Protected routes require auth
- [ ] Password requirements enforced

---

## Common Issues & Solutions

### ❌ "Unable to connect to remote server"
**Problem**: Backend not running  
**Solution**: Check Terminal 1 - backend should show `🚀 Application is running`

### ❌ Frontend shows blank page
**Problem**: Frontend not running  
**Solution**: Check Terminal 2 - should show `➜  Local:   http://localhost:5173/`

### ❌ "User already exists"
**Problem**: Email already used  
**Solution**: Use a different email or add timestamp: `test$(Get-Date -Format 'HHmmss')@example.com`

### ❌ Location shows "Unknown"
**Problem**: Localhost IP not geolocated  
**Solution**: This is normal for 127.0.0.1. Browser/Device/OS should still show.

---

## Success Criteria

🎉 **All tests pass if:**
1. Backend responds to all 7 API endpoints
2. Frontend loads all 4 pages correctly
3. Password validation shows real-time green/red indicators
4. Sign-in attempts table shows IP, location, browser, device, OS
5. Protected routes redirect unauthenticated users
6. Tokens work and refresh automatically
7. Logout clears session

---

## Next Steps After Testing

1. **Review test results**
2. **Fix any failing tests**
3. **Add unit tests** (optional - see `MANUAL_TESTING_GUIDE.md`)
4. **Deploy to production** (optional - see deployment guides)

---

## 📝 Notes

- **Terminals 1 & 2 MUST stay open** while testing
- Use **Terminal 4** for PowerShell tests
- Use **browser** for UI tests
- **Incognito mode** for testing protected routes
- **Different emails** for each test user

**Happy Testing! 🚀**
