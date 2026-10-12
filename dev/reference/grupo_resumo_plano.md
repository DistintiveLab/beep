# Plano de sincronização do grupo Resumo (função pura)

Recebe os vínculos atuais ao grupo e os ids desejados e devolve o que
falta inserir e o que sobra remover, sempre restrito ao grupo Resumo.

## Usage

``` r
grupo_resumo_plano(desejados, atuais, grupo_id = NA_integer_)
```

## Arguments

- desejados:

  integer com os mdata_id que devem pertencer ao grupo

- atuais:

  integer com os mdata_id hoje ligados ao grupo

- grupo_id:

  datagroup_id do grupo Resumo

## Value

lista com `inserir` e `remover` (integer, sem ordem garantida)
