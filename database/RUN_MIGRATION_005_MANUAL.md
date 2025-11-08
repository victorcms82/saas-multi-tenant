# MIGRATION 005 - Client Media Tables

## ⚠️ EXECUTAR NO SUPABASE SQL EDITOR

Como o PostgreSQL `psql` não está instalado localmente, execute esta migration manualmente no Supabase:

### Passo a Passo:

1. **Acesse o Supabase Dashboard**
   - URL: https://supabase.com/dashboard/project/vnlfgnfaortdvmraoapq

2. **Abra o SQL Editor**
   - Menu lateral: SQL Editor
   - Clique em: + New Query

3. **Cole o conteúdo do arquivo**
   - Arquivo: `database/migrations/005_add_client_media_tables.sql`
   - Cole TODO o conteúdo (430 linhas)

4. **Execute a migration**
   - Clique em: Run (ou Ctrl+Enter)
   - Aguarde mensagem de sucesso

5. **Verifique o resultado**
   - Você deve ver:
     ```
     ============================================
     MIGRATION 005: Client Media - EXECUTADA
     ============================================
     
     Tabelas criadas:
       ✅ client_media (acervo de mídia)
       ✅ media_send_rules (regras de envio)
       ✅ media_send_log (histórico)
     
     Function criada:
       ✅ search_client_media()
     
     Dados de exemplo inseridos:
       📸 3 mídias para clinica_sorriso_001
       📋 3 regras de envio
     ```

### Validação Rápida:

Após executar, rode esta query para validar:

```sql
-- Verificar tabelas criadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('client_media', 'media_send_rules', 'media_send_log')
ORDER BY table_name;

-- Verificar dados de exemplo
SELECT COUNT(*) as total_media FROM client_media;
SELECT COUNT(*) as total_rules FROM media_send_rules;

-- Ver mídias inseridas
SELECT 
  file_name,
  file_type,
  title,
  tags,
  category
FROM client_media
ORDER BY created_at;

-- Ver regras criadas
SELECT 
  rule_name,
  rule_type,
  keywords,
  message_number
FROM media_send_rules
ORDER BY priority;
```

**Resultado esperado:**
- 3 tabelas criadas
- 3 mídias inseridas (consultorio-recepcao.jpg, equipe-completa.jpg, cardapio-servicos.pdf)
- 3 regras inseridas (keyword triggers + conversation phase)

---

## 📋 Próximos Passos (Após Migration):

1. ✅ Configurar Supabase Storage bucket "client-media"
2. ✅ Upload manual de 2-3 imagens de teste
3. ✅ Testar WF0 completo com client_media
4. ✅ Validar envio de mídia por keyword
5. ✅ Validar envio de mídia por fase da conversa

---

## 🔧 Alternativa: Usar API do Supabase

Se preferir executar via código:

```javascript
// Arquivo: database/run-migration-005.js
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

const supabase = createClient(
  'https://vnlfgnfaortdvmraoapq.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' // service_role_key
);

const sql = fs.readFileSync('migrations/005_add_client_media_tables.sql', 'utf8');

async function runMigration() {
  const { error } = await supabase.rpc('exec_sql', { sql });
  if (error) console.error('Erro:', error);
  else console.log('✅ Migration executada!');
}

runMigration();
```

Executar:
```bash
node database/run-migration-005.js
```

---

**Status:** ⏳ Aguardando execução manual no Supabase SQL Editor
