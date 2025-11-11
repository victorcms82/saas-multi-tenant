# ============================================================================
# Script: Inserir client_subscriptions para clientes de teste
# ============================================================================

Write-Host "`n🔧 INSERINDO REGISTROS EM client_subscriptions" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Gray

$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"

$headers = @{
  "apikey" = $ANON_KEY
  "Authorization" = "Bearer $ANON_KEY"
  "Content-Type" = "application/json"
  "Prefer" = "return=representation,resolution=merge-duplicates"
}

# Clientes para inserir
$clientes = @(
  @{
    client_id = "estetica_bella_rede"
    agent_id = "default"
    template_id = "bella-default"
    monthly_price = 199.00
  },
  @{
    client_id = "clinica_sorriso_001"
    agent_id = "default"
    template_id = "clinica-default"
    monthly_price = 149.00
  }
)

Write-Host "`n📝 Inserindo $($clientes.Count) registros...`n" -ForegroundColor Yellow

$successCount = 0
$errorCount = 0

foreach ($cliente in $clientes) {
  Write-Host "   Cliente: $($cliente.client_id) / Agente: $($cliente.agent_id)" -ForegroundColor Cyan
  
  # Preparar body
  $body = @{
    client_id = $cliente.client_id
    agent_id = $cliente.agent_id
    template_id = $cliente.template_id
    template_snapshot = @{}
    status = "active"
    monthly_price = $cliente.monthly_price
    billing_cycle = "monthly"
    subscription_start_date = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    current_usage = @{
      messages_count = 0
      last_message_at = $null
    }
  } | ConvertTo-Json -Depth 3
  
  try {
    $response = Invoke-RestMethod `
      -Uri "$SUPABASE_URL/rest/v1/client_subscriptions" `
      -Method Post `
      -Headers $headers `
      -Body $body `
      -ErrorAction Stop
    
    Write-Host "      ✅ Inserido com sucesso!" -ForegroundColor Green
    $successCount++
    
  } catch {
    $errorMessage = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
    
    # Verificar se é conflito (já existe)
    if ($_.Exception.Response.StatusCode -eq 409 -or $errorMessage.message -like "*duplicate*") {
      Write-Host "      ℹ️  Já existe (OK)" -ForegroundColor Gray
      $successCount++
    } else {
      Write-Host "      ❌ Erro: $($_.Exception.Message)" -ForegroundColor Red
      if ($errorMessage) {
        Write-Host "         Detalhes: $($errorMessage.message)" -ForegroundColor Red
      }
      $errorCount++
    }
  }
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Gray
Write-Host "📊 RESUMO:" -ForegroundColor Cyan
Write-Host "   ✅ Sucesso/Já existe: $successCount" -ForegroundColor Green
Write-Host "   ❌ Erros: $errorCount" -ForegroundColor Red

if ($errorCount -eq 0) {
  Write-Host "`n🎉 TUDO CERTO! Registros inseridos." -ForegroundColor Green
  Write-Host "   O workflow agora deve funcionar normalmente." -ForegroundColor Cyan
} else {
  Write-Host "`n⚠️ Alguns registros falharam. Verifique os erros acima." -ForegroundColor Yellow
}

# Validar
Write-Host "`n🔍 VALIDANDO registros inseridos..." -ForegroundColor Cyan

foreach ($cliente in $clientes) {
  try {
    $validacao = Invoke-RestMethod `
      -Uri "$SUPABASE_URL/rest/v1/client_subscriptions?client_id=eq.$($cliente.client_id)&agent_id=eq.$($cliente.agent_id)" `
      -Method Get `
      -Headers $headers
    
    if ($validacao.Count -gt 0) {
      Write-Host "   ✅ $($cliente.client_id) / $($cliente.agent_id) → Existe!" -ForegroundColor Green
    } else {
      Write-Host "   ❌ $($cliente.client_id) / $($cliente.agent_id) → NÃO encontrado!" -ForegroundColor Red
    }
  } catch {
    Write-Host "   ❌ Erro ao validar $($cliente.client_id)" -ForegroundColor Red
  }
}

Write-Host "`n✨ Script finalizado!" -ForegroundColor Cyan
