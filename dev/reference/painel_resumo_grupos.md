# Resumo por grupo do catalogo: um cartao por indicador composto com o valor mais recente na localidade ate a data de corte (rotulo, valor e data) — conteudo do "Resumo da regiao" na aba Regiao

Resumo por grupo do catalogo: um cartao por indicador composto com o
valor mais recente na localidade ate a data de corte (rotulo, valor e
data) — conteudo do "Resumo da regiao" na aba Regiao

## Usage

``` r
painel_resumo_grupos(hierarquia, compostos, valores, refdate = NULL)
```

## Arguments

- hierarquia:

  tabela de
  [`painel_hierarquia()`](https://distintivelab.github.io/beep/dev/reference/painel_hierarquia.md)

- compostos:

  tabela de
  [`painel_compostos()`](https://distintivelab.github.io/beep/dev/reference/painel_compostos.md)

- valores:

  tabela de
  [`painel_valores_local_todos()`](https://distintivelab.github.io/beep/dev/reference/painel_valores_local_todos.md)

- refdate:

  data de corte: sem ela, a observacao mais recente; com ela, a ultima
  observacao em ou antes da data (slider por data do resumo)
