# Script para executar Migration 005 - Client Media Tables
# Uso: .\run-migration-005.ps1

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "EXECUTANDO MIGRATION 005: Client Media" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# Connection string do Supabase
$connectionString = "postgresql://postgres.vnlfgnfaortdvmraoapq:SenhaMaster123!@aws-0-us-east-1.pooler.supabase.com:6543/postgres"

# Caminho do arquivo SQL
$sqlFile = Join-Path $PSScriptRoot "migrations\005_add_client_media_tables.sql"

if (-not (Test-Path $sqlFile)) {
    Write-Host "❌ ERRO: Arquivo não encontrado: $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "📄 Arquivo: $sqlFile" -ForegroundColor Yellow
Write-Host "🔗 Conectando ao Supabase...`n" -ForegroundColor Yellow

# Tentar encontrar psql
$psqlPaths = @(
    "psql",
    "C:\Program Files\PostgreSQL\16\bin\psql.exe",
    "C:\Program Files\PostgreSQL\15\bin\psql.exe",
    "C:\Program Files\PostgreSQL\14\bin\psql.exe"
)

$psqlPath = $null
foreach ($path in $psqlPaths) {
    try {
        if (Get-Command $path -ErrorAction SilentlyContinue) {
            $psqlPath = $path
            break
        }
    } catch {
        continue
    }
}

if (-not $psqlPath) {
    Write-Host "❌ ERRO: PostgreSQL psql não encontrado" -ForegroundColor Red
    Write-Host "`nInstale o PostgreSQL de: https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ psql encontrado: $psqlPath`n" -ForegroundColor Green

# Executar migration
try {
    & $psqlPath $connectionString -f $sqlFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n============================================" -ForegroundColor Green
        Write-Host "✅ MIGRATION 005 EXECUTADA COM SUCESSO!" -ForegroundColor Green
        Write-Host "============================================" -ForegroundColor Green
        Write-Host "`nTabelas criadas:" -ForegroundColor Cyan
        Write-Host "  • client_media" -ForegroundColor White
        Write-Host "  • media_send_rules" -ForegroundColor White
        Write-Host "  • media_send_log" -ForegroundColor White
        Write-Host "`nFunctions:" -ForegroundColor Cyan
        Write-Host "  • search_client_media()" -ForegroundColor White
        Write-Host "`nDados de exemplo:" -ForegroundColor Cyan
        Write-Host "  • 3 mídias para clinica_sorriso_001" -ForegroundColor White
        Write-Host "  • 3 regras de envio" -ForegroundColor White
    } else {
        Write-Host "`n❌ ERRO na execução da migration" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "`n❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
