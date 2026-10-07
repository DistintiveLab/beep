# Incorpora um nivel territorial submunicipal a partir de um sf de feicoes

O sf precisa trazer o codigo longo do nivel (digitos apenas; largura
validada contra o registro de `niveis_territoriais_tipos`) e,
opcionalmente, um nome. Feicoes cujo codigo ja existe em `geoloc` sao
puladas (idempotente por codigo). As novas ganham `local_id` sequencial
dentro do bloco do tipo e `nivel_tipo` preenchido. A matview
`recortes_geograficos` NAO e regenerada: ela e uma visao por municipio
de proposito; niveis submunicipais nao participam dos recortes.

## Usage

``` r
ampliar_nivel_territorial(
  dados,
  tipo,
  col_codigo = NULL,
  col_nome = NULL,
  con = NULL,
  simplificar = 0.001,
  refrescar = FALSE
)
```

## Arguments

- dados:

  sf com a coluna de codigo (`col_codigo`) e opcionalmente nome
  (`col_nome`), geometria em EPSG:4326 ou reprojetavel

- tipo:

  um de `niveis_blocos_local_id$tipo`: "setor", "area_ponderacao",
  "bairro"

- col_codigo, col_nome:

  nomes das colunas de codigo/nome no sf

- con:

  conexao DBI com o DW; default abre o beepdb local

- simplificar:

  dTolerance (graus) da simplificacao no SQL
  (ST_SimplifyPreserveTopology); default 0.001 — mais fino que o 0.01
  dos municipios porque feicoes submunicipais sao pequenas

- refrescar:

  atualizar as matviews named/geonamed_datavalues ao fim? Custa alguns
  minutos em DW grande; o ETL em lote prefere refrescar uma unica vez no
  fim de tudo

## Value

data.frame invisivel com os codigos incorporados e seus local_ids
