# CLAUDE.md — avista-mintlify

Este arquivo fornece contexto ao Claude Code ao trabalhar neste repositório.

## Visão Geral

Este repositório contém a documentação pública da API, gerada com [Mintlify](https://mintlify.com).
Cada branch corresponde a uma marca (white-label) diferente. **Nunca misturar branding entre branches.**

## Branches e Branding

| Branch | Marca | API Base URL | Env Var Prefix | Suporte | Dashboard |
|--------|-------|-------------|----------------|---------|-----------|
| `main` | **Avista** | `https://api.avista.global` | `AVISTA_` | `suporte@avista.global` | `https://app.avista.global` |
| `firebanking` | **Fire Banking** | `https://api.public.firebanking.com.br` | `FIREBANKING_` | `suporte@firebanking.com.br` | `https://dashboard.firebanking.com.br` |
| `goforge` | **Forge** | `https://api.gateway.goforge.com.br` | `FORGE_` | `suporte@goforge.com.br` | `https://gateway.goforge.com.br/` |
| `ntxpay` | **NTX Pay** | `https://api.ntxpay.com` | `NTXPAY_` | `suporte@ntxpay.com` | `https://app.ntxpay.com` |
| `safirapay` | **Safira Pay** | `https://api.safirapay.com` | `SAFIRAPAY_` | `suporte@safirapay.com` | `https://app.safirapay.com` |

## Regras Críticas de Branding

Ao trabalhar em uma branch, usar **exclusivamente** o branding correspondente. Isso se aplica a:

- Nome da marca em textos e títulos
- URL base da API em exemplos de código
- Prefixo de variáveis de ambiente (ex: `AVISTA_CLIENT_ID`, `FIREBANKING_CLIENT_ID`, `FORGE_CLIENT_ID`, `NTXPAY_CLIENT_ID`, `SAFIRAPAY_CLIENT_ID`)
- E-mail de suporte
- Links de dashboard e navegação
- Nomes de participantes em diagramas Mermaid

## Configuração Visual por Branch

| Branch | Primary | Light | Dark | Tema padrão |
|--------|---------|-------|------|-------------|
| `main` | `#4A70B8` | `#6B8FD1` | `#355A9C` | — |
| `firebanking` | `#FF6B35` | `#FF8C5A` | `#E55A2B` | light |
| `goforge` | `#fe8b6e` | `#fe8b6e` | `#393e44` | light |
| `ntxpay` | `#18ac88` | `#18ac88` | `#163b6a` | light |
| `safirapay` | `#74b1f0` | `#74b1f0` | `#2d2a6f` | light |

## Padrão de Merge

Ao mergear `main` → branch white-label:
1. Fazer merge com `--no-commit --no-ff` para revisar conflitos
2. Resolver conflitos **mantendo o branding da branch destino**
3. Incorporar apenas mudanças de conteúdo (ex: tipos de campos, novos endpoints)
4. **OBRIGATÓRIO**: Executar a verificação de branding antes de commitar (ver seção abaixo)

## Verificação de Branding (Checklist Obrigatório)

Após qualquer merge, criação de branch ou alteração de conteúdo, executar este comando para garantir que não há vazamentos de branding. Substituir `BRANCH` pela branch atual:

```bash
# Definir padrão de busca conforme a branch
# Para safirapay: buscar por todas as OUTRAS marcas
# Exemplo para safirapay:
grep -rniE "firebanking|Fire Banking|goforge|Forge|ntxpay|NTX Pay|avista\.global|FIREBANKING_|NTXPAY_|FORGE_|AVISTA_" \
  --include="*.mdx" --include="*.json" . | grep -v CLAUDE.md | grep -v ".claude/"
```

### Pontos que devem ser verificados

Estes são os locais onde vazamentos de branding ocorrem com mais frequência:

| Arquivo | O que verificar |
|---------|----------------|
| `docs.json` | `name`, `colors`, `favicon`, `logo`, URLs (dashboard, status, docs), `navbar.primary.href`, `metadata` (og:*, twitter:*) |
| `index.mdx` | Título, descrição, URL da API, nome do portal, email de suporte, URLs de docs e status |
| `api-reference/introduction.mdx` | Mesmos campos do index.mdx |
| `api-reference/openapi.json` | `info.title`, `info.description`, `servers[0].url`, exemplos de webhook URL |
| `api-reference/guides/authentication.mdx` | URLs da API, prefixos de env vars (`MARCA_CLIENT_ID`, `MARCA_CLIENT_SECRET`), nome do portal |
| `api-reference/guides/quickstart.mdx` | Env vars, URLs da API, nome do painel |
| `api-reference/guides/webhook-resend.mdx` | URLs da API, env vars de token, **nome da classe C#** (ex: `SafiraPayClient`), URLs de webhook em exemplos |
| `api-reference/guides/webhooks/implementation.mdx` | Username de webhook (ex: `$WEBHOOK_USER = 'safirapay'`) |
| `api-reference/guides/webhooks/*.mdx` | Nomes de participantes em diagramas Mermaid |
| `pix-bacen/introduction.mdx` | Nome da API, participantes em diagramas Mermaid |
| `pix-bacen/authentication.mdx` | URLs da API, nome da API |
| `pix-bacen/activation.mdx` | Email de suporte |
| `pix-bacen/endpoints/*.mdx` | URLs da API nos exemplos de cURL |

### Causa-raiz de vazamentos (histórico)

Vazamentos de branding acontecem quando:
1. **Merge sem revisão**: merge de `main` → branch white-label sem verificar conflitos de branding
2. **Branch criada com sed incompleto**: o comando sed não cobriu todos os padrões (openapi.json, classes C#, diagramas Mermaid, usernames de webhook)
3. **Novos arquivos adicionados**: arquivos novos adicionados na `main` com branding Avista que não são convertidos ao mergear

## Como Criar uma Nova Branch White-Label

Siga estes passos para criar uma nova branch de marca a partir da branch white-label mais recente:

### 1. Criar a branch

```bash
# A partir da branch white-label mais recente
git checkout <branch-mais-recente>
git checkout -b <nova-branch>
```

### 2. Substituir todo o branding nos arquivos

**IMPORTANTE**: O comando deve cobrir TODOS os tipos de arquivo (.mdx, .json incluindo openapi.json) e TODOS os padrões de branding (URLs, nomes, env vars, classes, usernames).

```bash
# Substitua os valores entre < > pelos valores corretos
find . \( -name "*.mdx" -o -name "*.json" \) ! -path "./.git/*" ! -path "./.claude/*" ! -name "CLAUDE.md" -exec sed -i '' \
  -e 's|<NOME_MARCA_ANTERIOR>|<NOME_NOVA_MARCA>|g' \
  -e 's|api.<DOMINIO_ANTERIOR>|api.<NOVO_DOMINIO>|g' \
  -e 's|app.<DOMINIO_ANTERIOR>|app.<NOVO_DOMINIO>|g' \
  -e 's|docs.<DOMINIO_ANTERIOR>|docs.<NOVO_DOMINIO>|g' \
  -e 's|status.<DOMINIO_ANTERIOR>|status.<NOVO_DOMINIO>|g' \
  -e 's|suporte@<DOMINIO_ANTERIOR>|suporte@<NOVO_DOMINIO>|g' \
  -e 's|<PREFIXO_ANTERIOR>_|<NOVO_PREFIXO>_|g' \
  -e 's|<ClasseAnterior>Client|<NovaClasse>Client|g' \
  -e "s|webhooks/<slug_anterior>|webhooks/<novo_slug>|g" \
  -e "s|= '<slug_anterior>'|= '<novo_slug>'|g" \
  {} +
```

**Padrões frequentemente esquecidos** (verificar manualmente):
- `api-reference/openapi.json`: `info.title`, `info.description`, `servers[0].url`, exemplo de webhook URL
- `api-reference/guides/webhook-resend.mdx`: classe C# (ex: `FireBankingClient` → `NovaClient`)
- `api-reference/guides/webhooks/implementation.mdx`: username de webhook
- `pix-bacen/introduction.mdx`: participantes em diagramas Mermaid
- `docs.json`: favicon e logo (usar paths locais `/favicon.svg`, `/logo/light.svg`, `/logo/dark.svg`)

### 3. Atualizar `docs.json`

Campos a atualizar:
- `name`: nome da documentação
- `colors.primary`, `colors.light`, `colors.dark`: cores da marca
- `navigation.global.anchors`: URLs de Dashboard e Status
- `navigation.global.languages[0].href`: URL da documentação
- `navbar.primary.href`: URL do Dashboard
- `metadata`: og:site_name, og:title, og:description, twitter:title, twitter:description

### 4. Adicionar assets visuais

- `favicon.svg` — favicon do site
- `logo/light.svg` — logo para fundo claro
- `logo/dark.svg` — logo para fundo escuro

### 5. Atualizar este CLAUDE.md

Adicionar a nova branch nas tabelas de **Branches e Branding** e **Configuração Visual por Branch**.

### 6. Verificar ausência de vazamentos

```bash
# Buscar por TODAS as marcas que NÃO devem aparecer nesta branch
# Adaptar o padrão removendo a marca da branch atual
grep -rniE "firebanking|Fire Banking|goforge|Forge|ntxpay|NTX Pay|safirapay|Safira Pay|avista\.global|Avista|FIREBANKING_|NTXPAY_|FORGE_|SAFIRAPAY_|AVISTA_|framerusercontent|cloudinary" \
  --include="*.mdx" --include="*.json" . | grep -v CLAUDE.md | grep -v ".claude/"

# Se houver resultados, corrigir antes de commitar!
```

### 7. Commit e push

```bash
git add -A
git commit -m "chore(branding): inicializar branch <nova-branch> com branding <Nome Marca>"
git push -u origin <nova-branch>
```

### 8. Atualizar o CLAUDE.md do bootstrap

No repositório `avista-platform-bootstrap-v2`, adicionar a nova entrada na tabela de branding do `CLAUDE.md`.

## Desenvolvimento Local

```bash
mintlify dev        # Inicia em http://localhost:3000 (ou próxima porta livre)
./restart-docs.sh   # Limpa cache e reinicia
```

## Estrutura do Repositório

```
avista-mintlify/
├── docs.json                    # Configuração principal (nome, cores, logo, navegação)
├── favicon.svg                  # Favicon do site
├── logo/
│   ├── light.svg                # Logo para fundo claro
│   └── dark.svg                 # Logo para fundo escuro
├── api-reference/
│   ├── introduction.mdx
│   ├── guides/                  # Guias de integração
│   │   └── webhooks/            # Documentação de webhooks
│   ├── endpoints/               # Referência dos endpoints (OpenAPI)
│   └── openapi.json             # Spec OpenAPI
└── pix-bacen/                   # Documentação PIX Bacen (SPI)
    ├── endpoints/
    └── webhooks/
```
