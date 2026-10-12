# Feicoes submunicipais do mesmo nivel dentro de um municipio (prefixo de 7 digitos do geoloc_id — setor, bairro, subdistrito e area de ponderacao codificam o municipio nos primeiros digitos), simplificadas no SQL — malha do globo quando o destaque e submunicipal: as feicoes do nivel tesselam o municipio em foco. O nivel e selecionado pelo `nivel_tipo` (largura nao distingue bairro de subdistrito); sem tipo (legado), pela largura. Acima do teto de feicoes volta vazio e o globo fica apenas com o destaque sobre a UF (degradacao). Malhas grandes (acima de 2 mil feicoes, como os setores censitarios de uma capital inteira) ganham simplificacao mais forte no SQL para caberem no mapa, que usa teto proprio em [`painel_geo_irmaos_nivel_cache()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_irmaos_nivel_cache.md).

Feicoes submunicipais do mesmo nivel dentro de um municipio (prefixo de
7 digitos do geoloc_id — setor, bairro, subdistrito e area de ponderacao
codificam o municipio nos primeiros digitos), simplificadas no SQL —
malha do globo quando o destaque e submunicipal: as feicoes do nivel
tesselam o municipio em foco. O nivel e selecionado pelo `nivel_tipo`
(largura nao distingue bairro de subdistrito); sem tipo (legado), pela
largura. Acima do teto de feicoes volta vazio e o globo fica apenas com
o destaque sobre a UF (degradacao). Malhas grandes (acima de 2 mil
feicoes, como os setores censitarios de uma capital inteira) ganham
simplificacao mais forte no SQL para caberem no mapa, que usa teto
proprio em
[`painel_geo_irmaos_nivel_cache()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_irmaos_nivel_cache.md).

## Usage

``` r
painel_geo_irmaos_mun(con, mun, tipo = NULL, larg = NULL, max_feicoes = 2000L)
```
