# Converte os locais de votacao em pontos espaciais (sf POINT, EPSG:4326)

Filtra linhas sem coordenada util (NA/0) ou fora do bounding box do
Brasil. Serve para inspecao e mapas;
[`tse_harmonizar_secoes()`](https://distintivelab.github.io/beep/dev/reference/tse_harmonizar_secoes.md)
aceita tanto a saida desta funcao quanto o data.frame bruto.

## Usage

``` r
tse_pontuar_locais_votacao(locais)
```

## Arguments

- locais:

  data.frame de saida de
  [`tsebr::tse_locais_votacao()`](https://rdrr.io/pkg/tsebr/man/tse_locais_votacao.html)
  (ou equivalente com `lat`/`lon`).

## Value

objeto `sf` de POINT com as colunas originais e `lat`/`lon`.
