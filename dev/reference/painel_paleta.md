# Paleta de cores do mapa (port fiel do mypallet do labourvaluesdatapanel): divergente centrada em 0 quando ha negativos, com rampas invertidas conforme o argumento (checkbox "Inverter cores da escala"; a inversao tambem vale para dados so positivos). O argumento escala controla o dominio das cores (seletor "Escala" da toolbar do mapa): "zero" ancora em 0 (historico, comparavel entre datas), "minmax" usa a faixa observada no refdate (contraste maximo em faixas estreitas, como taxas de 16 a 23%) e "quantil" classifica por posicao no ranking (colorQuantile).

Paleta de cores do mapa (port fiel do mypallet do
labourvaluesdatapanel): divergente centrada em 0 quando ha negativos,
com rampas invertidas conforme o argumento (checkbox "Inverter cores da
escala"; a inversao tambem vale para dados so positivos). O argumento
escala controla o dominio das cores (seletor "Escala" da toolbar do
mapa): "zero" ancora em 0 (historico, comparavel entre datas), "minmax"
usa a faixa observada no refdate (contraste maximo em faixas estreitas,
como taxas de 16 a 23%) e "quantil" classifica por posicao no ranking
(colorQuantile).

## Usage

``` r
painel_paleta(
  values,
  invertida = FALSE,
  escala = c("zero", "minmax", "quantil")
)
```
