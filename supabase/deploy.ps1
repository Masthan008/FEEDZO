# Feedzo Supabase Edge Functions Deployment Script
# Run from workspace root: .\supabase\deploy.ps1

Write-Host "Deploying Feedzo Edge Functions..." -ForegroundColor Green

$functions = @("send-notification", "order-created", "driver-assigned", "order-status", "commission-calc", "loyalty-calculate", "loyalty-redeem")

foreach ($fn in $functions) {
    Write-Host "Deploying $fn..." -ForegroundColor Cyan
    supabase functions deploy $fn --no-verify-jwt
}

Write-Host ""
Write-Host "All functions deployed!" -ForegroundColor Green
Write-Host ""
Write-Host "Function URLs:" -ForegroundColor Yellow
Write-Host "  POST .../send-notification   - Send push to any user"
Write-Host "  POST .../order-created       - Notify restaurant on new order"
Write-Host "  POST .../driver-assigned     - Notify driver when assigned"
Write-Host "  POST .../order-status        - Notify customer on status change"
Write-Host "  POST .../commission-calc     - Calculate commission breakdown"
