# Nivel territorial de abertura default da aba Regiao: a variavel de ambiente `painel_nivel` (chave do nivel, ex.: `subdistrito` ou `2`) decide quando o nivel existe no catalogo; sem a variavel ou com nivel indisponivel, municipal quando disponivel, senao UF

Nivel territorial de abertura default da aba Regiao: a variavel de
ambiente `painel_nivel` (chave do nivel, ex.: `subdistrito` ou `2`)
decide quando o nivel existe no catalogo; sem a variavel ou com nivel
indisponivel, municipal quando disponivel, senao UF

## Usage

``` r
painel_nivel_default(niveis, padrao = Sys.getenv("painel_nivel", ""))
```
