# ============================================================================
# Script: Atualizar Node Query RAG no Workflow
# ============================================================================

Write-Host "🔧 Atualizando node Query RAG com código real..." -ForegroundColor Cyan

# Ler workflow JSON do input do usuário (foi passado via stdin/arquivo temp)
$workflowPath = "c:\Documentos\Projetos\saas-multi-tenant\workflows\WF0-ATUAL-PRODUCAO-RAG-ATIVO.json"

# Ler código do Query RAG
$ragCodePath = "c:\Documentos\Projetos\saas-multi-tenant\workflows\CODIGO-QUERY-RAG-REAL.js"
$ragCode = Get-Content -Path $ragCodePath -Raw -Encoding UTF8

# Ler workflow do arquivo temporário que o usuário enviou
$workflowJson = Get-Content -Path "$env:TEMP\workflow-atual.json" -Raw -Encoding UTF8 -ErrorAction SilentlyContinue

if (-not $workflowJson) {
    Write-Host "⚠️ Workflow não encontrado em arquivo temp. Usando input direto..." -ForegroundColor Yellow
    
    # O workflow será passado como string
    $workflowJson = $args[0]
}

if (-not $workflowJson) {
    Write-Host "❌ ERRO: Workflow não fornecido!" -ForegroundColor Red
    exit 1
}

# Parse JSON
try {
    $workflow = $workflowJson | ConvertFrom-Json
} catch {
    Write-Host "❌ ERRO ao parsear JSON: $_" -ForegroundColor Red
    exit 1
}

# Encontrar node Query RAG
$queryRagNode = $workflow.nodes | Where-Object { $_.name -eq "Query RAG (Namespace Isolado)" }

if (-not $queryRagNode) {
    Write-Host "❌ ERRO: Node 'Query RAG (Namespace Isolado)' não encontrado!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Node encontrado: $($queryRagNode.name)" -ForegroundColor Green

# Atualizar código
$queryRagNode.parameters.jsCode = $ragCode

Write-Host "✅ Código atualizado!" -ForegroundColor Green

# Salvar workflow atualizado
$outputPath = "c:\Documentos\Projetos\saas-multi-tenant\workflows\WF0-ATUAL-PRODUCAO-RAG-ATIVO.json"
$workflow | ConvertTo-Json -Depth 100 -Compress:$false | Set-Content -Path $outputPath -Encoding UTF8

Write-Host "✅ Workflow salvo em: $outputPath" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Próximos passos:" -ForegroundColor Yellow
Write-Host "   1. Importar no n8n: $outputPath" -ForegroundColor White
Write-Host "   2. Ativar workflow" -ForegroundColor White
Write-Host "   3. Testar com documento de exemplo" -ForegroundColor White
