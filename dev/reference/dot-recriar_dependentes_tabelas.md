# Recria as matviews salvas em ordem de dependencia: passadas sucessivas tentando criar cada uma ate todas existirem (ou estourar o limite). Cada tentativa roda entre SAVEPOINT/ROLLBACK TO: a funcao e chamada dentro da transacao da migracao e, no PostgreSQL, UMA instrucao falha aborta a transacao inteira ("current transaction is aborted") — sem savepoint, a primeira tentativa prematura derrubaria todas as demais.

Recria as matviews salvas em ordem de dependencia: passadas sucessivas
tentando criar cada uma ate todas existirem (ou estourar o limite). Cada
tentativa roda entre SAVEPOINT/ROLLBACK TO: a funcao e chamada dentro da
transacao da migracao e, no PostgreSQL, UMA instrucao falha aborta a
transacao inteira ("current transaction is aborted") — sem savepoint, a
primeira tentativa prematura derrubaria todas as demais.

## Usage

``` r
.recriar_dependentes_tabelas(con, salvos)
```
