# Declara e reconcilia os grupos tematicos do catalogo no DW

Idempotente e nao destrutivo: cria os `datagroup`/`group_parent` que
faltam (Eixos, Objetivos, Estratos PNAD e os grupos Eixo 1..7 / Objetivo
1..4), completa os vinculos de `mdata_group` de todos os indicadores que
seguem a convencao de `orig_name` e relata os vinculos que fogem dela —
sem apagar nenhuma linha. Rode depois de ETLs que adicionem indicadores;
num DW recem criado (sem indicadores) apenas declara os grupos.

## Usage

``` r
atualizar_grupos_indicadores(con = NULL, simular = FALSE, verbose = TRUE)
```

## Arguments

- con:

  conexao aberta com o DW; por padrao abre uma com as variaveis de
  ambiente `user`, `password`, `host` e `dbname` (mesmos defaults de
  [`db_datawrite()`](https://distintivelab.github.io/beep/dev/reference/db_datawrite.md))

- simular:

  se `TRUE` nao escreve nada: devolve apenas o plano

- verbose:

  imprime o resumo do que foi feito

## Value

invisivel, o plano aplicado (listas `grupos`, `pais`, `vinculos` e
`divergentes`)
