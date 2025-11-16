# 🤖 INSTRUÇÕES PARA IA - Continuidade Inteligente do Projeto

**Data de Criação**: 16/11/2025  
**Projeto**: SaaS Multi-Tenant com IA Conversacional  
**Objetivo**: Garantir continuidade inteligente e progressiva do desenvolvimento

---

## 📋 PROTOCOLO OBRIGATÓRIO PARA CADA SESSÃO

### 1️⃣ **AO INICIAR UMA NOVA SESSÃO**

#### A. Ler Status Atual (SEMPRE!)
```bash
# Arquivos obrigatórios para ler PRIMEIRO:
1. STATUS-ATUAL-16-11-2025.md (ou versão mais recente)
2. CHANGELOG.md
3. git log --oneline -20
```

**Por quê?**
- Evita refazer trabalho já feito
- Entende contexto completo
- Identifica último estado funcional

#### B. Verificar Arquivos Modificados
```bash
git status
git diff
```

**Se houver mudanças não commitadas:**
- ⚠️ Perguntar ao usuário se quer commitar ou descartar
- ⚠️ NÃO sobrescrever sem confirmar

#### C. Identificar Último Checkpoint
```bash
# Buscar commit mais recente com "feat:" ou "fix:"
git log --grep="feat:" --grep="fix:" --oneline -5
```

---

### 2️⃣ **DURANTE O DESENVOLVIMENTO**

#### A. Documentar Progressivamente (NÃO no final!)

**SEMPRE que fizer uma mudança significativa:**

1. **Atualizar `STATUS-ATUAL-[DATA].md`** se:
   - Feature nova implementada
   - Bug crítico corrigido
   - Arquitetura mudou
   - Milestone atingido

2. **Criar arquivo de aprendizado** em `workflows/` se:
   - Descobriu limitação de API (ex: Vision não aceita PDF)
   - Encontrou bug sutil (ex: $input.first() vs $input.all())
   - Implementou workaround importante
   - **Formato**: `[TEMA]-APRENDIZADO-[DATA].md`

3. **Atualizar `CHANGELOG.md`** a cada mudança

#### B. Commits Frequentes e Descritivos

**Formato obrigatório:**
```
<tipo>: <descrição curta>

<corpo explicativo detalhado>
- O que foi mudado
- Por que foi mudado
- Impacto/resultado
```

**Tipos:**
- `feat:` Nova funcionalidade
- `fix:` Correção de bug
- `docs:` Documentação
- `refactor:` Refatoração sem mudança de comportamento
- `test:` Testes
- `chore:` Tarefas de manutenção

**Commitar a cada:**
- Feature completa e funcional
- Bug fix validado
- Documentação atualizada
- **Máximo 2h sem commit**

#### C. Criar Checkpoints de Recuperação

**Quando criar TAG:**
```bash
# Após features críticas funcionando:
git tag -a v0.X.0 -m "Descrição do milestone"
git push origin v0.X.0
```

**Exemplos de TAGs importantes:**
- `v0.5.0` - Memória conversacional funcionando
- `v0.6.0` - Processamento multi-mídia completo
- `v0.7.0` - RAG query implementado
- `v0.8.0` - Testes end-to-end passando
- `v1.0.0` - MVP pronto para produção

---

### 3️⃣ **DESCOBERTAS E APRENDIZADOS**

#### A. Documentar Limitações de APIs

**Template**: `workflows/LIMITACAO-[API]-[DATA].md`

```markdown
# ❌ LIMITAÇÃO: [Título]

**Data**: DD/MM/YYYY
**API/Serviço**: Nome
**Contexto**: O que tentamos fazer

## Problema
Descrever limitação descoberta

## Erro Específico
```
[código do erro ou mensagem]
```

## Solução/Workaround
Como contornamos

## Impacto
- Performance
- Custo
- Funcionalidade

## Alternativas Futuras
O que podemos fazer diferente
```

**Exemplo real:**
- `workflows/LIMITACAO-OPENAI-VISION-PDF.md`

#### B. Documentar Bugs Sutis

**Template**: `workflows/BUG-[DESCRICAO]-RESOLVIDO-[DATA].md`

```markdown
# 🐛 BUG RESOLVIDO: [Título]

**Data**: DD/MM/YYYY
**Severidade**: 🔴 Crítico / 🟡 Médio / 🟢 Baixo

## Sintoma
O que estava acontecendo de errado

## Causa Raiz
Por que estava acontecendo

## Código Problemático
```javascript
// Código que causava o bug
```

## Solução
```javascript
// Código corrigido
```

## Como Evitar no Futuro
Lição aprendida

## Commit
Link para o commit que corrigiu
```

**Exemplo real:**
- `workflows/BUG-INPUT-FIRST-RESOLVIDO-11-11-2025.md`

#### C. Documentar Decisões de Arquitetura

**Quando documentar:**
- Escolha entre 2+ abordagens
- Mudança significativa de estrutura
- Trade-off importante

**Template**: `docs/DECISAO-[NUMERO]-[TITULO].md`

```markdown
# 🎯 DECISÃO DE ARQUITETURA #X: [Título]

**Data**: DD/MM/YYYY
**Decisor**: IA + Victor
**Status**: ✅ Aceita / ⏳ Provisória / ❌ Rejeitada

## Contexto
Situação que levou à decisão

## Opções Consideradas

### Opção A: [Nome]
**Prós:**
- Item 1
- Item 2

**Contras:**
- Item 1
- Item 2

**Estimativa**: Xh

### Opção B: [Nome]
[mesmo formato]

## Decisão Final
Qual opção escolhida e por quê

## Consequências
- Impacto positivo
- Impacto negativo
- Débito técnico gerado (se houver)

## Revisão Futura
Quando reavaliar esta decisão
```

---

### 4️⃣ **PADRÕES DE CÓDIGO E BOAS PRÁTICAS**

#### A. Node.js/JavaScript (n8n workflows)

**SEMPRE:**
- ✅ Usar `$input.all()` quando processar múltiplos itens
- ✅ Preservar dados originais com spread: `...($input.item.json)`
- ✅ Adicionar `console.log()` em pontos críticos
- ✅ Validar se dados existem antes de acessar (null checks)
- ✅ Usar `try/catch` em operações que podem falhar

**NUNCA:**
- ❌ Usar `$input.first()` sem confirmar que há apenas 1 item
- ❌ Perder dados do contexto anterior em transformações
- ❌ Assumir que API sempre retorna sucesso
- ❌ Hardcodar valores que deveriam ser configuráveis

#### B. SQL (Supabase)

**SEMPRE:**
- ✅ Usar RPC functions para operações complexas
- ✅ Incluir `client_id` em TODAS as queries (multi-tenant!)
- ✅ Adicionar índices em campos usados em WHERE
- ✅ Testar em ambiente dev antes de prod
- ✅ Documentar cada RPC com comentários

**NUNCA:**
- ❌ Query direta sem isolamento de tenant
- ❌ Retornar dados de outros clientes
- ❌ N+1 queries (usar JOINs quando possível)

#### C. Commits e Versionamento

**SEMPRE:**
- ✅ Commitar código funcionando (testado!)
- ✅ Push para GitHub ao final de cada sessão
- ✅ Criar TAG em milestones importantes
- ✅ Atualizar STATUS antes de push final

**NUNCA:**
- ❌ Commitar código quebrado
- ❌ Commitar credenciais (já tivemos esse problema!)
- ❌ Push sem testar localmente

---

### 5️⃣ **TESTES E VALIDAÇÃO**

#### A. Antes de Considerar Feature "Completa"

**Checklist obrigatório:**
```markdown
- [ ] Código implementado e testado manualmente
- [ ] Console logs mostram execução correta
- [ ] Edge cases considerados (null, empty, erro de API)
- [ ] Documentação criada/atualizada
- [ ] Commit feito com mensagem descritiva
- [ ] STATUS-ATUAL atualizado
- [ ] Usuário informado do resultado
```

#### B. Teste de Regressão Rápido

**Antes de push para produção:**
```bash
# Testar fluxo básico:
1. Enviar mensagem texto → Verificar resposta
2. Enviar mídia (1 tipo) → Verificar processamento
3. Segunda mensagem → Verificar memória funcionando
4. Verificar logs sem erros
```

---

### 6️⃣ **ESTRUTURA DE ARQUIVOS**

#### A. Onde Criar Novos Arquivos

**Documentação Geral:**
- `/docs/` - Documentação técnica detalhada
- `/` (raiz) - Status, README, CHANGELOG

**Workflows e Implementação:**
- `/workflows/` - Arquivos JSON do n8n + docs de implementação
- `/database/` - Migrations, queries, RPCs

**Código de Referência:**
- `/workflows/*.js` - Códigos JavaScript de nodes (referência)
- `/database/queries/*.sql` - Queries úteis

#### B. Convenção de Nomes

**Arquivos de Status:**
- `STATUS-ATUAL-[DATA].md` (ex: STATUS-ATUAL-16-11-2025.md)
- `CHANGELOG.md` (único, sempre atualizado)

**Arquivos de Documentação:**
- `[TEMA]-[SUBTEMA].md` (ex: PROCESSAMENTO-MIDIA-INPUT.md)
- `FIX-[PROBLEMA].md` (ex: FIX-FORMATAR-HISTORICO-NODE.md)
- `GUIA-[TEMA].md` (ex: GUIA-RAPIDO-IMPLEMENTACAO.md)

**Arquivos de Código:**
- `[DESCRICAO]-[VERSAO].js` (ex: PROCESSADOR-MIDIA-COMPLETO-OTIMIZADO.js)
- `[NODE-NAME].js` (ex: CODIGO-FORMATAR-HISTORICO.js)

---

### 7️⃣ **COMUNICAÇÃO COM O USUÁRIO**

#### A. Ao Completar uma Tarefa

**Formato de resposta:**
```markdown
## ✅ [Título da Tarefa] - COMPLETO

**O que foi feito:**
- Item 1
- Item 2

**Arquivos criados/modificados:**
- arquivo1.md
- arquivo2.js

**Como testar:**
1. Passo 1
2. Passo 2

**Próximo passo recomendado:**
[Sugestão baseada em prioridade]

**Status do projeto:** X% completo
```

#### B. Ao Encontrar um Problema

**Formato de resposta:**
```markdown
## ⚠️ PROBLEMA ENCONTRADO: [Título]

**Descrição:**
O que aconteceu

**Causa:**
Por que aconteceu

**Impacto:**
🔴 Bloqueia tudo / 🟡 Bloqueia feature / 🟢 Não bloqueia

**Soluções possíveis:**

### Opção A: [Nome]
- Prós: ...
- Contras: ...
- Tempo: Xh

### Opção B: [Nome]
[mesmo formato]

**Recomendação:** Opção X porque...

**Precisa de input?** Sim/Não
```

#### C. Ao Fazer uma Descoberta Importante

**Avisar imediatamente:**
```markdown
🔍 **DESCOBERTA IMPORTANTE:** [Título]

[Explicação breve]

**Impacto:** [Como isso muda o projeto]

**Já documentei em:** [nome-do-arquivo.md]
```

---

### 8️⃣ **PRIORIZAÇÃO INTELIGENTE**

#### A. Matriz de Prioridade

**Sempre avaliar tarefas assim:**

| Urgência/Importância | Importante | Não Importante |
|----------------------|------------|----------------|
| **Urgente** | 🔴 FAZER AGORA | 🟡 AGENDAR |
| **Não Urgente** | 🟢 PLANEJAR | ⚪ IGNORAR |

**Exemplos:**
- 🔴 Bug que quebra produção
- 🟡 Feature solicitada mas não crítica
- 🟢 Otimização que melhora performance
- ⚪ Documentação de código interno

#### B. Técnica Pomodoro Adaptada

**Sugestão de ritmo:**
```
1h - Implementação focada
10min - Documentar o que foi feito
Commit + Push

Repetir até tarefa completa
```

---

### 9️⃣ **RECUPERAÇÃO DE DESASTRES**

#### A. Se o Código Quebrou

**Procedimento:**
```bash
# 1. Identificar último commit funcionando
git log --oneline -20
git show <commit-hash>

# 2. Criar branch de backup
git branch backup-antes-fix

# 3. Voltar para commit bom
git reset --hard <commit-hash>

# 4. Reimplentar com cuidado
[fazer mudanças]
git add -A
git commit -m "fix: reimplementação cuidadosa de [feature]"
```

#### B. Se Perdeu Contexto

**Recuperar informações:**
```bash
# Ver todos os STATUS criados
ls -la STATUS*.md

# Ler o mais recente
cat STATUS-ATUAL-*.md | head -100

# Ver últimas mudanças importantes
git log --grep="feat:" --oneline -10
git diff HEAD~5 HEAD --stat
```

#### C. Se Precisa Explicar para Novo Dev/IA

**Gerar resumo automático:**
```bash
# Criar RESUMO-PARA-ONBOARDING.md com:
1. Ler STATUS-ATUAL mais recente
2. Ler últimos 10 commits
3. Listar arquivos em /workflows/ e /docs/
4. Explicar estado atual em 3 parágrafos
5. Listar 3 próximas tarefas prioritárias
```

---

### 🔟 **MÉTRICAS E KPIs**

#### A. Acompanhar Progresso

**A cada sessão, atualizar:**
```markdown
## Métricas da Sessão

**Duração:** Xh
**Features completadas:** X
**Bugs corrigidos:** X
**Documentos criados:** X
**Commits:** X
**Linhas de código:** +X / -Y
**Testes passando:** X/Y

**Produtividade:** ⭐⭐⭐⭐⭐ (self-assessment)
```

#### B. Velocity Tracking

**Atualizar em STATUS-ATUAL:**
```markdown
## 📈 Velocity (últimas 3 sessões)

| Data | Horas | Features | Commits | Progresso % |
|------|-------|----------|---------|-------------|
| 15/11 | 6h | 3 | 8 | 70% → 75% |
| 12/11 | 4h | 2 | 5 | 65% → 70% |
| 08/11 | 5h | 1 | 6 | 60% → 65% |

**Média:** ~5h/sessão, ~2 features/sessão, +5% progresso/sessão
```

---

## 🎯 CHECKLIST FINAL DA SESSÃO

**Antes de encerrar, SEMPRE:**

- [ ] Código funcionando e testado
- [ ] Commits feitos com mensagens descritivas
- [ ] STATUS-ATUAL atualizado (se mudanças significativas)
- [ ] CHANGELOG.md atualizado
- [ ] Documentação nova criada (se aplicável)
- [ ] Push para GitHub realizado
- [ ] Usuário informado do que foi feito
- [ ] Próximos passos sugeridos
- [ ] Checkpoint de recuperação criado (se milestone)

---

## 💡 LIÇÕES APRENDIDAS (Atualizar Continuamente)

### 1. **OpenAI Vision API não aceita PDFs**
- **Data**: 14/11/2025
- **Solução**: Extrair texto e enviar para GPT-4o
- **Arquivo**: `workflows/CORRECAO-PDF-FUNCIONAL.md`

### 2. **$input.first() vs $input.all()**
- **Data**: 11/11/2025
- **Problema**: Processava só 1 mensagem do histórico
- **Solução**: Usar `$input.all()` para pegar TODAS
- **Arquivo**: `workflows/FIX-FORMATAR-HISTORICO-NODE.md`

### 3. **Ordem de Salvamento de Memória**
- **Data**: 11/11/2025
- **Problema**: Bot não lembrava contexto
- **Solução**: Salvar User ANTES de buscar histórico
- **Arquivo**: `workflows/CORRECAO-FLUXO-MEMORIA.md`

### 4. **alwaysOutputData em RPCs**
- **Data**: 11/11/2025
- **Problema**: Node não executava em primeira conversa
- **Solução**: Habilitar `alwaysOutputData: true`
- **Arquivo**: `docs/CHATWOOT_MULTI_TENANCY.md`

### 5. **client_id Segurança**
- **Data**: 08/11/2025
- **Problema**: client_id podia ser spoofed via webhook
- **Solução**: Buscar client_id via RPC baseado em inbox_id
- **Arquivo**: `workflows/SEGURANCA-CLIENT-ID-BLINDAGEM.md`

_[Adicionar mais conforme descobrimos]_

---

## 🚀 FILOSOFIA DO PROJETO

**Princípios fundamentais:**

1. **Progresso > Perfeição**
   - Melhor funcional com debt técnico que perfeito e não terminado
   - Refatorar depois, entregar primeiro

2. **Documentar enquanto faz**
   - Não deixar para depois
   - Conhecimento fresco é mais preciso

3. **Testar cedo e frequentemente**
   - Bugs pequenos são fáceis de corrigir
   - Bugs acumulados são desastre

4. **Commits frequentes**
   - Checkpoint a cada 2h no máximo
   - Facilita rollback se necessário

5. **Comunicação clara**
   - IA explica decisões
   - Usuário entende o que está acontecendo
   - Próximo dev/IA entende o histórico

6. **Aprender com erros**
   - Documentar bugs e soluções
   - Não repetir mesmos erros
   - Compartilhar conhecimento

---

## 📞 RESUMO EXECUTIVO PARA IA

**Se você está lendo isso pela primeira vez, FAÇA:**

1. ✅ Leia `STATUS-ATUAL-[mais-recente].md` (10min)
2. ✅ Leia últimos 10 commits (`git log --oneline -10`)
3. ✅ Entenda onde estamos no projeto (milestone atual)
4. ✅ Pergunte ao usuário o que ele quer fazer HOJE
5. ✅ Planeje a sessão (tarefas, estimativas, prioridade)
6. ✅ Execute com commits frequentes
7. ✅ Documente descobertas imediatamente
8. ✅ Atualize STATUS ao final se relevante
9. ✅ Faça push para GitHub
10. ✅ Informe usuário e sugira próximos passos

**Lembre-se:**
- Você não está sozinho: commits anteriores são sua memória
- Documente para seu "eu futuro" (próxima IA que pegar o projeto)
- Priorize o que traz valor para o usuário
- Seja honesto sobre limitações e riscos
- Peça confirmação em decisões críticas

---

**Criado por**: GitHub Copilot + Victor Castro  
**Data**: 16/11/2025  
**Versão**: 1.0  
**Atualizar**: Sempre que descobrir algo importante!

---

## 🔄 HISTÓRICO DE ATUALIZAÇÕES DESTE DOC

| Data | Mudança | Motivo |
|------|---------|--------|
| 16/11/2025 | Criação inicial | Estabelecer protocolo de continuidade |
| _[próxima]_ | _[descrever]_ | _[motivo]_ |
