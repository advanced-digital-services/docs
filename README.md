# Documentação API Avista

Documentação completa da API Pública Avista para integração com serviços de pagamento PIX e gestão de contas.

## Visão Geral

Esta documentação está construída com [Mintlify](https://mintlify.com) e fornece:

- **Guias detalhados** em português brasileiro
- **Exemplos práticos** em Node.js, Python e PHP
- **Casos de uso** de negócio reais
- **Referência completa da API** gerada automaticamente via OpenAPI
- **Playground interativo** para testar endpoints

## Estrutura da Documentação

```
api-reference/
├── introduction.mdx          # Introdução à API
├── openapi.json             # Especificação OpenAPI 3.0
├── openapi.mdx              # Página de referência interativa
└── guides/
    ├── authentication.mdx   # Guia de autenticação
    ├── balance.mdx          # Consulta de saldo
    ├── pix-cash-in.mdx      # Recebimento PIX
    ├── pix-cash-out.mdx     # Pagamento PIX
    └── pix-refund-in.mdx    # Estorno PIX
```

## Desenvolvimento Local

### Pré-requisitos

- Node.js 14 ou superior
- npm ou yarn

### Instalação

1. Instale a CLI do Mintlify:

```bash
npm install -g mint
```

2. Clone este repositório:

```bash
git clone <repository-url>
cd avista-mintlify
```

3. Execute o servidor de desenvolvimento:

```bash
mint dev
```

4. Acesse a documentação em: `http://localhost:3000`

### Hot Reload

A CLI do Mintlify possui hot reload automático. Qualquer alteração nos arquivos `.mdx` ou `docs.json` será refletida imediatamente no navegador.

## Atualizar Especificação OpenAPI

Para atualizar a especificação da API:

1. Obtenha o JSON mais recente do endpoint:

```bash
curl http://localhost:4008/api/docs-json > api-reference/openapi.json
```

2. A documentação será atualizada automaticamente

## Estrutura do Conteúdo

### Guias

Os guias são escritos em formato MDX (Markdown + JSX) e incluem:

- **Visão geral** do endpoint/funcionalidade
- **Exemplos de código** em múltiplas linguagens
- **Casos de uso** de negócio reais
- **Boas práticas** e validações
- **Tratamento de erros**

### Componentes Mintlify

A documentação usa componentes especiais do Mintlify:

```mdx
<Card title="Título" icon="icon-name" href="/link">
  Descrição
</Card>

<CardGroup cols={2}>
  <Card>...</Card>
  <Card>...</Card>
</CardGroup>

<Info>Informação importante</Info>
<Warning>Aviso</Warning>
<Note>Nota</Note>

<Accordion title="Título">
  Conteúdo expansível
</Accordion>

<Steps>
  <Step title="Passo 1">Descrição</Step>
  <Step title="Passo 2">Descrição</Step>
</Steps>
```

## Publicação

### Deploy Automático

A documentação é publicada automaticamente via GitHub App do Mintlify:

1. Instale o [GitHub App](https://dashboard.mintlify.com/settings/organization/github-app)
2. Conecte seu repositório
3. Toda alteração na branch `main` será deployada automaticamente

### Deploy Manual

Para fazer deploy manual, use o Mintlify CLI:

```bash
mint build
```

## Customização

### Cores e Tema

Edite o arquivo `docs.json`:

```json
{
  "theme": "mint",
  "colors": {
    "primary": "#16A34A",
    "light": "#07C983",
    "dark": "#15803D"
  }
}
```

### Navegação

A navegação é configurada em `docs.json` na seção `navigation`:

```json
{
  "navigation": {
    "tabs": [
      {
        "tab": "API Avista",
        "groups": [...]
      }
    ]
  }
}
```

### Logo

Substitua os arquivos em `/logo/`:

- `light.svg` - Logo para tema claro
- `dark.svg` - Logo para tema escuro

### Favicon

Substitua o arquivo `favicon.svg`

## Exemplos de Código

### Adicionar Novo Exemplo

```mdx
### Node.js

\`\`\`typescript
// Seu código aqui
\`\`\`

### Python

\`\`\`python
# Seu código aqui
\`\`\`
```

### Usar Tabs para Múltiplas Linguagens

```mdx
<Tabs>
  <Tab title="Node.js">
    \`\`\`javascript
    // código
    \`\`\`
  </Tab>
  <Tab title="Python">
    \`\`\`python
    # código
    \`\`\`
  </Tab>
</Tabs>
```

## Manutenção

### Adicionar Novo Endpoint

1. Atualize `api-reference/openapi.json` com o novo endpoint
2. Crie um guia em `api-reference/guides/nome-do-endpoint.mdx`
3. Adicione o guia em `docs.json` na seção de navegação
4. Inclua exemplos de código e casos de uso

### Atualizar Documentação Existente

1. Edite o arquivo `.mdx` correspondente
2. Teste localmente com `mint dev`
3. Faça commit e push para a branch `main`
4. O deploy será feito automaticamente

## Troubleshooting

### Preview não está funcionando

```bash
mint update
```

### Página carrega como 404

Certifique-se de que:
1. O arquivo está listado em `docs.json`
2. O caminho está correto
3. O arquivo `.mdx` existe no local especificado

### Erros de Build

Verifique:
1. Sintaxe MDX está correta
2. Componentes estão fechados corretamente
3. Links internos estão corretos

## Recursos

- [Documentação Mintlify](https://mintlify.com/docs)
- [Componentes Mintlify](https://mintlify.com/docs/content/components)
- [OpenAPI Support](https://mintlify.com/docs/api-playground/openapi/setup)
- [MDX Documentation](https://mdxjs.com/)

## Suporte

Para questões sobre a documentação:

- **Issues**: Abra uma issue neste repositório
- **Email**: suporte@avista.com.br
- **Documentação API**: https://docs.avista.com.br

## Licença

Copyright © 2024 Avista. Todos os direitos reservados.
