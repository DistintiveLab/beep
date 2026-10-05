# Define o tipo do grafico em destaque de um indicador no painel

Cria a tabela auxiliar `mdata_grafico` no DW quando falta e grava o tipo
do indicador (UPSERT). O painel le a tabela de forma tolerante: sem
tabela ou sem linha para o indicador, o grafico segue "linha".

## Usage

``` r
definir_tipo_grafico(
  con,
  mdata_id,
  tipo = c("linha", "barras", "lollipop", "banda")
)
```

## Arguments

- con:

  conexao DBI (PostgreSQL) com o DW de indicadores

- mdata_id:

  id do indicador na tabela mdata

- tipo:

  um de "linha", "barras", "lollipop", "banda"

## Value

invisivelmente TRUE
