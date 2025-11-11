# ============================================================================
# DIAGNOSTICO AVANCADO: Por que imagem errada ainda e enviada
# ============================================================================

Write-Host "`n🔍 DIAGNOSTICO AVANCADO - Imagem Errada" -ForegroundColor Red
Write-Host "=" * 80 -ForegroundColor Gray

Write-Host "`n✅ CONFIRMADO: Node 'Construir Contexto Completo' FUNCIONANDO" -ForegroundColor Green
Write-Host "   - client_id correto: estetica_bella_rede" -ForegroundColor Gray
Write-Host "   - location_context correto: Bella Barra + 4 profissionais" -ForegroundColor Gray
Write-Host "   - system_prompt correto: Bella Estetica" -ForegroundColor Gray

Write-Host "`n❌ PROBLEMA: Imagem 'Equipe Clinica Sorriso' sendo enviada" -ForegroundColor Red

Write-Host "`n🔍 ANALISE DA MENSAGEM DO BOT:" -ForegroundColor Yellow
Write-Host "`n   Mensagem 1 (19:03):" -ForegroundColor White
Write-Host "   'Na Bella Estetica, temos uma equipe de profissionais...'" -ForegroundColor Gray
Write-Host "   'Enviei uma imagem em anexo com a equipe completa da Clinica Sorriso...'" -ForegroundColor Red
Write-Host "   📷 Anexo: Equipe Clinica Sorriso" -ForegroundColor Red
Write-Host "`n   ❌ Bot MENCIONA que esta enviando imagem da Clinica Sorriso!" -ForegroundColor Red

Write-Host "`n   Mensagem 2 (19:03):" -ForegroundColor White
Write-Host "   'Aqui estao os nomes dos profissionais da unidade da Bella Estetica:'" -ForegroundColor Gray
Write-Host "   '1. Dra. Ana Silva - Dermatologista'" -ForegroundColor Red
Write-Host "   '2. Dr. Carlos Mendes - Cirurgiao Plastico'" -ForegroundColor Gray
Write-Host "   '3. Paula Rocha - Esteticista'" -ForegroundColor Red
Write-Host "   '4. Renata Oliveira - Fisioterapeuta Dermato-Funcional'" -ForegroundColor Red
Write-Host "`n   ❌ Nomes NAO batem com o banco (Ana Paula Silva, Beatriz Costa, etc)" -ForegroundColor Red

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Write-Host "`n🎯 HIPOTESES:" -ForegroundColor Cyan

Write-Host "`n1️⃣ LLM ALUCINANDO" -ForegroundColor Yellow
Write-Host "   Sintomas:" -ForegroundColor White
Write-Host "   - Bot inventa nomes que nao existem no banco" -ForegroundColor Gray
Write-Host "   - Bot menciona 'Clinica Sorriso' mesmo recebendo contexto Bella" -ForegroundColor Gray
Write-Host "   - Bot mistura informacoes de fontes diferentes" -ForegroundColor Gray
Write-Host "`n   Causa possivel:" -ForegroundColor White
Write-Host "   - RAG retornando documentos errados" -ForegroundColor Gray
Write-Host "   - Memoria de conversas anteriores (Redis)" -ForegroundColor Gray
Write-Host "   - Prompt do LLM confuso" -ForegroundColor Gray

Write-Host "`n2️⃣ RAG COM DOCUMENTOS ERRADOS" -ForegroundColor Yellow
Write-Host "   Sintomas:" -ForegroundColor White
Write-Host "   - Bot tem 'conhecimento' da Clinica Sorriso" -ForegroundColor Gray
Write-Host "   - Bot sabe detalhes que nao estao no location_context" -ForegroundColor Gray
Write-Host "`n   Causa possivel:" -ForegroundColor White
Write-Host "   - Namespace 'estetica_bella_rede/default' tem docs da Sorriso" -ForegroundColor Gray
Write-Host "   - Embeddings misturados entre clientes" -ForegroundColor Gray

Write-Host "`n3️⃣ ATTACHMENTS HARDCODED NO WORKFLOW" -ForegroundColor Yellow
Write-Host "   Sintomas:" -ForegroundColor White
Write-Host "   - Imagem sempre a mesma (Clinica Sorriso)" -ForegroundColor Gray
Write-Host "   - Independente do client_id" -ForegroundColor Gray
Write-Host "`n   Causa possivel:" -ForegroundColor White
Write-Host "   - Node 'Enviar Resposta Chatwoot' tem URL hardcoded" -ForegroundColor Gray
Write-Host "   - Node de midia nao usa client_id para filtrar" -ForegroundColor Gray

Write-Host "`n4️⃣ CACHE/MEMORIA DA CONVERSA" -ForegroundColor Yellow
Write-Host "   Sintomas:" -ForegroundColor White
Write-Host "   - Primeira mensagem OK, segunda errada" -ForegroundColor Gray
Write-Host "   - Bot 'lembra' de informacoes antigas" -ForegroundColor Gray
Write-Host "`n   Causa possivel:" -ForegroundColor White
Write-Host "   - Redis guardando contexto errado" -ForegroundColor Gray
Write-Host "   - Historico de mensagens com client_id errado" -ForegroundColor Gray

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Write-Host "`n📝 PROXIMAS ACOES:" -ForegroundColor Cyan

Write-Host "`n   [ACAO 1] Verificar Node 'Query RAG' (CRITICO)" -ForegroundColor Yellow
Write-Host "   1. Ver output do node que busca RAG" -ForegroundColor White
Write-Host "   2. Verificar se retorna documentos da Clinica Sorriso" -ForegroundColor White
Write-Host "   3. Namespace usado: deve ser 'estetica_bella_rede/default'" -ForegroundColor White

Write-Host "`n   [ACAO 2] Verificar Node 'Preparar Prompt LLM'" -ForegroundColor Yellow
Write-Host "   1. Ver o prompt COMPLETO enviado ao GPT-4" -ForegroundColor White
Write-Host "   2. Verificar se menciona 'Clinica Sorriso' em algum lugar" -ForegroundColor White
Write-Host "   3. Verificar se location_context esta sendo usado" -ForegroundColor White

Write-Host "`n   [ACAO 3] Verificar Node 'Construir Resposta Final'" -ForegroundColor Yellow
Write-Host "   1. Ver de onde vem o 'attachments' array" -ForegroundColor White
Write-Host "   2. Verificar se tem URL hardcoded da imagem Sorriso" -ForegroundColor White

Write-Host "`n   [ACAO 4] Limpar Cache/Memoria" -ForegroundColor Yellow
Write-Host "   1. Deletar conversa no Chatwoot e comecar nova" -ForegroundColor White
Write-Host "   2. Limpar Redis (se possivel)" -ForegroundColor White
Write-Host "   3. Testar com contato novo" -ForegroundColor White

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Write-Host "`n🎯 TESTE RAPIDO:" -ForegroundColor Magenta
Write-Host "`n   Envie uma pergunta SIMPLES (sem profissionais):" -ForegroundColor White
Write-Host "   'Qual o endereco da clinica?'" -ForegroundColor Cyan
Write-Host "`n   Resposta esperada:" -ForegroundColor White
Write-Host "   'Av. das Americas, 5000 - Sala 301, Rio de Janeiro'" -ForegroundColor Gray
Write-Host "`n   Se responder ERRADO → Problema no RAG/LLM" -ForegroundColor Yellow
Write-Host "   Se responder CERTO → Problema so com imagens" -ForegroundColor Yellow

Write-Host "`n" + ("=" * 80) -ForegroundColor Gray
Write-Host "⏸️  AGUARDANDO: Output dos nodes RAG e Preparar Prompt" -ForegroundColor Yellow
Write-Host ("=" * 80) + "`n" -ForegroundColor Gray
