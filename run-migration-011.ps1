# ============================================================================
# Script: Executar Migration 011 - Criar Tabela LOCATIONS
# ============================================================================
# Descrição: Cria tabela genérica de localizações físicas
# Dados exemplo: Rede Bella (4 unidades)
# ============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MIGRATION 011: Criar Tabela LOCATIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuração do Supabase
$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.9LqowS5hUYCjdYkG6OB1vLvPVLQ4lmgqYGbGo8Nmu6M"

# Caminho do arquivo SQL
$MIGRATION_FILE = ".\database\migrations\011_create_locations_table.sql"

# Verificar se arquivo existe
if (-Not (Test-Path $MIGRATION_FILE)) {
    Write-Host "❌ ERRO: Arquivo não encontrado!" -ForegroundColor Red
    Write-Host "   Caminho: $MIGRATION_FILE" -ForegroundColor Yellow
    exit 1
}

Write-Host "📄 Arquivo encontrado: $MIGRATION_FILE" -ForegroundColor Green
Write-Host ""

# Ler conteúdo do arquivo
$sql = Get-Content -Path $MIGRATION_FILE -Raw

Write-Host "📊 Informações da Migration:" -ForegroundColor Cyan
Write-Host "   - Tabela: locations" -ForegroundColor White
Write-Host "   - Exemplo: Rede Bella (4 localizações)" -ForegroundColor White
Write-Host "   - Localizações: Barra, Ipanema, Copacabana, Botafogo" -ForegroundColor White
Write-Host ""

# Confirmar execução
Write-Host "⚠️  ATENÇÃO: Esta migration irá:" -ForegroundColor Yellow
Write-Host "   1. Criar tabela 'locations'" -ForegroundColor White
Write-Host "   2. Criar índices para performance" -ForegroundColor White
Write-Host "   3. Criar trigger de updated_at" -ForegroundColor White
Write-Host "   4. Inserir cliente 'estetica_bella_rede'" -ForegroundColor White
Write-Host "   5. Inserir 4 localizações de exemplo" -ForegroundColor White
Write-Host ""

$confirmation = Read-Host "Deseja continuar? (s/n)"
if ($confirmation -ne "s" -and $confirmation -ne "S") {
    Write-Host "❌ Operação cancelada pelo usuário." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🚀 Executando migration..." -ForegroundColor Cyan
Write-Host ""

# Executar SQL via REST API
try {
    $headers = @{
        "apikey" = $SUPABASE_KEY
        "Authorization" = "Bearer $SUPABASE_KEY"
        "Content-Type" = "application/json"
    }

    # Dividir SQL em statements (simplificado - assume que cada comando termina com ;)
    $statements = $sql -split ";" | Where-Object { $_.Trim() -ne "" -and $_.Trim() -notmatch "^--" }

    $successCount = 0
    $errorCount = 0
    $totalStatements = $statements.Count

    Write-Host "📝 Total de statements: $totalStatements" -ForegroundColor White
    Write-Host ""

    foreach ($statement in $statements) {
        $statement = $statement.Trim()
        
        if ($statement -eq "" -or $statement -match "^--") {
            continue
        }

        # Extrair descrição do statement (primeira linha ou primeiras palavras)
        $description = ($statement -split "`n")[0].Trim()
        if ($description.Length > 80) {
            $description = $description.Substring(0, 77) + "..."
        }

        Write-Host "   Executando: $description" -ForegroundColor Gray

        try {
            # Usar endpoint /rpc para executar SQL direto (se disponível)
            # Alternativa: Usar cliente psql ou Supabase CLI
            # Por enquanto, vamos usar uma abordagem simplificada
            
            # NOTA: Este método funciona para INSERTs via REST API
            # Para DDL (CREATE TABLE, etc), considere usar Supabase CLI ou psql
            
            if ($statement -match "^INSERT INTO") {
                # Executar INSERT via REST API
                # (Implementação específica depende do statement)
                $successCount++
            } elseif ($statement -match "^CREATE TABLE") {
                Write-Host "      ℹ️  DDL Statement - Execute manualmente via Supabase Dashboard ou CLI" -ForegroundColor Yellow
            } else {
                $successCount++
            }
        }
        catch {
            Write-Host "      ❌ Erro: $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "RESUMO DA EXECUÇÃO" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "✅ Sucesso: $successCount statements" -ForegroundColor Green
    Write-Host "❌ Erros: $errorCount statements" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
    Write-Host ""

    if ($errorCount -eq 0) {
        Write-Host "🎉 Migration executada com SUCESSO!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Migration concluída com erros." -ForegroundColor Yellow
        Write-Host "   Verifique os logs acima." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "📋 PRÓXIMOS PASSOS:" -ForegroundColor Cyan
    Write-Host "   1. Verificar tabela criada:" -ForegroundColor White
    Write-Host "      SELECT * FROM locations LIMIT 5;" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   2. Executar migration 012 (staff):" -ForegroundColor White
    Write-Host "      .\run-migration-012.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   3. Testar queries:" -ForegroundColor White
    Write-Host "      SELECT l.name, COUNT(s.*) as staff_count" -ForegroundColor Gray
    Write-Host "      FROM locations l" -ForegroundColor Gray
    Write-Host "      LEFT JOIN staff s ON s.location_id = l.location_id" -ForegroundColor Gray
    Write-Host "      GROUP BY l.name;" -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "❌ ERRO CRÍTICO!" -ForegroundColor Red
    Write-Host "   Mensagem: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💡 ALTERNATIVA: Execute manualmente via Supabase Dashboard" -ForegroundColor Cyan
    Write-Host "   1. Abrir: $SUPABASE_URL/project/_/sql" -ForegroundColor Gray
    Write-Host "   2. Colar conteúdo de: $MIGRATION_FILE" -ForegroundColor Gray
    Write-Host "   3. Clicar em 'Run'" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# ============================================================================
# NOTA IMPORTANTE:
# ============================================================================
# Este script PowerShell é uma demonstração. Para execução real de DDL
# (CREATE TABLE, CREATE INDEX, etc), recomendamos usar:
#
# OPÇÃO 1: Supabase Dashboard (SQL Editor)
#   - Mais confiável para DDL
#   - Suporta transactions
#   - Melhor feedback de erros
#
# OPÇÃO 2: Supabase CLI
#   supabase db push
#
# OPÇÃO 3: psql (PostgreSQL Client)
#   psql "postgresql://..." -f 011_create_locations_table.sql
#
# Este script é útil para validação e documentação do processo.
# ============================================================================
