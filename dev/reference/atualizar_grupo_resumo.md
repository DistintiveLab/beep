# Define o grupo Resumo do painel no DW

Idempotente: garante o `datagroup` "Resumo" (criando quando falta) e
sincroniza os vínculos de `mdata_group` com exatamente os indicadores
pedidos, inserindo os que faltam e removendo os excedentes somente deste
grupo (vínculos de outros grupos nunca são tocados). Conjunto vazio
remove todos os membros e deixa o grupo declarado.

## Usage

``` r
atualizar_grupo_resumo(mdata_ids = integer(0), con = NULL, verbose = TRUE)
```

## Arguments

- mdata_ids:

  integer (ou conversível) com os mdata_id desejados

- con:

  conexão aberta com o DW; por padrão abre uma com as variáveis de
  ambiente `user`, `password`, `host` e `dbname`

- verbose:

  imprime o resumo do que foi feito

## Value

invisivel, uma lista com `grupo_id`, `inserir` e `remover`
