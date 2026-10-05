# Plano de atualizacao do catalogo: o que falta no DW

Funcao pura: recebe o conteudo atual das tabelas e devolve as linhas que
seriam inseridas, sem tocar no banco. Os grupos que faltam ja saem com
`datagroup_id` atribuido (continuando a numeracao existente), de modo
que os pais e os vinculos possam ser resolvidos no mesmo passo e o plano
seja exatamente o que
[`atualizar_grupos_indicadores()`](https://distintivelab.github.io/beep/reference/atualizar_grupos_indicadores.md)
aplica. Os pais sao comparados por nome e os vinculos pelo par
(mdata_id, datagroup_id).

## Usage

``` r
grupos_catalogo_plano(mdata, grupos, vinculos, pais)
```

## Arguments

- mdata:

  data.frame com `mdata_id` e `orig_name`

- grupos:

  data.frame com `datagroup_id` e `datagroup_name`

- vinculos:

  data.frame com `mdata_id` e `datagroup_id` (mdata_group)

- pais:

  data.frame com `datagroup_id` e `datagroup_parentid`

## Value

lista com `grupos`, `pais` e `vinculos` (linhas a inserir) e
`divergentes` (vinculos existentes que fogem da convencao; so relatorio)
