# Registro dos tipos de nivel territorial: rotulo do painel e larguras (em digitos) aceitas para o geoloc_id. As larguras dos niveis convencionais vem da convencao IBGE ja adotada pelo DW; as submunicipais aceitam mais de uma largura porque a composicao oficial varia entre censos (setor 2022 pode vir com 15 ou 16 digitos conforme a fonte; bairro e mun7 + 4~5). O identificador semantico e o `nivel_tipo` gravado no `local` — a largura so resolve o rotulo no painel.

Registro dos tipos de nivel territorial: rotulo do painel e larguras (em
digitos) aceitas para o geoloc_id. As larguras dos niveis convencionais
vem da convencao IBGE ja adotada pelo DW; as submunicipais aceitam mais
de uma largura porque a composicao oficial varia entre censos (setor
2022 pode vir com 15 ou 16 digitos conforme a fonte; bairro e mun7 +
4~5). O identificador semantico e o `nivel_tipo` gravado no `local` — a
largura so resolve o rotulo no painel.

## Usage

``` r
niveis_territoriais_tipos
```

## Format

An object of class `data.frame` with 11 rows and 4 columns.
