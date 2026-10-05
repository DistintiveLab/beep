# Aquece o cache de disco do painel DW apos um ETL

Executa as leituras que o painel faria a frio — catalogo, geometrias,
localidades por nivel e (com `valores = TRUE`) a serie achatada de cada
indicador — gravando os RDS em `cache/` sob `diretorio`, para o proximo
arranque do app sair quente do disco. O cache e relativo ao diretorio de
trabalho e as chaves carregam host+dbname: rode com o mesmo ambiente do
app (o `.Renviron` da pasta, quando existe, e lido antes).
`limpar = TRUE` apaga o cache antes, levando embora chaves orfas de
versoes antigas (ex.: `valores_ano_<id>_<ano>` do cache por ano).

## Usage

``` r
aquecer_painel(diretorio = NULL, valores = TRUE, limpar = TRUE)
```

## Arguments

- diretorio:

  raiz do app do painel (default: diretorio corrente)

- valores:

  aquece tambem as series achatadas por indicador — a etapa mais longa;
  FALSE aquece so catalogo e geometrias

- limpar:

  apaga o cache de disco antes de aquecer (default TRUE)

## Value

invisivelmente um data.frame com o tempo de cada etapa

## Details

Usado pelo gancho pos-ETL de
[`atualizar_indicadores()`](https://distintivelab.github.io/beep/reference/atualizar_indicadores.md)
e disponivel para rodar na mao (Rscript/cron) depois de qualquer carga
manual.
