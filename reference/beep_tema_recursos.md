# Recursos do núcleo do tema: CSS + JS + base Gov.br + div raiz

Inclui as variáveis/toggle de paleta (inst/tema), a base Rawline/Gov.br
do shinyGovBRstyle (servida do próprio pacote, sem CDN externo) e a div
raiz `#beep_tema_raiz` com o `data-paleta` inicial lido pelo JS. Colocar
uma única vez por app, junto aos recursos de cabeçalho.

## Usage

``` r
beep_tema_recursos(paleta = c("govbr", "pb"))
```
