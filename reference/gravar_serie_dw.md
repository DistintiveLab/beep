# Grava (recalculando por completo ou acrescentando) a serie de um indicador

Grava (recalculando por completo ou acrescentando) a serie de um
indicador

## Usage

``` r
gravar_serie_dw(orig_name, serie, modo = c("replace", "append"))
```

## Arguments

- orig_name:

  nome do indicador em mdata

- serie:

  data.frame com `local`, `periodo`, `valor`

- modo:

  `"replace"` (default) ou `"append"`
