# Garante o indice de `local_id` na tabela `data_values` do DW

[`painel_niveis()`](https://distintivelab.github.io/beep/reference/painel_niveis.md)
e
[`painel_locais_nivel()`](https://distintivelab.github.io/beep/reference/painel_locais_nivel.md)
descobrem "quais localidades tem dados" com EXISTS sobre data_values:
sem indice em local_id o planejador varre a tabela inteira (~10 milhoes
de linhas). O indice tambem acelera o lookup do aquecedor e da regiao
por localidade. `CREATE INDEX IF NOT EXISTS` — idempotente; a primeira
criacao pode levar ~1 minuto e ocupa espaco extra no banco.

## Usage

``` r
garantir_indice_valores(con)
```

## Arguments

- con:

  conexao DBI (PostgreSQL) com o DW de indicadores

## Value

invisivelmente TRUE
