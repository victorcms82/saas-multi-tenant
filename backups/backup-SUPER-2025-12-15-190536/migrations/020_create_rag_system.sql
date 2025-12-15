-- ============================================================================
-- MIGRATION 020: Sistema RAG Completo com pgvector
-- ============================================================================
-- Data: 16/11/2025
-- Descrição: Cria estrutura completa para RAG (Retrieval-Augmented Generation)
--            com suporte a embeddings vetoriais usando pgvector
-- ============================================================================

-- ============================================================================
-- PARTE 1: Criar Extensão pgvector
-- ============================================================================

-- Habilitar extensão pgvector (se ainda não habilitada)
CREATE EXTENSION IF NOT EXISTS vector;

COMMENT ON EXTENSION vector IS 'Vector similarity search for embeddings (OpenAI ada-002 = 1536 dimensions)';

-- ============================================================================
-- PARTE 2: Tabela rag_documents
-- ============================================================================

CREATE TABLE IF NOT EXISTS rag_documents (
  -- Identificação
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Multi-tenancy (isolamento por cliente e agente)
  client_id TEXT NOT NULL,
  agent_id TEXT NOT NULL DEFAULT 'default',
  
  -- Conteúdo
  content TEXT NOT NULL,
  content_hash TEXT NOT NULL, -- MD5 para deduplicação
  
  -- Vector embedding (OpenAI text-embedding-ada-002 = 1536 dimensões)
  embedding VECTOR(1536) NOT NULL,
  
  -- Metadados
  metadata JSONB DEFAULT '{}'::jsonb,
  
  -- Informações do documento original
  source_type TEXT, -- 'pdf', 'txt', 'url', 'manual', 'google_drive', 'notion'
  source_id TEXT,   -- ID do documento original (se aplicável)
  source_url TEXT,  -- URL original (se aplicável)
  file_name TEXT,   -- Nome do arquivo original
  
  -- Chunking info
  chunk_index INTEGER DEFAULT 0, -- Índice do chunk no documento
  total_chunks INTEGER DEFAULT 1, -- Total de chunks do documento
  
  -- Tracking
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by TEXT, -- Usuário que fez upload
  
  -- Constraints
  CONSTRAINT rag_documents_client_agent_fk 
    FOREIGN KEY (client_id, agent_id) 
    REFERENCES agents(client_id, agent_id)
    ON DELETE CASCADE,
  
  CONSTRAINT rag_documents_content_not_empty 
    CHECK (LENGTH(content) > 0),
  
  CONSTRAINT rag_documents_chunk_valid
    CHECK (chunk_index >= 0 AND chunk_index < total_chunks)
);

-- Comentários
COMMENT ON TABLE rag_documents IS 'Armazena documentos chunkeados com embeddings vetoriais para RAG';
COMMENT ON COLUMN rag_documents.embedding IS 'Vector embedding gerado por OpenAI ada-002 (1536 dims)';
COMMENT ON COLUMN rag_documents.content_hash IS 'MD5 hash do conteúdo para deduplicação';
COMMENT ON COLUMN rag_documents.metadata IS 'Metadados customizados: autor, tags, categoria, etc';

-- ============================================================================
-- PARTE 3: Índices Otimizados
-- ============================================================================

-- Índice IVFFlat para busca vetorial (vector cosine similarity)
-- lists = 100 é bom para até ~100k documentos
CREATE INDEX IF NOT EXISTS rag_documents_embedding_idx 
ON rag_documents 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

COMMENT ON INDEX rag_documents_embedding_idx IS 'Índice IVFFlat para busca vetorial rápida (cosine similarity)';

-- Índice para filtro multi-tenant (CRÍTICO para segurança!)
CREATE INDEX IF NOT EXISTS rag_documents_client_agent_idx 
ON rag_documents (client_id, agent_id);

-- Índice para busca por hash (deduplicação)
CREATE INDEX IF NOT EXISTS rag_documents_content_hash_idx 
ON rag_documents (content_hash);

-- Índice para busca por source
CREATE INDEX IF NOT EXISTS rag_documents_source_idx 
ON rag_documents (client_id, agent_id, source_type, source_id);

-- Índice para ordenação por data
CREATE INDEX IF NOT EXISTS rag_documents_created_at_idx 
ON rag_documents (created_at DESC);

-- Índice GIN para busca em metadata (JSONB)
CREATE INDEX IF NOT EXISTS rag_documents_metadata_idx 
ON rag_documents USING gin (metadata);

-- ============================================================================
-- PARTE 4: Trigger para updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_rag_documents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS rag_documents_updated_at_trigger ON rag_documents;
CREATE TRIGGER rag_documents_updated_at_trigger
  BEFORE UPDATE ON rag_documents
  FOR EACH ROW
  EXECUTE FUNCTION update_rag_documents_updated_at();

-- ============================================================================
-- PARTE 5: Row Level Security (RLS)
-- ============================================================================

ALTER TABLE rag_documents ENABLE ROW LEVEL SECURITY;

-- Policy: Usuários só veem documentos do próprio cliente
DROP POLICY IF EXISTS rag_documents_select_policy ON rag_documents;
CREATE POLICY rag_documents_select_policy
  ON rag_documents
  FOR SELECT
  USING (client_id = current_setting('app.current_client_id', true));

-- Policy: Usuários só inserem documentos no próprio cliente
DROP POLICY IF EXISTS rag_documents_insert_policy ON rag_documents;
CREATE POLICY rag_documents_insert_policy
  ON rag_documents
  FOR INSERT
  WITH CHECK (client_id = current_setting('app.current_client_id', true));

-- Policy: Usuários só deletam documentos do próprio cliente
DROP POLICY IF EXISTS rag_documents_delete_policy ON rag_documents;
CREATE POLICY rag_documents_delete_policy
  ON rag_documents
  FOR DELETE
  USING (client_id = current_setting('app.current_client_id', true));

COMMENT ON POLICY rag_documents_select_policy ON rag_documents IS 'Isola documentos por cliente (RLS)';

-- ============================================================================
-- PARTE 6: RPC Function - query_rag_documents
-- ============================================================================

CREATE OR REPLACE FUNCTION query_rag_documents(
  p_client_id TEXT,
  p_agent_id TEXT,
  p_query_embedding VECTOR(1536),
  p_limit INTEGER DEFAULT 5,
  p_threshold FLOAT DEFAULT 0.7
)
RETURNS TABLE (
  id UUID,
  content TEXT,
  similarity FLOAT,
  metadata JSONB,
  source_type TEXT,
  source_url TEXT,
  file_name TEXT,
  chunk_index INTEGER,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rd.id,
    rd.content,
    -- Calcular similaridade (1 - distância cosine)
    1 - (rd.embedding <=> p_query_embedding) AS similarity,
    rd.metadata,
    rd.source_type,
    rd.source_url,
    rd.file_name,
    rd.chunk_index,
    rd.created_at
  FROM rag_documents rd
  WHERE rd.client_id = p_client_id
    AND rd.agent_id = p_agent_id
    -- Filtrar apenas documentos acima do threshold de similaridade
    AND (1 - (rd.embedding <=> p_query_embedding)) > p_threshold
  -- Ordenar por similaridade (mais similar primeiro)
  ORDER BY rd.embedding <=> p_query_embedding
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION query_rag_documents IS 
  'Busca documentos similares usando vector search (cosine similarity). Retorna top K documentos acima do threshold de similaridade.';

-- ============================================================================
-- PARTE 7: RPC Function - save_rag_document
-- ============================================================================

CREATE OR REPLACE FUNCTION save_rag_document(
  p_client_id TEXT,
  p_agent_id TEXT,
  p_content TEXT,
  p_embedding VECTOR(1536),
  p_metadata JSONB DEFAULT '{}'::jsonb,
  p_source_type TEXT DEFAULT NULL,
  p_source_id TEXT DEFAULT NULL,
  p_source_url TEXT DEFAULT NULL,
  p_file_name TEXT DEFAULT NULL,
  p_chunk_index INTEGER DEFAULT 0,
  p_total_chunks INTEGER DEFAULT 1,
  p_created_by TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_content_hash TEXT;
  v_document_id UUID;
  v_existing_id UUID;
BEGIN
  -- Calcular hash do conteúdo para deduplicação
  v_content_hash := MD5(p_content);
  
  -- Verificar se já existe documento idêntico
  SELECT id INTO v_existing_id
  FROM rag_documents
  WHERE client_id = p_client_id
    AND agent_id = p_agent_id
    AND content_hash = v_content_hash
  LIMIT 1;
  
  -- Se já existe, retornar ID existente (deduplicação)
  IF v_existing_id IS NOT NULL THEN
    RETURN v_existing_id;
  END IF;
  
  -- Inserir novo documento
  INSERT INTO rag_documents (
    client_id,
    agent_id,
    content,
    content_hash,
    embedding,
    metadata,
    source_type,
    source_id,
    source_url,
    file_name,
    chunk_index,
    total_chunks,
    created_by
  ) VALUES (
    p_client_id,
    p_agent_id,
    p_content,
    v_content_hash,
    p_embedding,
    p_metadata,
    p_source_type,
    p_source_id,
    p_source_url,
    p_file_name,
    p_chunk_index,
    p_total_chunks,
    p_created_by
  )
  RETURNING id INTO v_document_id;
  
  RETURN v_document_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION save_rag_document IS 
  'Salva documento com embedding. Faz deduplicação por content_hash. Retorna UUID do documento (novo ou existente).';

-- ============================================================================
-- PARTE 8: RPC Function - delete_rag_documents_by_source
-- ============================================================================

CREATE OR REPLACE FUNCTION delete_rag_documents_by_source(
  p_client_id TEXT,
  p_agent_id TEXT,
  p_source_type TEXT,
  p_source_id TEXT
)
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  DELETE FROM rag_documents
  WHERE client_id = p_client_id
    AND agent_id = p_agent_id
    AND source_type = p_source_type
    AND source_id = p_source_id;
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION delete_rag_documents_by_source IS 
  'Deleta todos os chunks de um documento específico. Útil para atualizar documento (delete + re-upload).';

-- ============================================================================
-- PARTE 9: View para Estatísticas
-- ============================================================================

CREATE OR REPLACE VIEW rag_statistics AS
SELECT 
  client_id,
  agent_id,
  COUNT(*) AS total_documents,
  COUNT(DISTINCT source_id) AS unique_sources,
  SUM(LENGTH(content)) AS total_content_length,
  AVG(LENGTH(content)) AS avg_chunk_size,
  MIN(created_at) AS first_upload,
  MAX(created_at) AS last_upload
FROM rag_documents
GROUP BY client_id, agent_id;

COMMENT ON VIEW rag_statistics IS 'Estatísticas de documentos RAG por cliente/agente';

-- ============================================================================
-- PARTE 10: Dados de Exemplo (OPCIONAL - Comentado)
-- ============================================================================

/*
-- Exemplo: Inserir documento de teste
-- (Descomente para testar)

DO $$
DECLARE
  v_test_embedding VECTOR(1536);
  v_doc_id UUID;
BEGIN
  -- Gerar embedding fake (todos zeros - só para teste!)
  -- Em produção, usar OpenAI ada-002
  v_test_embedding := array_fill(0.0, ARRAY[1536])::VECTOR(1536);
  
  -- Inserir documento de teste
  v_doc_id := save_rag_document(
    p_client_id := 'test-client',
    p_agent_id := 'default',
    p_content := 'Este é um documento de teste para o sistema RAG.',
    p_embedding := v_test_embedding,
    p_metadata := '{"tags": ["teste", "exemplo"], "author": "system"}'::jsonb,
    p_source_type := 'manual',
    p_file_name := 'teste.txt'
  );
  
  RAISE NOTICE 'Documento de teste criado: %', v_doc_id;
END $$;
*/

-- ============================================================================
-- PARTE 11: Verificação
-- ============================================================================

DO $$
DECLARE
  v_extension_exists BOOLEAN;
  v_table_exists BOOLEAN;
  v_function_exists BOOLEAN;
BEGIN
  -- Verificar extensão vector
  SELECT EXISTS(
    SELECT 1 FROM pg_extension WHERE extname = 'vector'
  ) INTO v_extension_exists;
  
  IF NOT v_extension_exists THEN
    RAISE EXCEPTION 'Extensão vector não foi criada!';
  END IF;
  
  -- Verificar tabela
  SELECT EXISTS(
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'rag_documents'
  ) INTO v_table_exists;
  
  IF NOT v_table_exists THEN
    RAISE EXCEPTION 'Tabela rag_documents não foi criada!';
  END IF;
  
  -- Verificar function
  SELECT EXISTS(
    SELECT 1 FROM pg_proc WHERE proname = 'query_rag_documents'
  ) INTO v_function_exists;
  
  IF NOT v_function_exists THEN
    RAISE EXCEPTION 'Function query_rag_documents não foi criada!';
  END IF;
  
  RAISE NOTICE '✅ Migration 020 executada com sucesso!';
  RAISE NOTICE '   - Extensão vector: OK';
  RAISE NOTICE '   - Tabela rag_documents: OK';
  RAISE NOTICE '   - Function query_rag_documents: OK';
  RAISE NOTICE '   - Function save_rag_document: OK';
  RAISE NOTICE '   - Function delete_rag_documents_by_source: OK';
  RAISE NOTICE '   - View rag_statistics: OK';
END $$;

-- ============================================================================
-- ROLLBACK (se necessário)
-- ============================================================================

/*
-- Para reverter esta migration:

DROP VIEW IF EXISTS rag_statistics;
DROP FUNCTION IF EXISTS delete_rag_documents_by_source;
DROP FUNCTION IF EXISTS save_rag_document;
DROP FUNCTION IF EXISTS query_rag_documents;
DROP TRIGGER IF EXISTS rag_documents_updated_at_trigger ON rag_documents;
DROP FUNCTION IF EXISTS update_rag_documents_updated_at;
DROP TABLE IF EXISTS rag_documents CASCADE;
-- DROP EXTENSION IF EXISTS vector; -- CUIDADO: Pode afetar outras tabelas!

*/

-- ============================================================================
-- FIM DA MIGRATION 020
-- ============================================================================
