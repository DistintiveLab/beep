# Valor do ultimo refdate de cada localidade dentro de um ano: replica no SQL (DISTINCT ON + faixa make_date, indices amigaveis; NULL e NaN caem no \<\> 'NaN'::float8) o que antes puxava o indicador inteiro e agregava em R

Valor do ultimo refdate de cada localidade dentro de um ano: replica no
SQL (DISTINCT ON + faixa make_date, indices amigaveis; NULL e NaN caem
no \<\> 'NaN'::float8) o que antes puxava o indicador inteiro e agregava
em R

## Usage

``` r
painel_valores_ano(con, mdata_id, ano)
```
