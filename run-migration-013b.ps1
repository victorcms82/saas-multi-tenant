# ============================================================================
# Script: Executar Migration 013b - FIX client_id no RPC
# ============================================================================

Write-Host "`n🚀 MIGRATION 013b: Adicionar client_id ao RPC get_location_staff_summary" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Gray

# Configurações
$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"

# Caminho do arquivo SQL
$SQL_FILE = "database\migrations\013b_fix_rpc_add_client_id.sql"

Write-Host "`n📂 Verificando arquivo SQL..." -ForegroundColor Yellow
if (-not (Test-Path $SQL_FILE)) {
    Write-Host "❌ ERRO: Arquivo não encontrado: $SQL_FILE" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Arquivo encontrado!" -ForegroundColor Green

# Ler conteúdo do SQL
Write-Host "`n📖 Lendo SQL..." -ForegroundColor Yellow
$sqlContent = Get-Content $SQL_FILE -Raw

# Separar comandos (split por ponto-e-vírgula seguido de quebra de linha)
$commands = $sqlContent -split ";\s*`n" | Where-Object { 
    $_.Trim() -ne "" -and 
    $_.Trim() -notmatch "^--" -and
    $_.Trim() -notmatch "^\/\*" 
}

Write-Host "✅ SQL carregado! Total de comandos: $($commands.Count)" -ForegroundColor Green

# Executar cada comando
$successCount = 0
$errorCount = 0

foreach ($i in 0..($commands.Count - 1)) {
    $cmd = $commands[$i].Trim()
    
    # Pular comandos vazios ou comentários
    if ($cmd -eq "" -or $cmd -match "^--") {
        continue
    }
    
    # Identificar tipo de comando
    $cmdType = "SQL"
    if ($cmd -match "^DROP FUNCTION") { $cmdType = "DROP FUNCTION" }
    elseif ($cmd -match "^CREATE OR REPLACE FUNCTION") { $cmdType = "CREATE FUNCTION" }
    elseif ($cmd -match "^COMMENT ON") { $cmdType = "COMMENT" }
    elseif ($cmd -match "^SELECT") { $cmdType = "TEST QUERY" }
    
    Write-Host "`n[$($i + 1)/$($commands.Count)] Executando: $cmdType" -ForegroundColor Cyan
    
    # Preparar body para a API
    $body = $cmd + ";"
    
    try {
        $response = Invoke-RestMethod `
            -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" `
            -Method Post `
            -Headers @{
                "apikey" = $ANON_KEY
                "Authorization" = "Bearer $ANON_KEY"
                "Content-Type" = "application/json"
                "Prefer" = "return=representation"
            } `
            -Body (@{ query = $body } | ConvertTo-Json) `
            -ErrorAction Stop
        
        Write-Host "   ✅ Sucesso!" -ForegroundColor Green
        $successCount++
        
    } catch {
        Write-Host "   ⚠️ Tentando via query direta..." -ForegroundColor Yellow
        
        # Tentar método alternativo via SQL Editor endpoint
        try {
            $headers = @{
                "apikey" = $ANON_KEY
                "Authorization" = "Bearer $ANON_KEY"
                "Content-Type" = "text/plain"
            }
            
            # Como fallback, vamos executar via psql se disponível
            Write-Host "   ℹ️ API REST não suporta DDL diretamente." -ForegroundColor Yellow
            Write-Host "   📝 Salvando comando para execução manual..." -ForegroundColor Yellow
            
            # Criar arquivo temporário com o comando
            $tempFile = "temp_migration_013b_cmd_$i.sql"
            $cmd + ";" | Out-File -FilePath $tempFile -Encoding UTF8
            
            Write-Host "   💾 Salvo em: $tempFile" -ForegroundColor Gray
            
        } catch {
            Write-Host "   ❌ Erro: $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
    }
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Gray
Write-Host "📊 RESUMO DA EXECUÇÃO:" -ForegroundColor Cyan
Write-Host "   ✅ Sucesso: $successCount" -ForegroundColor Green
Write-Host "   ❌ Erros: $errorCount" -ForegroundColor Red

if ($errorCount -gt 0) {
    Write-Host "`n⚠️ ATENÇÃO: Alguns comandos falharam!" -ForegroundColor Yellow
    Write-Host "   Recomendação: Execute manualmente via Supabase SQL Editor" -ForegroundColor Yellow
    Write-Host "   URL: https://supabase.com/dashboard/project/vnlfgnfaortdvmraoapq/sql" -ForegroundColor Blue
    Write-Host "`n   📋 Cole o conteúdo de: $SQL_FILE" -ForegroundColor Gray
}

Write-Host "`n🔍 VALIDANDO MIGRATION..." -ForegroundColor Cyan

# Testar se a função foi criada corretamente
try {
    Write-Host "`n   Testando RPC com inbox_id = 3..." -ForegroundColor Yellow
    
    $testBody = @{
        p_inbox_id = 3
    } | ConvertTo-Json
    
    $testResponse = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/rest/v1/rpc/get_location_staff_summary" `
        -Method Post `
        -Headers @{
            "apikey" = $ANON_KEY
            "Authorization" = "Bearer $ANON_KEY"
            "Content-Type" = "application/json"
        } `
        -Body $testBody `
        -ErrorAction Stop
    
    Write-Host "`n✅ RPC FUNCIONANDO!" -ForegroundColor Green
    Write-Host "   📍 client_id: $($testResponse[0].client_id)" -ForegroundColor Cyan
    Write-Host "   🏢 location_name: $($testResponse[0].location_name)" -ForegroundColor Cyan
    Write-Host "   👥 total_staff: $($testResponse[0].total_staff)" -ForegroundColor Cyan
    
    if ($testResponse[0].client_id) {
        Write-Host "`n🎉 MIGRATION 013b EXECUTADA COM SUCESSO!" -ForegroundColor Green
        Write-Host "   🔒 Campo client_id está presente e funcional!" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️ ATENÇÃO: RPC funcionando mas client_id não retornado!" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "`n❌ ERRO AO TESTAR RPC!" -ForegroundColor Red
    Write-Host "   Mensagem: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`n   ⚠️ A migration precisa ser executada MANUALMENTE!" -ForegroundColor Yellow
    Write-Host "   📝 Siga estas instruções:" -ForegroundColor Yellow
    Write-Host "   1. Acesse: https://supabase.com/dashboard/project/vnlfgnfaortdvmraoapq/sql" -ForegroundColor Blue
    Write-Host "   2. Cole o conteúdo de: $SQL_FILE" -ForegroundColor Gray
    Write-Host "   3. Clique em Run (Ctrl+Enter)" -ForegroundColor Gray
}

Write-Host "`n" + ("=" * 80) -ForegroundColor Gray
Write-Host "✨ Script finalizado!" -ForegroundColor Cyan
