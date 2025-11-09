# ==================================================
# Run Migration 007 - Chatwoot Multi-Tenancy
# ==================================================
# Purpose: Adicionar colunas Chatwoot na tabela clients
# ==================================================

param(
    [string]$SupabaseUrl = "https://vnlfgnfaortdvmraoapq.supabase.co",
    [string]$ServiceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"
)

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   MIGRATION 007: Chatwoot Multi-Tenancy" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Ler arquivo SQL
$MigrationFile = ".\database\migrations\007_add_chatwoot_multi_tenancy.sql"

if (-not (Test-Path $MigrationFile)) {
    Write-Host "❌ Arquivo não encontrado: $MigrationFile" -ForegroundColor Red
    exit 1
}

$SqlContent = Get-Content $MigrationFile -Raw

Write-Host "📄 Arquivo: $MigrationFile" -ForegroundColor White
Write-Host "📏 Tamanho: $($SqlContent.Length) chars" -ForegroundColor Gray
Write-Host ""

Write-Host "🔧 Esta migration irá:" -ForegroundColor Yellow
Write-Host "  1. Adicionar 5 colunas na tabela 'clients'" -ForegroundColor White
Write-Host "     - chatwoot_inbox_id" -ForegroundColor Gray
Write-Host "     - chatwoot_agent_id" -ForegroundColor Gray
Write-Host "     - chatwoot_agent_email" -ForegroundColor Gray
Write-Host "     - chatwoot_access_granted" -ForegroundColor Gray
Write-Host "     - chatwoot_setup_at" -ForegroundColor Gray
Write-Host "  2. Criar 2 índices para performance" -ForegroundColor White
Write-Host ""

$Confirm = Read-Host "Executar migration? (s/N)"

if ($Confirm -ne "s") {
    Write-Host "❌ Cancelado" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "⏳ Executando migration..." -ForegroundColor Yellow
Write-Host ""

# Headers para Supabase
$Headers = @{
    "apikey" = $ServiceKey
    "Authorization" = "Bearer $ServiceKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

# Executar via RPC (query)
$Body = @{
    query = $SqlContent
} | ConvertTo-Json

try {
    $Response = Invoke-RestMethod `
        -Uri "$SupabaseUrl/rest/v1/rpc/exec_sql" `
        -Method POST `
        -Headers $Headers `
        -Body $Body -ErrorAction Stop
    
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "   ✅ MIGRATION EXECUTADA COM SUCESSO!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    
} catch {
    # Se exec_sql não existir, tentar via SQL Editor API alternativa
    Write-Host "⚠️  RPC exec_sql não disponível, tentando método alternativo..." -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "📋 INSTRUÇÕES MANUAIS:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Acesse o Supabase SQL Editor:" -ForegroundColor White
    Write-Host "   https://supabase.com/dashboard/project/vnlfgnfaortdvmraoapq/sql/new" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Cole o SQL abaixo:" -ForegroundColor White
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host $SqlContent -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Clique em 'RUN' (Ctrl+Enter)" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Verifique se retorna: 'Migration 007 concluída com sucesso!'" -ForegroundColor White
    Write-Host ""
    
    # Copiar SQL para clipboard se possível
    try {
        Set-Clipboard -Value $SqlContent
        Write-Host "✅ SQL copiado para área de transferência!" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "ℹ️  SQL disponível no arquivo: $MigrationFile" -ForegroundColor Yellow
    }
    
    $ManualConfirm = Read-Host "Executou manualmente e deu sucesso? (s/N)"
    
    if ($ManualConfirm -ne "s") {
        Write-Host "❌ Migration não confirmada" -ForegroundColor Red
        exit 1
    }
}

# Verificar se colunas foram criadas
Write-Host "🔍 Verificando colunas criadas..." -ForegroundColor Yellow
Write-Host ""

$CheckQuery = @"
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'clients' 
AND column_name LIKE 'chatwoot%'
ORDER BY ordinal_position;
"@

$CheckHeaders = @{
    "apikey" = $ServiceKey
    "Authorization" = "Bearer $ServiceKey"
    "Content-Type" = "application/json"
}

try {
    $Columns = Invoke-RestMethod `
        -Uri "$SupabaseUrl/rest/v1/rpc/exec_sql?query=$([uri]::EscapeDataString($CheckQuery))" `
        -Method POST `
        -Headers $CheckHeaders `
        -Body "{}" -ErrorAction SilentlyContinue
    
    if ($Columns) {
        Write-Host "✅ Colunas criadas:" -ForegroundColor Green
        $Columns | ForEach-Object {
            Write-Host "   - $($_.column_name) ($($_.data_type))" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "ℹ️  Verificação automática não disponível" -ForegroundColor Yellow
    Write-Host "   Execute manualmente:" -ForegroundColor Gray
    Write-Host "   SELECT column_name FROM information_schema.columns WHERE table_name = 'clients' AND column_name LIKE 'chatwoot%';" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   📋 PRÓXIMOS PASSOS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Executar script de setup para cliente:" -ForegroundColor White
Write-Host "   .\setup-chatwoot-client.ps1 -ClientId 'clinica_sorriso_001'" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Isso irá:" -ForegroundColor White
Write-Host "   - Criar Inbox dedicada no Chatwoot" -ForegroundColor Gray
Write-Host "   - Criar Agent (usuário) para o cliente" -ForegroundColor Gray
Write-Host "   - Atualizar tabela clients com IDs" -ForegroundColor Gray
Write-Host "   - Configurar webhook específico" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Testar isolamento multi-tenant" -ForegroundColor White
Write-Host ""

Write-Host "✅ Migration 007 finalizada!`n" -ForegroundColor Green
