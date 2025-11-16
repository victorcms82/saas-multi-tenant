// ============================================================================
// NODE: "⚙️ Buscar Configuração de Memória"
// ============================================================================
// Busca configurações dinâmicas de memória (limit + hours) por agente
// ============================================================================

// Dados do workflow
const clientId = $input.item.json.client_id;
const agentId = $input.item.json.agent_id || 'default';

// Buscar configuração via RPC
const memoryConfig = await fetch(
  'https://vnlfgnfaortdvmraoapq.supabase.co/rest/v1/rpc/get_memory_config',
  {
    method: 'POST',
    headers: {
      'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubGZnbmZhb3J0ZHZtcmFvYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTM1NDgsImV4cCI6MjA3NzI4OTU0OH0.Qu6ithTk2tNNG-SYQDN5BP15pb_xKufOQUhqAuwxT0U',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      p_client_id: clientId,
      p_agent_id: agentId
    })
  }
).then(res => res.json());

// Extrair configurações
const config = memoryConfig[0] || {
  memory_limit: 50,
  memory_hours_back: 24,
  memory_enabled: true
};

console.log(`✅ Memória configurada: limit=${config.memory_limit}, hours=${config.memory_hours_back}, enabled=${config.memory_enabled}`);

return {
  json: {
    ...($input.item.json),
    memory_limit: config.memory_limit,
    memory_hours_back: config.memory_hours_back,
    memory_enabled: config.memory_enabled
  }
};
