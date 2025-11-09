# Deletar TODOS os webhooks do Chatwoot
param(
    [string]$ChatwootUrl = "https://chatwoot.evolutedigital.com.br",
    [string]$ApiToken = "zL8FNtrajZjGv4LP9BrZiCif",
    [string]$AccountId = "1"
)

$Headers = @{
    "api_access_token" = $ApiToken
    "Content-Type" = "application/json"
}

Write-Host "🗑️  Deletando webhooks do Chatwoot..." -ForegroundColor Red
Write-Host ""

try {
    # Listar webhooks
    $Response = Invoke-RestMethod `
        -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/webhooks" `
        -Method GET `
        -Headers $Headers
    
    if ($Response.payload.Count -eq 0) {
        Write-Host "✅ Nenhum webhook para deletar!" -ForegroundColor Green
        exit 0
    }
    
    Write-Host "Encontrados $($Response.payload.Count) webhook(s)" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($webhook in $Response.payload) {
        Write-Host "Deletando webhook ID: $($webhook.id)" -ForegroundColor Yellow
        Write-Host "  URL: $($webhook.url)" -ForegroundColor Gray
        
        try {
            Invoke-RestMethod `
                -Uri "$ChatwootUrl/api/v1/accounts/$AccountId/webhooks/$($webhook.id)" `
                -Method DELETE `
                -Headers $Headers | Out-Null
            
            Write-Host "  ✅ Deletado!" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Erro: $_" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "✅ Todos os webhooks foram deletados!" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Erro: $_" -ForegroundColor Red
}
