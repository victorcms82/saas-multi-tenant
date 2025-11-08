# Script para testar conexões Supabase
# Testa diferentes configurações de host/porta/SSL

Write-Host "=== TESTANDO CONEXÕES SUPABASE ===" -ForegroundColor Cyan
Write-Host ""

$configs = @(
    @{
        Name = "Pooler porta 5432 (Direta)"
        Host = "aws-0-us-east-1.pooler.supabase.com"
        Port = 5432
        ConnectionString = "Host=aws-0-us-east-1.pooler.supabase.com;Port=5432;Database=postgres;Username=postgres.vnlfgnfaortdvmraoapq;Password=B1S89OpAO4o4YmHhI7nsSGQd5APBAA;SSL Mode=Require"
    },
    @{
        Name = "Pooler porta 6543 (Transaction)"
        Host = "aws-0-us-east-1.pooler.supabase.com"
        Port = 6543
        ConnectionString = "Host=aws-0-us-east-1.pooler.supabase.com;Port=6543;Database=postgres;Username=postgres.vnlfgnfaortdvmraoapq;Password=B1S89OpAO4o4YmHhI7nsSGQd5APBAA;SSL Mode=Prefer;Trust Server Certificate=true"
    },
    @{
        Name = "Host Direto porta 5432"
        Host = "db.vnlfgnfaortdvmraoapq.supabase.co"
        Port = 5432
        ConnectionString = "Host=db.vnlfgnfaortdvmraoapq.supabase.co;Port=5432;Database=postgres;Username=postgres.vnlfgnfaortdvmraoapq;Password=B1S89OpAO4o4YmHhI7nsSGQd5APBAA;SSL Mode=Require"
    }
)

foreach ($config in $configs) {
    Write-Host "Testando: $($config.Name)" -ForegroundColor Yellow
    Write-Host "  Host: $($config.Host):$($config.Port)" -ForegroundColor Gray
    
    try {
        # Testar TCP primeiro
        $tcpTest = Test-NetConnection -ComputerName $config.Host -Port $config.Port -WarningAction SilentlyContinue -InformationLevel Quiet
        
        if ($tcpTest) {
            Write-Host "  ✅ Porta acessível" -ForegroundColor Green
            Write-Host "  Connection String para n8n:" -ForegroundColor Cyan
            Write-Host "  $($config.ConnectionString)" -ForegroundColor White
        } else {
            Write-Host "  ❌ Porta inacessível" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Erro: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "=== CONFIGURAÇÃO RECOMENDADA PARA N8N ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Opção 1 (Pooler - SSL flexível):" -ForegroundColor Yellow
Write-Host "  Host: aws-0-us-east-1.pooler.supabase.com"
Write-Host "  Port: 6543"
Write-Host "  Database: postgres"
Write-Host "  User: postgres.vnlfgnfaortdvmraoapq"
Write-Host "  Password: B1S89OpAO4o4YmHhI7nsSGQd5APBAA"
Write-Host "  SSL Mode: Allow (ou Prefer)" -ForegroundColor Green
Write-Host "  ☑ Trust Server Certificate: Yes" -ForegroundColor Green
Write-Host ""
Write-Host "Opção 2 (Direto - Mais estável):" -ForegroundColor Yellow
Write-Host "  Host: db.vnlfgnfaortdvmraoapq.supabase.co"
Write-Host "  Port: 5432"
Write-Host "  Database: postgres"
Write-Host "  User: postgres.vnlfgnfaortdvmraoapq"
Write-Host "  Password: B1S89OpAO4o4YmHhI7nsSGQd5APBAA"
Write-Host "  SSL Mode: Require"
Write-Host ""
Write-Host "DICA: Se n8n não tem opção 'Trust Server Certificate', use Opção 2" -ForegroundColor Magenta
