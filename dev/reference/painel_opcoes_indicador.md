# Opcoes do seletor de indicadores do painel, agrupadas por eixo/objetivo

Monta a lista aninhada que o `updateSelectizeInput(server = TRUE)`
transforma em optgroups, os titulos de grupo nao clicaveis do selectize:
"Eixo 1".."Eixo 7", "Objetivo 1".."Objetivo 4", "Estratos PNAD" e, por
fim, "Demais indicadores" (series de apoio e variantes de trabalho).
Dentro de cada eixo/objetivo o composto abre o grupo e os componentes
vem numerados ("Indicador N - Nome (orig_name)"); os Estratos PNAD
seguem o numero do estrato (pnadc1..7 e comp_pnadc8..14); os demais
mantem a ordem alfabetica do `orig_name` de
[`painel_mdata()`](https://distintivelab.github.io/beep/dev/reference/painel_mdata.md).
Indicadores marcados como invisiveis (tabela auxiliar `mdata_visivel`,
coluna `visivel` do catalogo) ficam de fora das opcoes.

## Usage

``` r
painel_opcoes_indicador(md)
```
