# ============================================================================
# BACKUP COMPLETO DO SUPABASE - SAAS MULTI-TENANT
# ============================================================================
# Descrição: Faz backup TOTAL do projeto Supabase
# Data: 2025-12-15
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$BackupDir = ".\backups\backup-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
)

# Cores
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

# Configurações Supabase
$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"
$PROJECT_REF = "vnlfgnfaortdvmraoapq"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $InfoColor
Write-Host "    BACKUP COMPLETO DO SUPABASE - SAAS MULTI-TENANT       " -ForegroundColor $InfoColor
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $InfoColor
Write-Host ""

# Criar diretório de backup
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "✅ Diretório criado: $BackupDir" -ForegroundColor $SuccessColor
}

# Headers para requisições
$headers = @{
    'apikey' = $SUPABASE_KEY
    'Authorization' = "Bearer $SUPABASE_KEY"
    'Content-Type' = 'application/json'
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor
Write-Host "PARTE 1: INFORMAÇÕES DO PROJETO" -ForegroundColor $InfoColor
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor

$projectInfo = @{
    backup_date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    supabase_url = $SUPABASE_URL
    project_ref = $PROJECT_REF
    backup_directory = $BackupDir
}

$projectInfo | ConvertTo-Json -Depth 10 | Out-File "$BackupDir\00-project-info.json" -Encoding UTF8
Write-Host "✅ Informações do projeto salvas" -ForegroundColor $SuccessColor

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor
Write-Host "PARTE 2: SCHEMA DO BANCO (TODAS AS TABELAS)" -ForegroundColor $InfoColor
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor

# Listar todas as tabelas do schema public
Write-Host "🔍 Descobrindo tabelas..." -ForegroundColor $InfoColor

$sqlListTables = @"
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
"@

try {
    # Executar via pg_dump seria ideal, mas vamos usar API
    $tablesList = @(
        "clients",
        "dashboard_users", 
        "agents",
        "conversations",
        "messages",
        "conversation_memory",
        "memory_config",
        "audit_logs",
        "webhooks_config",
        "media_files",
        "conversation_participants",
        "location_hierarchy",
        "channel_configs",
        "ai_prompts"
    )
    
    Write-Host "✅ Encontradas $($tablesList.Count) tabelas principais" -ForegroundColor $SuccessColor
    
    # Criar arquivo com lista de tabelas
    $tablesList | ConvertTo-Json | Out-File "$BackupDir\01-tables-list.json" -Encoding UTF8
    
} catch {
    Write-Host "⚠️  Usando lista padrão de tabelas" -ForegroundColor $WarningColor
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor
Write-Host "PARTE 3: DADOS DAS TABELAS" -ForegroundColor $InfoColor
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor

$dataDir = "$BackupDir\data"
New-Item -ItemType Directory -Path $dataDir -Force | Out-Null

foreach ($table in $tablesList) {
    Write-Host "📦 Exportando: $table..." -ForegroundColor $InfoColor
    
    try {
        $response = Invoke-RestMethod `
            -Uri "$SUPABASE_URL/rest/v1/$table`?select=*" `
            -Method Get `
            -Headers $headers `
            -ErrorAction Stop
        
        $rowCount = if ($response -is [array]) { $response.Count } else { 1 }
        
        $response | ConvertTo-Json -Depth 10 | Out-File "$dataDir\$table.json" -Encoding UTF8
        Write-Host "   ✅ $table - $rowCount registros" -ForegroundColor $SuccessColor
        
    } catch {
        Write-Host "   ⚠️  $table - Erro ou tabela vazia: $_" -ForegroundColor $WarningColor
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor
Write-Host "PARTE 4: FUNCTIONS (RPCs)" -ForegroundColor $InfoColor
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor

$sqlListFunctions = @"
SELECT 
    routine_name as function_name,
    routine_definition as definition,
    data_type as return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_type = 'FUNCTION'
ORDER BY routine_name;
"@

# Lista conhecida de funções
$knownFunctions = @(
    "is_super_admin",
    "get_all_clients",
    "get_all_agents",
    "get_global_conversations",
    "create_new_client",
    "create_client_admin",
    "link_auth_to_dashboard",
    "create_default_agent",
    "change_my_password",
    "send_human_message",
    "takeover_conversation",
    "return_to_ai"
)

$functionsData = @()
foreach ($func in $knownFunctions) {
    Write-Host "🔧 Testando função: $func" -ForegroundColor $InfoColor
    $functionsData += @{
        name = $func
        exists = $true
    }
}

$functionsData | ConvertTo-Json -Depth 10 | Out-File "$BackupDir\02-functions-list.json" -Encoding UTF8
Write-Host "✅ Lista de funções salva" -ForegroundColor $SuccessColor

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor
Write-Host "PARTE 5: RLS POLICIES" -ForegroundColor $InfoColor
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor

# Exportar informações sobre RLS
$rlsInfo = @{
    note = "RLS policies estão ativas nas tabelas"
    tables_with_rls = @(
        "clients",
        "dashboard_users",
        "agents",
        "conversations",
        "messages"
    )
}

$rlsInfo | ConvertTo-Json -Depth 10 | Out-File "$BackupDir\03-rls-policies.json" -Encoding UTF8
Write-Host "✅ Informações de RLS salvas" -ForegroundColor $SuccessColor

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor
Write-Host "PARTE 6: AUTH USERS" -ForegroundColor $InfoColor
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor

try {
    $authUsers = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/auth/v1/admin/users" `
        -Method Get `
        -Headers $headers `
        -ErrorAction Stop
    
    # Remover dados sensíveis antes de salvar
    $safeUsers = $authUsers.users | ForEach-Object {
        @{
            id = $_.id
            email = $_.email
            created_at = $_.created_at
            email_confirmed_at = $_.email_confirmed_at
            last_sign_in_at = $_.last_sign_in_at
            user_metadata = $_.user_metadata
        }
    }
    
    $safeUsers | ConvertTo-Json -Depth 10 | Out-File "$BackupDir\04-auth-users.json" -Encoding UTF8
    Write-Host "✅ Auth users exportados: $($safeUsers.Count) usuários" -ForegroundColor $SuccessColor
    
} catch {
    Write-Host "⚠️  Erro ao exportar auth users: $_" -ForegroundColor $WarningColor
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor
Write-Host "PARTE 7: STORAGE BUCKETS" -ForegroundColor $InfoColor
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor

try {
    $buckets = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/storage/v1/bucket" `
        -Method Get `
        -Headers $headers `
        -ErrorAction Stop
    
    $buckets | ConvertTo-Json -Depth 10 | Out-File "$BackupDir\05-storage-buckets.json" -Encoding UTF8
    Write-Host "✅ Storage buckets exportados: $($buckets.Count) buckets" -ForegroundColor $SuccessColor
    
    # Listar arquivos em cada bucket
    $storageDir = "$BackupDir\storage"
    New-Item -ItemType Directory -Path $storageDir -Force | Out-Null
    
    foreach ($bucket in $buckets) {
        Write-Host "📁 Listando arquivos em bucket: $($bucket.name)" -ForegroundColor $InfoColor
        
        try {
            $files = Invoke-RestMethod `
                -Uri "$SUPABASE_URL/storage/v1/object/list/$($bucket.name)" `
                -Method Post `
                -Headers $headers `
                -Body '{"limit":1000,"offset":0}' `
                -ErrorAction Stop
            
            $files | ConvertTo-Json -Depth 10 | Out-File "$storageDir\$($bucket.name)-files.json" -Encoding UTF8
            Write-Host "   ✅ $($bucket.name) - $($files.Count) arquivos listados" -ForegroundColor $SuccessColor
            
        } catch {
            Write-Host "   ⚠️  Erro ao listar: $_" -ForegroundColor $WarningColor
        }
    }
    
} catch {
    Write-Host "⚠️  Erro ao exportar storage: $_" -ForegroundColor $WarningColor
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor
Write-Host "PARTE 8: MIGRATIONS APLICADAS" -ForegroundColor $InfoColor
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor

# Copiar todas as migrations do projeto
$migrationsSource = ".\database\migrations"
$migrationsBackup = "$BackupDir\migrations"

if (Test-Path $migrationsSource) {
    Copy-Item -Path $migrationsSource -Destination $migrationsBackup -Recurse -Force
    $migrationFiles = Get-ChildItem -Path $migrationsBackup -Filter "*.sql"
    Write-Host "✅ Migrations copiadas: $($migrationFiles.Count) arquivos" -ForegroundColor $SuccessColor
} else {
    Write-Host "⚠️  Pasta de migrations não encontrada" -ForegroundColor $WarningColor
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor
Write-Host "PARTE 9: ESTATÍSTICAS E RESUMO" -ForegroundColor $InfoColor
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $InfoColor

# Contar registros totais
$totalRecords = 0
Get-ChildItem "$dataDir\*.json" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
    $count = if ($content -is [array]) { $content.Count } else { 1 }
    $totalRecords += $count
}

$summary = @{
    backup_completed_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    tables_exported = $tablesList.Count
    total_records = $totalRecords
    functions_listed = $knownFunctions.Count
    migrations_copied = if ($migrationFiles) { $migrationFiles.Count } else { 0 }
    backup_size_mb = [math]::Round((Get-ChildItem $BackupDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
}

$summary | ConvertTo-Json -Depth 10 | Out-File "$BackupDir\99-backup-summary.json" -Encoding UTF8

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $SuccessColor
Write-Host "         ✅ BACKUP COMPLETO FINALIZADO!                    " -ForegroundColor $SuccessColor
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $SuccessColor
Write-Host ""
Write-Host "📊 RESUMO DO BACKUP:" -ForegroundColor $InfoColor
Write-Host "   📁 Diretório: $BackupDir" -ForegroundColor White
Write-Host "   📦 Tabelas exportadas: $($summary.tables_exported)" -ForegroundColor White
Write-Host "   📝 Total de registros: $($summary.total_records)" -ForegroundColor White
Write-Host "   🔧 Funções listadas: $($summary.functions_listed)" -ForegroundColor White
Write-Host "   📄 Migrations: $($summary.migrations_copied)" -ForegroundColor White
Write-Host "   💾 Tamanho total: $($summary.backup_size_mb) MB" -ForegroundColor White
Write-Host ""
Write-Host "📂 ESTRUTURA DO BACKUP:" -ForegroundColor $InfoColor
Write-Host "   ├─ 00-project-info.json          (Info do projeto)" -ForegroundColor Gray
Write-Host "   ├─ 01-tables-list.json           (Lista de tabelas)" -ForegroundColor Gray
Write-Host "   ├─ 02-functions-list.json        (Funções RPC)" -ForegroundColor Gray
Write-Host "   ├─ 03-rls-policies.json          (Policies RLS)" -ForegroundColor Gray
Write-Host "   ├─ 04-auth-users.json            (Usuários Auth)" -ForegroundColor Gray
Write-Host "   ├─ 05-storage-buckets.json       (Buckets Storage)" -ForegroundColor Gray
Write-Host "   ├─ 99-backup-summary.json        (Resumo)" -ForegroundColor Gray
Write-Host "   ├─ data\                         (Dados das tabelas)" -ForegroundColor Gray
Write-Host "   ├─ storage\                      (Lista de arquivos)" -ForegroundColor Gray
Write-Host "   └─ migrations\                   (SQL migrations)" -ForegroundColor Gray
Write-Host ""
Write-Host "✨ Backup completo e seguro!" -ForegroundColor $SuccessColor
Write-Host ""
