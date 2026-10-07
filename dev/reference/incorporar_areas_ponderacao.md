# Incorpora a malha de areas de ponderacao do Censo

Baixa a malha via \[geobr::read_weighting_area()\] e insere cada area
com ampliar_nivel_territorial() (tipo "area_ponderacao": geoloc_id de 13
digitos, local_id no bloco 2000000-2999999; o municipio pai e o prefixo
7d do codigo). Cargas repetidas sao idempotentes por codigo e ficam
registradas em niveis_carga.

## Usage

``` r
incorporar_areas_ponderacao(
  con = NULL,
  ufs = "all",
  ano = 2010,
  simplificar = 0.001,
  refrescar = FALSE
)
```

## Arguments

- con:

  conexao DBI com o DW; default abre o beepdb local

- ufs:

  "all" ou vetor de codigos de UF (2 digitos) ou municipio IBGE (7
  digitos)

- ano:

  Censo de referencia (2010 e o publicado para areas de ponderacao)

- simplificar:

  dTolerance (graus) da simplificacao no SQL

- refrescar:

  atualizar as matviews named/geonamed_datavalues ao fim? Custa minutos
  em DW grande; ETL em lote prefere refrescar uma unica vez

## Value

invisivel data.frame (escopo, n_localidades) com o resumo da carga — o
mesmo registro vai para a tabela `niveis_carga`
