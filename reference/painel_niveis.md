# Niveis territoriais disponiveis no DW: apenas os que possuem dados, com quantidade de localidades distintas. A largura 7 aparece em duas linhas — municipios ("7") e regioes de interesse em PNAD Contínua ("7p") — para nao somar 5.570 + 146 numa unica entrada. O EXISTS varre o catalogo de locais (milissegundos com o indice data_values(local_id), ver [`garantir_indice_valores()`](https://distintivelab.github.io/beep/reference/garantir_indice_valores.md)) em vez de agregar os ~10 milhoes de pontos do data_values

Niveis territoriais disponiveis no DW: apenas os que possuem dados, com
quantidade de localidades distintas. A largura 7 aparece em duas linhas
— municipios ("7") e regioes de interesse em PNAD Contínua ("7p") — para
nao somar 5.570 + 146 numa unica entrada. O EXISTS varre o catalogo de
locais (milissegundos com o indice data_values(local_id), ver
[`garantir_indice_valores()`](https://distintivelab.github.io/beep/reference/garantir_indice_valores.md))
em vez de agregar os ~10 milhoes de pontos do data_values

## Usage

``` r
painel_niveis(con)
```
