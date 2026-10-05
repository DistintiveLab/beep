# Atualiza um esqueleto de painel ja gerado, preservando edicoes locais

Companheira de
[`deploy_panel()`](https://distintivelab.github.io/beep/reference/deploy_panel.md)
com `esqueleto = TRUE`: quando uma versao nova do beep traz melhorias no
painel (bug fix de modulo, novo asset), `atualizar_painel()` absorve
essas mudancas no esqueleto ja materializado no projeto **sem destruir o
que o projeto adaptou**.

## Usage

``` r
atualizar_painel(diretorio = "painel", forcar = FALSE)
```

## Arguments

- diretorio:

  caminho do diretorio da app (default "painel")

- forcar:

  substitui tambem arquivos modificados localmente (default FALSE)

## Value

caminho absoluto do diretorio da app (invisivel)

## Details

O mecanismo usa o `esqueleto_manifest.json` gerado junto com a app: para
cada arquivo previsto nesta versao,

- **intacto** (hash local igual ao hash do manifest) — substituido pela
  versao nova do beep;

- **modificado localmente** — preservado como esta e reportado no fim (o
  hash upstream esperado continua no manifest, entao a divergencia segue
  detectavel na proxima atualizacao); mescle as mudancas manualmente ou
  repontue com `forcar = TRUE`;

- **novo nesta versao** — adicionado; arquivo previsto antes e retirado
  do esqueleto — apenas reportado, nunca apagado.

`forcar = TRUE` substitui inclusive os arquivos com edicoes locais
(destructivo — descarta as adaptacoes do projeto).
