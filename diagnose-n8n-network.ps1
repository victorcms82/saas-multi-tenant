# Teste de conectividade do n8n
# Execute este comando no container do n8n para verificar conectividade

Write-Host "=== DIAGNÓSTICO DE REDE N8N ===" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar se n8n está em Docker
Write-Host "1. Verificando se n8n está em Docker..." -ForegroundColor Yellow
docker ps | Select-String "n8n"

Write-Host ""
Write-Host "2. Testando conectividade do HOST (sua máquina)..." -ForegroundColor Yellow

# Testar do host
$hosts = @(
    "db.vnlfgnfaortdvmraoapq.supabase.co",
    "aws-0-us-east-1.pooler.supabase.com",
    "8.8.8.8"
)

foreach ($host in $hosts) {
    $result = Test-NetConnection -ComputerName $host -Port 5432 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($result) {
        Write-Host "  ✅ $host - ACESSÍVEL" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $host - INACESSÍVEL" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "3. Se n8n está em Docker, execute:" -ForegroundColor Yellow
Write-Host "   docker exec -it <container-name> ping -c 3 db.vnlfgnfaortdvmraoapq.supabase.co" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Para conectar do Docker ao Supabase, adicione ao docker-compose.yml:" -ForegroundColor Yellow
Write-Host @"
services:
  n8n:
    dns:
      - 8.8.8.8
      - 1.1.1.1
    extra_hosts:
      - "db.vnlfgnfaortdvmraoapq.supabase.co:$(Resolve-DnsName db.vnlfgnfaortdvmraoapq.supabase.co -Type A | Select-Object -First 1 -ExpandProperty IPAddress)"
"@ -ForegroundColor Cyan

Write-Host ""
Write-Host "=== SOLUÇÃO ALTERNATIVA: USAR SUPABASE REST API ===" -ForegroundColor Magenta
Write-Host ""
Write-Host "Se continuar com erro ENETUNREACH, use HTTP Request em vez de Postgres:" -ForegroundColor Yellow
Write-Host "  URL: https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/agents" -ForegroundColor White
Write-Host "  Header: apikey: [sua-anon-key]" -ForegroundColor White
Write-Host "  Header: Authorization: Bearer [sua-service-role-key]" -ForegroundColor White
