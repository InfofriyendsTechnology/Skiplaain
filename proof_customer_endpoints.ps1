#!/usr/bin/env pwsh
# Proof script for Customer App API endpoints

$ErrorActionPreference = "Continue"
$apiBase = "http://localhost:61026"

# Get TEST customer token
Write-Host "`n=== Getting TEST Customer Token ===" -ForegroundColor Cyan
try {
    $loginRes = Invoke-RestMethod -Uri "$apiBase/api/auth/verify-otp" -Method POST -ContentType "application/json" -Body (@{
        phone = "8000000001"
        otp = "111111"
        userType = "customer"
    } | ConvertTo-Json)
    $token = $loginRes.data.token
    Write-Host "Token obtained: $($token.Substring(0,20))..." -ForegroundColor Green
} catch {
    Write-Host "Login failed: $_" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Test 1: GET /salons
Write-Host "`n=== TEST 1: GET /api/salons ===" -ForegroundColor Cyan
try {
    $res = Invoke-RestMethod -Uri "$apiBase/api/salons" -Method GET -Headers $headers
    Write-Host "Status: 200 OK" -ForegroundColor Green
    Write-Host "Salons found: $($res.data.Count)"
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
}

# Test 2: GET /salons/:id (use first salon from above)
Write-Host "`n=== TEST 2: GET /api/salons/:id ===" -ForegroundColor Cyan
try {
    $salonsRes = Invoke-RestMethod -Uri "$apiBase/api/salons" -Method GET -Headers $headers
    if ($salonsRes.data.Count -gt 0) {
        $salonId = $salonsRes.data[0].id
        $detailRes = Invoke-RestMethod -Uri "$apiBase/api/salons/$salonId" -Method GET -Headers $headers
        Write-Host "Status: 200 OK" -ForegroundColor Green
        Write-Host "Salon: $($detailRes.data.salonName)"
    }
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
}

# Test 3: GET /plans?salonId=
Write-Host "`n=== TEST 3: GET /api/plans?salonId= ===" -ForegroundColor Cyan
try {
    $salonsRes = Invoke-RestMethod -Uri "$apiBase/api/salons" -Method GET -Headers $headers
    if ($salonsRes.data.Count -gt 0) {
        $salonId = $salonsRes.data[0].id
        $plansRes = Invoke-RestMethod -Uri "$apiBase/api/plans?salonId=$salonId" -Method GET -Headers $headers
        Write-Host "Status: 200 OK" -ForegroundColor Green
        Write-Host "Plans found: $($plansRes.data.Count)"
    }
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
}

# Test 4: GET /subscriptions/status?salonId=
Write-Host "`n=== TEST 4: GET /api/subscriptions/status?salonId= ===" -ForegroundColor Cyan
try {
    $salonsRes = Invoke-RestMethod -Uri "$apiBase/api/salons" -Method GET -Headers $headers
    if ($salonsRes.data.Count -gt 0) {
        $salonId = $salonsRes.data[0].id
        $statusRes = Invoke-RestMethod -Uri "$apiBase/api/subscriptions/status?salonId=$salonId" -Method GET -Headers $headers
        Write-Host "Status: 200 OK" -ForegroundColor Green
        Write-Host "Has active: $($statusRes.data.hasActiveMembership)"
    }
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
}

# Test 5: POST /subscriptions/order
Write-Host "`n=== TEST 5: POST /api/subscriptions/order ===" -ForegroundColor Cyan
try {
    $salonsRes = Invoke-RestMethod -Uri "$apiBase/api/salons" -Method GET -Headers $headers
    $plansRes = Invoke-RestMethod -Uri "$apiBase/api/plans?salonId=$($salonsRes.data[0].id)" -Method GET -Headers $headers
    if ($plansRes.data.Count -gt 0) {
        $planId = $plansRes.data[0].id
        $orderRes = Invoke-RestMethod -Uri "$apiBase/api/subscriptions/order" -Method POST -Headers $headers -Body (@{
            planId = $planId
        } | ConvertTo-Json)
        Write-Host "Status: 200 OK" -ForegroundColor Green
        Write-Host "Order ID: $($orderRes.data.orderId)"
    }
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
}

# Test 6: GET /subscriptions/my
Write-Host "`n=== TEST 6: GET /api/subscriptions/my ===" -ForegroundColor Cyan
try {
    $myRes = Invoke-RestMethod -Uri "$apiBase/api/subscriptions/my" -Method GET -Headers $headers
    Write-Host "Status: 200 OK" -ForegroundColor Green
    Write-Host "My subscriptions: $($myRes.data.Count)"
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
}

# Test 7: GET /customers/me
Write-Host "`n=== TEST 7: GET /api/customers/me ===" -ForegroundColor Cyan
try {
    $meRes = Invoke-RestMethod -Uri "$apiBase/api/customers/me" -Method GET -Headers $headers
    Write-Host "Status: 200 OK" -ForegroundColor Green
    Write-Host "Customer: $($meRes.data.name)"
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
}

# Test 8: POST /bookings without plan (should return 402)
Write-Host "`n=== TEST 8: POST /api/bookings (without plan - expect 402) ===" -ForegroundColor Cyan
try {
    $salonsRes = Invoke-RestMethod -Uri "$apiBase/api/salons" -Method GET -Headers $headers
    $salonId = $salonsRes.data[0].id
    $bookingRes = Invoke-RestMethod -Uri "$apiBase/api/bookings" -Method POST -Headers $headers -Body (@{
        partnerId = $salonId
        bookingDate = "2024-12-25"
        timeSlot = "10:00"
        serviceIds = @("service-1")
    } | ConvertTo-Json)
    Write-Host "Status: 200 (unexpected - should be 402)" -ForegroundColor Yellow
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 402) {
        Write-Host "Status: 402 Payment Required" -ForegroundColor Green
    } else {
        Write-Host "Status: $statusCode" -ForegroundColor Red
    }
}

# Test 9: PATCH /bookings/:id/status cancelled
Write-Host "`n=== TEST 9: PATCH /api/bookings/:id/status (cancelled) ===" -ForegroundColor Cyan
Write-Host "Skipped - requires existing booking ID" -ForegroundColor Yellow

Write-Host "`n=== Customer Proof Complete ===" -ForegroundColor Cyan
