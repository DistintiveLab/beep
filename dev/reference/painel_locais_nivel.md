# Localidades de um nivel territorial (pela chave de [`painel_nivel_parse()`](https://distintivelab.github.io/beep/dev/reference/painel_nivel_parse.md) ) que possuem dados, rotuladas por nome (municipios ganham sigla da UF; regioes PNAD ja trazem o contexto no proprio nome). O EXISTS replace o DISTINCT sobre data_values e fica milissegundos com o indice data_values(local_id) (ver [`garantir_indice_valores()`](https://distintivelab.github.io/beep/dev/reference/garantir_indice_valores.md))

Localidades de um nivel territorial (pela chave de
[`painel_nivel_parse()`](https://distintivelab.github.io/beep/dev/reference/painel_nivel_parse.md)
) que possuem dados, rotuladas por nome (municipios ganham sigla da UF;
regioes PNAD ja trazem o contexto no proprio nome). O EXISTS replace o
DISTINCT sobre data_values e fica milissegundos com o indice
data_values(local_id) (ver
[`garantir_indice_valores()`](https://distintivelab.github.io/beep/dev/reference/garantir_indice_valores.md))

## Usage

``` r
painel_locais_nivel(con, nivel_id)
```
