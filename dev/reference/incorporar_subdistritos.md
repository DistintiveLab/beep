# Incorpora subdistritos derivados dos setores censitarios

Dissolve os setores por subdistrito (codigo do Censo: municipio 7
digitos

- sequencial 4; codigos completos de 11 digitos tambem sao aceitos
  como-is) e grava cada subdistrito com
  [`ampliar_nivel_territorial()`](https://distintivelab.github.io/beep/dev/reference/ampliar_nivel_territorial.md)
  (tipo "subdistrito": `geoloc_id` de 11 digitos, `local_id` no bloco
  3000000-3999999). No DF as Regioes Administrativas sao exatamente os
  subdistritos — o recorte submunicipal com geometria oficial quando o
  Censo nao publica atributo de bairro no municipio. Setores sem
  subdistrito informado ficam de fora — nunca inferido. Cargas repetidas
  sao idempotentes por codigo e registradas em `niveis_carga` com fonte
  "dissolve_setores" (uma linha por municipio; passe um `ano` fixo para
  atualizar a mesma linha — com o default `NA` cada carga gera linha
  nova).

## Usage

``` r
incorporar_subdistritos(
  setores,
  col_subdistrito = NULL,
  col_nome = NULL,
  col_setor = NULL,
  con = NULL,
  simplificar = 0.001,
  refrescar = FALSE,
  ano = NA_integer_
)
```

## Arguments

- setores:

  sf de setores censitarios com atributo de subdistrito
  (`col_subdistrito`, ex. `code_subdistrict` da geobr
  `read_census_tract()`) e, quando o atributo for sufixo curto (1-4
  digitos), o codigo do setor (`col_setor`, auto-detetavel) para derivar
  o municipio pai; CRS qualquer (reprojetado para 4326 na gravacao)

- col_subdistrito, col_nome, col_setor:

  nomes das colunas de subdistrito (codigo), nome e codigo de setor no
  sf; defaults por auto-deteccao

- con:

  conexao DBI com o DW; default abre o beepdb local

- simplificar:

  dTolerance (graus) da simplificacao no SQL

- refrescar:

  atualizar as matviews named/geonamed_datavalues ao fim? Custa minutos
  em DW grande; ETL em lote prefere refrescar uma unica vez

- ano:

  ano de referencia do atributo de subdistrito (proveniencia em
  `niveis_carga`; default NA — ver nota acima)

## Value

invisivel data.frame (escopo, n_localidades) com o resumo da carga por
municipio — o mesmo registro vai para `niveis_carga`
