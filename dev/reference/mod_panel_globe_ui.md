# panel_globe UI Function

A shiny Module. Globo ortografico das delimitacoes territoriais do nivel
corrente (geometrias do banco de dados do painel): arrastar gira
livremente pelo mundo, a roda e os botoes aproximam estilo Google Earth
e clicar numa area com dados escolhe a localidade na aba Regiao. No
nivel municipal (sem geometria coletiva leve) a base sao as UFs com o
municipio escolhido destacado, a UF inteira em foco e a malha de bordas
dos demais municipios do estado. Port do globo do labourvaluesdatapanel.

## Usage

``` r
mod_panel_globe_ui(id)
```

## Arguments

- id, input, output, session:

  Internal parameters for shiny.
