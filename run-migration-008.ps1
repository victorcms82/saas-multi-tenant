# Script para rodar Migration 008 - client_media_rules
# Cria tabela de regras de disparo de mídia

$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"

Write-Host "🚀 Rodando Migration 008: client_media_rules..." -ForegroundColor Cyan
Write-Host ""

# Ler SQL
$sql = Get-Content "database\migrations\008_create_client_media_rules.sql" -Raw

# Executar via RPC
$body = @{
    query = $sql
} | ConvertTo-Json

$headers = @{
    'apikey' = $SUPABASE_SERVICE_KEY
    'Authorization' = "Bearer $SUPABASE_SERVICE_KEY"
    'Content-Type' = 'application/json'
}

try {
    Write-Host "📊 Executando SQL..." -ForegroundColor Yellow
    
    # Dividir SQL em statements individuais para evitar erro
    $statements = $sql -split ";\s*(?=CREATE|INSERT|ALTER|COMMENT|--)"
    
    foreach ($stmt in $statements) {
        if ($stmt.Trim() -and -not $stmt.Trim().StartsWith("--")) {
            Write-Host "." -NoNewline -ForegroundColor Gray
            try {
                Invoke-RestMethod `
                    -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
                    -Method POST `
                    -Headers $headers `
                    -Body (@{ query = $stmt + ";" } | ConvertTo-Json) `
                    -ErrorAction SilentlyContinue | Out-Null
            } catch {
                # Ignorar erros de "já existe"
                if (-not $_.Exception.Message.Contains("already exists")) {
                    throw
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host ""
    Write-Host "✅ Migration executada com sucesso!" -ForegroundColor Green
    Write-Host ""
    
    # Verificar resultado
    Write-Host "🔍 Verificando regras criadas..." -ForegroundColor Cyan
    $headers2 = @{
        'apikey' = $SUPABASE_SERVICE_KEY
        'Authorization' = "Bearer $SUPABASE_SERVICE_KEY"
    }
    
    $result = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/client_media_rules?client_id=eq.clinica_sorriso_001&select=*,client_media(title,file_name)" `
        -Headers $headers2 `
        -Method GET
    
    Write-Host ""
    Write-Host "📋 Regras criadas:" -ForegroundColor Green
    $result | ForEach-Object {
        Write-Host "  ✅ Trigger: $($_.trigger_value)" -ForegroundColor White
        Write-Host "     Arquivo: $($_.client_media.title) ($($_.client_media.file_name))" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "🎯 Próximo passo: Testar no WhatsApp enviando keywords!" -ForegroundColor Magenta
    
} catch {
    Write-Host ""
    Write-Host "❌ Erro na migration:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    if ($_.ErrorDetails) {
        Write-Host ""
        Write-Host "Detalhes:" $_.ErrorDetails.Message
    }
}
