# CLAUDE.md — advanced-mintlify

Este arquivo fornece contexto ao Claude Code ao trabalhar neste repositório.

## Visão Geral

Documentação pública da **API NTX Pay México** (Mintlify). O contrato HTTP documentado aqui é o exposto por `advanced-backend-public-ms` (microsserviço stateless de gateway público), branch `hml`.

**Escopo: México apenas** — SPEI (cash-in/cash-out) e OXXO (cash-in). Não há PIX/BACEN/MED neste repositório.

Cada branch corresponde a uma marca (white-label) diferente. **Nunca misturar branding entre branches.**

## Branches e Branding

| Branch | Marca | API Base URL | Env Var Prefix | Suporte | Dashboard |
|--------|-------|-------------|----------------|---------|-----------|
| `main` | **NTX Pay** | `https://api.ntxpay.com` | `NTXPAY_` | `suporte@ntxpay.com` | `https://app.ntxpay.com` |

Outras marcas (Fire Banking, Forge, Safira Pay) podem ser criadas em branches separadas seguindo o mesmo padrão. As cores e URLs específicas serão decididas no momento da criação.

## Regras Críticas de Branding

Ao trabalhar em uma branch, usar **exclusivamente** o branding correspondente. Isso se aplica a:

- Nome da marca em textos e títulos
- URL base da API em exemplos de código
- Prefixo de variáveis de ambiente (ex: `NTXPAY_CLIENT_ID`)
- E-mail de suporte
- Links de dashboard e navegação
- Nomes de participantes em diagramas Mermaid

## Configuração Visual (branch `main` = NTX Pay)

| Propriedade | Valor |
|---|---|
| Primary | `#18ac88` |
| Light | `#18ac88` |
| Dark | `#163b6a` |
| Tema padrão | `light` |

## Endpoints Cobertos

Documenta o contrato de `advanced-backend-public-ms` (branch `hml`):

| Tab | Grupo | Endpoints |
|-----|-------|-----------|
| Referência da API | Autenticação | `POST /api/auth/token` (X.509 + clientId/clientSecret) |
| Referência da API | Signup | `POST /api/signup` (público, sandbox ou produção) |
| Referência da API | Saldo | `GET /api/balance` (centavos MXN) |
| Referência da API | SPEI | `POST /api/spei/cash-in`, `POST /api/spei/cash-out` |
| Referência da API | OXXO | `POST /api/oxxo/cash-in` |
| Referência da API | Transações | `GET /api/transactions` (rate-limit 30/min por conta) |
| Referência da API | Webhooks Config | `GET`, `POST`, `DELETE /api/webhooks-config[/:id]` |

Endpoints do backend **não** expostos para o cliente externo: `/health/*` (interno k8s).

## Estrutura do Repositório

```
advanced-mintlify/
├── docs.json                    # Configuração principal (nome, cores, logo, navegação)
├── favicon.svg                  # Favicon do site
├── index.mdx                    # Landing page
├── logo/
│   ├── light.svg
│   └── dark.svg
└── api-reference/
    ├── introduction.mdx
    ├── guides/                  # Guias de integração (.mdx)
    │   ├── quickstart.mdx
    │   ├── signup.mdx
    │   ├── authentication.mdx
    │   ├── balance.mdx
    │   ├── spei-cash-in.mdx
    │   ├── spei-cash-out.mdx
    │   ├── oxxo-cash-in.mdx
    │   ├── transactions-list.mdx
    │   ├── sandbox-testing.mdx
    │   └── webhooks/
    │       ├── overview.mdx
    │       ├── setup.mdx
    │       ├── implementation.mdx
    │       ├── cash-in.mdx
    │       ├── cash-out.mdx
    │       ├── refund-in.mdx
    │       └── refund-out.mdx
    ├── endpoints/               # Stubs OpenAPI (frontmatter `openapi: METHOD /path`)
    │   ├── generate-token.mdx
    │   ├── signup.mdx
    │   ├── get-balance.mdx
    │   ├── spei-cash-in.mdx
    │   ├── spei-cash-out.mdx
    │   ├── oxxo-cash-in.mdx
    │   ├── transactions-list.mdx
    │   ├── webhooks-config-list.mdx
    │   ├── webhooks-config-setup.mdx
    │   └── webhooks-config-delete.mdx
    └── openapi.json             # Spec OpenAPI 3.0 (fonte de verdade dos schemas)
```

## Como atualizar quando o backend muda

1. **Endpoint novo**:
   - Atualize `api-reference/openapi.json` (path, schemas, tags)
   - Crie `api-reference/endpoints/<nome>.mdx` com frontmatter `openapi: METHOD /api/...`
   - Crie guia `api-reference/guides/<nome>.mdx` se for fluxo novo
   - Adicione referências no `docs.json` (`navigation.tabs[].groups[].pages`)

2. **Schema alterado** (campos novos, validators):
   - Atualize só `api-reference/openapi.json` — o playground reflete automático

3. **Renomear/remover endpoint**:
   - Atualize `openapi.json`
   - Renomeie/apague o `.mdx` correspondente
   - Atualize `docs.json` para refletir

## Verificação de Branding

Após qualquer merge ou criação de branch:

```bash
# Substitua o regex pelas marcas que NÃO devem aparecer nesta branch
grep -rniE "avista|firebanking|Fire Banking|goforge|Forge|safirapay|Safira Pay|AVISTA_|FIREBANKING_|FORGE_|SAFIRAPAY_" \
  --include="*.mdx" --include="*.json" . | grep -v CLAUDE.md | grep -v ".claude/"
```

Se houver resultados, corrigir antes de commitar.

## Desenvolvimento Local

```bash
mintlify dev        # Inicia em http://localhost:3000 (ou próxima porta livre)
./restart-docs.sh   # Limpa cache e reinicia
```
