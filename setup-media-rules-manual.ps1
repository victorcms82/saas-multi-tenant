# ═══════════════════════════════════════════════════════════════
# INSTRUÇÕES: Criar client_media_rules no Supabase
# ═══════════════════════════════════════════════════════════════

Write-Host "📋 PASSO A PASSO PARA CRIAR MÍDIA DO ACERVO" -ForegroundColor Cyan
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

Write-Host "🔗 PASSO 1: Abrir SQL Editor do Supabase" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Acesse: https://supabase.com/dashboard/project/vnlfgnfaortdvmraoapq/sql" -ForegroundColor Blue
Write-Host ""

Write-Host "📝 PASSO 2: Copiar SQL" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Abra o arquivo:" -ForegroundColor White
Write-Host "   database\migrations\008_create_client_media_rules.sql" -ForegroundColor Green
Write-Host ""
Write-Host "   Ou copie o conteúdo abaixo:" -ForegroundColor White
Write-Host ""
Write-Host "   ► Selecione TODO o conteúdo do arquivo" -ForegroundColor Gray
Write-Host "   ► Ctrl+C para copiar" -ForegroundColor Gray
Write-Host ""

Write-Host "▶️  PASSO 3: Executar no Supabase" -ForegroundColor Yellow
Write-Host ""
Write-Host "   1. Cole o SQL no editor" -ForegroundColor White
Write-Host "   2. Clique no botão 'RUN' (canto inferior direito)" -ForegroundColor White
Write-Host "   3. Aguarde mensagem de sucesso" -ForegroundColor White
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

$continue = Read-Host "Executou o SQL no Supabase? (s/n)"

if ($continue -eq 's') {
    Write-Host ""
    Write-Host "✅ Ótimo! Vamos verificar se funcionou..." -ForegroundColor Green
    Write-Host ""
    
    $env:SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U"
    $headers = @{
        'apikey' = $env:SUPABASE_KEY
        'Authorization' = "Bearer $env:SUPABASE_KEY"
    }
    
    try {
        $rules = Invoke-RestMethod `
            -Uri "https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/client_media_rules?client_id=eq.clinica_sorriso_001&select=*,client_media(title,file_name,file_url)" `
            -Headers $headers `
            -Method GET
        
        Write-Host "🎉 SUCESSO! Tabela criada e regras configuradas:" -ForegroundColor Green
        Write-Host ""
        
        $rules | ForEach-Object {
            Write-Host "  📄 Arquivo: $($_.client_media.title)" -ForegroundColor White
            Write-Host "     Trigger: $($_.trigger_value)" -ForegroundColor Gray
            Write-Host "     Tipo: $($_.trigger_type)" -ForegroundColor Gray
            Write-Host "     URL: $($_.client_media.file_url)" -ForegroundColor DarkGray
            Write-Host ""
        }
        
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host ""
        Write-Host "🧪 PRÓXIMO PASSO: TESTAR NO WHATSAPP!" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   Envie uma dessas mensagens:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   • 'Quero a tabela de preços'" -ForegroundColor White
        Write-Host "   • 'Quanto custa?'" -ForegroundColor White
        Write-Host "   • 'Me mostra o consultório'" -ForegroundColor White
        Write-Host "   • 'Quero ver a equipe'" -ForegroundColor White
        Write-Host ""
        Write-Host "   Bot deve:" -ForegroundColor Yellow
        Write-Host "   ✅ Reconhecer a palavra-chave" -ForegroundColor Green
        Write-Host "   ✅ Buscar o arquivo no Supabase" -ForegroundColor Green
        Write-Host "   ✅ Enviar no WhatsApp" -ForegroundColor Green
        Write-Host ""
        
    } catch {
        Write-Host "❌ ERRO: Tabela ainda não foi criada" -ForegroundColor Red
        Write-Host ""
        Write-Host "Detalhes: $($_.Exception.Message)" -ForegroundColor DarkRed
        Write-Host ""
        Write-Host "Volte e execute o SQL no Supabase primeiro!" -ForegroundColor Yellow
    }
    
} else {
    Write-Host ""
    Write-Host "⏸️  Ok! Execute o SQL no Supabase e rode este script novamente." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   .\setup-media-rules-manual.ps1" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Gray
