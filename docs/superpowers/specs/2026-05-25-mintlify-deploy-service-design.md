# Serviço de Deploy — advanced-mintlify (NTX Pay)

**Data:** 2026-05-25 (revisado após inspeção do repositório)
**Repo:** `advanced-digital-services/advanced-mintlify`
**Branch alvo:** `main` (marca NTX Pay; `docs.json.name = "NTX Pay API"`)
**Status:** Design aprovado — pendente plano de implementação

## Visão geral

O `advanced-mintlify` é a documentação pública da API. A hospedagem é feita pelo **Mintlify SaaS**,
que faz deploy automático no push para a branch configurada no dashboard.

> **Correção vs. CLAUDE.md:** o `CLAUDE.md` descreve um modelo white-label "uma marca por branch"
> (5 branches). Na realidade, **só existe a branch `main`** no remoto, e ela já é a **NTX Pay México**
> (commit `7371b45 docs: rewrite for NTX Pay México`, conteúdo multilíngue `en/`/`es/`/`pt-br/`,
> SPEI/OXXO). O modelo multi-branch está obsoleto. O serviço de deploy tem como alvo a `main`.

Como o deploy em si é SaaS (fora do controle do repositório), o "serviço de deploy" que faz
sentido criar **dentro do repo** é um **gate de qualidade em CI** que roda antes da doc chegar à
branch de deploy, mais um **runbook** dos passos que só existem no dashboard. Objetivo: impedir
que documentação quebrada — ou com vazamento de branding de outra marca — seja publicada.

## Objetivos

- Bloquear merge para `main` quando a doc tem links internos quebrados ou JSON inválido.
- Bloquear merge quando vazar branding de outra marca para dentro do repo NTX Pay (guarda histórica).
- Documentar os passos de configuração que só existem no dashboard do Mintlify.

## Não-objetivos

- Hospedar/servir a doc a partir do cluster K3s (padrão `build-and-deploy.yml` com helm/WireGuard
  dos outros repos — **não se aplica** ao Mintlify hosted).
- Automatizar configuração de dashboard (branch de deploy, domínio custom, DNS, preview) — manual,
  documentado no runbook.
- Reativar o modelo white-label multi-branch.

## Arquitetura

Três componentes, todos na branch `main`:

```
advanced-mintlify/  (branch main)
├── .github/workflows/docs-ci.yml   # gate de CI (validação + branding)
├── scripts/check-branding.sh       # fonte única do check anti-vazamento (CI + local)
└── DEPLOY.md                       # runbook dos passos de dashboard
```

### 1. `.github/workflows/docs-ci.yml`

Gate de CI. **Triggers:**
- `pull_request` → `main`: roda o gate antes do merge (gate real via branch protection).
- `push` → `main`: roda como sinal pré/pós-deploy (o Mintlify deploya independente do resultado).

**Jobs (paralelos):**

- **`validate`**
  1. `actions/checkout@v4`
  2. `actions/setup-node@v4` (Node 20)
  3. `npm i -g mint`
  4. `mint broken-links` — links internos quebrados
  5. `jq empty docs.json` e `jq empty api-reference/openapi.json` — JSON válido
- **`branding`**
  1. `actions/checkout@v4`
  2. `bash scripts/check-branding.sh "${{ github.base_ref || github.ref_name }}"`

O gate é o conjunto dos dois jobs passarem.

### 2. `scripts/check-branding.sh`

Fonte única da verificação de branding (substitui o grep manual do `CLAUDE.md`). Reutilizável:
roda igual no CI e localmente.

**Contrato:**
- `$1` = branch (default: branch git corrente, ou `main`). `$2` = diretório a escanear (default: `.`).
- Mapeia **branch → marca mantida → tokens proibidos** (tokens das outras marcas).
- Dois passes de `grep` em `--include="*.mdx" --include="*.json"`, excluindo `CLAUDE.md`,
  `.claude/`, `.git/`, `docs/superpowers/`:
  - **strict** (`grep -iwE`, palavra inteira) para tokens com risco de falso-positivo: `avista`, `forge`.
  - **loose** (`grep -iE`, substring) para o resto: nomes compostos, domínios, prefixos de env, assets.
- Exit `0` se limpo; exit `1` imprimindo as ocorrências.

**Mapa de tokens (corrigido p/ uma marca por enquanto; branch-aware para o futuro):**

| Branch | Marca mantida | strict (-iwE) | loose (-iE) |
|---|---|---|---|
| `main` | **NTX Pay** | `avista` | `firebanking\|fire banking\|goforge\|safirapay\|safira pay\|avista\.global\|firebanking\.com\.br\|goforge\.com\.br\|safirapay\.com\|AVISTA_\|FIREBANKING_\|GOFORGE_\|FORGE_\|SAFIRAPAY_\|framerusercontent\|res\.cloudinary\.com` |

> **Refinamento vs. CLAUDE.md (após achar falsos-positivos reais no conteúdo, 2026-05-25):**
> - `-iwE` em `avista` (palavra inteira) evita `avistar`/`à vista`.
> - O token solto `forge` foi **removido**: é verbo inglês legítimo (ex.: "anyone can *forge*
>   notifications" em docs de segurança de webhook). A marca Forge segue coberta de forma inequívoca
>   por `goforge` / `FORGE_` / `goforge.com.br` no loose.
> - `cloudinary` foi estreitado para `res\.cloudinary\.com` (subdomínio que serve assets): pega
>   URL de asset de marca vazado, mas não o link genérico `cloudinary.com` que aparece em boilerplate
>   do Mintlify recomendando o produto como CDN.
> - `framerusercontent` mantido (só aparece como host de asset vazado de site white-label).
>
> Conteúdo atual validado limpo na inspeção (2026-05-25) com o padrão refinado, **sem alterar prosa**.

### 3. `DEPLOY.md` (raiz do repo)

Runbook operacional (não publicado — não está na navegação do `docs.json`). Conteúdo:

1. **GitHub App do Mintlify** — instalar e conectar o repositório.
2. **Branch de deploy** — confirmar no dashboard como `main`.
3. **Domínio custom** — domínio de docs NTX Pay + registro DNS CNAME apontando para o alvo do Mintlify.
4. **Preview por PR** — confirmar preview automático do GitHub App nos PRs.
5. **Branch protection** — exigir o check `docs-ci` como required status check antes do merge para
   `main` (é o que transforma o CI em gate real).
6. **Validação local** — como rodar `mint broken-links` e `scripts/check-branding.sh` antes de abrir PR.
7. **Troubleshooting** — deploy não dispara: App instalado no repo certo + branch de deploy = `main`.

## Fluxo de dados

```
Dev abre PR → main
        │
        ▼
docs-ci.yml dispara (pull_request)
        ├── validate:  mint broken-links + jq (docs.json, openapi.json)
        └── branding:  check-branding.sh main
        │
        ▼
Ambos passam? ──não──► PR bloqueado (branch protection)
        │sim
        ▼
Merge em main → push
        ├── docs-ci.yml roda de novo (sinal)
        └── Mintlify SaaS detecta push → deploy automático → domínio NTX Pay
```

## Decisões de design

- **Script separado do YAML**: roda local (pré-commit, como manda o `CLAUDE.md`) e no CI; YAML enxuto.
- **Branch-aware mesmo com uma branch**: o mapa suporta as 5 marcas; hoje só `main`/NTX Pay é exercido.
  Custo zero e evita reescrever se o white-label voltar.
- **`pull_request` como gate principal**: usa o workflow da branch base (`main`), então o arquivo
  precisa existir em `main`. O gate real vem da branch protection — documentado no runbook.
- **Sem Docker/helm/WireGuard**: deliberadamente diferente do `build-and-deploy.yml`, porque o
  deploy é SaaS.

## Verificação (como saber que está pronto)

- `bash scripts/check-branding.sh main` na `main` retorna `0` (sem vazamento).
- Inserir "Avista" proposital em um `.mdx` faz o script retornar `1`; remover volta a `0`.
- "enforce"/"avistar"/"forge notifications"/link `cloudinary.com` em um `.mdx` **não** disparam
  (falsos-positivos). Já uma URL `res.cloudinary.com/...` **dispara** (asset real vazado).
- `mint broken-links` roda sem erros.
- `jq empty docs.json` e `jq empty api-reference/openapi.json` passam.
- O workflow aparece no GitHub Actions e passa em um PR de teste contra `main`.

## Riscos / pontos a validar

- **Disponibilidade do `mint` no CI**: confirmar que `npm i -g mint` + `mint broken-links` roda
  headless no runner sem exigir login (broken-links é análise local — não deve exigir).
- **Branch protection** depende de permissão de admin no repo — passo manual de dashboard/GitHub.
- **Commits/push** só após confirmação explícita do usuário (regra absoluta do projeto).
