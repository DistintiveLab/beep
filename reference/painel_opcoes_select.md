# Opcoes das caixas de selecao do painel: selectize com pesquisa por parte do nome e sem truncar listas longas

O selectize.js renderiza no maximo `max_options` itens (default 1000):
sem elevar o limite, a lista de localidades (5,7 mil municipios no DW)
termina antes do fim e o resto so aparece para quem digita o nome.

## Usage

``` r
painel_opcoes_select(placeholder, max_options = 10000L)
```

## Arguments

- placeholder:

  texto de ajuda dentro da caixa

- max_options:

  numero maximo de itens renderizados de uma vez
