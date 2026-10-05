# Scripts antigos pressupoem a sessao interativa com library(DBI) etc.; no lote agendado nada esta anexado. Anexa via library() apenas os pacotes cujas funcoes o script chama sem namespace e que ainda nao resolvem no ambiente de execucao. Retorna o que ficou sem resolucao (funcoes proprias do script sao esperadas aqui).

Scripts antigos pressupoem a sessao interativa com library(DBI) etc.; no
lote agendado nada esta anexado. Anexa via library() apenas os pacotes
cujas funcoes o script chama sem namespace e que ainda nao resolvem no
ambiente de execucao. Retorna o que ficou sem resolucao (funcoes
proprias do script sao esperadas aqui).

## Usage

``` r
.anexar_pacotes_script(exprs, env)
```
