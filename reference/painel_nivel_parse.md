# Decodifica a chave de nivel territorial do painel

A chave e a largura do geoloc_id como texto ("1".."8") ou "7p" para as
regioes de interesse em PNAD Contínua, que dividem a largura 7 com os
municipios. Devolve o nivel numerico, se e o subnivel PNAD e o fragmento
SQL que seleciona os locais do nivel (pressupoe aliases `l` e `g` no
chamador).

## Usage

``` r
painel_nivel_parse(nivel_id)
```
