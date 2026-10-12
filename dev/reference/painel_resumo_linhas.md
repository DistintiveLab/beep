# Nucleo do resumo: valor mais recente (e o anterior) de cada indicador pedido na localidade, ate a data de corte

Nucleo do resumo: valor mais recente (e o anterior) de cada indicador
pedido na localidade, ate a data de corte

## Usage

``` r
painel_resumo_linhas(indicadores, valores, refdate = NULL)
```

## Arguments

- indicadores:

  data.frame com `mdata_id`, `rotulo`, `grupo` e `raiz` (uma linha por
  cartao do resumo, na ordem desejada)

- valores:

  tabela de
  [`painel_valores_local_todos()`](https://distintivelab.github.io/beep/dev/reference/painel_valores_local_todos.md)

- refdate:

  data de corte: sem ela, a observacao mais recente; com ela, a ultima
  observacao em ou antes da data (slider por data do resumo)
