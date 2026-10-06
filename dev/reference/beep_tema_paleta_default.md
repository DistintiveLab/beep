# Paleta inicial dos apps beep (usa a variável de ambiente `beep_paleta`)

Análogo ao
[`painel_brand_paleta()`](https://distintivelab.github.io/beep/dev/reference/painel_brand_paleta.md)
do painel: a env sobrepõe o default, então o admin e o app beep de um
projeto podem nascer pb via `.Renviron` sem tocar em código. Valores:
"govbr" (padrão) ou "pb".

## Usage

``` r
beep_tema_paleta_default(default = "govbr")
```
