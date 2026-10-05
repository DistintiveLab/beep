# Malha municipal (sf) de um codigo IBGE de 7 digitos

Fonte 1: API v3 malhas (geojson; municipios recem-criados podem ainda
nao constar). Fonte 2: shapefile por UF da malha oficial no geoftp,
percorrendo anos do mais recente para tras ate encontrar o codigo.

## Usage

``` r
.baixar_malha_ibge(geoloc7, uf_sigla)
```
