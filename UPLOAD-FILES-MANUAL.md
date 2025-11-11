# 📁 INSTRUÇÕES: Upload Manual de Arquivos para Supabase Storage

## 🚨 PROBLEMA IDENTIFICADO
Os arquivos estão cadastrados na tabela `client_media` mas **NÃO existem fisicamente** no bucket `client-media`.

## ✅ SOLUÇÃO: Upload Manual via Interface do Supabase

### 📋 Passo a Passo:

1. **Abrir Supabase Dashboard**
   - URL: https://supabase.com/dashboard/project/vnlfgnfaortdvmraoapq
   - Login com sua conta

2. **Navegar para Storage**
   - Menu lateral: `Storage`
   - Selecionar bucket: `client-media`
   - Criar pasta (se não existir): `clinica_sorriso_001/`

3. **Upload dos 3 Arquivos**

   📄 **Arquivo 1: consultorio-recepcao.jpg**
   - Localização: `clinica_sorriso_001/consultorio-recepcao.jpg`
   - Tipo: Imagem JPG
   - Conteúdo: Foto da recepção do consultório
   - **USAR QUALQUER FOTO** de consultório odontológico da internet

   📄 **Arquivo 2: equipe-completa.jpg**
   - Localização: `clinica_sorriso_001/equipe-completa.jpg`
   - Tipo: Imagem JPG
   - Conteúdo: Foto da equipe
   - **USAR QUALQUER FOTO** de equipe de dentistas

   📄 **Arquivo 3: tabela-precos.pdf**
   - Localização: `clinica_sorriso_001/tabela-precos.pdf`
   - Tipo: PDF
   - Conteúdo: Tabela de preços dos serviços
   - **CRIAR PDF SIMPLES** com:
     ```
     TABELA DE PREÇOS
     Clínica Sorriso

     Limpeza: R$ 150
     Clareamento: R$ 800
     Implante: R$ 2.500
     Ortodontia: R$ 300/mês
     ```

4. **Validar URLs**
   Após upload, as URLs devem ser:
   - `https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/clinica_sorriso_001/consultorio-recepcao.jpg`
   - `https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/clinica_sorriso_001/equipe-completa.jpg`
   - `https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/clinica_sorriso_001/tabela-precos.pdf`

5. **Testar Acesso**
   ```powershell
   # Após upload, rodar:
   curl -I "https://vnlfgnfaortdvmraoapq.supabase.co/storage/v1/object/public/client-media/clinica_sorriso_001/consultorio-recepcao.jpg"
   # Deve retornar HTTP 200
   ```

## 🔧 Alternativa: Usar Imagens de Teste Online

Se não quiser criar arquivos, pode **ATUALIZAR** as URLs na tabela para usar imagens públicas:

```sql
-- Atualizar com imagens de teste (Unsplash)
UPDATE public.client_media 
SET file_url = 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800'
WHERE title = 'Recepção do Consultório';

UPDATE public.client_media 
SET file_url = 'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=800'
WHERE title = 'Equipe Clínica Sorriso';

UPDATE public.client_media 
SET file_url = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'
WHERE title = 'Tabela de Preços';
```

## 📱 Próximos Passos

Após upload/atualização:
1. ✅ Executar: `.\test-chatwoot-send-attachment.ps1`
2. ✅ Validar envio via API do Chatwoot
3. ✅ Testar no WhatsApp real

---

**AVISO**: O problema de "signature verification failed" indica que:
- OU o SERVICE_KEY está incorreto
- OU o bucket `client-media` não tem permissões configuradas para service_role
- OU a política de upload não permite o caminho `clinica_sorriso_001/*`

Recomendo usar a **interface web** do Supabase que já tem autenticação integrada.
