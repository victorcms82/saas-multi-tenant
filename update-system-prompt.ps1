# Script para atualizar System Prompt no Supabase
# Escola de Automação - V2 Improved

$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"

# Ler o novo system prompt
$newPrompt = Get-Content "prompts\system-prompt-v2-improved.md" -Raw

# Criar JSON para update
$body = @{
    system_prompt = $newPrompt
} | ConvertTo-Json -Depth 10

# Headers
$headers = @{
    'apikey' = $SUPABASE_KEY
    'Authorization' = "Bearer $SUPABASE_KEY"
    'Content-Type' = 'application/json'
    'Prefer' = 'return=representation'
}

Write-Host "🚀 Atualizando System Prompt no Supabase..." -ForegroundColor Cyan
Write-Host ""

try {
    $result = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/agents?client_id=eq.clinica_sorriso_001&agent_id=eq.default" `
        -Method PATCH `
        -Headers $headers `
        -Body $body

    Write-Host "✅ System Prompt atualizado com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Resultado:" -ForegroundColor Yellow
    $result | ConvertTo-Json -Depth 5
    
    Write-Host ""
    Write-Host "🎯 MUDANÇAS APLICADAS:" -ForegroundColor Magenta
    Write-Host "  ✅ Adicionado: Instruções de memória e contexto" -ForegroundColor White
    Write-Host "  ✅ Adicionado: Responder perguntas simples diretamente" -ForegroundColor White
    Write-Host "  ✅ Adicionado: Orientações sobre envio de materiais" -ForegroundColor White
    Write-Host "  ✅ Melhorado: Fluxo de conversa mais natural" -ForegroundColor White
    Write-Host ""
    Write-Host "🧪 PRÓXIMO PASSO: Teste no WhatsApp!" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Erro ao atualizar:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Response:" $_.ErrorDetails.Message
}
