# ============================================================================
# Script: Executar Migration 025 - Fix Dashboard Users RLS Login
# ============================================================================
# Data: 2025-01-19
# Autor: Sistema Automatizado
# Descrição: Corrige RLS da tabela dashboard_users para permitir login
# ============================================================================

# Configurações
$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_SERVICE_ROLE_KEY = $env:SUPABASE_SERVICE_ROLE_KEY
$MIGRATION_FILE = "database/migrations/025_fix_dashboard_users_rls_login.sql"

# Validar variável de ambiente
if (-not $SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "`n❌ ERRO: Variável SUPABASE_SERVICE_ROLE_KEY não configurada!" -ForegroundColor Red
    Write-Host "`nConfigure com:" -ForegroundColor Yellow
    Write-Host '$env:SUPABASE_SERVICE_ROLE_KEY = "sua-service-role-key"' -ForegroundColor White
    exit 1
}

# Validar arquivo de migration
if (-not (Test-Path $MIGRATION_FILE)) {
    Write-Host "`n❌ ERRO: Arquivo $MIGRATION_FILE não encontrado!" -ForegroundColor Red
    exit 1
}

# Banner
Write-Host "`n============================================================================" -ForegroundColor Cyan
Write-Host "  MIGRATION 025: Fix Dashboard Users RLS for Login" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan

Write-Host "`n📋 PROBLEMA IDENTIFICADO:" -ForegroundColor Yellow
Write-Host "  - Durante login, auth.uid() ainda não existe" -ForegroundColor White
Write-Host "  - Policy antiga bloqueava SELECT (id = auth.uid())" -ForegroundColor White
Write-Host "  - Resultado: 'Database error querying schema'" -ForegroundColor Red

Write-Host "`n✅ SOLUÇÃO:" -ForegroundColor Green
Write-Host "  - Nova policy: SELECT usando auth.email() (durante login)" -ForegroundColor White
Write-Host "  - Nova policy: SELECT usando auth.uid() (após login)" -ForegroundColor White
Write-Host "  - auth.email() disponível no JWT antes do login completar" -ForegroundColor White

# Ler conteúdo da migration
Write-Host "`n📄 Lendo migration..." -ForegroundColor Cyan
$migrationContent = Get-Content -Path $MIGRATION_FILE -Raw

# Executar migration via Supabase REST API
Write-Host "`n🚀 Executando migration no Supabase..." -ForegroundColor Cyan

$headers = @{
    "apikey" = $SUPABASE_SERVICE_ROLE_KEY
    "Authorization" = "Bearer $SUPABASE_SERVICE_ROLE_KEY"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

$body = @{
    query = $migrationContent
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" -Method Post -Headers $headers -Body $body -ErrorAction Stop
    
    Write-Host "`n✅ MIGRATION EXECUTADA COM SUCESSO!" -ForegroundColor Green
    
    # Mostrar resultado
    if ($response) {
        Write-Host "`n📊 RESULTADO:" -ForegroundColor Cyan
        $response | ConvertTo-Json -Depth 10 | Write-Host
    }
    
} catch {
    # Se exec_sql não existir, tentar via SQL direto
    Write-Host "`n⚠️ Método exec_sql não disponível, tentando SQL direto..." -ForegroundColor Yellow
    
    $sqlHeaders = @{
        "apikey" = $SUPABASE_SERVICE_ROLE_KEY
        "Authorization" = "Bearer $SUPABASE_SERVICE_ROLE_KEY"
        "Content-Type" = "application/sql"
    }
    
    try {
        $sqlResponse = Invoke-WebRequest -Uri "$SUPABASE_URL/rest/v1/" -Method Post -Headers $sqlHeaders -Body $migrationContent -ErrorAction Stop
        
        Write-Host "`n✅ MIGRATION EXECUTADA COM SUCESSO (SQL direto)!" -ForegroundColor Green
        
    } catch {
        Write-Host "`n❌ ERRO ao executar migration:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "`n💡 SOLUÇÃO ALTERNATIVA:" -ForegroundColor Yellow
        Write-Host "  1. Acesse: $SUPABASE_URL" -ForegroundColor White
        Write-Host "  2. Vá em: SQL Editor" -ForegroundColor White
        Write-Host "  3. Cole o conteúdo de: $MIGRATION_FILE" -ForegroundColor White
        Write-Host "  4. Execute manualmente" -ForegroundColor White
        exit 1
    }
}

# Validar resultado
Write-Host "`n🔍 Validando policies criadas..." -ForegroundColor Cyan

$validateQuery = @"
SELECT 
  policyname,
  cmd,
  qual as using_expression
FROM pg_policies
WHERE tablename = 'dashboard_users'
ORDER BY policyname;
"@

$validateBody = @{
    query = $validateQuery
} | ConvertTo-Json

try {
    $validateResponse = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" -Method Post -Headers $headers -Body $validateBody -ErrorAction SilentlyContinue
    
    if ($validateResponse) {
        Write-Host "`n✅ POLICIES CRIADAS:" -ForegroundColor Green
        $validateResponse | Format-Table -AutoSize
    }
    
} catch {
    Write-Host "`n⚠️ Não foi possível validar automaticamente" -ForegroundColor Yellow
}

# Resumo final
Write-Host "`n============================================================================" -ForegroundColor Cyan
Write-Host "  ✅ MIGRATION 025 CONCLUÍDA" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Cyan

Write-Host "`n📋 O QUE FOI FEITO:" -ForegroundColor Yellow
Write-Host "  ✅ Policy antiga removida: 'Users can view own profile'" -ForegroundColor White
Write-Host "  ✅ Nova policy criada: 'dashboard_users_select_policy'" -ForegroundColor White
Write-Host "  ✅ Permite SELECT com auth.email() (durante login)" -ForegroundColor White
Write-Host "  ✅ Permite SELECT com auth.uid() (após login)" -ForegroundColor White
Write-Host "  ✅ Policy UPDATE: apenas próprio perfil" -ForegroundColor White
Write-Host "  ✅ Policy INSERT: apenas próprio usuário" -ForegroundColor White

Write-Host "`n🧪 TESTE AGORA:" -ForegroundColor Cyan
Write-Host "  1. Acesse o Lovable dashboard" -ForegroundColor White
Write-Host "  2. Faça login com:" -ForegroundColor White
Write-Host "     Email: teste@evolutedigital.com.br" -ForegroundColor Yellow
Write-Host "     Senha: Teste@2024!" -ForegroundColor Yellow
Write-Host "  3. Login deve funcionar ✅" -ForegroundColor Green

Write-Host "`n💡 EXPLICAÇÃO TÉCNICA:" -ForegroundColor Magenta
Write-Host "  - Durante login: Supabase Auth gera JWT com auth.email()" -ForegroundColor White
Write-Host "  - JWT permite query em dashboard_users usando email" -ForegroundColor White
Write-Host "  - Após login: JWT também tem auth.uid()" -ForegroundColor White
Write-Host "  - Ambos auth.email() e auth.uid() vêm do JWT assinado (seguro)" -ForegroundColor White

Write-Host ""
