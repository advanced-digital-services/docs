# Serviço de Deploy advanced-mintlify (NTX Pay) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **REGRA DO PROJETO (absoluta):** nenhum `git commit`/`git push` sem **confirmação explícita do
> usuário**. Os passos de commit abaixo existem como marcos, mas o executor DEVE pausar e pedir
> confirmação antes de rodá-los. Antes de qualquer commit, rodar `npx eslint . --fix` **não se
> aplica** (repo sem JS), mas o gate local (`check-branding.sh` + `mint broken-links`) deve passar.

**Goal:** Criar um gate de CI (broken-links + JSON + anti-vazamento de branding) e um runbook de deploy para a doc NTX Pay hospedada no Mintlify SaaS, na branch `main`.

**Architecture:** Workflow GitHub Actions (`docs-ci.yml`) com dois jobs paralelos — `validate` (mint broken-links + `jq`) e `branding` (script dedicado). A lógica de branding vive em `scripts/check-branding.sh`, reutilizável local e no CI. Deploy em si permanece no Mintlify SaaS; passos de dashboard ficam em `DEPLOY.md`.

**Tech Stack:** GitHub Actions, Bash, GNU grep/jq, Node 20, Mintlify CLI (`mint`).

---

## File Structure

- `scripts/check-branding.sh` *(criar)* — check anti-vazamento de branding, branch-aware. Único responsável pela detecção de marca alheia.
- `.github/workflows/docs-ci.yml` *(criar)* — orquestra o gate (jobs `validate` + `branding`).
- `DEPLOY.md` *(criar)* — runbook dos passos manuais de dashboard + validação local.
- `docs/superpowers/specs/2026-05-25-mintlify-deploy-service-design.md` *(já existe)* — spec de referência.

Ordem de implementação: **Task 1** (script, com testes) → **Task 2** (workflow, consome o script) → **Task 3** (runbook).

---

## Task 1: Script de check de branding (`scripts/check-branding.sh`)

**Files:**
- Create: `scripts/check-branding.sh`
- Test: validação manual com fixtures em diretório temporário (bash puro, sem framework)

- [ ] **Step 1: Criar o script com o contrato definido**

Criar `scripts/check-branding.sh` com este conteúdo exato:

```bash
#!/usr/bin/env bash
# check-branding.sh — detecta vazamento de branding de outra marca no repositório.
# Uso: scripts/check-branding.sh [branch] [scan_dir]
#   branch   : branch corrente (default: branch git atual, ou "main")
#   scan_dir : diretório a escanear (default: ".")
# Saída: exit 0 se limpo; exit 1 se houver vazamento; exit 2 em erro de uso.
set -euo pipefail

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)}"
SCAN_DIR="${2:-.}"

[[ -d "$SCAN_DIR" ]] || { echo "::error::scan_dir '$SCAN_DIR' não encontrado"; exit 2; }

# STRICT e LOOSE são strings de alternância ERE (separadas por '|'), não arrays.
# STRICT: palavra inteira (grep -iwE) p/ tokens com risco de falso-positivo.
# LOOSE : substring (grep -iE) p/ nomes compostos, domínios, env prefixes, assets externos.
case "$BRANCH" in
  main|ntxpay)  # marca mantida: NTX Pay
    STRICT='avista'
    LOOSE='firebanking|fire banking|goforge|safirapay|safira pay|avista\.global|firebanking\.com\.br|goforge\.com\.br|safirapay\.com|AVISTA_|FIREBANKING_|GOFORGE_|FORGE_|SAFIRAPAY_|framerusercontent|res\.cloudinary\.com'
    ;;
  *)
    echo "::warning::branch '$BRANCH' sem mapa de branding definido — pulando check"
    exit 0
    ;;
esac

# Só conteúdo publicável (.mdx/.json). docs/superpowers/ (specs/plans) e dirs de infra
# ficam fora via --exclude-dir (path-safe; não filtra por conteúdo da linha).
# CLAUDE.md (.md) já não entra no scan por causa do --include.
EXCLUDES=(--include='*.mdx' --include='*.json'
          --exclude-dir='.claude' --exclude-dir='.git'
          --exclude-dir='node_modules' --exclude-dir='superpowers')

found=0
tmp_out="$(mktemp)"
trap 'rm -f "$tmp_out"' EXIT

# grep retorna 1 quando não há match; o 'if' isenta do set -e.
if grep -rniwE "${EXCLUDES[@]}" "$STRICT" "$SCAN_DIR" >> "$tmp_out"; then
  found=1
fi
if grep -rniE "${EXCLUDES[@]}" "$LOOSE" "$SCAN_DIR" >> "$tmp_out"; then
  found=1
fi

if [[ "$found" -eq 1 ]]; then
  echo "❌ Vazamento de branding detectado na branch '$BRANCH' (marca esperada: NTX Pay):"
  sort -u "$tmp_out"
  exit 1
fi

echo "✅ Sem vazamento de branding na branch '$BRANCH'."
exit 0
```

- [ ] **Step 2: Tornar executável**

Run: `chmod +x scripts/check-branding.sh`
Expected: sem saída, exit 0.

- [ ] **Step 3: Teste — repo real limpo deve passar**

Run: `bash scripts/check-branding.sh main .`
Expected: imprime `✅ Sem vazamento de branding na branch 'main'.` e exit 0.
(Conteúdo atual já foi inspecionado como limpo em 2026-05-25.)

Verificar exit code:
Run: `bash scripts/check-branding.sh main . ; echo "exit=$?"`
Expected: `exit=0`

- [ ] **Step 4: Teste de falha — vazamento detectado**

Criar fixtures temporárias e validar que o script falha:

```bash
TMP="$(mktemp -d)"
printf '# Doc NTX Pay\nUse a API NTX Pay.\n' > "$TMP/clean.mdx"
printf '# Vazada\nBem-vindo à Avista e ao Fire Banking.\n' > "$TMP/leak.mdx"
bash scripts/check-branding.sh main "$TMP" ; echo "exit=$?"
```

Expected: imprime `❌ Vazamento de branding detectado ...` listando `leak.mdx` (Avista + Fire Banking) e `exit=1`.

- [ ] **Step 5: Teste de falso-positivo — não pode disparar em palavras/menções legítimas**

```bash
TMP="$(mktemp -d)"
printf '# Texto\nWe enforce limits. Do not forget. Pague à vista (avistar não).\n' > "$TMP/ok.mdx"
printf '# Webhook\nanyone can forge notifications without the signature.\n' > "$TMP/forge.mdx"
printf '# Imagens\nHost on [Cloudinary](https://cloudinary.com/) or S3.\n' > "$TMP/cloud.mdx"
printf '{"note":"enforce and forget"}\n' > "$TMP/ok.json"
bash scripts/check-branding.sh main "$TMP" ; echo "exit=$?"
rm -rf "$TMP"
```

Expected: `✅ Sem vazamento ...` e `exit=0`. O `avista` é `-iwE` (palavra inteira) → `avistar`/`à vista` não casam. `forge` NÃO está mais no padrão (verbo inglês legítimo em docs de segurança); a marca Forge é coberta por `goforge`/`FORGE_`/`goforge.com.br`. O link genérico `cloudinary.com` não casa `res\.cloudinary\.com` (só asset real vaza).

- [ ] **Step 5b: Teste — asset real do Cloudinary deve vazar**

```bash
TMP="$(mktemp -d)"
printf '# Logo\n![logo](https://res.cloudinary.com/acme/logo.png)\n' > "$TMP/asset.mdx"
bash scripts/check-branding.sh main "$TMP" ; echo "exit=$?"
rm -rf "$TMP"
```

Expected: `❌ Vazamento ...` listando `asset.mdx` e `exit=1` (URL de asset `res.cloudinary.com` é vazamento real).

- [ ] **Step 6: Teste — limpa fixtures de vazamento**

Run: `rm -rf "$TMP"` (se ainda existir do Step 4)
Expected: sem erro.

- [ ] **Step 7: Commit** *(pausar e confirmar com o usuário antes de rodar)*

```bash
git add scripts/check-branding.sh
git commit -m "feat(ci): add branch-aware branding-leak check script"
```

---

## Task 2: Workflow de CI (`.github/workflows/docs-ci.yml`)

**Files:**
- Create: `.github/workflows/docs-ci.yml`

- [ ] **Step 1: Criar o workflow**

Criar `.github/workflows/docs-ci.yml` com este conteúdo exato:

```yaml
name: Docs CI

# Gate de qualidade da doc ANTES do Mintlify SaaS publicar.
# O deploy em si é feito pelo Mintlify (push na branch de deploy configurada
# no dashboard = main). Este workflow NÃO faz deploy — valida e barra branding.
#
# Triggers:
# - pull_request -> main : gate real (combinar com required status check / branch protection)
# - push        -> main : sinal pré/pós-deploy (Mintlify deploya independente do resultado)

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: docs-ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  validate:
    name: Validate docs (links + JSON)
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install Mintlify CLI
        run: npm i -g mint

      - name: Validate JSON (docs.json + openapi.json)
        run: |
          jq empty docs.json
          jq empty api-reference/openapi.json
          echo "✅ JSON válido"

      - name: Check broken internal links
        run: mint broken-links

  branding:
    name: Branding leak check
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@v4

      - name: Run branding check
        run: bash scripts/check-branding.sh "${{ github.base_ref || github.ref_name }}"
```

- [ ] **Step 2: Validar sintaxe YAML localmente**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/docs-ci.yml')); print('YAML OK')"`
Expected: `YAML OK`

- [ ] **Step 3: Validar que o job branding casa com o contrato do script**

Conferir que o argumento passado (`github.base_ref` em PR = `main`; `github.ref_name` em push = `main`) é uma branch coberta pelo `case` do script (`main|ntxpay`).
Run: `bash scripts/check-branding.sh main . ; echo "exit=$?"`
Expected: `exit=0` (mesma invocação que o CI fará).

- [ ] **Step 4: (Opcional) Smoke test do mint broken-links local**

Se o `mint` estiver instalado localmente:
Run: `mint broken-links`
Expected: roda e reporta links (idealmente sem quebrados). Se `mint` não estiver instalado localmente, pular — o CI cobre.

- [ ] **Step 5: Commit** *(pausar e confirmar com o usuário antes de rodar)*

```bash
git add .github/workflows/docs-ci.yml
git commit -m "ci: add docs-ci gate (broken-links + JSON + branding)"
```

---

## Task 3: Runbook de deploy (`DEPLOY.md`)

**Files:**
- Create: `DEPLOY.md`

- [ ] **Step 1: Criar o runbook**

Criar `DEPLOY.md` na raiz com este conteúdo exato:

```markdown
# Deploy — NTX Pay API Docs

Esta documentação é hospedada pelo **Mintlify SaaS**. O deploy é **automático** no push para a
branch de deploy configurada no dashboard (`main`). Este repositório **não** faz deploy via
container/K3s — apenas valida a doc em CI (`.github/workflows/docs-ci.yml`) antes da publicação.

## Como o deploy funciona

```
push/merge em main ──► Mintlify GitHub App detecta ──► build + deploy automático ──► domínio NTX Pay
```

Pull Requests geram **preview deploys** automáticos via GitHub App do Mintlify.

## Configuração no dashboard (passos manuais — uma vez)

Feito em https://dashboard.mintlify.com (requer admin da organização e do repositório):

1. **Instalar o GitHub App do Mintlify**
   - Dashboard → Settings → GitHub App → instalar em `advanced-digital-services/advanced-mintlify`.
2. **Branch de deploy**
   - Dashboard → Settings → Git Settings → definir a **deployment branch = `main`**.
3. **Domínio custom**
   - Dashboard → Settings → Custom Domain → informar o domínio de docs da NTX Pay.
   - Criar o registro **DNS CNAME** apontando para o alvo informado pelo Mintlify.
4. **Preview por PR**
   - Confirmar que "Preview Deployments" está habilitado (gera link de preview em cada PR).
5. **Branch protection (transforma o CI em gate real)**
   - GitHub → repo → Settings → Branches → Add rule para `main`:
     - Require a pull request before merging.
     - Require status checks to pass before merging → selecionar **`Validate docs (links + JSON)`**
       e **`Branding leak check`** (jobs do workflow `Docs CI`).

## Validação local (antes de abrir PR)

```bash
# Links internos quebrados
npm i -g mint
mint broken-links

# Vazamento de branding (marca alheia no repo NTX Pay)
bash scripts/check-branding.sh main

# JSON válido
jq empty docs.json
jq empty api-reference/openapi.json
```

## Troubleshooting

- **Deploy não dispara após push:** verificar que o GitHub App está instalado no repositório certo
  e que a deployment branch no dashboard é `main` (bate com a branch do push).
- **CI falha em "Branding leak check":** rodar `bash scripts/check-branding.sh main` localmente; a
  saída lista o arquivo e o termo vazado. Corrigir o conteúdo (deve ser exclusivamente NTX Pay).
- **CI falha em "broken-links":** rodar `mint broken-links` local; corrigir os links internos
  apontados.
```

- [ ] **Step 2: Validar que o DEPLOY.md não entra na navegação publicada**

Run: `grep -c "DEPLOY" docs.json || true`
Expected: `0` (DEPLOY.md não está referenciado na navegação → não é publicado pelo Mintlify).

- [ ] **Step 3: Rodar o gate de branding sobre o repo já com os novos arquivos**

Run: `bash scripts/check-branding.sh main . ; echo "exit=$?"`
Expected: `exit=0` (DEPLOY.md cita "Avista"/"Fire Banking"? NÃO — o runbook não cita marcas alheias; confirmar `exit=0`).

> Nota: se o `DEPLOY.md` por algum motivo contiver nomes de outras marcas, o `.md` não é `.mdx`
> nem `.json`, então **não** é escaneado pelo script (que só inclui `*.mdx`/`*.json`). Sem risco.

- [ ] **Step 4: Commit** *(pausar e confirmar com o usuário antes de rodar)*

```bash
git add DEPLOY.md
git commit -m "docs: add Mintlify deploy runbook (NTX Pay)"
```

---

## Pós-implementação (manual, fora do código)

- [ ] Abrir PR `feature/docs-ci → main` via `gh pr create` *(confirmar com o usuário)*.
- [ ] Verificar que o workflow `Docs CI` roda no PR e ambos os jobs passam.
- [ ] Configurar branch protection exigindo os dois status checks (passo do `DEPLOY.md`).
- [ ] Executar os passos de dashboard do Mintlify (GitHub App, branch de deploy, domínio, preview).

---

## Self-review (preenchido)

- **Cobertura do spec:** gate broken-links+JSON → Task 2; anti-branding → Task 1 (script) + Task 2 (job); runbook dashboard → Task 3. ✔
- **Placeholders:** nenhum — todo código/comando está explícito. ✔
- **Consistência de tipos/nomes:** `scripts/check-branding.sh` com assinatura `[branch] [scan_dir]` usada de forma idêntica em Task 1 (testes), Task 2 (job `branding`) e Task 3 (validação local/runbook). Nomes dos jobs (`Validate docs (links + JSON)`, `Branding leak check`) batem entre o workflow (Task 2) e a instrução de branch protection (Task 3). ✔
```
