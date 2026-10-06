# Probe SIDRA (API v3 do IBGE): ultimos periodos publicados na tabela. A resposta e um data.frame(id, literals, modificacao) em ordem cronologica; usa-se apenas a coluna id, filtrada por formato valido (AAAA ou AAAAMM) para nao confundir datas internas (ex.: modificacao "01/01/0001") com periodos publicados.

Probe SIDRA (API v3 do IBGE): ultimos periodos publicados na tabela. A
resposta e um data.frame(id, literals, modificacao) em ordem
cronologica; usa-se apenas a coluna id, filtrada por formato valido
(AAAA ou AAAAMM) para nao confundir datas internas (ex.: modificacao
"01/01/0001") com periodos publicados.

## Usage

``` r
.probe_sidra(tabela)
```
