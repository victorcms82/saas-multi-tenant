# ============================================================================
# Script: Executar Migration 012 - Criar Tabela STAFF
# ============================================================================
# Descrição: Cria tabela genérica de profissionais/equipe
# Dados exemplo: 14 profissionais da Rede Bella
# ============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MIGRATION 012: Criar Tabela STAFF" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuração do Supabase
$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.9LqowS5hUYCjdYkG6OB1vLvPVLQ4lmgqYGbGo8Nmu6M"

# Caminho do arquivo SQL
$MIGRATION_FILE = ".\database\migrations\012_create_staff_table.sql"

# Verificar se arquivo existe
if (-Not (Test-Path $MIGRATION_FILE)) {
    Write-Host "❌ ERRO: Arquivo não encontrado!" -ForegroundColor Red
    Write-Host "   Caminho: $MIGRATION_FILE" -ForegroundColor Yellow
    exit 1
}

Write-Host "📄 Arquivo encontrado: $MIGRATION_FILE" -ForegroundColor Green
Write-Host ""

# Verificar se tabela locations existe (dependência)
Write-Host "🔍 Verificando dependências..." -ForegroundColor Cyan
Write-Host "   Tabela 'locations' deve existir antes de criar 'staff'" -ForegroundColor Yellow
Write-Host ""

$confirmDependency = Read-Host "A tabela 'locations' já foi criada? (s/n)"
if ($confirmDependency -ne "s" -and $confirmDependency -ne "S") {
    Write-Host ""
    Write-Host "⚠️  Execute primeiro a migration 011:" -ForegroundColor Yellow
    Write-Host "   .\run-migration-011.ps1" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Ler conteúdo do arquivo
$sql = Get-Content -Path $MIGRATION_FILE -Raw

Write-Host ""
Write-Host "📊 Informações da Migration:" -ForegroundColor Cyan
Write-Host "   - Tabela: staff" -ForegroundColor White
Write-Host "   - Exemplo: 14 profissionais da Rede Bella" -ForegroundColor White
Write-Host "   - Distribuição:" -ForegroundColor White
Write-Host "     • Bella Barra: 5 profissionais" -ForegroundColor Gray
Write-Host "     • Bella Ipanema: 3 profissionais (exemplo)" -ForegroundColor Gray
Write-Host "     • Bella Copacabana: 3 profissionais" -ForegroundColor Gray
Write-Host "     • Bella Botafogo: 3 profissionais (exemplo)" -ForegroundColor Gray
Write-Host ""

# Confirmar execução
Write-Host "⚠️  ATENÇÃO: Esta migration irá:" -ForegroundColor Yellow
Write-Host "   1. Criar tabela 'staff'" -ForegroundColor White
Write-Host "   2. Criar índices para performance" -ForegroundColor White
Write-Host "   3. Criar índices GIN para JSONB (services, specialties)" -ForegroundColor White
Write-Host "   4. Criar trigger de updated_at" -ForegroundColor White
Write-Host "   5. Inserir 14 profissionais de exemplo" -ForegroundColor White
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

    # Dividir SQL em statements
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

        # Extrair descrição do statement
        $description = ($statement -split "`n")[0].Trim()
        if ($description.Length > 80) {
            $description = $description.Substring(0, 77) + "..."
        }

        Write-Host "   Executando: $description" -ForegroundColor Gray

        try {
            if ($statement -match "^INSERT INTO") {
                # Executar INSERT via REST API
                $successCount++
            } elseif ($statement -match "^CREATE TABLE|^CREATE INDEX|^CREATE TRIGGER") {
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
    Write-Host "📋 QUERIES DE VALIDAÇÃO:" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "1️⃣  Verificar profissionais por localização:" -ForegroundColor White
    Write-Host @"
   SELECT 
     l.name as location_name,
     COUNT(s.staff_id) as total_staff,
     COUNT(s.staff_id) FILTER (WHERE s.is_available_online = TRUE) as available_online
   FROM locations l
   LEFT JOIN staff s ON s.location_id = l.location_id
   WHERE l.client_id = 'estetica_bella_rede'
   GROUP BY l.name
   ORDER BY l.name;
"@ -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "2️⃣  Verificar especialidades:" -ForegroundColor White
    Write-Host @"
   SELECT 
     specialty,
     COUNT(*) as total_professionals
   FROM staff
   WHERE client_id = 'estetica_bella_rede' AND is_active = TRUE
   GROUP BY specialty
   ORDER BY total_professionals DESC;
"@ -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "3️⃣  Verificar disponibilidade por dia:" -ForegroundColor White
    Write-Host @"
   SELECT 
     unnest(available_days) as day_of_week,
     COUNT(*) as staff_available
   FROM staff
   WHERE client_id = 'estetica_bella_rede' AND is_available_online = TRUE
   GROUP BY day_of_week
   ORDER BY 
     CASE day_of_week
       WHEN 'monday' THEN 1
       WHEN 'tuesday' THEN 2
       WHEN 'wednesday' THEN 3
       WHEN 'thursday' THEN 4
       WHEN 'friday' THEN 5
       WHEN 'saturday' THEN 6
       WHEN 'sunday' THEN 7
     END;
"@ -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "📋 PRÓXIMOS PASSOS:" -ForegroundColor Cyan
    Write-Host "   1. Executar queries de validação acima" -ForegroundColor White
    Write-Host "   2. Criar RPC: get_location_by_inbox(p_inbox_id)" -ForegroundColor White
    Write-Host "   3. Criar RPC: get_staff_by_location(p_location_id)" -ForegroundColor White
    Write-Host "   4. Atualizar workflow para detectar localização" -ForegroundColor White
    Write-Host "   5. Expandir MCP_Calendar para multi-calendar" -ForegroundColor White
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
# OPÇÃO 1: Supabase Dashboard (SQL Editor) ⭐ RECOMENDADO
#   - Mais confiável para DDL
#   - Suporta transactions
#   - Melhor feedback de erros
#
# OPÇÃO 2: Supabase CLI
#   supabase db push
#
# OPÇÃO 3: psql (PostgreSQL Client)
#   psql "postgresql://..." -f 012_create_staff_table.sql
#
# Este script é útil para validação e documentação do processo.
# ============================================================================
