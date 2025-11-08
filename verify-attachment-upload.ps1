# Script para verificar última execução do WF0 no n8n
# NOTA: Requer configuração de API do n8n

Write-Host "📋 Para verificar resultado do upload de anexos:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Opção 1 - Via Chatwoot:" -ForegroundColor Yellow
Write-Host "  1. Acesse: https://chatwoot.evolutedigital.com.br/app/accounts/1/conversations/2" -ForegroundColor Gray
Write-Host "  2. Verifique se aparece:" -ForegroundColor Gray
Write-Host "     ✅ Mensagem: 'Estou enviando a Tabela de Preços...'" -ForegroundColor Green
Write-Host "     ✅ Anexo: tabela-precos.pdf (clicável)" -ForegroundColor Green
Write-Host ""
Write-Host "Opção 2 - Via n8n Logs:" -ForegroundColor Yellow
Write-Host "  1. Acesse: https://n8n.evolutedigital.com.br" -ForegroundColor Gray
Write-Host "  2. Workflows → WF0-Gestor-Universal-REORGANIZADO → Executions" -ForegroundColor Gray
Write-Host "  3. Clique na última execução" -ForegroundColor Gray
Write-Host "  4. Vá no node 'Log Upload Resultado'" -ForegroundColor Gray
Write-Host "  5. Verifique o output:" -ForegroundColor Gray
Write-Host "     - attachment_upload_status: 200 ✅" -ForegroundColor Green
Write-Host "     - attachment_sent: true ✅" -ForegroundColor Green
Write-Host ""
Write-Host "Se aparecer erro:" -ForegroundColor Red
Write-Host "  - 404: conversation_id não existe" -ForegroundColor Gray
Write-Host "  - 401: api_access_token inválido" -ForegroundColor Gray
Write-Host "  - 422: formato do arquivo incorreto" -ForegroundColor Gray
Write-Host "  - 500: erro no Chatwoot" -ForegroundColor Gray
Write-Host ""
