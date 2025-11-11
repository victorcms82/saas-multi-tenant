# Inserir estetica_bella_rede em client_subscriptions

$body = @{
  client_id = "estetica_bella_rede"
  agent_id = "default"
  template_id = "support-premium"
  template_snapshot = @{}
  status = "active"
  monthly_price = 199.00
  billing_cycle = "monthly"
  subscription_start_date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json

Write-Host "`n🔧 Inserindo estetica_bella_rede..." -ForegroundColor Cyan

try {
  $result = Invoke-RestMethod `
    -Uri "https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/client_subscriptions" `
    -Method Post `
    -Headers @{
      "apikey"="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
      "Authorization"="Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
      "Content-Type"="application/json"
      "Prefer"="return=representation"
    } `
    -Body $body
  
  Write-Host "✅ SUCESSO!" -ForegroundColor Green
  $result | ConvertTo-Json -Depth 2
  
} catch {
  Write-Host "❌ ERRO: $_" -ForegroundColor Red
  Write-Host $_.ErrorDetails.Message -ForegroundColor Yellow
}
