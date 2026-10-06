# Esconde ou revela um indicador nos seletores do painel

Cria a tabela auxiliar `mdata_visivel` no DW quando falta e grava a flag
do indicador (UPSERT). Indicadores ocultos saem dos seletores das abas
Regiao, Mapa e Baixar, mas a serie continua no DW (downloads direto do
banco e cargas seguem intactos). O painel le a tabela de forma
tolerante: sem tabela ou sem linha, o indicador e visivel.

## Usage

``` r
definir_visibilidade(con, mdata_id, visivel = TRUE)
```

## Arguments

- con:

  conexao DBI (PostgreSQL) com o DW de indicadores

- mdata_id:

  id do indicador na tabela mdata

- visivel:

  FALSE esconde o indicador dos seletores (default TRUE)

## Value

invisivelmente TRUE
