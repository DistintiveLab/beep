# Incorpora um municipio criado depois da carga original do DW

Baixa metadados e geometria da API do IBGE, insere `geoloc` (malha
simplificada) e `local` (local_id = max + 1, sempre apos o bloco PNAD,
7088, 7089, ...), vincula os recortes geograficos (regiao imediata e
intermediaria resolvidas pelo nome do IBGE; participacoes em Amazonia
Legal, faixa de fronteira, semiarido e SUDENE copiadas de um municipio
de referencia da mesma regiao imediata) e regenera a matview
`recortes_geograficos`. A tipologia PNDR nao e copiada nem resolvida — o
IBGE ainda nao publica classificacao para municipios novos; passe o id
do grupo via `grupos` quando existir. DATASUS tambem costuma demorar a
publicar populacao de municipios novos: indicadores que dependem de
popmun ficam com o valor do municipio pendente ate la (scripts devem
tolerar NA; ver massa_salarial_municipal.R).

## Usage

``` r
incorporar_municipio_ibge(
  geoloc_id,
  municipio_referencia = NULL,
  grupos = NULL,
  tolerancia = 0.01,
  con = NULL,
  regenerar_recortes = TRUE
)
```

## Arguments

- geoloc_id:

  codigo IBGE do municipio, 6 ou 7 digitos

- municipio_referencia:

  geoloc_id (7d) ou local_id de um municipio vizinho de onde copiar as
  participacoes (default: primeiro municipio da mesma regiao imediata do
  novo municipio)

- grupos:

  ids de datagroup adicionais a vincular (ex.: tipologia)

- tolerancia:

  dTolerance (graus) da simplificacao da malha; default 0.01, calibrado
  com a resolucao das geometrias existentes

- con:

  conexao DBI com o DW; default abre o beepdb local

- regenerar_recortes:

  regenerar a matview recortes_geograficos?

## Value

`local_id` do municipio incorporado, invisivel
