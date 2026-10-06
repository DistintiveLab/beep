# Indicador de abertura do painel, escolhido pelo orig_name

A variavel de ambiente `beep_indicador` (ex.: `desprod1`) decide qual
indicador das abas Regiao, Mapa e Baixar nasce selecionado; vazia ou
desconhecida cai no primeiro do catalogo (`md`, de
[`painel_mdata()`](https://distintivelab.github.io/beep/dev/reference/painel_mdata.md)).
Lida a cada chamada, ou seja, a sessao R precisa ser reiniciada para
enxergar uma mudanca (o server roda o `updateSelectizeInput` na
abertura).

## Usage

``` r
painel_indicador_default(md, padrao = Sys.getenv("beep_indicador", ""))
```
