# ============================================================================
# EXECUTAR MIGRATIONS VIA CONEXÃO POSTGRESQL DIRETA
# ============================================================================

param(
    [string]$PgHost = "db.vnlfgnfaortdvmraoapq.supabase.co",
    [string]$PgPort = "5432",
    [string]$PgDatabase = "postgres",
    [string]$PgUsername = "postgres",
    [string]$PgPassword = "B1S89OpAO4o4YmHhI7nsSGQd5APBAA"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 EXECUTANDO MIGRATIONS NO SUPABASE (PostgreSQL Direto)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se psql está instalado
try {
    $psqlVersion = psql --version 2>$null
    Write-Host "✅ PostgreSQL Client: $psqlVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ PostgreSQL client (psql) não encontrado!" -ForegroundColor Red
    Write-Host "   Instale: https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Criar connection string
$env:PGPASSWORD = $PgPassword

Write-Host "🔌 Testando conexão..." -ForegroundColor Yellow

# Testar conexão
try {
    $testQuery = "SELECT version();"
    $result = psql -h $PgHost -p $PgPort -U $PgUsername -d $PgDatabase -c $testQuery -t 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Conexão OK!" -ForegroundColor Green
        Write-Host "   $($result.Trim())" -ForegroundColor Gray
    }
    else {
        Write-Host "❌ Erro de conexão!" -ForegroundColor Red
        Write-Host "   $result" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "❌ Erro ao testar conexão: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Função para executar SQL file
function Invoke-PostgreSQLFile {
    param(
        [string]$SqlFile,
        [string]$Description
    )
    
    Write-Host "📝 $Description" -ForegroundColor Yellow
    Write-Host "   Arquivo: $SqlFile"
    
    if (-not (Test-Path $SqlFile)) {
        Write-Host "   ❌ Arquivo não encontrado!" -ForegroundColor Red
        return $false
    }
    
    try {
        # Executar arquivo SQL
        $output = psql -h $PgHost -p $PgPort -U $PgUsername -d $PgDatabase -f $SqlFile 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Executado com sucesso!" -ForegroundColor Green
            
            # Mostrar output se tiver (resultados de SELECT)
            if ($output) {
                $output | ForEach-Object {
                    if ($_ -match "✅|❌|⚠️") {
                        Write-Host "   $_" -ForegroundColor Cyan
                    }
                }
            }
            
            return $true
        }
        else {
            Write-Host "   ❌ ERRO na execução!" -ForegroundColor Red
            Write-Host "   $output" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "   ❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# EXECUTAR MIGRATIONS NA ORDEM
# ============================================================================

Write-Host "1️⃣ FIX ENCODING + LOCATIONS" -ForegroundColor Cyan
Write-Host ""

$success1 = Invoke-PostgreSQLFile `
    -SqlFile "database/FIX-ENCODING-AND-LOCATIONS.sql" `
    -Description "Corrigir encoding e adicionar locations"

Write-Host ""
Start-Sleep -Seconds 2

Write-Host "2️⃣ MIGRATION 015 - BLINDAGEM MÍDIA" -ForegroundColor Cyan
Write-Host ""

$success2 = Invoke-PostgreSQLFile `
    -SqlFile "database/migrations/015_blindagem_total_media.sql" `
    -Description "Blindar mídia contra cross-tenant"

Write-Host ""
Start-Sleep -Seconds 2

Write-Host "3️⃣ MIGRATION 016 - ISOLAMENTO TOTAL" -ForegroundColor Cyan
Write-Host ""

$success3 = Invoke-PostgreSQLFile `
    -SqlFile "database/migrations/016_isolamento_total_multi_tenant.sql" `
    -Description "Isolamento total multi-tenant"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "📊 RESUMO DA EXECUÇÃO" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

if ($success1) { 
    Write-Host "✅ FIX Encoding + Locations: OK" -ForegroundColor Green 
} else { 
    Write-Host "❌ FIX Encoding + Locations: FALHOU" -ForegroundColor Red 
}

if ($success2) { 
    Write-Host "✅ Migration 015: OK" -ForegroundColor Green 
} else { 
    Write-Host "❌ Migration 015: FALHOU" -ForegroundColor Red 
}

if ($success3) { 
    Write-Host "✅ Migration 016: OK" -ForegroundColor Green 
} else { 
    Write-Host "❌ Migration 016: FALHOU" -ForegroundColor Red 
}

Write-Host ""

if ($success1 -and $success2 -and $success3) {
    Write-Host "🎉 TODAS AS MIGRATIONS EXECUTADAS COM SUCESSO!" -ForegroundColor Green
    Write-Host ""
    Write-Host "⏭️  PRÓXIMOS PASSOS:" -ForegroundColor Yellow
    Write-Host "1. Upload dos arquivos da Bella no Storage"
    Write-Host "2. Executar INSERT-BELLA-MEDIA.sql"
    Write-Host "3. Testar no WhatsApp"
    Write-Host ""
    Write-Host "🔍 VALIDAR INTEGRIDADE:" -ForegroundColor Yellow
    Write-Host "   psql -h $PgHost -p $PgPort -U $PgUsername -d $PgDatabase -c ""SELECT * FROM validate_tenant_isolation();"""
} else {
    Write-Host "⚠️  ALGUMAS MIGRATIONS FALHARAM" -ForegroundColor Red
    Write-Host "Verifique os erros acima e tente novamente."
}

Write-Host ""

# Limpar senha do ambiente
Remove-Item Env:PGPASSWORD
