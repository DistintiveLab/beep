# Grafico em destaque da serie da aba Regiao, despachando o tipo por indicador ("linha" default, "barras" ou "lollipop") e renomeando as colunas para legendas amigaveis no hover do plotly ("Ano"/"valor" em vez de "as.Date(refdate)"/"value"). Series anuais/bienais usam o ano inteiro no eixo x; as demais mantem a data

Grafico em destaque da serie da aba Regiao, despachando o tipo por
indicador ("linha" default, "barras" ou "lollipop") e renomeando as
colunas para legendas amigaveis no hover do plotly ("Ano"/"valor" em vez
de "as.Date(refdate)"/"value"). Series anuais/bienais usam o ano inteiro
no eixo x; as demais mantem a data

## Usage

``` r
painel_plot_indicador(
  v,
  titulo = NULL,
  cor = "#1351B4",
  tipo = "linha",
  rotulo_x = "Ano"
)
```
