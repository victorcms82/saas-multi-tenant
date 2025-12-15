# ============================================================================
# Script para executar Migration 013: RPCs Location Detection
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🚀 MIGRATION 013: RPCs Location Detection" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Ler SQL da migration
$migrationPath = ".\database\migrations\013_create_rpc_location_detection.sql"
if (-not (Test-Path $migrationPath)) {
    Write-Host "❌ Arquivo não encontrado: $migrationPath" -ForegroundColor Red
    exit 1
}

$sql = Get-Content $migrationPath -Raw -Encoding UTF8

Write-Host "📄 SQL carregado: $(($sql -split "`n").Count) linhas`n" -ForegroundColor Green

Write-Host "📋 Funções que serão criadas:" -ForegroundColor White
Write-Host "  1. get_location_by_inbox(inbox_id)" -ForegroundColor Yellow
Write-Host "  2. get_staff_by_location(location_id, service?, include_unavailable?)" -ForegroundColor Yellow
Write-Host "  3. get_available_slots(staff_id, date?)" -ForegroundColor Yellow
Write-Host "  4. get_location_staff_summary(inbox_id)" -ForegroundColor Yellow

Write-Host "`n⚡ Copie o SQL abaixo e execute no Supabase Dashboard (SQL Editor):`n" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor DarkGray

# Copiar para clipboard
$sql | Set-Clipboard
Write-Host "✅ SQL copiado para área de transferência!" -ForegroundColor Green

Write-Host "`n🎯 PRÓXIMOS PASSOS:" -ForegroundColor Cyan
Write-Host "  1. Abra o Supabase Dashboard" -ForegroundColor White
Write-Host "  2. Vá em SQL Editor" -ForegroundColor White
Write-Host "  3. Cole o SQL (Ctrl+V)" -ForegroundColor White
Write-Host "  4. Execute (Run)" -ForegroundColor White
Write-Host "  5. Teste as funções com as queries de validação" -ForegroundColor White

Write-Host "`n📊 TESTE RÁPIDO (após executar):" -ForegroundColor Cyan
Write-Host "  SELECT * FROM get_staff_by_location('bella_barra_001');" -ForegroundColor Yellow

Write-Host "`n========================================`n" -ForegroundColor DarkGray
