# FIX: Workflow aceitar anexos sem texto

Write-Host "🔧 CORREÇÃO NECESSÁRIA NO N8N" -ForegroundColor Cyan
Write-Host ""
Write-Host "PROBLEMA: Bot não responde quando envia APENAS foto (sem texto)" -ForegroundColor Red
Write-Host ""
Write-Host "SOLUÇÃO: Atualizar node 'Identificar Cliente e Agente'" -ForegroundColor Green
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""
Write-Host "📋 PASSOS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Abra n8n: https://n8n.evolutedigital.com.br" -ForegroundColor White
Write-Host "2. Workflow: WF0-Gestor-Universal-REORGANIZADO" -ForegroundColor White
Write-Host "3. Node: 'Identificar Cliente e Agente'" -ForegroundColor White
Write-Host "4. Encontre estas linhas (linhas 15-19):" -ForegroundColor White
Write-Host ""
Write-Host "   ANTES:" -ForegroundColor Red
Write-Host '   // VALIDAÇÃO: Abortar se message_body vazio' -ForegroundColor Gray
Write-Host '   if (!messageBody || messageBody.trim() === "") {' -ForegroundColor Gray
Write-Host '     throw new Error("message_body não pode estar vazio");' -ForegroundColor Gray
Write-Host '   }' -ForegroundColor Gray
Write-Host ""
Write-Host "5. Substitua por:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   DEPOIS:" -ForegroundColor Green
Write-Host '   // Canal e attachments' -ForegroundColor Cyan
Write-Host '   const channel = payload.inbox?.channel_type || payload.body?.inbox?.channel_type || "whatsapp";' -ForegroundColor Cyan
Write-Host '   const attachments = payload.attachments || payload.body?.attachments || [];' -ForegroundColor Cyan
Write-Host '' -ForegroundColor Cyan
Write-Host '   // VALIDAÇÃO: Abortar se message_body vazio E sem attachments' -ForegroundColor Cyan
Write-Host '   if ((!messageBody || messageBody.trim() === "") && attachments.length === 0) {' -ForegroundColor Cyan
Write-Host '     throw new Error("Mensagem vazia sem anexos");' -ForegroundColor Cyan
Write-Host '   }' -ForegroundColor Cyan
Write-Host '' -ForegroundColor Cyan
Write-Host '   // Se só tem attachment sem texto, criar mensagem padrão' -ForegroundColor Cyan
Write-Host '   if ((!messageBody || messageBody.trim() === "") && attachments.length > 0) {' -ForegroundColor Cyan
Write-Host '     messageBody = "[Arquivo enviado]";' -ForegroundColor Cyan
Write-Host '   }' -ForegroundColor Cyan
Write-Host ""
Write-Host "6. IMPORTANTE: Remova as linhas duplicadas:" -ForegroundColor Yellow
Write-Host "   Mais abaixo no código, APAGUE estas linhas (linhas ~35-37):" -ForegroundColor Yellow
Write-Host ""
Write-Host "   APAGAR:" -ForegroundColor Red
Write-Host '   // Canal e attachments' -ForegroundColor Gray -BackgroundColor DarkRed
Write-Host '   const channel = payload.inbox?.channel_type || ...;' -ForegroundColor Gray -BackgroundColor DarkRed
Write-Host '   const attachments = payload.attachments || ...;' -ForegroundColor Gray -BackgroundColor DarkRed
Write-Host ""
Write-Host "7. Salve (Ctrl+S) e ative o workflow" -ForegroundColor White
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ RESULTADO:" -ForegroundColor Green
Write-Host "   Bot vai responder mesmo quando enviar só foto/anexo" -ForegroundColor White
Write-Host ""
Write-Host "🧪 TESTE:" -ForegroundColor Cyan
Write-Host "   Envie foto sem legenda no WhatsApp" -ForegroundColor White
Write-Host ""

Read-Host "Pressione ENTER quando concluir"

Write-Host ""
Write-Host "✅ Pronto para testar!" -ForegroundColor Green
