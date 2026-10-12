# Incorpora a malha de areas de ponderacao de UFs/municipios

Baixa via
[`geobr::read_weighting_area()`](https://ipea.github.io/geobr/reference/read_weighting_area.html)
(Censo 2010) e insere cada area com
[`ampliar_nivel_territorial()`](https://distintivelab.github.io/beep/dev/reference/ampliar_nivel_territorial.md)
(tipo "area_ponderacao": `geoloc_id` = codigo de 13 digitos, `local_id`
no bloco 2000000-2999999). O municipio pai e o prefixo 7d do codigo; sem
vinculo em `recortes_geograficos`. Cargas repetidas sao idempotentes por
codigo e ficam registradas em `niveis_carga`.

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

  `"all"` ou vetor de codigos de UF (2 digitos) ou municipio IBGE (7
  digitos) para carga parcial

- ano:

  Censo de referencia (2010 — unico com malha de AP publicada)

- simplificar:

  dTolerance (graus) da simplificacao no SQL

- refrescar:

  atualizar as matviews named/geonamed_datavalues ao fim?

## Value

invisivel data.frame (escopo, n_localidades) com o resumo da carga — o
mesmo registro vai para a tabela `niveis_carga`
