# Agrega a votacao nominal por secao em bairro (e zona, para as secoes sem bairro determinavel)

Agrega a votacao nominal por secao em bairro (e zona, para as secoes sem
bairro determinavel)

## Usage

``` r
tse_agregar_votacao(
  votacao,
  mapa,
  col_municipio = "CD_MUNICIPIO",
  col_zona = "NR_ZONA",
  col_secao = "NR_SECAO",
  col_votos = "QT_VOTOS",
  col_votavel = NULL
)
```

## Arguments

- votacao:

  data.frame da votacao nominal por secao

- mapa:

  saida de
  [`tse_mapa_secao_bairro()`](https://distintivelab.github.io/beep/dev/reference/tse_mapa_secao_bairro.md)
  ou o seu elemento `$mapa`

- col_municipio, col_zona, col_secao:

  nomes das colunas de chave no arquivo de votacao (defaults no padrao
  TSE)

- col_votos:

  nome da coluna de votos

- col_votavel:

  opcional: coluna (numero ou nome) do candidato para manter o detalhe
  por votavel na agregacao

## Value

lista: `bairro` (votos por municipio+bairro+votavel), `zona` (votos das
secoes sem bairro, por municipio+zona+votavel), `sem_mapa` (secoes da
votacao ausentes do mapa, com os votos), `resumo`
