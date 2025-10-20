# Simple Startup and Test Script
# This script starts all services and performs basic connectivity tests

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  LOCATION AUTH - STARTUP & TEST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Check if Backend is running
Write-Host "[1] Checking Backend..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/health" -TimeoutSec 5
    Write-Host "✅ Backend is RUNNING - Status: $($health.status)" -ForegroundColor Green
    $backendRunning = $true
} catch {
    Write-Host "❌ Backend is NOT running" -ForegroundColor Red
    Write-Host "   Start it with: cd backend; npm run start:dev" -ForegroundColor Yellow
    $backendRunning = $false
}

# Test 2: Check if Frontend is running
Write-Host "`n[2] Checking Frontend..." -ForegroundColor Yellow
try {
    $frontend = Invoke-WebRequest -Uri "http://localhost:5173" -UseBasicParsing -TimeoutSec 5
    Write-Host "✅ Frontend is RUNNING - Status: $($frontend.StatusCode)" -ForegroundColor Green
    $frontendRunning = $true
} catch {
    Write-Host "❌ Frontend is NOT running" -ForegroundColor Red
    Write-Host "   Start it with: cd frontend; npx vite dev" -ForegroundColor Yellow
    $frontendRunning = $false
}

# Test 3: Check if Keycloak is running
Write-Host "`n[3] Checking Keycloak..." -ForegroundColor Yellow
try {
    $keycloak = Invoke-RestMethod -Uri "http://localhost:8080/realms/location-auth-realm" -TimeoutSec 5
    Write-Host "✅ Keycloak is RUNNING - Realm: $($keycloak.realm)" -ForegroundColor Green
    $keycloakRunning = $true
} catch {
    Write-Host "❌ Keycloak is NOT running" -ForegroundColor Red
    Write-Host "   Start it with: docker run -d -p 8080:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin123 quay.io/keycloak/keycloak:26.4.1 start-dev" -ForegroundColor Yellow
    $keycloakRunning = $false
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  SERVICE STATUS SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nBackend:  $(if($backendRunning){'✅ Running'}else{'❌ Stopped'})" -ForegroundColor $(if($backendRunning){'Green'}else{'Red'})
Write-Host "Frontend: $(if($frontendRunning){'✅ Running'}else{'❌ Stopped'})" -ForegroundColor $(if($frontendRunning){'Green'}else{'Red'})
Write-Host "Keycloak: $(if($keycloakRunning){'✅ Running'}else{'❌ Stopped'})" -ForegroundColor $(if($keycloakRunning){'Green'}else{'Red'})

if ($backendRunning -and $frontendRunning -and $keycloakRunning) {
    Write-Host "`n🎉 All services are running!" -ForegroundColor Green
    Write-Host "`nReady to test! Open your browser to:" -ForegroundColor Cyan
    Write-Host "   http://localhost:5173" -ForegroundColor White
    
    # Quick API Test
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  QUICK API TEST" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Creating test user..." -ForegroundColor Yellow
    $testEmail = "quicktest_$(Get-Date -Format 'HHmmss')@example.com"
    
    try {
        $signupBody = @{
            name = "Quick Test"
            email = $testEmail
            password = "TestPass123!"
        } | ConvertTo-Json
        
        $signupResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signup" -Method POST -Body $signupBody -ContentType "application/json"
        Write-Host "✅ Sign-up successful!" -ForegroundColor Green
        Write-Host "   User: $($signupResponse.user.email)" -ForegroundColor Gray
        Write-Host "   ID: $($signupResponse.user.id)" -ForegroundColor Gray
        
        # Try signing in
        Write-Host "`nSigning in..." -ForegroundColor Yellow
        $signinBody = @{
            email = $testEmail
            password = "TestPass123!"
        } | ConvertTo-Json
        
        $signinResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signin" -Method POST -Body $signinBody -ContentType "application/json"
        Write-Host "✅ Sign-in successful!" -ForegroundColor Green
        
        # Get sign-in attempts
        Write-Host "`nFetching sign-in attempts..." -ForegroundColor Yellow
        $headers = @{ "Authorization" = "Bearer $($signinResponse.accessToken)" }
        $attempts = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/signin-attempts" -Headers $headers
        
        Write-Host "✅ Found $($attempts.attempts.Count) sign-in attempts" -ForegroundColor Green
        if ($attempts.attempts.Count -gt 0) {
            $latest = $attempts.attempts[0]
            Write-Host "`n   Latest Attempt:" -ForegroundColor Cyan
            Write-Host "   ├─ IP: $($latest.ip_address)" -ForegroundColor Gray
            Write-Host "   ├─ Location: $($latest.city), $($latest.country)" -ForegroundColor Gray
            Write-Host "   ├─ Browser: $($latest.browser)" -ForegroundColor Gray
            Write-Host "   ├─ Device: $($latest.device)" -ForegroundColor Gray
            Write-Host "   ├─ OS: $($latest.operating_system)" -ForegroundColor Gray
            Write-Host "   └─ Success: $(if($latest.success){'✅ Yes'}else{'❌ No'})" -ForegroundColor Gray
        }
        
        Write-Host "`n🎉 ALL API TESTS PASSED!" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ API Test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
} else {
    Write-Host "`n❌ Some services are not running. Please start them first." -ForegroundColor Red
    
    if (-not $backendRunning) {
        Write-Host "`nTo start Backend:" -ForegroundColor Yellow
        Write-Host "   cd u:\web_projects\location_project\backend" -ForegroundColor White
        Write-Host "   npm run start:dev" -ForegroundColor White
    }
    
    if (-not $frontendRunning) {
        Write-Host "`nTo start Frontend:" -ForegroundColor Yellow
        Write-Host "   cd u:\web_projects\location_project\frontend" -ForegroundColor White
        Write-Host "   npx vite dev" -ForegroundColor White
    }
    
    if (-not $keycloakRunning) {
        Write-Host "`nTo start Keycloak:" -ForegroundColor Yellow
        Write-Host "   docker run -d -p 8080:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin123 quay.io/keycloak/keycloak:26.4.1 start-dev" -ForegroundColor White
    }
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
