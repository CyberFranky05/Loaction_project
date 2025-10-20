# Backend API Test Script
# Tests all endpoints of the Location Auth Backend

$baseUrl = "http://localhost:3000/api/v1"

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "🧪 Testing Location Auth Backend API" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Test 1: Health Check
Write-Host "`n📊 Test 1: Health Check" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/health" -Method GET -UseBasicParsing
    Write-Host "✅ Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Root Endpoint
Write-Host "`n📊 Test 2: Root Endpoint" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/" -Method GET -UseBasicParsing
    Write-Host "✅ Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Sign Up
Write-Host "`n📊 Test 3: Sign Up (New User)" -ForegroundColor Yellow
$signupBody = @{
    name = "API Test User"
    email = "apitest@example.com"
    password = "TestPass123!"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$baseUrl/auth/signup" -Method POST -Body $signupBody -ContentType "application/json" -UseBasicParsing
    Write-Host "✅ Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "⚠️  User already exists (this is expected if running test multiple times)" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 4: Sign In with existing test user
Write-Host "`n📊 Test 4: Sign In (Existing User)" -ForegroundColor Yellow
$signinBody = @{
    email = "testuser@example.com"
    password = "TestPass123!"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$baseUrl/auth/signin" -Method POST -Body $signinBody -ContentType "application/json" -UseBasicParsing
    $signinData = $response.Content | ConvertFrom-Json
    $accessToken = $signinData.access_token
    Write-Host "✅ Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "✅ Got access token: $($accessToken.Substring(0, 50))..." -ForegroundColor Green
    
    # Test 5: Get Profile
    Write-Host "`n📊 Test 5: Get Profile (Authenticated)" -ForegroundColor Yellow
    try {
        $headers = @{
            "Authorization" = "Bearer $accessToken"
        }
        $response = Invoke-WebRequest -Uri "$baseUrl/auth/profile" -Method GET -Headers $headers -UseBasicParsing
        Write-Host "✅ Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "Response: $($response.Content)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 6: Get Sign-in Attempts
    Write-Host "`n📊 Test 6: Get Sign-in Attempts (Authenticated)" -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/auth/signin-attempts" -Method GET -Headers $headers -UseBasicParsing
        Write-Host "✅ Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "Response: $($response.Content)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Sign-in failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "⚠️  Skipping authenticated tests" -ForegroundColor Yellow
}

# Test 7: Invalid Sign In
Write-Host "`n📊 Test 7: Sign In with Wrong Password (Should Fail)" -ForegroundColor Yellow
$invalidBody = @{
    email = "testuser@example.com"
    password = "WrongPassword123!"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$baseUrl/auth/signin" -Method POST -Body $invalidBody -ContentType "application/json" -UseBasicParsing
    Write-Host "❌ Should have failed but didn't!" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ Correctly rejected invalid credentials (401)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Unexpected error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "✅ API Testing Complete!" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Write-Host "`n📋 Available Endpoints:" -ForegroundColor Yellow
Write-Host "  GET    $baseUrl/" -ForegroundColor White
Write-Host "  GET    $baseUrl/health" -ForegroundColor White
Write-Host "  POST   $baseUrl/auth/signup" -ForegroundColor White
Write-Host "  POST   $baseUrl/auth/signin" -ForegroundColor White
Write-Host "  POST   $baseUrl/auth/refresh" -ForegroundColor White
Write-Host "  POST   $baseUrl/auth/logout" -ForegroundColor White
Write-Host "  GET    $baseUrl/auth/profile (requires auth)" -ForegroundColor White
Write-Host "  GET    $baseUrl/auth/signin-attempts (requires auth)" -ForegroundColor White
Write-Host ""
