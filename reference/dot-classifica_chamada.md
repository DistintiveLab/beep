# Classifica uma call como chamada de coleta (educabr/sidra/url). O head pode ser simbolo ("sidra(...)") ou call de namespace ("educabR::le_afd(...)") / acesso ("obj\$metodo(...)"), por isso a classificacao e por deparse do nome completo.

Classifica uma call como chamada de coleta (educabr/sidra/url). O head
pode ser simbolo ("sidra(...)") ou call de namespace
("educabR::le_afd(...)") / acesso ("obj\$metodo(...)"), por isso a
classificacao e por deparse do nome completo.

## Usage

``` r
.classifica_chamada(call)
```
