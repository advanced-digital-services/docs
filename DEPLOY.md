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
