# Migra o schema do DW para aceitar niveis territoriais submunicipais

Tudo em uma transacao: falha em qualquer passo deixa o banco como
estava. Bancos ja migrados sao no-op (verifica o tipo da coluna antes de
agir).

## Usage

``` r
preparar_niveis_submunicipais(con = NULL)
```

## Arguments

- con:

  conexao DBI com o DW; default abre o beepdb local

## Value

invisivel TRUE

## Details

1.  `geoloc.geoloc_id` vira BIGINT (codigos submunicipais de 11-16
    digitos nao cabem no int4 original). Matviews dependentes sao salvas
    (definicao + indices via pg_rewrite/pg_depend), dropadas e recriadas
    ao fim; chaves estrangeiras que apontam para geoloc(geoloc_id) sao
    dropadas e recriadas com a mesma definicao.

2.  `local` ganha a coluna `nivel_tipo` (texto), com backfill pela
    largura do geoloc_id e pelo bloco PNAD de local_id; niveis
    submunicipais novos recebem o tipo dos loaders
    (ampliar_nivel_territorial()).
