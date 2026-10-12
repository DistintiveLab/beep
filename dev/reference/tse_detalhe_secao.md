# Detalhe da votacao por secao agregado ao nivel municipal ou submunicipal

Espelha a semantica de
[`tsebr::tse_detalhe_municipio()`](https://rdrr.io/pkg/tsebr/man/tse_detalhe_municipio.html)
(dedupe `first()` por secao-turno — as metricas do detalhe repetem em
cada cargo da mesma secao — e soma por localidade), mas agrega pela
localidade do nivel `agregar_por` atribuida as secoes na tabela de
harmonizacao `tse_secao_bairro` (preenchida por
[`tse_harmonizar_secoes()`](https://distintivelab.github.io/beep/dev/reference/tse_harmonizar_secoes.md)).
A soma por municipio bate, portanto, com a serie municipal do tsebr — o
cheque natural de sanidade.

## Usage

``` r
tse_detalhe_secao(
  con = NULL,
  ano,
  uf,
  metrica = c("aptos", "comparecimento", "abstencoes", "votos_nulos", "votos_brancos"),
  agregar_por = c("subdistrito", "setor", "municipio", "bairro", "area_ponderacao"),
  dest_dir = NULL
)
```

## Arguments

- con:

  conexao DBI com o DW (default abre pelo idiom dos `garantir_*`); usada
  so para ler `tse_secao_bairro` quando `agregar_por != "municipio"`.

- ano:

  ano eleitoral ou vetor (ex.: 2022, 2026).

- uf:

  sigla da UF.

- metrica:

  coluna(s) do detalhe a agregar: `aptos`, `comparecimento`,
  `abstencoes`, `votos_nulos` ou `votos_brancos`.

- agregar_por:

  nivel de agregacao: `subdistrito` (default), `setor`, `bairro` ou
  `area_ponderacao` (exigem harmonizacao previa no DW para o par ano/UF)
  ou `municipio` (mapa TSE x IBGE).

- dest_dir:

  diretorio de cache do download (repassado ao tsebr).

## Value

`data.frame` long: `local` (geoloc_id numerico do DW), `periodo` (31/12
do ano), `valor`, `uf`, `metrica` — mesmo shape do
[`tsebr::tse_detalhe_municipio()`](https://rdrr.io/pkg/tsebr/man/tse_detalhe_municipio.html),
aceito de pronto pelo ramo TSE do upload de fontes.

## Details

Com `agregar_por = "municipio"` a harmonizacao nao e usada: o mapeio e
direto pelo
[`tsebr::tse_mapa_municipios()`](https://rdrr.io/pkg/tsebr/man/tse_mapa_municipios.html)
(codigo TSE -\> IBGE de 7 digitos), reproduzindo o
`tse_detalhe_municipio()`.

Secoes sem atribuicao (sem harmonizacao previa, conflito ou ponto fora
do raio) sao descartadas com
[`warning()`](https://rdrr.io/r/base/warning.html) informando a
contagem: nessas localidades o valor agregado fica abaixo do municipal
na mesma proporcao da perda.

## Examples

``` r
if (FALSE) { # \dontrun{
tse_detalhe_secao(2026, "DF", metrica = "abstencoes",
                  agregar_por = "subdistrito")
} # }
```
