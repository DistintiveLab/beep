# Incorpora a malha de setores censitarios de UFs/municipios

Baixa a malha do Censo via \[geobr::read_census_tract()\] e insere cada
setor com ampliar_nivel_territorial() (tipo "setor": geoloc_id = codigo
do setor em 15-16 digitos, local_id no bloco 100000-999999; o municipio
pai e o prefixo 7d do codigo, sem vinculo em recortes_geograficos).
Cargas repetidas sao idempotentes por codigo e ficam registradas em
niveis_carga.

## Usage

``` r
incorporar_setores_censitarios(
  con = NULL,
  ufs = "all",
  ano = 2022,
  zone = "all",
  simplificar = 0.001,
  refrescar = FALSE
)
```

## Arguments

- con:

  conexao DBI com o DW; default abre o beepdb local

- ufs:

  "all" ou vetor de codigos de UF (2 digitos) ou municipio IBGE (7
  digitos) — a malha nacional completa e uma operacao de minutos-horas e
  ~GB de geometria; o uso comum e por estado ou municipio

- ano:

  Censo de referencia: 2010 (zone "urban"/"rural"/"all") ou 2022, quando
  a malha publicada/geobr disponivel nao exigir zona

- zone:

  zona dos setores no Censo 2010 (default "all")

- simplificar:

  dTolerance (graus) da simplificacao no SQL

- refrescar:

  atualizar as matviews named/geonamed_datavalues ao fim? Custa minutos
  em DW grande; ETL em lote prefere refrescar uma unica vez

## Value

invisivel data.frame (escopo, n_localidades) com o resumo da carga — o
mesmo registro vai para a tabela `niveis_carga`
