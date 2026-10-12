# Harmoniza secoes de votacao com um nivel submunicipal do DW e grava a tabela `tse_secao_bairro`

Atribuicao principal por ponto (metodo "ponto"): para cada linha de
local de votacao com coordenada util, o vizinho mais proximo do nivel
pedido (`bairro`, `subdistrito`, `setor` ou `area_ponderacao` do DW) via
KNN PostGIS, aceito so se a distancia geodesica ficar dentro de `raio_m`
metros. Secoes que casam com mais de uma localidade distinta viram
"conflito" (sem atribuicao, campos NULL). Fallback por nome (metodo
"nome", so para `nivel = "bairro"` e com `mapa_municipios`): casa o
bairro declarado pelo TSE com o bairro do DW reutilizando os auxiliares
puros de `tse_auxiliares.R`.

## Usage

``` r
tse_harmonizar_secoes(
  con = NULL,
  locais,
  ano,
  uf,
  raio_m = 2000,
  nivel = c("auto", "bairro", "subdistrito", "setor", "area_ponderacao"),
  mapa_municipios = NULL
)
```

## Arguments

- con:

  conexao DBI com o DW; default abre pelo idiom dos `garantir_*` (env
  vars `user`/`password`/`host`/`dbname`).

- locais:

  data.frame de
  [`tsebr::tse_locais_votacao()`](https://rdrr.io/pkg/tsebr/man/tse_locais_votacao.html)
  (ou sf de
  [`tse_pontuar_locais_votacao()`](https://distintivelab.github.io/beep/dev/reference/tse_pontuar_locais_votacao.md)).

- ano, uf:

  ano e sigla da UF processados (chave do trecho gravado).

- raio_m:

  raio maximo em metros entre o local de votacao e o vizinho mais
  proximo (default 2000).

- nivel:

  nivel do DW a atribuir: `"auto"` (bairro se houver no DW, senao
  subdistrito), ou um de `"bairro"`, `"subdistrito"`, `"setor"`,
  `"area_ponderacao"`.

- mapa_municipios:

  vetor nomeado cod_municipio_tse -\> codigo IBGE de 7 digitos, exigido
  pelo metodo "nome" (nivel bairro).

## Value

lista com `nivel`, `raio_m`, `n_secoes`, `por_metodo` (secoes e
eleitores por metodo), `cobertura_eleitores`, `conflitos` (secoes com
multiplos vizinhos) e `concordancia` (cheque ponto x nome, quando ambos
existem).

## Details

Grava uma linha para TODA secao do arquivo, atribuida ou nao, apagando
antes o trecho `(ano, uf, nivel_tipo)` (idempotente por trecho).
