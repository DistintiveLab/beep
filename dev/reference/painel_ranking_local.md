# Posicao de uma localidade num indicador e data: quantos municipios do pais e da propria UF tem valor MAIOR naquela data

Os dois universos sao municipais (largura 7 do geoloc_id): o pais
inteiro e a UF de origem, pelo prefixo de 2 digitos do geoloc_id. A
posicao conta os valores estritamente maiores, entao empates dividem a
mesma posicao; o total (`n_uf`, `n_br`) e quantos municipios tem dado na
data para o indicador. Com `refdate` valido a comparacao e no dia exato
(slider por data do mapa); sem `refdate`, vale a regra de ano de
[`painel_valores_ano()`](https://distintivelab.github.io/beep/dev/reference/painel_valores_ano.md)
(ultimo refdate de cada localidade dentro do ano, `DISTINCT ON` + faixa
`make_date`), e o valor da propria localidade e do mesmo ano.

## Usage

``` r
painel_ranking_local(con, mdata_id, local_id, ano, refdate = NULL)
```

## Details

Contar de cima para baixo assume "maior e melhor", o sentido dos
indicadores compostos do catalogo do painel: o resumo nao guarda direcao
do indicador (a tabela mdata nao tem essa coluna).
