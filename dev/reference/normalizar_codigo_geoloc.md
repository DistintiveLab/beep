# Normaliza um codigo de localidade (geoloc_id ou equivalente) para texto exato, sem notacao cientifica — Bigint volta do RPostgres como integer64 (bit64) ou numeric, e `as.character()` de double grande produz "1.1002e+14". Codigo real brasileiro tem no maximo 16 digitos (UF 11..53 a esquerda ~ 5.3e15 \< 2^53), entao o caminho numerico e exato em double.

Normaliza um codigo de localidade (geoloc_id ou equivalente) para texto
exato, sem notacao cientifica — Bigint volta do RPostgres como integer64
(bit64) ou numeric, e
[`as.character()`](https://rdrr.io/r/base/character.html) de double
grande produz "1.1002e+14". Codigo real brasileiro tem no maximo 16
digitos (UF 11..53 a esquerda ~ 5.3e15 \< 2^53), entao o caminho
numerico e exato em double.

## Usage

``` r
normalizar_codigo_geoloc(x)
```
