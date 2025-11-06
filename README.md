# Plataforma de Agentes IA - Multi-Tenant SaaS
**Evolute Digital** - Plataforma SaaS de agentes IA

## 📋 Informações
- **Desenvolvedor**: Victor Castro
- **Empresa**: Evolute Digital
- **Contato**: victor@evolutedigital.com.br
- **GitHub**: https://github.com/victorcms82/saas-multi-tenant

## 🚀 Status do Projeto

- ✅ **Arquitetura**: Definida e documentada
- ✅ **Database Schema**: Completo (Supabase + pgvector)
- ✅ **WF 0 - Gestor Universal**: Implementado e testado
- ⚠️ **WF RAG Ingestion**: Em desenvolvimento
- ⚠️ **Frontend**: Planejado
- ⚠️ **Billing Integration**: Planejado

## 🎯 O que é este projeto?

Uma **plataforma SaaS Multi-Tenant** que permite vender e gerenciar múltiplos **Agentes de IA autônomos** para diferentes clientes de forma escalável. Cada agente pode ter personalidade, conhecimento e ferramentas únicas, operando 24/7 em múltiplos canais.

### Diferencial

- **Multi-tenant nativo**: 1 infraestrutura → N clientes
- **Conhecimento ilimitado**: RAG com pgvector
- **Multi-canal**: WhatsApp, Instagram, Email, Chat
- **Personalização total**: System prompts + tools dinâmicas
- **Observabilidade completa**: Logs, métricas, custos

## 🏗️ Arquitetura

```
┌─────────────────┐
│     Canais      │  WhatsApp, Instagram, Email, Chat
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  n8n Workflows  │  Orquestração e lógica de negócio
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌──────────┐
│Supabase│ │  Redis   │  Estado + Cache
│pgvector│ │  Memory  │
└────────┘ └──────────┘
    │
    ▼
┌─────────────────┐
│  Google Vertex  │  Gemini 2.0 Flash + Embeddings
│       AI        │
└─────────────────┘
```

## 📂 Estrutura do Repositório

```
saas-multi-tenant/
├── docs/                          # Documentação completa
│   ├── ARCHITECTURE.md           # Arquitetura técnica
│   ├── SUMARIO_EXECUTIVO.md      # Sumário mestre (8500+ linhas)
│   └── API_REFERENCE.md          # Referência de APIs
│
├── workflows/                     # Workflows n8n
│   ├── WF0-Gestor-Universal.json              # Part 1: Base Flow
│   ├── WF0-Gestor-Universal-Part2-LLM.json    # Part 2: LLM & Tools
│   ├── WF0-Gestor-Universal-Part3-Finalization.json  # Part 3: Final
│   ├── README.md                 # Documentação dos workflows
│   ├── SETUP.md                  # Guia de configuração
│   └── SUMMARY.md                # Resumo executivo
│
├── database/                      # Migrations e scripts SQL
│   └── migrations/
│
├── scripts/                       # Scripts de automação
│
└── README.md                      # Este arquivo
```

## 🔧 Stack Tecnológica

### Backend & Orchestration
- **n8n** v1.118.1 - Orquestração de workflows
- **Supabase** - PostgreSQL + pgvector + Vault
- **Redis** - Cache + Memória + Filas

### AI & ML
- **Google Vertex AI** - Gemini 2.0 Flash (LLM primário)
- **OpenAI** - GPT-4o-mini (fallback)
- **pgvector** - Vector database para RAG

### Infrastructure
- **Hetzner Cloud** - Servidor (CX21/CX31)
- **Easypanel** v2.23.0 - Docker management
- **Evolution API** - Gateway WhatsApp
- **Chatwoot** v4.7.0 - Hub de atendimento

### Integrações
- Google Calendar
- Pipedrive/HubSpot CRM
- Gmail API
- Stripe (billing)

## 🚀 Quick Start

### 1. Clone o Repositório

```bash
git clone https://github.com/victorcms82/saas-multi-tenant.git
cd saas-multi-tenant
```

### 2. Configure o Database (Supabase)

Siga as instruções em [`workflows/SETUP.md`](workflows/SETUP.md) seção 2.

### 3. Importe Workflows no n8n

```bash
# Acesse seu n8n
# Workflows → Import from File
# Importe os 3 arquivos JSON de workflows/
```

### 4. Configure Credentials

Veja [`workflows/README.md`](workflows/README.md) seção "Configurações Necessárias"

### 5. Teste o Sistema

```bash
# Envie uma mensagem de teste
curl -X POST "https://seu-n8n.com/webhook/gestor-ia?client_id=test-client" \
  -H "Content-Type: application/json" \
  -d '{
    "conversation": {"id": 999},
    "sender": {"name": "Teste User"},
    "content": "Olá, esta é uma mensagem de teste!"
  }'
```

## 📚 Documentação

### Principal
- **[SUMARIO_EXECUTIVO.md](docs/SUMARIO_EXECUTIVO.md)** - Documento mestre (8500+ linhas)
  - Arquitetura completa
  - Database schema
  - Estratégia de LLM
  - Workflows detalhados
  - Custos e ROI

### Workflows
- **[workflows/README.md](workflows/README.md)** - Como usar os workflows
- **[workflows/SETUP.md](workflows/SETUP.md)** - Guia de configuração
- **[workflows/SUMMARY.md](workflows/SUMMARY.md)** - Resumo do WF 0

### Arquitetura
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Detalhes técnicos
- **[docs/API_REFERENCE.md](docs/API_REFERENCE.md)** - Referência de APIs

## 🎯 Casos de Uso

| Agente | Função | Canais | Tools |
|--------|--------|--------|-------|
| **SDR** | Qualificação de leads | WhatsApp, Instagram, Email | RAG, Calendar, CRM |
| **Vendedor** | Negociação e fechamento | WhatsApp, Chat, Email | RAG, Calendar, Payments |
| **Suporte** | Troubleshooting e FAQ | Chatwoot, WhatsApp, Email | RAG, Ticket System |
| **Cobrança** | Lembretes e negociação | WhatsApp, Email, SMS | RAG, Payments, CRM |
| **Onboarding** | Ativação de clientes | Email, Chat, WhatsApp | RAG, Calendar, Docs |

## 💰 Modelo de Negócio

### Pricing Sugerido
- **Starter**: R$ 197/mês - 1 agente, 5k mensagens
- **Pro**: R$ 497/mês - 3 agentes, 20k mensagens
- **Enterprise**: R$ 997/mês - Ilimitado

### Custos Operacionais (por 10k msgs/mês)
- LLM (Gemini): ~$0.60
- Embeddings: ~$0.05
- Infraestrutura: ~$15-20
- **Total**: ~$16/mês por cliente médio

**Margem**: ~95% no plano Pro 🚀

## 🔐 Segurança

- ✅ HMAC signature validation em webhooks
- ✅ Secrets no Supabase Vault
- ✅ Rate limiting por cliente
- ✅ Tenant isolation (client_id)
- ✅ Row Level Security (RLS) ready
- ✅ SSL/TLS em todas as comunicações

## 📊 Observabilidade

### Métricas Registradas
- Total de execuções
- Latência (total e por componente)
- Custos em USD
- Tokens consumidos
- Taxa de sucesso/erro
- Usage por cliente (billing)

### Queries Úteis

```sql
-- Dashboard de hoje
SELECT 
  client_id,
  COUNT(*) as executions,
  AVG(total_latency_ms) as avg_latency,
  SUM(total_cost_usd) as total_cost
FROM agent_executions
WHERE timestamp > now() - interval '24 hours'
GROUP BY client_id;

-- Top 5 clientes por custo
SELECT 
  client_id,
  total_cost_usd,
  total_tokens
FROM client_usage
WHERE billing_period = date_trunc('month', now())
ORDER BY total_cost_usd DESC
LIMIT 5;
```

## 🛣️ Roadmap

### Fase 1 - MVP (Atual) ✅
- [x] Arquitetura definida
- [x] Database schema completo
- [x] WF 0: Gestor Universal
- [x] Integração Vertex AI + OpenAI
- [x] RAG híbrido (vector + keyword)
- [x] Multi-canal (Chatwoot + WhatsApp)

### Fase 2 - Expansion (1-2 meses)
- [ ] WF RAG Ingestion completo
- [ ] WF Onboarding automatizado
- [ ] Frontend (dashboard admin)
- [ ] Integração Stripe (billing)
- [ ] Instagram + Email channels
- [ ] Analytics e relatórios

### Fase 3 - Scale (3-6 meses)
- [ ] Horizontal scaling (n8n cluster)
- [ ] Multi-região
- [ ] Fine-tuning de modelos
- [ ] White-label para revendedores
- [ ] Marketplace de agentes
- [ ] Mobile app

## 🤝 Contribuindo

Este é um projeto privado da Evolute Digital. Para contribuições ou parcerias, entre em contato:

- **Email**: victor@evolutedigital.com.br
- **LinkedIn**: [Victor Castro](https://linkedin.com/in/victorcms82)

## 📄 Licença

Copyright © 2025 Evolute Digital. Todos os direitos reservados.

Este é um projeto proprietário. Uso não autorizado é proibido.

## 🙏 Agradecimentos

- **n8n** - Plataforma de automação incrível
- **Supabase** - Backend as a Service poderoso
- **Google Cloud** - IA de ponta com Vertex AI
- **Comunidade Open Source** - Inspiração constante

---

**Desenvolvido com ❤️ por Evolute Digital**

*Transformando empresas com Agentes de IA autônomos*
