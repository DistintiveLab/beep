# Extrai da AST do script a primeira chamada de coleta, sem executa-la. Desce em corpos de funcao e argumentos (ex.: o le_afd dentro da funcao passada a um lapply). Retorna lista(tipo, ...) ou NULL.

Extrai da AST do script a primeira chamada de coleta, sem executa-la.
Desce em corpos de funcao e argumentos (ex.: o le_afd dentro da funcao
passada a um lapply). Retorna lista(tipo, ...) ou NULL.

## Usage

``` r
.primeira_chamada_coleta(exprs)
```
