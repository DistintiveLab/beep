# Resumo da harmonizacao gravada em `tse_secao_bairro`

Resumo da harmonizacao gravada em `tse_secao_bairro`

## Usage

``` r
tse_resumo_harmonizacao(con = NULL, ano = NULL, uf = NULL)
```

## Arguments

- con:

  conexao DBI com o DW (default abre pelo idiom dos `garantir_*`).

- ano, uf:

  filtro do trecho; `NULL` traz todos.

## Value

lista com `por_nivel` (data.frame ano x uf x nivel x metodo com secoes e
localidades distintas) e `n_secoes_total`.
