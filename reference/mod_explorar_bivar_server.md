# Server da correlacao: pares completos alinhados por (localidade, ano) com NAs removidos por pares; Pearson e Spearman com n de pares sempre visível (badge quando insuficiente), leitura pooled/between/within e janela com preset sugerido de últimos 10 anos. `par_inicial` é um reactive que recebe list(x = mdata_id, y = mdata_id) vindo da matriz ou do ranking de preditores

Server da correlacao: pares completos alinhados por (localidade, ano)
com NAs removidos por pares; Pearson e Spearman com n de pares sempre
visível (badge quando insuficiente), leitura pooled/between/within e
janela com preset sugerido de últimos 10 anos. `par_inicial` é um
reactive que recebe list(x = mdata_id, y = mdata_id) vindo da matriz ou
do ranking de preditores

## Usage

``` r
mod_explorar_bivar_server(id, par_inicial = NULL)
```
