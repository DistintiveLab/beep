# Malha decorativa do globo em torno da localidade em foco: selecao municipal desenha as bordas dos demais municipios do estado ([`painel_geo_mun_uf_cache()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_mun_uf_cache.md)); selecao submunicipal (setor, bairro, subdistrito, area de ponderacao — geoloc_id com mais de 10 digitos) troca as bordas pelas proprias feicoes do nivel (pelo `nivel_tipo` da localidade) dentro do municipio em foco ([`painel_geo_irmaos_mun()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_irmaos_mun.md)), que tesselam o municipio inteiro. A feicao do destaque sai fora do cache (cada selecao exclui a si mesma), como em [`painel_geo_mun_uf_cache()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_mun_uf_cache.md).

Malha decorativa do globo em torno da localidade em foco: selecao
municipal desenha as bordas dos demais municipios do estado
([`painel_geo_mun_uf_cache()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_mun_uf_cache.md));
selecao submunicipal (setor, bairro, subdistrito, area de ponderacao —
geoloc_id com mais de 10 digitos) troca as bordas pelas proprias feicoes
do nivel (pelo `nivel_tipo` da localidade) dentro do municipio em foco
([`painel_geo_irmaos_mun()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_irmaos_mun.md)),
que tesselam o municipio inteiro. A feicao do destaque sai fora do cache
(cada selecao exclui a si mesma), como em
[`painel_geo_mun_uf_cache()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_mun_uf_cache.md).

## Usage

``` r
painel_geo_malha_foco_cache(local_id)
```
