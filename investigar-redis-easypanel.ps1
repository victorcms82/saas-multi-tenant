# ============================================================================
# INVESTIGAR REDIS - EASYPANEL
# ============================================================================
# Este script conecta no Redis via Easypanel e investiga contaminação de cache
# ============================================================================

# CONFIGURAÇÃO - PREENCHER COM SEUS DADOS
$REDIS_HOST = "SEU_REDIS_HOST"  # Ex: redis.easypanel.io ou 123.45.67.89
$REDIS_PORT = 6379
$REDIS_PASSWORD = "SUA_SENHA_REDIS"  # Pegar no Easypanel → Redis → Settings

# Se Redis está em Docker no Easypanel, pode precisar de SSH:
$SSH_HOST = "SEU_EASYPANEL_HOST"  # Ex: servidor.easypanel.io
$SSH_USER = "root"
$SSH_KEY_PATH = "$env:USERPROFILE\.ssh\id_rsa"  # Ou caminho da sua chave SSH

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🔍 INVESTIGAÇÃO DE REDIS - EASYPANEL" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# ============================================================================
# OPÇÃO 1: Conectar via redis-cli instalado localmente
# ============================================================================
Write-Host "[OPÇÃO 1] Tentando redis-cli local..." -ForegroundColor Yellow

$redisCliExists = Get-Command redis-cli -ErrorAction SilentlyContinue

if ($redisCliExists) {
    Write-Host "✅ redis-cli encontrado localmente!`n" -ForegroundColor Green
    
    # Testar conexão
    Write-Host "📡 Testando conexão com Redis..." -ForegroundColor Cyan
    $testConnection = redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD PING 2>&1
    
    if ($testConnection -match "PONG") {
        Write-Host "✅ Conexão estabelecida!`n" -ForegroundColor Green
        
        # INVESTIGAÇÃO 1: Verificar DB-0 (buffer/queues)
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "📊 INVESTIGANDO DB-0 (Buffer/Queues)" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
        
        redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 0 KEYS "*bella*"
        redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 0 KEYS "*sorriso*"
        redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 0 DBSIZE
        
        # INVESTIGAÇÃO 2: Verificar DB-1 (memory/cache)
        Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "💾 INVESTIGANDO DB-1 (Memory/Cache)" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
        
        $db1Keys = redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 1 KEYS "*"
        
        if ($db1Keys) {
            Write-Host "🔍 Chaves encontradas no DB-1:" -ForegroundColor Yellow
            redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 1 KEYS "*bella*"
            redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 1 KEYS "*sorriso*"
            redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 1 KEYS "*clinica*"
            redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 1 KEYS "*estetica*"
            
            Write-Host "`n📊 Total de chaves no DB-1:" -ForegroundColor Cyan
            redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 1 DBSIZE
            
            # INVESTIGAÇÃO 3: Ver conteúdo de chaves suspeitas
            Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host "🔬 ANALISANDO CONTEÚDO DAS CHAVES" -ForegroundColor Cyan
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
            
            # Buscar chaves que podem ter contaminação
            $suspectKeys = redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 1 KEYS "*context*"
            
            if ($suspectKeys) {
                foreach ($key in $suspectKeys) {
                    Write-Host "🔑 Chave: $key" -ForegroundColor Yellow
                    $value = redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 1 GET $key
                    
                    # Verificar se tem dados de outro cliente
                    if ($value -match "clinica_sorriso" -and $key -match "bella") {
                        Write-Host "❌ CONTAMINAÇÃO DETECTADA!" -ForegroundColor Red
                        Write-Host "   Chave da Bella contém dados da Clínica Sorriso!" -ForegroundColor Red
                        Write-Host "   Preview: $($value.Substring(0, [Math]::Min(200, $value.Length)))..." -ForegroundColor Red
                    }
                    elseif ($value -match "bella" -and $key -match "sorriso") {
                        Write-Host "❌ CONTAMINAÇÃO DETECTADA!" -ForegroundColor Red
                        Write-Host "   Chave da Clínica Sorriso contém dados da Bella!" -ForegroundColor Red
                        Write-Host "   Preview: $($value.Substring(0, [Math]::Min(200, $value.Length)))..." -ForegroundColor Red
                    }
                    else {
                        Write-Host "✅ Chave OK (sem contaminação aparente)" -ForegroundColor Green
                    }
                    Write-Host ""
                }
            }
            
            # DECISÃO: Perguntar se quer limpar
            Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host "💣 AÇÃO: LIMPAR CACHE?" -ForegroundColor Cyan
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
            
            Write-Host "⚠️  OPÇÕES:" -ForegroundColor Yellow
            Write-Host "  1. Limpar APENAS DB-1 (cache/memory) - RECOMENDADO" -ForegroundColor Yellow
            Write-Host "  2. Limpar AMBOS DB-0 e DB-1" -ForegroundColor Yellow
            Write-Host "  3. Limpar chaves específicas (manual)" -ForegroundColor Yellow
            Write-Host "  4. NÃO LIMPAR (só investigar)`n" -ForegroundColor Yellow
            
            $choice = Read-Host "Escolha (1-4)"
            
            switch ($choice) {
                "1" {
                    Write-Host "`n🧹 Limpando DB-1 (cache)..." -ForegroundColor Cyan
                    redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 1 FLUSHDB
                    Write-Host "✅ DB-1 limpo! Cache será regenerado automaticamente.`n" -ForegroundColor Green
                    
                    # Verificar
                    $sizeAfter = redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 1 DBSIZE
                    Write-Host "📊 DB-1 size após limpeza: $sizeAfter chaves" -ForegroundColor Cyan
                }
                "2" {
                    Write-Host "`n⚠️  CUIDADO! Isso vai limpar buffer de mensagens também!" -ForegroundColor Red
                    $confirm = Read-Host "Tem certeza? (digite 'SIM' para confirmar)"
                    
                    if ($confirm -eq "SIM") {
                        Write-Host "`n🧹 Limpando DB-0..." -ForegroundColor Cyan
                        redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 0 FLUSHDB
                        Write-Host "✅ DB-0 limpo!`n" -ForegroundColor Green
                        
                        Write-Host "🧹 Limpando DB-1..." -ForegroundColor Cyan
                        redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 1 FLUSHDB
                        Write-Host "✅ DB-1 limpo!`n" -ForegroundColor Green
                    }
                    else {
                        Write-Host "❌ Operação cancelada." -ForegroundColor Yellow
                    }
                }
                "3" {
                    Write-Host "`n🔑 Digite o padrão de chave para deletar (ex: *bella*context*):" -ForegroundColor Cyan
                    $pattern = Read-Host "Padrão"
                    
                    $keysToDelete = redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 1 KEYS $pattern
                    
                    if ($keysToDelete) {
                        Write-Host "`n📋 Chaves que serão deletadas:" -ForegroundColor Yellow
                        $keysToDelete | ForEach-Object { Write-Host "  - $_" }
                        
                        $confirm = Read-Host "`nConfirmar deleção? (s/n)"
                        if ($confirm -eq "s") {
                            foreach ($key in $keysToDelete) {
                                redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n 1 DEL $key
                            }
                            Write-Host "✅ Chaves deletadas!`n" -ForegroundColor Green
                        }
                    }
                    else {
                        Write-Host "❌ Nenhuma chave encontrada com esse padrão." -ForegroundColor Red
                    }
                }
                "4" {
                    Write-Host "`n✅ Investigação concluída. Nenhuma limpeza realizada." -ForegroundColor Green
                }
            }
        }
        else {
            Write-Host "ℹ️  DB-1 está vazio (sem cache)." -ForegroundColor Gray
        }
        
    }
    else {
        Write-Host "❌ Não conseguiu conectar no Redis!" -ForegroundColor Red
        Write-Host "Erro: $testConnection`n" -ForegroundColor Red
    }
}
else {
    Write-Host "❌ redis-cli não encontrado localmente.`n" -ForegroundColor Red
    
    # ============================================================================
    # OPÇÃO 2: Conectar via SSH + Docker exec
    # ============================================================================
    Write-Host "[OPÇÃO 2] Tentando via SSH + Docker..." -ForegroundColor Yellow
    
    $sshExists = Get-Command ssh -ErrorAction SilentlyContinue
    
    if ($sshExists) {
        Write-Host "✅ SSH encontrado!`n" -ForegroundColor Green
        
        Write-Host "📡 Conectando via SSH no Easypanel..." -ForegroundColor Cyan
        Write-Host "ℹ️  Se pedir senha, use a senha SSH do seu servidor.`n" -ForegroundColor Gray
        
        # Descobrir nome do container Redis
        Write-Host "🔍 Buscando container Redis..." -ForegroundColor Cyan
        $dockerCmd = "docker ps --filter 'name=redis' --format '{{.Names}}'"
        
        $redisContainer = ssh -i $SSH_KEY_PATH "$SSH_USER@$SSH_HOST" $dockerCmd 2>&1
        
        if ($redisContainer) {
            Write-Host "✅ Container Redis encontrado: $redisContainer`n" -ForegroundColor Green
            
            # Executar comandos Redis via Docker
            Write-Host "🔬 Investigando Redis via Docker...`n" -ForegroundColor Cyan
            
            # DB-1 KEYS
            ssh -i $SSH_KEY_PATH "$SSH_USER@$SSH_HOST" "docker exec $redisContainer redis-cli -n 1 KEYS '*bella*'"
            ssh -i $SSH_KEY_PATH "$SSH_USER@$SSH_HOST" "docker exec $redisContainer redis-cli -n 1 KEYS '*sorriso*'"
            
            Write-Host "`n💣 Deseja limpar o cache agora? (s/n)" -ForegroundColor Yellow
            $cleanChoice = Read-Host "Opção"
            
            if ($cleanChoice -eq "s") {
                Write-Host "`n🧹 Limpando DB-1 via Docker..." -ForegroundColor Cyan
                ssh -i $SSH_KEY_PATH "$SSH_USER@$SSH_HOST" "docker exec $redisContainer redis-cli -n 1 FLUSHDB"
                Write-Host "✅ Cache limpo!`n" -ForegroundColor Green
            }
        }
        else {
            Write-Host "❌ Container Redis não encontrado!" -ForegroundColor Red
            Write-Host "ℹ️  Verifique o nome do container no Easypanel.`n" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "❌ SSH não encontrado.`n" -ForegroundColor Red
        
        # ============================================================================
        # OPÇÃO 3: Instruções para fazer manualmente no Easypanel
        # ============================================================================
        Write-Host "[OPÇÃO 3] FAZER MANUALMENTE NO EASYPANEL:" -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Yellow
        
        Write-Host "1. Acessar Easypanel → Redis → Terminal" -ForegroundColor White
        Write-Host "2. Executar comandos:`n" -ForegroundColor White
        
        Write-Host "   # Verificar DB-1" -ForegroundColor Cyan
        Write-Host "   redis-cli -n 1 KEYS '*bella*'" -ForegroundColor Gray
        Write-Host "   redis-cli -n 1 KEYS '*sorriso*'" -ForegroundColor Gray
        Write-Host "   redis-cli -n 1 DBSIZE`n" -ForegroundColor Gray
        
        Write-Host "   # Se encontrar contaminação:" -ForegroundColor Cyan
        Write-Host "   redis-cli -n 1 FLUSHDB`n" -ForegroundColor Gray
        
        Write-Host "3. Testar no WhatsApp após limpar`n" -ForegroundColor White
    }
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ INVESTIGAÇÃO CONCLUÍDA!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
