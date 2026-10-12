# Decodifica a chave de nivel territorial do painel

A chave e a largura do geoloc_id como texto ("1".."8") ou "7p" para as
regioes de interesse em PNAD Contínua, que dividem a largura 7 com os
municipios. Niveis submunicipais usam o proprio `nivel_tipo` como chave
("bairro", "subdistrito", "setor", "area_ponderacao") — bairro e
subdistrito dividem a largura 11, entao a largura nao distingue niveis.
Devolve o nivel numerico (largura representativa nos submunicipais), o
tipo quando ha, se e o subnivel PNAD e o fragmento SQL que seleciona os
locais do nivel (pressupoe aliases `l` e `g` no chamador).

## Usage

``` r
painel_nivel_parse(nivel_id)
```
