# ========================================
# SETUP AUTOMATICO - PLATAFORMA AGENTES IA
# ========================================

$ErrorActionPreference = "Stop"

# Funcao para escrever com cor
function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

# Criar diretorios
Write-ColorText "Criando diretorios..." "Blue"
$directories = @(
    "docs",
    "workflows\templates",
    "database\migrations",
    "scripts",
    ".github\workflows"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Write-ColorText "Criado diretorio: $dir" "Green"
}

# Criar arquivos base
$files = @{
    ".clinerules" = @"
# Claude Code Rules - Evolute Digital
## Contexto do Projeto
Plataforma SaaS multi-tenant de agentes IA
Proprietario: Victor Castro - Evolute Digital
Repositorio: https://github.com/victorcms82/saas-multi-tenant
"@

    "README.md" = @"
# Plataforma de Agentes IA - Multi-Tenant SaaS
**Evolute Digital** - Plataforma SaaS de agentes IA

## Informacoes
- Desenvolvedor: Victor Castro
- Empresa: Evolute Digital
- Contato: victor@evolutedigital.com.br
- GitHub: https://github.com/victorcms82/saas-multi-tenant
"@

    ".gitignore" = @"
.env
node_modules/
*.log
.DS_Store
"@

    "package.json" = @"
{
  "name": "plataforma-agentes-ia-evolute",
  "version": "1.0.0",
  "description": "Plataforma SaaS multi-tenant de agentes IA",
  "author": "Victor Castro <victor@evolutedigital.com.br>",
  "private": true,
  "scripts": {
    "dev": "nodemon index.js",
    "start": "node index.js"
  }
}
"@

    ".env.example" = @"
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_KEY=
GOOGLE_PROJECT_ID=
GOOGLE_LOCATION=
REDIS_URL=
CHATWOOT_URL=
CHATWOOT_API_TOKEN=
NODE_ENV=development
"@

    "docs\ARCHITECTURE.md" = "# Arquitetura do Sistema - Evolute Digital"
    "docs\API_REFERENCE.md" = "# API Reference - Evolute Digital"
    "docs\SUMARIO_EXECUTIVO.md" = "# Sumario Executivo - Plataforma Agentes IA"
}

foreach ($file in $files.Keys) {
    Write-ColorText "Criando arquivo: $file" "Blue"
    Set-Content -Path $file -Value $files[$file]
    Write-ColorText "Arquivo criado com sucesso!" "Green"
}

# Inicializar Git
Write-ColorText "Configurando Git..." "Blue"
if (!(Test-Path ".git")) {
    git init
    git config user.name "Victor Castro"
    git config user.email "victor@evolutedigital.com.br"
    Write-ColorText "Git inicializado" "Green"
}

# Resumo final
Write-ColorText "`nSETUP COMPLETO!`n" "Green"
Write-ColorText "Proximos passos:" "Yellow"
Write-Host @"
1. Configurar .env (copiar de .env.example)
2. Instalar dependencias: npm install
3. Commit inicial: git add .
4. Criar commit: git commit -m "Initial setup"
5. Configurar remote: git remote add origin https://github.com/victorcms82/saas-multi-tenant
6. Criar branch main: git branch -M main
7. Push: git push -u origin main

Repositorio: https://github.com/victorcms82/saas-multi-tenant
"@