# 🚀 FINAL TESTING INSTRUCTIONS

## Current Status:
- ✅ Frontend: Running on http://localhost:5173
- ✅ Keycloak: Running on port 8080
- ❌ Backend: NEEDS TO BE STARTED

---

## STEP 1: Start Backend (CRITICAL!)

**Open Windows PowerShell as a separate window** (not in VS Code terminal):

1. Press `Win + X` → Select "Windows PowerShell"
2. Run these commands:
```powershell
cd U:\web_projects\location_project\backend
npm run start:dev
```

3. Wait for this message:
```
🚀 Application is running on: http://localhost:3000/api/v1
```

4. **LEAVE THIS WINDOW OPEN!** Don't close it!

---

## STEP 2: Test Backend is Running

**Open ANOTHER PowerShell window:**

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/health"
```

✅ **Expected Output:**
```
status    : ok
timestamp : 2025-10-21T00:30:00.000Z
```

If you get an error, backend is not running - go back to Step 1!

---

## STEP 3: Run Automated Tests

In the same PowerShell window from Step 2:

```powershell
cd U:\web_projects\location_project
.\test-simple.ps1
```

✅ **Expected:** All 7 tests pass with green ✅ checkmarks

---

## STEP 4: Browser Testing

### Test 4.1: Landing Page
1. Open browser to: **http://localhost:5173**
2. ✅ Should see "Welcome to Location Auth System"
3. ✅ See 3 feature cards (Secure Auth, Location Tracking, Sign-in Monitoring)

### Test 4.2: Sign Up with Password Validation
1. Click **"Get Started"** button
2. Fill form:
   - Name: **Your Name**
   - Email: **yourname@example.com**
   - Password: Start typing slowly...

3. **Watch the password indicators:**
   - Type: `t` → All indicators RED ❌
   - Type: `te` → All indicators RED ❌
   - Type: `tes` → All indicators RED ❌
   - Type: `test` → All indicators RED ❌ (too short)
   - Type: `Test` → Uppercase turns GREEN ✅
   - Type: `Test1` → Uppercase + Digit turn GREEN ✅✅
   - Type: `Test12` → Still RED (need 8 chars + special)
   - Type: `Test123` → Still RED (need special char)
   - Type: `Test123!` → **ALL GREEN** ✅✅✅✅✅

4. Confirm Password: `Test123!`
5. ✅ Should see green message "Passwords match"
6. Click **"Sign Up"**
7. ✅ Success message appears
8. ✅ Auto-redirects to sign-in page (wait 2 seconds)

### Test 4.3: Sign In
1. Enter credentials:
   - Email: **yourname@example.com**
   - Password: **Test123!**
2. Click **"Sign In"**
3. ✅ Redirected to dashboard

### Test 4.4: Dashboard - Sign-In Attempts Table
1. ✅ See welcome message: "Welcome back, [Your Name]!"
2. ✅ See "Sign-In Attempts" header
3. ✅ See table with these columns:
   - Status (✓ Success / ✗ Failed)
   - Date & Time
   - IP Address
   - Location
   - Browser
   - Device
   - OS

4. ✅ Should see **2 attempts**:
   - First attempt: Sign-up (Status: ✓ Success)
   - Second attempt: Sign-in (Status: ✓ Success)

5. **Verify data in table:**
   - IP: `127.0.0.1` or your local IP
   - Location: May show "Unknown" for localhost (this is normal!)
   - Browser: Chrome / Edge / Firefox (should be correct!)
   - Device: Desktop (should be correct!)
   - OS: Windows (should be correct!)

6. Click **"Refresh"** button
7. ✅ Table reloads

### Test 4.5: Failed Login
1. Click **"Logout"**
2. ✅ Redirected to sign-in page
3. Try signing in with **WRONG password**: `WrongPass123!`
4. ✅ See error message: "Invalid email or password"
5. Sign in with **CORRECT password**: `Test123!`
6. Go to dashboard
7. ✅ Should now see **3 attempts** in table:
   - 1st: Sign-up (Success ✓)
   - 2nd: Sign-in (Success ✓)
   - 3rd: Failed sign-in (Failed ✗ - should be RED!)

### Test 4.6: Protected Routes
1. Click **Logout**
2. Open new **Incognito/Private window**
3. Go directly to: `http://localhost:5173/dashboard`
4. ✅ Should AUTO-redirect to `/signin` (not allowed without auth!)

---

## STEP 5: API Testing (PowerShell)

In PowerShell window:

### Create a test user via API:
```powershell
$email = "apitest@example.com"
$body = @{
    name = "API Test User"
    email = $email
    password = "TestPass123!"
} | ConvertTo-Json

$signup = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signup" -Method POST -Body $body -ContentType "application/json"

# Save tokens
$accessToken = $signup.accessToken
$refreshToken = $signup.refreshToken

# Show user
$signup.user | ConvertTo-Json
```

✅ **Expected:** User object with email, name, id

### Get sign-in attempts via API:
```powershell
$headers = @{ "Authorization" = "Bearer $accessToken" }
$attempts = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signin-attempts" -Headers $headers

# Show attempts
$attempts | ConvertTo-Json -Depth 3
```

✅ **Expected:** Array with sign-in attempts showing IP, location, browser, etc.

---

## ✅ Test Checklist

### Backend API (7 tests)
- [ ] Health check responds
- [ ] Sign-up creates user
- [ ] Sign-in returns tokens
- [ ] Get profile works with auth
- [ ] Get signin-attempts returns data
- [ ] Refresh token generates new token
- [ ] Logout works

### Frontend UI (8 tests)
- [ ] Landing page loads
- [ ] Sign-up page displays
- [ ] Password validation shows real-time (green/red)
- [ ] All 5 password requirements turn green with "Test123!"
- [ ] Confirm password shows green checkmark when matching
- [ ] Sign-in page works
- [ ] Dashboard displays
- [ ] Sign-in attempts table shows data

### Data Validation (5 tests)
- [ ] IP address logged (127.0.0.1)
- [ ] Browser detected correctly
- [ ] Device shows "Desktop"
- [ ] OS shows "Windows"
- [ ] Success/Failed status accurate

### Integration (4 tests)
- [ ] Complete signup → signin → dashboard flow works
- [ ] Failed login creates failed attempt entry
- [ ] Protected routes redirect unauthenticated users
- [ ] Logout clears session

---

## 🎯 SUCCESS CRITERIA

**ALL TESTS PASS IF:**

1. ✅ test-simple.ps1 shows 7/7 tests passed
2. ✅ Can sign up in browser
3. ✅ Password indicators turn green with "Test123!"
4. ✅ Can sign in
5. ✅ Dashboard shows sign-in attempts table
6. ✅ Table has correct columns and data
7. ✅ Browser/Device/OS detected
8. ✅ Failed login shows in table
9. ✅ Logout works
10. ✅ Protected routes redirect

---

## 📸 What to Look For

### Password Validation (MOST IMPORTANT!)
When typing password "Test123!" you should see indicators like this:

```
Password Requirements:
✅ At least 8 characters
✅ At least one uppercase letter  
✅ At least one lowercase letter
✅ At least one digit
✅ At least one special character
```

### Dashboard Table (SECOND MOST IMPORTANT!)
Should look like this:

```
Status      Date & Time         IP Address    Location      Browser  Device   OS
✓ Success   Oct 21, 12:30 AM    127.0.0.1     Unknown       Chrome   Desktop  Windows
✓ Success   Oct 21, 12:31 AM    127.0.0.1     Unknown       Chrome   Desktop  Windows
✗ Failed    Oct 21, 12:32 AM    127.0.0.1     Unknown       Chrome   Desktop  Windows
```

---

## 🐛 Troubleshooting

### "Unable to connect to remote server"
→ Backend is not running. Go back to Step 1!

### Password indicators not showing
→ Refresh browser page, check browser console for errors

### Dashboard table empty
→ Make sure you signed up and signed in first

### Location shows "Unknown"
→ Normal for localhost (127.0.0.1). Real IPs will show location.

---

## 🎉 DONE!

Once all tests pass, you have a fully functional:
- ✅ Backend API with 7 endpoints
- ✅ Frontend with 4 pages
- ✅ Real-time password validation
- ✅ Location-based authentication tracking
- ✅ Sign-in attempts monitoring

**Congratulations! Your system is working! 🚀**
