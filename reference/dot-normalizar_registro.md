# Padroniza um registro de dependencias (vindo do JSON do DW) para list(deps = data.frame(serie, regua, acao), series_proprias = character); NULL se registro vazio/invalido. Acao desconhecida vira "avisar" (fail-open).

Padroniza um registro de dependencias (vindo do JSON do DW) para
list(deps = data.frame(serie, regua, acao), series_proprias =
character); NULL se registro vazio/invalido. Acao desconhecida vira
"avisar" (fail-open).

## Usage

``` r
.normalizar_registro(reg)
```
