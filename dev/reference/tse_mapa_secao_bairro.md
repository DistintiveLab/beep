# Mapa secao -\> bairro a partir do perfil do eleitorado por secao

Uma linha por (municipio, zona, secao). Secoes com um unico bairro no
perfil ganham esse bairro; com bairros multiplos ficam NA e sao listadas
em `ambiguas`; sem bairro algum ficam NA. Nada e inferido.

## Usage

``` r
tse_mapa_secao_bairro(
  perfil,
  col_municipio = "CD_MUNICIPIO",
  col_zona = "NR_ZONA",
  col_secao = "NR_SECAO",
  col_bairro = "NM_BAIRRO"
)
```

## Arguments

- perfil:

  data.frame do perfil do eleitorado por secao (uma linha por estrato; o
  bairro se repete nas linhas da mesma secao)

- col_municipio, col_zona, col_secao, col_bairro:

  nomes das colunas no perfil (defaults no padrao dos arquivos do TSE)

## Value

lista: `mapa` (municipio, zona, secao, bairro, situacao), `ambiguas`
(secoes com bairros multiplos e quantos distintos), `resumo`
