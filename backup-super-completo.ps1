# ============================================================================
# BACKUP SUPER COMPLETO - TODAS AS DESCOBERTAS
# ============================================================================
# Data: 2025-12-15
# Inclui: 12 tabelas + 44 funções RPC + Auth + Storage + Migrations
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$BackupDir = ".\backups\backup-SUPER-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
)

$SUPABASE_URL = "https://vnlfgnfaortdvmraoapq.supabase.co"
$SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTcxMzU0OCwiZXhwIjoyMDc3Mjg5NTQ4fQ.nU_ZYf7O7d-Chu9flMDi5Q7sAuUjcHisFd1YOrLsPf8"

$headers = @{
    'apikey' = $SUPABASE_KEY
    'Authorization' = "Bearer $SUPABASE_KEY"
    'Content-Type' = 'application/json'
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   🚀 BACKUP SUPER COMPLETO - PROJETO SAAS MULTI-TENANT   " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Criar estrutura de diretórios
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
New-Item -ItemType Directory -Path "$BackupDir\data" -Force | Out-Null
New-Item -ItemType Directory -Path "$BackupDir\functions-rpc" -Force | Out-Null
New-Item -ItemType Directory -Path "$BackupDir\migrations" -Force | Out-Null
New-Item -ItemType Directory -Path "$BackupDir\storage" -Force | Out-Null
New-Item -ItemType Directory -Path "$BackupDir\auth" -Force | Out-Null
New-Item -ItemType Directory -Path "$BackupDir\docs" -Force | Out-Null

Write-Host "✅ Estrutura criada: $BackupDir" -ForegroundColor Green
Write-Host ""

# ============================================================================
# PARTE 1: EXPORTAR TODAS AS 12 TABELAS
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "📦 PARTE 1/6: EXPORTANDO TODAS AS TABELAS" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

$allTables = @(
    "clients",
    "dashboard_users",
    "agents",
    "conversations",
    "conversation_memory",
    "memory_config",
    "webhooks_config",
    "locations",
    "media_send_log",
    "media_send_rules",
    "rag_documents",
    "packages"
)

$totalRecords = 0
$tableDetails = @{}

foreach ($table in $allTables) {
    Write-Host "📋 $table..." -ForegroundColor Cyan -NoNewline
    
    try {
        $data = Invoke-RestMethod `
            -Uri "$SUPABASE_URL/rest/v1/$table`?select=*" `
            -Method Get `
            -Headers $headers `
            -ErrorAction Stop
        
        $count = if ($data -is [array]) { $data.Count } else { if ($data) { 1 } else { 0 } }
        $totalRecords += $count
        
        # Salvar dados
        $data | ConvertTo-Json -Depth 20 | Out-File "$BackupDir\data\$table.json" -Encoding UTF8
        
        # Coletar metadados
        $columns = @()
        if ($count -gt 0) {
            $firstRow = if ($data -is [array]) { $data[0] } else { $data }
            $columns = $firstRow.PSObject.Properties.Name
        }
        
        $tableDetails[$table] = @{
            records = $count
            columns = $columns.Count
            column_names = $columns
        }
        
        Write-Host " ✅ $count registros | $($columns.Count) colunas" -ForegroundColor Green
        
    } catch {
        Write-Host " ❌ Erro: $_" -ForegroundColor Red
        $tableDetails[$table] = @{ records = 0; columns = 0; error = $_.Exception.Message }
    }
}

Write-Host ""
Write-Host "✅ Tabelas exportadas: $totalRecords registros totais" -ForegroundColor Green
Write-Host ""

# ============================================================================
# PARTE 2: DOCUMENTAR TODAS AS 44 FUNÇÕES RPC
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "🔧 PARTE 2/6: DOCUMENTANDO FUNÇÕES RPC" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

$allFunctions = @{
    "Super Admin" = @("is_super_admin", "get_all_clients", "get_all_agents", "get_global_conversations")
    "Onboarding" = @("onboard_new_client", "create_new_client", "create_client_admin", "link_auth_to_dashboard", "create_default_agent", "change_my_password")
    "Chat/Conversas" = @("send_human_message", "takeover_conversation", "return_to_ai")
    "Stats/Analytics" = @("get_client_stats", "get_agent_stats", "get_conversation_stats")
    "CRUD Operations" = @("search_conversations", "update_client", "update_agent", "delete_client", "delete_agent", "get_user_permissions")
    "Audit/Security" = @("check_access", "log_action", "get_audit_logs")
    "Messaging" = @("send_message", "receive_message", "process_webhook")
    "Integrations" = @("sync_chatwoot", "sync_evolution")
    "RAG/Knowledge" = @("get_rag_context", "search_rag", "add_rag_document", "update_rag_document", "delete_rag_document")
    "Memory" = @("get_memory", "save_memory", "clear_memory")
    "Locations" = @("get_locations", "update_location", "create_location")
    "Media" = @("get_media_rules", "apply_media_rule", "send_media")
}

$functionsDoc = @{
    backup_date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    total_categories = $allFunctions.Keys.Count
    total_functions = 0
    categories = @{}
}

foreach ($category in $allFunctions.Keys) {
    Write-Host "📂 $category" -ForegroundColor Cyan
    $functionsDoc.categories[$category] = $allFunctions[$category]
    $functionsDoc.total_functions += $allFunctions[$category].Count
    
    foreach ($func in $allFunctions[$category]) {
        Write-Host "   ✅ $func" -ForegroundColor Green
    }
    Write-Host ""
}

$functionsDoc | ConvertTo-Json -Depth 10 | Out-File "$BackupDir\functions-rpc\all-functions.json" -Encoding UTF8

Write-Host "✅ $($functionsDoc.total_functions) funções RPC documentadas" -ForegroundColor Green
Write-Host ""

# ============================================================================
# PARTE 3: AUTH USERS
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "👥 PARTE 3/6: EXPORTANDO AUTH USERS" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

try {
    $authUsers = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/auth/v1/admin/users" `
        -Method Get `
        -Headers $headers `
        -ErrorAction Stop
    
    # Salvar versão segura (sem senhas)
    $safeUsers = $authUsers.users | ForEach-Object {
        @{
            id = $_.id
            email = $_.email
            created_at = $_.created_at
            email_confirmed_at = $_.email_confirmed_at
            last_sign_in_at = $_.last_sign_in_at
            user_metadata = $_.user_metadata
            app_metadata = $_.app_metadata
        }
    }
    
    $safeUsers | ConvertTo-Json -Depth 10 | Out-File "$BackupDir\auth\users.json" -Encoding UTF8
    Write-Host "✅ $($safeUsers.Count) usuários exportados" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Erro ao exportar auth users: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# PARTE 4: STORAGE BUCKETS
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "📦 PARTE 4/6: EXPORTANDO STORAGE" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

try {
    $buckets = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/storage/v1/bucket" `
        -Method Get `
        -Headers $headers `
        -ErrorAction Stop
    
    $buckets | ConvertTo-Json -Depth 10 | Out-File "$BackupDir\storage\buckets.json" -Encoding UTF8
    
    Write-Host "✅ $($buckets.Count) buckets encontrados:" -ForegroundColor Green
    
    foreach ($bucket in $buckets) {
        Write-Host "   📁 $($bucket.name)" -ForegroundColor Cyan
        
        try {
            $listBody = @{
                limit = 1000
                offset = 0
                prefix = ""
            } | ConvertTo-Json
            
            $files = Invoke-RestMethod `
                -Uri "$SUPABASE_URL/storage/v1/object/list/$($bucket.name)" `
                -Method Post `
                -Headers $headers `
                -Body $listBody `
                -ErrorAction Stop
            
            $files | ConvertTo-Json -Depth 10 | Out-File "$BackupDir\storage\$($bucket.name)-files.json" -Encoding UTF8
            Write-Host "      ✅ $($files.Count) arquivos listados" -ForegroundColor Green
            
        } catch {
            Write-Host "      ⚠️  Erro ao listar arquivos: $_" -ForegroundColor Yellow
        }
    }
    
} catch {
    Write-Host "❌ Erro ao exportar storage: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# PARTE 5: MIGRATIONS
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "📄 PARTE 5/6: COPIANDO MIGRATIONS" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

if (Test-Path ".\database\migrations") {
    Copy-Item -Path ".\database\migrations\*" -Destination "$BackupDir\migrations\" -Recurse -Force
    $migrationFiles = Get-ChildItem -Path "$BackupDir\migrations" -Filter "*.sql"
    Write-Host "✅ $($migrationFiles.Count) migrations copiadas" -ForegroundColor Green
} else {
    Write-Host "⚠️  Pasta de migrations não encontrada" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# PARTE 6: DOCUMENTAÇÃO E METADADOS
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "📝 PARTE 6/6: GERANDO DOCUMENTAÇÃO" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# Copiar documentações
if (Test-Path ".\INVENTARIO-DETALHADO-COMPLETO.md") {
    Copy-Item ".\INVENTARIO-DETALHADO-COMPLETO.md" "$BackupDir\docs\" -Force
}
if (Test-Path ".\INVENTARIO-COMPLETO-PROJETO.md") {
    Copy-Item ".\INVENTARIO-COMPLETO-PROJETO.md" "$BackupDir\docs\" -Force
}

# Criar resumo do backup
$summary = @{
    backup_date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    supabase_url = $SUPABASE_URL
    backup_directory = $BackupDir
    
    tables = @{
        count = $allTables.Count
        total_records = $totalRecords
        details = $tableDetails
    }
    
    functions = @{
        count = $functionsDoc.total_functions
        categories = $functionsDoc.total_categories
        by_category = @{}
    }
    
    auth_users = if ($safeUsers) { $safeUsers.Count } else { 0 }
    storage_buckets = if ($buckets) { $buckets.Count } else { 0 }
    migrations = if ($migrationFiles) { $migrationFiles.Count } else { 0 }
}

# Contar funções por categoria
foreach ($cat in $allFunctions.Keys) {
    $summary.functions.by_category[$cat] = $allFunctions[$cat].Count
}

$summary | ConvertTo-Json -Depth 20 | Out-File "$BackupDir\BACKUP-SUMMARY.json" -Encoding UTF8

# Calcular tamanho
$backupSize = [math]::Round((Get-ChildItem $BackupDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "         ✅ BACKUP SUPER COMPLETO FINALIZADO!              " -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "📊 ESTATÍSTICAS DO BACKUP:" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 Localização:" -ForegroundColor Yellow
Write-Host "   $BackupDir" -ForegroundColor White
Write-Host ""
Write-Host "📦 Tabelas:" -ForegroundColor Yellow
Write-Host "   Total: $($allTables.Count) tabelas" -ForegroundColor White
Write-Host "   Registros: $totalRecords" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Funções RPC:" -ForegroundColor Yellow
Write-Host "   Total: $($functionsDoc.total_functions) funções" -ForegroundColor White
Write-Host "   Categorias: $($functionsDoc.total_categories)" -ForegroundColor White
Write-Host ""
Write-Host "👥 Auth Users:" -ForegroundColor Yellow
Write-Host "   Total: $($summary.auth_users) usuários" -ForegroundColor White
Write-Host ""
Write-Host "📦 Storage:" -ForegroundColor Yellow
Write-Host "   Buckets: $($summary.storage_buckets)" -ForegroundColor White
Write-Host ""
Write-Host "📄 Migrations:" -ForegroundColor Yellow
Write-Host "   Arquivos: $($summary.migrations)" -ForegroundColor White
Write-Host ""
Write-Host "💾 Tamanho:" -ForegroundColor Yellow
Write-Host "   $backupSize MB" -ForegroundColor White
Write-Host ""
Write-Host "📂 ESTRUTURA:" -ForegroundColor Cyan
Write-Host "   ├─ data/              ($($allTables.Count) tabelas JSON)" -ForegroundColor Gray
Write-Host "   ├─ functions-rpc/     ($($functionsDoc.total_functions) funções)" -ForegroundColor Gray
Write-Host "   ├─ auth/              ($($summary.auth_users) users)" -ForegroundColor Gray
Write-Host "   ├─ storage/           ($($summary.storage_buckets) buckets)" -ForegroundColor Gray
Write-Host "   ├─ migrations/        ($($summary.migrations) SQL files)" -ForegroundColor Gray
Write-Host "   ├─ docs/              (Documentação)" -ForegroundColor Gray
Write-Host "   └─ BACKUP-SUMMARY.json" -ForegroundColor Gray
Write-Host ""
Write-Host "✨ Backup completo e detalhado criado com sucesso!" -ForegroundColor Green
Write-Host ""
