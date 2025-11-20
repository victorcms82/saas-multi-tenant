# ============================================================================
# Script PowerShell: Verificar Migration 022
# ============================================================================

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "VERIFICANDO MIGRATION 022" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# Verificar se há arquivo .env ou config com credenciais Supabase
$envFile = "Supabase\.env"
if (-not (Test-Path $envFile)) {
    Write-Host "⚠️  Arquivo .env não encontrado em Supabase\" -ForegroundColor Yellow
    Write-Host "Vou usar variáveis de ambiente ou você precisa configurar manualmente`n" -ForegroundColor Yellow
}

# SQL de verificação
$verificationSQL = @"
-- Verificar tabelas criadas
SELECT 
  'conversations' as tabela,
  COUNT(*) as total_linhas,
  '✅ Existe' as status
FROM conversations
UNION ALL
SELECT 
  'dashboard_users' as tabela,
  COUNT(*) as total_linhas,
  '✅ Existe' as status
FROM dashboard_users;

-- Verificar novos campos em conversation_memory
SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'conversation_memory'
  AND column_name IN ('conversation_uuid', 'sender_name', 'sender_avatar_url');

-- Verificar funções RPC
SELECT 
  routine_name as funcao,
  '✅ Criada' as status
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'get_conversations_list',
    'get_conversation_detail',
    'takeover_conversation',
    'release_conversation',
    'send_human_message',
    'get_dashboard_stats',
    'sync_conversation_from_chatwoot'
  );
"@

Write-Host "📋 SQL de Verificação Gerado`n" -ForegroundColor Green
Write-Host $verificationSQL -ForegroundColor Gray

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "INSTRUÇÕES PARA VERIFICAÇÃO" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

Write-Host "1️⃣  Acesse: https://supabase.com/dashboard" -ForegroundColor White
Write-Host "2️⃣  Vá para: SQL Editor" -ForegroundColor White
Write-Host "3️⃣  Cole o SQL acima" -ForegroundColor White
Write-Host "4️⃣  Execute (Run)`n" -ForegroundColor White

Write-Host "OU execute via psql:" -ForegroundColor Yellow
Write-Host @"
psql "postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres" -c "
SELECT 'conversations' as tabela, COUNT(*) FROM conversations
UNION ALL
SELECT 'dashboard_users', COUNT(*) FROM dashboard_users;
"
"@ -ForegroundColor Gray

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "VERIFICAÇÃO RÁPIDA (Se tiver psql)" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# Tentar carregar variáveis do Supabase
$supabaseConfigPath = "Supabase\config.toml"
if (Test-Path $supabaseConfigPath) {
    Write-Host "✅ Encontrado config.toml do Supabase`n" -ForegroundColor Green
    
    $config = Get-Content $supabaseConfigPath -Raw
    
    # Extrair informações básicas
    if ($config -match 'project_id\s*=\s*"([^"]+)"') {
        $projectId = $matches[1]
        Write-Host "📦 Project ID: $projectId" -ForegroundColor Cyan
    }
} else {
    Write-Host "ℹ️  Para verificação automática, configure as credenciais do Supabase" -ForegroundColor Yellow
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "CHECKLIST MANUAL" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

Write-Host "[ ] Tabela 'conversations' existe?" -ForegroundColor White
Write-Host "[ ] Tabela 'dashboard_users' existe?" -ForegroundColor White
Write-Host "[ ] Campo 'conversation_uuid' em conversation_memory?" -ForegroundColor White
Write-Host "[ ] 7 funções RPC criadas?" -ForegroundColor White
Write-Host "[ ] RLS habilitado nas novas tabelas?" -ForegroundColor White

Write-Host "`n✨ Script de verificação criado!" -ForegroundColor Green
Write-Host "Execute o SQL acima no Supabase Dashboard → SQL Editor`n" -ForegroundColor Green

# Salvar SQL em arquivo para fácil cópia
$sqlFile = "database\queries\verify-migration-022-quick.sql"
$verificationSQL | Out-File -FilePath $sqlFile -Encoding UTF8
Write-Host "💾 SQL salvo em: $sqlFile" -ForegroundColor Cyan
Write-Host "   Você pode copiar diretamente desse arquivo!`n" -ForegroundColor Cyan
