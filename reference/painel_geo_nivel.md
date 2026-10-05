# Geometrias de um nivel territorial do DW para o globo, simplificadas no SQL (0.01 grau ~ 1 km) para o geojson ficar leve; niveis acima do limite de feicoes (municipio: 5.6 mil poligonos) voltam vazio e o chamador cai nas UFs como base do desenho — as regioes PNAD (146 feicoes) sao desenhadas normalmente

Geometrias de um nivel territorial do DW para o globo, simplificadas no
SQL (0.01 grau ~ 1 km) para o geojson ficar leve; niveis acima do limite
de feicoes (municipio: 5.6 mil poligonos) voltam vazio e o chamador cai
nas UFs como base do desenho — as regioes PNAD (146 feicoes) sao
desenhadas normalmente

## Usage

``` r
painel_geo_nivel(con, nivel_id, max_feicoes = 700L)
```
