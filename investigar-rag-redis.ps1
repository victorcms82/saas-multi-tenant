# ============================================================================
# INVESTIGAR RAG NO REDIS
# ============================================================================

Write-Host "`n🔍 INVESTIGANDO RAG NO REDIS..." -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

# Verificar se redis-cli está disponível
$redisCliPath = Get-Command redis-cli -ErrorAction SilentlyContinue

if (-not $redisCliPath) {
    Write-Host "`n❌ redis-cli não encontrado no PATH" -ForegroundColor Red
    Write-Host "`n💡 Alternativas:" -ForegroundColor Yellow
    Write-Host "  1. Acesse o Redis via interface web (RedisInsight, Redis Commander)" -ForegroundColor White
    Write-Host "  2. Verifique no n8n qual database/credentials está usando" -ForegroundColor White
    Write-Host "  3. Use Docker: docker exec -it redis redis-cli" -ForegroundColor White
    exit 1
}

Write-Host "`n✅ redis-cli encontrado: $($redisCliPath.Source)`n" -ForegroundColor Green

# Configuração (ajuste conforme seu ambiente)
$REDIS_HOST = "localhost"
$REDIS_PORT = 6379
$REDIS_PASSWORD = ""  # Se tiver senha

Write-Host "[1/3] Testando conexão com Redis..." -ForegroundColor Yellow

# Testar conexão
$pingCmd = if ($REDIS_PASSWORD) {
    "redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD PING"
} else {
    "redis-cli -h $REDIS_HOST -p $REDIS_PORT PING"
}

try {
    $result = Invoke-Expression $pingCmd 2>&1
    if ($result -like "*PONG*") {
        Write-Host "  ✅ Conexão OK`n" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Redis não respondeu" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ❌ Erro ao conectar: $_" -ForegroundColor Red
    exit 1
}

# Verificar databases 0, 1, 2
Write-Host "[2/3] Procurando chaves relacionadas a RAG...`n" -ForegroundColor Yellow

for ($db = 0; $db -le 2; $db++) {
    Write-Host "  📦 Database $db" -ForegroundColor Cyan
    
    # Contar chaves
    $countCmd = if ($REDIS_PASSWORD) {
        "redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n $db DBSIZE"
    } else {
        "redis-cli -h $REDIS_HOST -p $REDIS_PORT -n $db DBSIZE"
    }
    
    $keyCount = Invoke-Expression $countCmd 2>&1
    Write-Host "     Total de chaves: $keyCount" -ForegroundColor Gray
    
    # Buscar padrões de RAG
    $patterns = @(
        "rag:*",
        "vector:*",
        "embedding:*",
        "estetica_bella_rede:*",
        "clinica_sorriso_001:*",
        "*rag*",
        "*vector*",
        "*document*"
    )
    
    foreach ($pattern in $patterns) {
        $keysCmd = if ($REDIS_PASSWORD) {
            "redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD -n $db KEYS `"$pattern`""
        } else {
            "redis-cli -h $REDIS_HOST -p $REDIS_PORT -n $db KEYS `"$pattern`""
        }
        
        $keys = Invoke-Expression $keysCmd 2>&1 | Where-Object { $_ -ne "(empty array)" -and $_ }
        
        if ($keys) {
            Write-Host "     ✅ Padrão '$pattern': $($keys.Count) chaves" -ForegroundColor Green
            $keys | Select-Object -First 3 | ForEach-Object {
                Write-Host "        • $_" -ForegroundColor White
            }
        }
    }
    Write-Host ""
}

# Sugerir próximos passos
Write-Host "[3/3] Próximos passos`n" -ForegroundColor Yellow

Write-Host "💡 OPÇÕES:" -ForegroundColor Cyan
Write-Host "  A. Se encontrou chaves de RAG:" -ForegroundColor White
Write-Host "     -> Posso criar script para deletar chaves contaminadas" -ForegroundColor Gray
Write-Host "`n  B. Se não encontrou:" -ForegroundColor White
Write-Host "     -> Verificar no n8n qual serviço de RAG está usando" -ForegroundColor Gray
Write-Host "     -> Pode ser Pinecone, Qdrant, ou outro externo" -ForegroundColor Gray
Write-Host "`n  C. Alternativa mais fácil:" -ForegroundColor White
Write-Host "     -> Desabilitar temporariamente o node de RAG no n8n" -ForegroundColor Gray
Write-Host "     -> Testar se bot responde corretamente sem RAG" -ForegroundColor Gray

Write-Host "`n" + ("=" * 70) -ForegroundColor Gray
