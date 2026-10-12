# Matviews que dependem (direta ou transitivamente) de tabelas base, com definicao e indices — a maquinaria de pg_rewrite/pg_depend segue a mesma abordagem de `.salvar_dependentes_recortes()` (create_extend_geogroup_view.R), generalizada para varias tabelas e fechada por transitividade.

Matviews que dependem (direta ou transitivamente) de tabelas base, com
definicao e indices — a maquinaria de pg_rewrite/pg_depend segue a mesma
abordagem de `.salvar_dependentes_recortes()`
(create_extend_geogroup_view.R), generalizada para varias tabelas e
fechada por transitividade.

## Usage

``` r
.salvar_dependentes_tabelas(con, tabelas)
```
