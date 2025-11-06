# ============================================================================
# SCRIPT: Executar Migration 001 - Tabela AGENTS
# Data: 06/11/2025
# Descrição: Aplica migration para suportar múltiplos agentes por cliente
# ============================================================================

# Cores para output
function Write-Success { param($msg) Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Error { param($msg) Write-Host "❌ $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "ℹ️  $msg" -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  MIGRATION 001: Tabela AGENTS" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

# ============================================================================
# PASSO 1: Verificar credenciais Supabase
# ============================================================================

Write-Info "Verificando credenciais do Supabase..."

# Você precisa definir essas variáveis de ambiente ou editar aqui:
$SUPABASE_PROJECT_ID = $env:SUPABASE_PROJECT_ID
$SUPABASE_DB_PASSWORD = $env:SUPABASE_DB_PASSWORD

if (-not $SUPABASE_PROJECT_ID) {
    Write-Warning "SUPABASE_PROJECT_ID não encontrado!"
    Write-Host "`nDefina as variáveis de ambiente ou edite este script:" -ForegroundColor Yellow
    Write-Host "  `$env:SUPABASE_PROJECT_ID = 'seu-projeto-id'" -ForegroundColor Yellow
    Write-Host "  `$env:SUPABASE_DB_PASSWORD = 'sua-senha-db'" -ForegroundColor Yellow
    Write-Host "`nOu execute:" -ForegroundColor Yellow
    Write-Host "  `$SUPABASE_PROJECT_ID = 'n8n-evolute'  # Seu projeto" -ForegroundColor Cyan
    Write-Host "  `$SUPABASE_DB_PASSWORD = Read-Host -AsSecureString 'Senha do DB'" -ForegroundColor Cyan
    exit 1
}

# Construir connection string
$DB_HOST = "db.$SUPABASE_PROJECT_ID.supabase.co"
$DB_PORT = "5432"
$DB_NAME = "postgres"
$DB_USER = "postgres"

Write-Success "Credenciais encontradas!"
Write-Info "Host: $DB_HOST"
Write-Info "Database: $DB_NAME"

# ============================================================================
# PASSO 2: Verificar PostgreSQL Client (psql)
# ============================================================================

Write-Info "`nVerificando instalação do PostgreSQL client..."

$psqlPath = Get-Command psql -ErrorAction SilentlyContinue

if (-not $psqlPath) {
    Write-Error "PostgreSQL client (psql) não encontrado!"
    Write-Host "`nInstale o PostgreSQL:" -ForegroundColor Yellow
    Write-Host "  1. Download: https://www.postgresql.org/download/windows/" -ForegroundColor Cyan
    Write-Host "  2. Ou via Chocolatey: choco install postgresql" -ForegroundColor Cyan
    Write-Host "  3. Ou via Scoop: scoop install postgresql" -ForegroundColor Cyan
    
    Write-Host "`nAlternativamente, use a UI do Supabase:" -ForegroundColor Yellow
    Write-Host "  1. Acesse: https://supabase.com/dashboard/project/$SUPABASE_PROJECT_ID/editor" -ForegroundColor Cyan
    Write-Host "  2. Vá em SQL Editor" -ForegroundColor Cyan
    Write-Host "  3. Cole o conteúdo de: database/migrations/001_add_agents_table.sql" -ForegroundColor Cyan
    Write-Host "  4. Execute (RUN)" -ForegroundColor Cyan
    exit 1
}

Write-Success "psql encontrado: $($psqlPath.Source)"

# ============================================================================
# PASSO 3: Teste de Conexão
# ============================================================================

Write-Info "`nTestando conexão com Supabase..."

$env:PGPASSWORD = $SUPABASE_DB_PASSWORD

$testQuery = "SELECT version();"
$testResult = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $testQuery -t 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha ao conectar no Supabase!"
    Write-Host "`nErro: $testResult" -ForegroundColor Red
    Write-Host "`nVerifique:" -ForegroundColor Yellow
    Write-Host "  1. Senha do database está correta" -ForegroundColor Cyan
    Write-Host "  2. Project ID está correto: $SUPABASE_PROJECT_ID" -ForegroundColor Cyan
    Write-Host "  3. Firewall/VPN não está bloqueando" -ForegroundColor Cyan
    exit 1
}

Write-Success "Conexão bem-sucedida!"
Write-Info "PostgreSQL version: $($testResult.Trim())"

# ============================================================================
# PASSO 4: Backup Pré-Migration (Segurança)
# ============================================================================

Write-Info "`nCriando backup das tabelas afetadas..."

$backupDir = ".\database\backups"
$backupFile = "$backupDir\pre-migration-001_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"

if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

Write-Info "Fazendo dump de: clients, rag_documents, agent_executions, channels"

$backupQuery = @"
-- Backup Pre-Migration 001
-- Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

-- Clients
COPY (SELECT * FROM public.clients) TO STDOUT WITH CSV HEADER;

-- RAG Documents
COPY (SELECT client_id, rag_namespace, COUNT(*) as doc_count FROM public.rag_documents GROUP BY client_id, rag_namespace) TO STDOUT WITH CSV HEADER;

-- Agent Executions (últimos 7 dias)
COPY (SELECT client_id, COUNT(*) as exec_count FROM public.agent_executions WHERE created_at > NOW() - INTERVAL '7 days' GROUP BY client_id) TO STDOUT WITH CSV HEADER;
"@

$backupQuery | psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME > $backupFile 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Success "Backup criado: $backupFile"
} else {
    Write-Warning "Backup falhou (mas continuando...)"
}

# ============================================================================
# PASSO 5: Verificar Pré-Condições
# ============================================================================

Write-Info "`nVerificando pré-condições..."

# Verificar se tabela agents já existe
$checkAgentsQuery = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'agents';"
$agentsExists = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $checkAgentsQuery -t 2>&1

if ($agentsExists.Trim() -eq "1") {
    Write-Warning "Tabela 'agents' já existe!"
    Write-Host "`nDeseja continuar? (isso pode causar erro se migration já foi executada)" -ForegroundColor Yellow
    $continue = Read-Host "Continuar? (s/N)"
    if ($continue -ne "s") {
        Write-Info "Migration cancelada."
        exit 0
    }
}

# Contar clientes existentes
$clientCountQuery = "SELECT COUNT(*) FROM public.clients;"
$clientCount = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $clientCountQuery -t 2>&1

Write-Info "Clientes existentes: $($clientCount.Trim())"

if ($clientCount.Trim() -eq "0") {
    Write-Warning "Nenhum cliente encontrado. Migration criará estrutura vazia."
}

# ============================================================================
# PASSO 6: EXECUTAR MIGRATION
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  EXECUTANDO MIGRATION" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

$migrationFile = ".\database\migrations\001_add_agents_table.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Error "Arquivo de migration não encontrado: $migrationFile"
    exit 1
}

Write-Info "Arquivo: $migrationFile"
Write-Info "Linhas: $((Get-Content $migrationFile).Count)"

Write-Host "`nEsta migration irá:" -ForegroundColor Yellow
Write-Host "  1. Criar tabela 'agents'" -ForegroundColor Cyan
Write-Host "  2. Adicionar 7 índices" -ForegroundColor Cyan
Write-Host "  3. Migrar dados de 'clients' → 'agents' (criar agente 'default' para cada cliente)" -ForegroundColor Cyan
Write-Host "  4. Atualizar tabelas: rag_documents, agent_executions, channels, rate_limit_buckets" -ForegroundColor Cyan
Write-Host "  5. Adicionar campo 'max_agents' em clients" -ForegroundColor Cyan
Write-Host "`n⚠️  ATENÇÃO: Isso modifica o schema do banco de dados!`n" -ForegroundColor Red

$confirm = Read-Host "Confirma execução da migration? (s/N)"

if ($confirm -ne "s") {
    Write-Info "Migration cancelada pelo usuário."
    exit 0
}

Write-Info "`nExecutando migration..."
Write-Host "─────────────────────────────────────────" -ForegroundColor Gray

# Executar migration
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f $migrationFile

if ($LASTEXITCODE -ne 0) {
    Write-Error "`nMigration FALHOU!"
    Write-Host "`nVerifique os erros acima." -ForegroundColor Red
    Write-Host "Para rollback, execute:" -ForegroundColor Yellow
    Write-Host "  psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c 'DROP TABLE IF EXISTS public.agents CASCADE;'" -ForegroundColor Cyan
    exit 1
}

Write-Host "─────────────────────────────────────────" -ForegroundColor Gray
Write-Success "`nMigration EXECUTADA COM SUCESSO! 🎉"

# ============================================================================
# PASSO 7: Validação Pós-Migration
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  VALIDAÇÃO PÓS-MIGRATION" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

# 1. Verificar tabela agents criada
Write-Info "1. Verificando tabela 'agents'..."
$agentsCountQuery = "SELECT COUNT(*) FROM public.agents;"
$agentsCount = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $agentsCountQuery -t 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Success "Tabela 'agents' criada! Registros: $($agentsCount.Trim())"
} else {
    Write-Error "Erro ao verificar tabela 'agents'"
}

# 2. Listar agentes criados
Write-Info "`n2. Listando agentes criados..."
$listAgentsQuery = "SELECT client_id, agent_id, agent_name, package FROM public.agents ORDER BY client_id, agent_id;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $listAgentsQuery

# 3. Verificar campo max_agents
Write-Info "`n3. Verificando campo 'max_agents' em clients..."
$maxAgentsQuery = "SELECT client_id, max_agents FROM public.clients LIMIT 5;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $maxAgentsQuery

# 4. Verificar FKs
Write-Info "`n4. Verificando Foreign Keys..."
$fkQuery = @"
SELECT 
  COUNT(*) as agents_orphaned
FROM public.agents a
WHERE NOT EXISTS (SELECT 1 FROM public.clients c WHERE c.client_id = a.client_id);
"@
$orphans = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $fkQuery -t 2>&1

if ($orphans.Trim() -eq "0") {
    Write-Success "Nenhum agente órfão encontrado!"
} else {
    Write-Warning "ATENÇÃO: $($orphans.Trim()) agentes órfãos!"
}

# ============================================================================
# PASSO 8: Próximos Passos
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  MIGRATION COMPLETA! 🎉" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

Write-Success "Tabela 'agents' criada e populada com sucesso!"

Write-Host "`n📋 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "  1. Atualizar workflows n8n para usar 'agents' ao invés de 'clients'" -ForegroundColor Cyan
Write-Host "  2. Configurar Chatwoot com custom attribute 'agent_id'" -ForegroundColor Cyan
Write-Host "  3. Criar novos agentes para clientes existentes (se necessário)" -ForegroundColor Cyan
Write-Host "  4. Testar roteamento multi-agente" -ForegroundColor Cyan

Write-Host "`n🔧 QUERIES ÚTEIS:" -ForegroundColor Yellow
Write-Host "  # Listar agentes de um cliente" -ForegroundColor Gray
Write-Host "  SELECT * FROM agents WHERE client_id = 'acme-corp';" -ForegroundColor Cyan

Write-Host "`n  # Criar novo agente" -ForegroundColor Gray
Write-Host "  INSERT INTO agents (client_id, agent_id, agent_name, package, system_prompt, rag_namespace)" -ForegroundColor Cyan
Write-Host "  VALUES ('acme-corp', 'sdr', 'Agente SDR', 'sdr', 'Você é...', 'acme-corp/sdr');" -ForegroundColor Cyan

Write-Host "`n  # Verificar isolamento de dados" -ForegroundColor Gray
Write-Host "  SELECT agent_id, COUNT(*) FROM rag_documents WHERE client_id = 'acme-corp' GROUP BY agent_id;" -ForegroundColor Cyan

Write-Host "`n✅ Migration 001 finalizada com sucesso!`n" -ForegroundColor Green

# Limpar senha do ambiente
Remove-Item env:PGPASSWORD -ErrorAction SilentlyContinue
