# Hierarquia do catalogo de indicadores: raiz (Eixos, Objetivos, Estratos PNAD) \> grupo (Eixo 1..7, Objetivo 1..4) \> indicador, com a classe do dado (data_class_id) — estrutura do resumo e do accordeon da aba Regiao

Os ids e nomes de grupo vem da tabela datagroup do DW; o vinculo de cada
indicador ao grupo vem da convencao de orig_name (ver
[`painel_grupo_indicador()`](https://distintivelab.github.io/beep/reference/painel_grupo_indicador.md)).
Indicador sem grupo conhecido fica de fora.

## Usage

``` r
painel_hierarquia(con)
```
