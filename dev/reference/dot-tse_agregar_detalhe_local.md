# Nucleo puro de agregacao do detalhe por secao (testavel offline): dedupe `first()` por secao-turno (as metricas repetem em cada cargo), descarta linhas sem local e soma por local e turno (quando o detalhe traz a coluna, cada turno vira um ponto proprio com periodo no domingo da eleicao) — espelho do `tsebr::tse_detalhe_municipio()`.

Nucleo puro de agregacao do detalhe por secao (testavel offline): dedupe
`first()` por secao-turno (as metricas repetem em cada cargo), descarta
linhas sem local e soma por local e turno (quando o detalhe traz a
coluna, cada turno vira um ponto proprio com periodo no domingo da
eleicao) — espelho do
[`tsebr::tse_detalhe_municipio()`](https://rdrr.io/pkg/tsebr/man/tse_detalhe_municipio.html).

## Usage

``` r
.tse_agregar_detalhe_local(d, local_chr, metrica, a)
```
