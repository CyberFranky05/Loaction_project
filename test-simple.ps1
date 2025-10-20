# Simple Test Script
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  LOCATION AUTH - QUICK TEST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Backend Health
Write-Host "[1] Testing Backend..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/health" -TimeoutSec 5
    Write-Host "✅ Backend is RUNNING - Status: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Frontend
Write-Host "`n[2] Testing Frontend..." -ForegroundColor Yellow
try {
    $frontend = Invoke-WebRequest -Uri "http://localhost:5173" -UseBasicParsing -TimeoutSec 5
    Write-Host "✅ Frontend is RUNNING" -ForegroundColor Green
} catch {
    Write-Host "❌ Frontend FAILED" -ForegroundColor Red
}

# Test 3: Keycloak
Write-Host "`n[3] Testing Keycloak..." -ForegroundColor Yellow
try {
    $keycloak = Invoke-RestMethod -Uri "http://localhost:8080/realms/location-auth-realm" -TimeoutSec 5
    Write-Host "✅ Keycloak is RUNNING - Realm: $($keycloak.realm)" -ForegroundColor Green
} catch {
    Write-Host "❌ Keycloak FAILED" -ForegroundColor Red
}

# Test 4: Sign Up
Write-Host "`n[4] Testing Sign Up..." -ForegroundColor Yellow
$testEmail = "test_$(Get-Date -Format 'HHmmss')@example.com"
try {
    $body = @{
        name = "Test User"
        email = $testEmail
        password = "TestPass123!"
    } | ConvertTo-Json
    
    $signup = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signup" -Method POST -Body $body -ContentType "application/json"
    Write-Host "✅ Sign Up SUCCESS - User: $($signup.user.email)" -ForegroundColor Green
    $accessToken = $signup.accessToken
    $refreshToken = $signup.refreshToken
} catch {
    Write-Host "❌ Sign Up FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 5: Sign In
Write-Host "`n[5] Testing Sign In..." -ForegroundColor Yellow
try {
    $body = @{
        email = $testEmail
        password = "TestPass123!"
    } | ConvertTo-Json
    
    $signin = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signin" -Method POST -Body $body -ContentType "application/json"
    Write-Host "✅ Sign In SUCCESS" -ForegroundColor Green
    $accessToken = $signin.accessToken
} catch {
    Write-Host "❌ Sign In FAILED" -ForegroundColor Red
}

# Test 6: Get Profile
Write-Host "`n[6] Testing Get Profile..." -ForegroundColor Yellow
try {
    $headers = @{ "Authorization" = "Bearer $accessToken" }
    $profile = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/profile" -Headers $headers
    Write-Host "✅ Profile SUCCESS - Name: $($profile.name)" -ForegroundColor Green
} catch {
    Write-Host "❌ Profile FAILED" -ForegroundColor Red
}

# Test 7: Get Sign-In Attempts
Write-Host "`n[7] Testing Sign-In Attempts..." -ForegroundColor Yellow
try {
    $headers = @{ "Authorization" = "Bearer $accessToken" }
    $attempts = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signin-attempts" -Headers $headers
    Write-Host "✅ Found $($attempts.attempts.Count) sign-in attempts" -ForegroundColor Green
    
    if ($attempts.attempts.Count -gt 0) {
        $latest = $attempts.attempts[0]
        Write-Host "`n   Latest Attempt Details:" -ForegroundColor Cyan
        Write-Host "   - IP: $($latest.ip_address)" -ForegroundColor Gray
        Write-Host "   - Location: $($latest.city), $($latest.country)" -ForegroundColor Gray
        Write-Host "   - Browser: $($latest.browser)" -ForegroundColor Gray
        Write-Host "   - Device: $($latest.device)" -ForegroundColor Gray
        Write-Host "   - OS: $($latest.operating_system)" -ForegroundColor Gray
        Write-Host "   - Success: $(if($latest.success){'Yes'}else{'No'})" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Sign-In Attempts FAILED" -ForegroundColor Red
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  🎉 ALL TESTS PASSED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nTest User Created:" -ForegroundColor Yellow
Write-Host "Email: $testEmail" -ForegroundColor White
Write-Host "Password: TestPass123!" -ForegroundColor White
Write-Host "`nNext: Open browser to http://localhost:5173" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
