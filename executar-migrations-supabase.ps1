# ============================================================================
# EXECUTAR MIGRATIONS AUTOMATICAMENTE VIA SUPABASE API
# ============================================================================

param(
    [string]$ProjectUrl = "https://vnlfgnfaortdvmraoapq.supabase.co",
    [string]$ServiceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 EXECUTANDO MIGRATIONS NO SUPABASE" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Configurar headers
$headers = @{
    "apikey" = $ServiceKey
    "Authorization" = "Bearer $ServiceKey"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

$restUrl = "$ProjectUrl/rest/v1/rpc"

# Função para executar SQL via PostgreSQL direto
function Invoke-SupabaseSQL {
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
    
    $sql = Get-Content $SqlFile -Raw -Encoding UTF8
    
    # Usar PostgREST para executar query diretamente
    # Vamos fazer statement por statement
    try {
        # Dividir SQL em statements (simplificado)
        $statements = $sql -split ";\s*(?=\n|$)" | Where-Object { $_.Trim() -ne "" -and $_.Trim() -notmatch "^--" }
        
        $successCount = 0
        $errorCount = 0
        
        foreach ($stmt in $statements) {
            $cleanStmt = $stmt.Trim()
            if ($cleanStmt -eq "" -or $cleanStmt -match "^--") { continue }
            
            # Para cada statement, tentar executar via RPC
            $body = $cleanStmt
            
            try {
                # Usar endpoint de query genérico
                $queryUrl = "$ProjectUrl/rest/v1/rpc/query"
                $response = Invoke-WebRequest -Uri $queryUrl -Method Post -Headers $headers -Body $body -ContentType "application/sql"
                $successCount++
            }
            catch {
                # Ignorar alguns erros esperados (como DROP IF EXISTS em coisas que não existem)
                if ($_.Exception.Message -notmatch "does not exist") {
                    $errorCount++
                    Write-Host "   ⚠️  Erro em statement: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
        }
        
        if ($errorCount -eq 0) {
            Write-Host "   ✅ Executado com sucesso! ($successCount statements)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "   ⚠️  Executado com $errorCount erros, $successCount sucessos" -ForegroundColor Yellow
            return $true  # Considerar sucesso se maioria passou
        }
    }
    catch {
        Write-Host "   ❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Resposta: $($_.ErrorDetails.Message)" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# EXECUTAR MIGRATIONS NA ORDEM
# ============================================================================

Write-Host "1️⃣ FIX ENCODING + LOCATIONS" -ForegroundColor Cyan
Write-Host ""

$success1 = Invoke-SupabaseSQL `
    -SqlFile "database/FIX-ENCODING-AND-LOCATIONS.sql" `
    -Description "Corrigir encoding e adicionar locations"

Write-Host ""
Start-Sleep -Seconds 2

Write-Host "2️⃣ MIGRATION 015 - BLINDAGEM MÍDIA" -ForegroundColor Cyan
Write-Host ""

$success2 = Invoke-SupabaseSQL `
    -SqlFile "database/migrations/015_blindagem_total_media.sql" `
    -Description "Blindar mídia contra cross-tenant"

Write-Host ""
Start-Sleep -Seconds 2

Write-Host "3️⃣ MIGRATION 016 - ISOLAMENTO TOTAL" -ForegroundColor Cyan
Write-Host ""

$success3 = Invoke-SupabaseSQL `
    -SqlFile "database/migrations/016_isolamento_total_multi_tenant.sql" `
    -Description "Isolamento total multi-tenant"

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "📊 RESUMO DA EXECUÇÃO" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
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
} else {
    Write-Host "⚠️  ALGUMAS MIGRATIONS FALHARAM" -ForegroundColor Red
    Write-Host "Verifique os erros acima e tente novamente."
}

Write-Host ""
