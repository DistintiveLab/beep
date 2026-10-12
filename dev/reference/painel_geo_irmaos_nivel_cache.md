# Malha completa de um nivel submunicipal dentro de um municipio (geoloc de 7 digitos), cacheada por municipio — chave derivada da de [`painel_geo_malha_foco_cache()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_malha_foco_cache.md), com o teto no final para nao conflitar com a malha do globo. O teto e maior que o do globo: o mapa aguenta malhas de capital inteira (~5 mil setores) com a simplificacao adaptativa de [`painel_geo_irmaos_mun()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_irmaos_mun.md)

Malha completa de um nivel submunicipal dentro de um municipio (geoloc
de 7 digitos), cacheada por municipio — chave derivada da de
[`painel_geo_malha_foco_cache()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_malha_foco_cache.md),
com o teto no final para nao conflitar com a malha do globo. O teto e
maior que o do globo: o mapa aguenta malhas de capital inteira (~5 mil
setores) com a simplificacao adaptativa de
[`painel_geo_irmaos_mun()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_irmaos_mun.md)

## Usage

``` r
painel_geo_irmaos_nivel_cache(
  mun,
  tipo = NULL,
  larg = NULL,
  max_feicoes = 6000L
)
```
