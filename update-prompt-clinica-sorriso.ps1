# Atualizar System Prompt para Clínica Sorriso

$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"

Write-Host "🦷 Atualizando System Prompt para CLÍNICA SORRISO..." -ForegroundColor Cyan
Write-Host ""

# Ler o novo system prompt
$newPrompt = Get-Content "prompts\system-prompt-clinica-sorriso.md" -Raw

# Criar JSON para update
$body = @{
    system_prompt = $newPrompt
    agent_name = "Carla - Atendimento Clínica Sorriso"
} | ConvertTo-Json -Depth 10

# Headers
$headers = @{
    'apikey' = $SUPABASE_SERVICE_KEY
    'Authorization' = "Bearer $SUPABASE_SERVICE_KEY"
    'Content-Type' = 'application/json'
    'Prefer' = 'return=representation'
}

try {
    $result = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/agents?client_id=eq.clinica_sorriso_001&agent_id=eq.default" `
        -Method PATCH `
        -Headers $headers `
        -Body $body

    Write-Host "✅ System Prompt atualizado com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Agente atualizado:" -ForegroundColor Yellow
    Write-Host "  Nome: $($result[0].agent_name)" -ForegroundColor White
    Write-Host "  Cliente: $($result[0].client_id)" -ForegroundColor White
    Write-Host "  Model: $($result[0].llm_model)" -ForegroundColor White
    Write-Host ""
    Write-Host "🦷 MUDANÇAS APLICADAS:" -ForegroundColor Magenta
    Write-Host "  ✅ Persona: Carla (recepcionista da clínica)" -ForegroundColor White
    Write-Host "  ✅ Contexto: Clínica odontológica" -ForegroundColor White
    Write-Host "  ✅ Serviços: Limpeza, clareamento, implantes, etc" -ForegroundColor White
    Write-Host "  ✅ Arquivos: Compatíveis (consultório, equipe, preços)" -ForegroundColor White
    Write-Host ""
    Write-Host "🧪 PRÓXIMO PASSO: TESTAR NO WHATSAPP!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Teste 1: 'Quanto custa uma limpeza?'" -ForegroundColor White
    Write-Host "   Teste 2: 'Quero ver a tabela de preços'" -ForegroundColor White
    Write-Host "   Teste 3: 'Me mostra o consultório'" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "❌ Erro ao atualizar:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Response:" $_.ErrorDetails.Message
}
