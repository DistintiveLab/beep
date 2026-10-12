# Prepara o DW para niveis territoriais submunicipais (idempotente)

1.  `geoloc.geoloc_id` e `local.geoloc_id` passam a BIGINT (codigos de
    setor chegam a 16 digitos). Matviews dependentes sao salvas
    (definicao + indices), dropadas com CASCADE e recriadas depois do
    ALTER — o PostgreSQL recusa alterar coluna usada por view/regra.
    Chaves estrangeiras que apontam para `geoloc(geoloc_id)` (ex.:
    `fk_geoloc_geoloc_id` criada pelo `prepare_db`) sao dropadas e
    recriadas com a mesma definicao.

2.  `local` ganha a coluna `nivel_tipo` (texto), com backfill pela
    largura do geoloc_id e pelo bloco PNAD de local_id; niveis
    submunicipais novos recebem o tipo dos loaders
    ([`ampliar_nivel_territorial()`](https://distintivelab.github.io/beep/dev/reference/ampliar_nivel_territorial.md)).

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

Tudo em uma transacao: falha em qualquer passo deixa o banco como
estava. Bancos ja migrados sao no-op (verifica o tipo da coluna antes de
agir).
