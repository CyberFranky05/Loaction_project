# Manual Testing Guide - Step by Step

## Prerequisites Check

### 1. Check Backend Status
Open PowerShell and run:
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/health"
```
**Expected**: `{ "status": "ok", "timestamp": "..." }`

### 2. Check Frontend Status
Open browser to: `http://localhost:5173`
**Expected**: Landing page with "Welcome to Location Auth System"

### 3. Check Keycloak Status
Open browser to: `http://localhost:8080`
**Expected**: Keycloak welcome page

---

## Test 1: Backend API Endpoints

### Test 1.1: Health Check
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/health" -Method GET
```
✅ **Expected**: Status OK

### Test 1.2: Sign Up (Create New User)
```powershell
$body = @{
    name = "Test User"
    email = "test$(Get-Date -Format 'HHmmss')@example.com"
    password = "TestPass123!"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signup" -Method POST -Body $body -ContentType "application/json"
$response | ConvertTo-Json -Depth 3

# Save tokens for later tests
$accessToken = $response.accessToken
$refreshToken = $response.refreshToken
```
✅ **Expected**: User object with access & refresh tokens

### Test 1.3: Sign In
```powershell
$body = @{
    email = "testuser@example.com"  # Use an existing user email
    password = "TestPass123!"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signin" -Method POST -Body $body -ContentType "application/json"
$response | ConvertTo-Json -Depth 3

$accessToken = $response.accessToken
$refreshToken = $response.refreshToken
```
✅ **Expected**: Access token, refresh token, user data

### Test 1.4: Get Profile (Protected Route)
```powershell
$headers = @{
    "Authorization" = "Bearer $accessToken"
}

Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/profile" -Method GET -Headers $headers | ConvertTo-Json
```
✅ **Expected**: User profile data

### Test 1.5: Get Sign-In Attempts
```powershell
$headers = @{
    "Authorization" = "Bearer $accessToken"
}

Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signin-attempts" -Method GET -Headers $headers | ConvertTo-Json -Depth 3
```
✅ **Expected**: Array of sign-in attempts with IP, location, browser, device info

### Test 1.6: Refresh Token
```powershell
$body = @{
    refreshToken = $refreshToken
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/refresh" -Method POST -Body $body -ContentType "application/json"
$response | ConvertTo-Json

$accessToken = $response.accessToken
```
✅ **Expected**: New access token

### Test 1.7: Logout
```powershell
$headers = @{
    "Authorization" = "Bearer $accessToken"
}

$body = @{
    refreshToken = $refreshToken
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/logout" -Method POST -Headers $headers -Body $body -ContentType "application/json"
```
✅ **Expected**: Success message

### Test 1.8: Invalid Credentials (Should Fail)
```powershell
$body = @{
    email = "test@example.com"
    password = "WrongPassword"
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signin" -Method POST -Body $body -ContentType "application/json"
} catch {
    Write-Host "Expected Error: $($_.Exception.Message)" -ForegroundColor Green
}
```
✅ **Expected**: 401 Unauthorized error

---

## Test 2: Frontend UI Testing

### Test 2.1: Landing Page
1. Open `http://localhost:5173`
2. ✅ Verify hero section displays
3. ✅ Verify three feature cards show
4. ✅ Click "Get Started" button → should go to `/signup`
5. ✅ Click "Sign In" button → should go to `/signin`

### Test 2.2: Sign-Up Page
1. Navigate to `http://localhost:5173/signup`
2. ✅ Enter Name: "John Doe"
3. ✅ Enter Email: "john.doe@example.com"
4. ✅ Enter Password: "test" → All indicators should be RED
5. ✅ Complete Password: "TestPass123!" → All indicators turn GREEN
6. ✅ Enter Confirm Password: "TestPass123!" → Shows green checkmark
7. ✅ Click "Sign Up"
8. ✅ Verify success message appears
9. ✅ Verify redirect to `/signin` after 2 seconds

### Test 2.3: Sign-In Page
1. Navigate to `http://localhost:5173/signin`
2. ✅ Enter Email: "john.doe@example.com"
3. ✅ Enter Password: "TestPass123!"
4. ✅ Click "Sign In"
5. ✅ Verify redirect to `/dashboard`

### Test 2.4: Dashboard Page
1. Should be on `http://localhost:5173/dashboard`
2. ✅ Verify welcome message shows user name
3. ✅ Verify sign-in attempts table displays
4. ✅ Verify table shows columns: Status, Date & Time, IP, Location, Browser, Device, OS
5. ✅ Verify at least 2 attempts (signup + signin)
6. ✅ Click "Refresh" button → table refreshes
7. ✅ Click "Logout" button → redirects to `/signin`

### Test 2.5: Protected Route
1. Open new incognito/private window
2. Navigate to `http://localhost:5173/dashboard`
3. ✅ Verify automatic redirect to `/signin`

### Test 2.6: Failed Login
1. On sign-in page, enter wrong password
2. ✅ Verify error message appears: "Invalid email or password"
3. Sign in with correct credentials
4. Go to dashboard
5. ✅ Verify failed attempt shows in table with RED status

---

## Test 3: Integration Flow

### Complete User Journey
1. ✅ Open `http://localhost:5173`
2. ✅ Click "Get Started"
3. ✅ Fill signup form with:
   - Name: "Jane Smith"
   - Email: "jane.smith$(Get-Date -Format 'mmss')@example.com"
   - Password: "SecurePass123!"
   - Confirm Password: "SecurePass123!"
4. ✅ Watch password indicators turn green
5. ✅ Submit form
6. ✅ Wait for redirect to signin
7. ✅ Enter same credentials
8. ✅ Submit signin form
9. ✅ Verify dashboard loads
10. ✅ Verify sign-in attempts table shows:
    - Sign-up attempt (IP, location, browser, device)
    - Sign-in attempt (IP, location, browser, device)
11. ✅ Click refresh
12. ✅ Verify data reloads
13. ✅ Click logout
14. ✅ Verify redirect to signin
15. ✅ Try accessing `/dashboard` directly
16. ✅ Verify redirect to signin

---

## Test 4: Password Validation

### Real-Time Validation Test
1. Navigate to `/signup`
2. Type password character by character and observe indicators:

| Password | Length | Uppercase | Lowercase | Digit | Special |
|----------|--------|-----------|-----------|-------|---------|
| t        | ❌     | ❌        | ✅        | ❌    | ❌      |
| te       | ❌     | ❌        | ✅        | ❌    | ❌      |
| tes      | ❌     | ❌        | ✅        | ❌    | ❌      |
| test     | ❌     | ❌        | ✅        | ❌    | ❌      |
| Test     | ❌     | ✅        | ✅        | ❌    | ❌      |
| Test1    | ❌     | ✅        | ✅        | ✅    | ❌      |
| Test12   | ❌     | ✅        | ✅        | ✅    | ❌      |
| Test123  | ❌     | ✅        | ✅        | ✅    | ❌      |
| Test123! | ✅     | ✅        | ✅        | ✅    | ✅      |

✅ All indicators should be GREEN with "Test123!"

---

## Test 5: Geolocation Tracking

### Verify Location Data
1. Sign in successfully
2. Go to dashboard
3. Check latest sign-in attempt
4. ✅ Verify IP address is shown (e.g., "127.0.0.1" for localhost)
5. ✅ Verify location shows (may be "Unknown" for localhost)
6. ✅ Verify browser name (e.g., "Chrome", "Firefox", "Edge")
7. ✅ Verify device type (e.g., "Desktop", "Mobile")
8. ✅ Verify OS (e.g., "Windows", "macOS", "Linux")

---

## Test 6: Token Management

### Test Auto-Refresh
1. Sign in and get access token
2. Wait for token to near expiration (or force expiration)
3. Make an API call
4. ✅ Verify auto-refresh interceptor triggers
5. ✅ Verify new token is obtained
6. ✅ Verify original request succeeds

### Test Expired Token
1. Manually clear localStorage
2. Try to access `/dashboard`
3. ✅ Verify redirect to `/signin`

---

## Test Checklist Summary

### Backend Tests (8)
- [x] Health check
- [x] Sign up
- [x] Sign in
- [x] Get profile
- [x] Get sign-in attempts
- [x] Refresh token
- [x] Logout
- [x] Invalid credentials

### Frontend Tests (6)
- [x] Landing page UI
- [x] Sign-up page with password validation
- [x] Sign-in page
- [x] Dashboard with attempts table
- [x] Protected route redirect
- [x] Failed login handling

### Integration Tests (1)
- [x] Complete user journey (signup → signin → dashboard → logout)

### Data Validation (3)
- [x] Password validation rules
- [x] Geolocation tracking
- [x] Token management

---

## Expected Results Summary

✅ **All backend endpoints respond correctly**
✅ **Frontend pages load and function properly**
✅ **Password validation works in real-time**
✅ **Sign-in attempts are logged with location data**
✅ **Protected routes redirect unauthenticated users**
✅ **Token refresh works automatically**
✅ **Logout clears session**

---

## Troubleshooting

### Backend not responding
```powershell
# Check if backend is running
netstat -ano | findstr "3000"

# If not, start it:
cd u:\web_projects\location_project\backend
npm run start:dev
```

### Frontend not loading
```powershell
# Check if frontend is running
netstat -ano | findstr "5173"

# If not, start it:
cd u:\web_projects\location_project\frontend
npx vite dev
```

### Keycloak not accessible
```powershell
# Check if Keycloak container is running
docker ps | findstr keycloak

# If not, start it:
docker run -d -p 8080:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin123 quay.io/keycloak/keycloak:26.4.1 start-dev
```

---

**Save this file and follow the tests step by step manually for comprehensive system validation!**
