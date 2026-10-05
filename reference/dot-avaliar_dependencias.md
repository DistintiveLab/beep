# Decisao PURA (sem DB), testavel: dadas as deps declaradas, o frescor (max refdate; NA = ausente) de cada serie e as series proprias do script, decide pular/avisar. Regra fase 1 (reguas proprio e fonte coincidem): viola quem tem ano(dep) \< ano(serie propria), ou dep ausente do DW com serie propria ja existente. Sem serie propria no DW (primeira carga) ou sem deps, executa. A primeira violacao de acao "pular" decide; violacoes "avisar" viram motivo com pular = FALSE.

Decisao PURA (sem DB), testavel: dadas as deps declaradas, o frescor
(max refdate; NA = ausente) de cada serie e as series proprias do
script, decide pular/avisar. Regra fase 1 (reguas proprio e fonte
coincidem): viola quem tem ano(dep) \< ano(serie propria), ou dep
ausente do DW com serie propria ja existente. Sem serie propria no DW
(primeira carga) ou sem deps, executa. A primeira violacao de acao
"pular" decide; violacoes "avisar" viram motivo com pular = FALSE.

## Usage

``` r
.avaliar_dependencias(deps, frescor, series_proprias)
```
