# populate_initialdb — seeder territorial do DW beep

Portado de pndr_dashboard/data-raw/populate_initialdb.R (o primeiro
seeder do ecossistema AEDi/beep) para preencher `local`/`geoloc` e os
grupos territoriais de um DW recem-criado por
[`prepare_db()`](https://distintivelab.github.io/beep/dev/reference/prepare_db.md),
mantendo as convencoes que o ecossistema consome: `local_id` 1..~5570
municipios, estratos PNAD na faixa 5571..7087 (geoloc_id sintetico),
micro/mesorregioes antigas deslocadas para 8 digitos (10000000+), Brasil
= max(local_id)+1.

## Usage

``` r
populate_initialdb(
  con = NULL,
  dbtype = "pgsql",
  dir_dadostat = NULL,
  pndr_groups = FALSE,
  pnadc_inicio = 5572L,
  limpar = TRUE
)
```

## Arguments

- con:

  Conexao DBI aberta no DW alvo; se NULL, abre com as env vars padrao do
  beep (user/password/host/dbname).

- dbtype:

  "pgsql" (unico suportado; sqlite não tem PostGIS).

- dir_dadostat:

  Diretorio com insumos opcionais do projeto (tipologia2018_ajustada.csv
  e manual do painel PNDR); so usado com `pndr_groups = TRUE`.

- pndr_groups:

  Criar os grupos de desenvolvimento regional (Tipologia PNDR 2018,
  Eixos/Objetivos)? Default FALSE - a view `recortes_geograficos` tolera
  a ausencia (colunas NA). Os recortes territoriais universais (Faixa de
  Fronteira, Amazonia Legal, Semiarido, SUDENE, regioes, UF/Regiao)
  sempre entram.

- pnadc_inicio:

  Primeiro `local_id` do bloco de estratos PNAD (default 5572:
  municípios da malha 2024 ocupam 1..5571).

- limpar:

  Truncar `local_group`/`local`/`geoloc` antes de popular (default
  TRUE - torna o seeder re-executavel).

## Details

Carga: municipios, micror e mesorregioes (IBGE 1990), UFs,
macrorregioes, Brasil, regioes imediatas/intermediarias (2020), estratos
PNAD Contínua, e os grupos territoriais (Faixa de Fronteira, Amazonia
Legal, Semiarido, SUDENE, Tipologia PNDR 2018, regioes, UF/Regiao) com
`local_group`/`group_parent`.

NAO carrega indicadores (mdata/data_values/mdata_exts): esses vem dos
pipelines de cada projeto.

Uso: `data-raw/populate_initialdb.R | populate_initialdb()` (requer
conexao ao Postgres do DW e os pacotes Suggests geobr/readODS/rvest
(brazilmaps não é mais usado: a v1.0.0 quebrou API e o geobr cobre todos
os níveis).
