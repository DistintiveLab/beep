# AGENTS.md

Guidance for AI agents working in the **beep** repository.

## What This Project Is

`beep` (successor of the AEDi package) is an R package that bundles an
interactive **Shiny dashboard** (built on the
[`golem`](https://thinkr-open.github.io/golem/) framework) for **Análise
Exploratória de Dados e Indicadores** — importing Brazilian public-data
sources, storing them in a relational database, and deriving composite
indicators from them.

- **Language/locale:** All UI text, code comments, and user-facing
  strings are in **Portuguese (pt-BR)**. `DESCRIPTION` declares
  `Language: pt-BR`. Match this when editing user-facing strings.
- **Lifecycle:** `experimental` / WIP. **Direct successor of AEDi**
  (DistintiveLab/AEDi; full rename September 2026 — `beep_tema_*`,
  `beepdb`, `BEEP_SCRIPT_ARGS`). The name is an acronym: *Back-End de
  Exploração e Painéis de dados*. Original predecessor: `owEDA` (legacy
  entry points may still reference `owEDA:::app_server` in `inst/app/`).
- **License:** MIT, with attribution to jimbriggs/EDA (see
  `LICENSE`/`LICENSE.md`).
- **Repo history:** history was rewritten in 2026-09 and again in
  2026-10 — `main` is now a **single commit** (baseline + renamed AEDi
  import, without the unversioned `coleta/` workspace). The pre-rewrite
  states survive only in local branches: `backup-pre-rewrite` (the old
  [targets](https://docs.ropensci.org/targets/) project-scaffolding
  prototype) and `backup-pre-rewrite-2` (full history including
  `coleta/`). Bringing the scaffolding back as a package feature is a
  **planned future option** (see README roadmap).

## Essential Commands

Standard `golem` + `devtools` workflow (see `devhist.R` for the
canonical setup sequence):

``` r

devtools::document()        # regenerate NAMESPACE + man/ from roxygen
devtools::check()           # R CMD check
devtools::build()           # build tarball
devtools::install()         # install locally
devtools::test()            # testthat suite (golem recommended tests)
```

Run the apps (must be executed from the **project root** so relative
cache dirs resolve):

``` r

beep::run_app()    # exploratory analysis app (data upload)
beep::run_panel()  # indicators dashboard
```

Initialize / rebuild the backend database schema:

``` r

prepare_db()                                # SQLite (default): creates beepdb.sqlite
prepare_db(type = "pgsql", userdb = ...,    # PostgreSQL + PostGIS
           passwddb = ..., hostdb = ...)
```

Docs site (deployed to `gh-pages` by `.github/workflows/pkgdown.yaml`;
local output `docs/` is gitignored):

``` r

pkgdown::build_site()
```

README: edit `README.Rmd`, then `rmarkdown::render("README.Rmd")` (never
edit `README.md` directly).

## Architecture & Control Flow

### Shiny app structure

    run_app()  (R/run_app.R)
      ├── ensures cache dirs exist: coleta/, manipula/, documenta/, visualiza/ (each + /cache)
      └── shinyApp(ui = app_ui(), server = app_server)

    app_ui()  (R/ui_app.R)
      ├── add_external_resources()  → loads www/styles.css, www/custom.js, shinyjs, sweetalert
      └── shinydashboardPlus::dashboardPage
            ├── header    = header_ui()        (R/ui_header.R)        → logo + header_buttons
            ├── sidebar   = sidebar_ui()       (R/ui_sidebar.R)       → nav menu (mostly placeholders)
            ├── body      = body_ui()          (R/ui_body.R)          → upload_data_ui("data")
            └── controlbar= right_sidebar_ui() (R/ui_rightbar.R)      → help panel

    app_server()  (R/server_app.R)
      ├── upload_data_server("data")   ← the core module
      └── callModule(header_buttons, "header")

Only the **“Upload de Dados-Fontes”** tab (`tabName = "upload_data"`) is
wired to content. The other sidebar items (Diagnóstico, Dicionário,
Insights, Modelagem) are placeholders not yet implemented.

### The core module: `upload_data_module.R`

`upload_data_ui` renders a `tabBox` with four tabs:

1.  **Inserção de Fonte** — pick a source type, generate/fetch data,
    write to DB.
2.  **Tabela de Dados** — preview imported data in a
    [`DT::datatable`](https://rdrr.io/pkg/DT/man/datatable.html).
3.  **Resumo** —
    [`summarytools::dfSummary`](https://rdrr.io/pkg/summarytools/man/dfSummary.html)
    rendering.
4.  **Variáveis e Indicadores** — drag-and-drop indicator builder using
    `sortable`, a
    [`shinymath::mathInput`](https://rdrr.io/pkg/shinymath/man/mathInput.html)
    LaTeX equation, and `latex2r` to convert to R code.

### Source-type submodules (nested via `parent_session`)

Each data source has its own `*_ui` / `*_server` pair in
`R/upload_<source>.R`. They are dynamically injected inside
`upload_data_module` based on `input$sourcetype`:

| `sourcetype` | Source | File | Generates |
|----|----|----|----|
| 5 | IBGE SIDRA | `upload_sidraibge.R` | `sidra::sidra(...)` call string |
| 11 | DATASUS | `upload_datasus.R` | `datasus::<func>(...)` call string |
| 12 | RAIS (PostgreSQL) | `upload_raispsql.R` | RAIS query call string |
| 13 | INEP / IDEB | `upload_inep.R` | `educabR::le_ideb(...)` call string |
| 14 | TSE (via `tsebr`) | `upload_tsebr.R` | call string com marcador `# tsebr-familia:` -\> séries municipais/UF (`tse_resultados_municipio`, `tse_detalhe_municipio`, `tse_prestacao_uf`); candidaturas = só CSV de referência |
| 15 | IBGE Censo (via `censoagg`/`censobr`) | `upload_censobr.R` | call string com marcador `# censo-origem:` -\> lista nomeada variável -\> long; uma série (`mdata`) por variável |
| 1/2/9 | URL / local upload / server file | inline in `upload_data_module.R` | file path |

**Key pattern:** Submodules do *not* fetch data themselves. They build
an **R expression as a text string** and write it into the parent
module’s `upload_file` input via
`updateTextInput(session = parent_session, "upload_file", value = ...)`.
The parent’s `selected_files()` reactive then does
`eval(parse(text = input$upload_file))` to actually execute it. New
source types must follow this contract. Os submódulos 14/15 prefixam o
call string com um **marcador na mesma linha do código, separado por
`"; "`** (`# tsebr-familia: <familia>; <call>` /
`# censo-origem: <origem>; <call>`), que o ramo do `selected_files`
consome (e remove antes do eval, via
`sub("^[^;]*;\\s*", "", sub("^[^\n]+\n", "", ...))`) para decidir o
reshape/escrita. O separador é single-line de propósito: o browser
aplica a sanitização de `<input type="text">` e **remove `\n`** do valor
— um call string multi-linha viraria um comentário único e o eval
devolveria NULL.

Datasources `TSE` e `IBGE Censo` são criados sob demanda no DW por
`garantir_datasource_tse()` / `garantir_datasource_censo()`
(idempotentes pelo nome; types 4=ckan e 6=ibge_ftp). Dados por seção
eleitoral/setor censitário **não** entram no DW ainda (não há níveis
submunicipais no `local`): perfis do eleitorado por seção ficam no
pacote
([`tsebr::tse_perfis_secao`](https://rdrr.io/pkg/tsebr/man/tse_perfis_secao.html))
até o trilho territorial ser implementado.

### Data write pipeline

[`db_datawrite()`](https://distintivelab.github.io/beep/dev/reference/db_datawrite.md)
(`R/dbdatawriter.R`) is the single sink for new data:

1.  **Sanitize locals** — matches `local` (IBGE code or name) against
    the `local` table to resolve `local_id`.
2.  **Sanitize dates** — coerces `periodo` to `Date` via `%Y`, `%Y-%m`,
    or `%Y-%m-%d`; annual data (`data_freq_id == 9`) is forced to Dec
    31.
3.  **Append** to `mdata`, `mdata_exts`, `mdata_timetable`, and
    `data_values`.
4.  **Refresh materialized views** (`named_datavalues`,
    `geonamed_datavalues`).

## Database

### Backends

- **PostgreSQL + PostGIS** is the production backend (used by the live
  app and by `db_datawrite`).
- **SQLite** is supported by `prepare_db(type = "sqlite")` for local
  schema bootstrapping, but `db_datawrite` is PostgreSQL-only.

### Connection / environment variables (from `.Renviron`)

The app reads DB credentials via
[`Sys.getenv()`](https://rdrr.io/r/base/Sys.getenv.html). A `.Renviron`
file in the project root provides them. **The app will not start without
these set.**

| Variable(s) | Used for | Where |
|----|----|----|
| `dbname`, `user`, `password`, `host` | Main beep PostgreSQL DB | `upload_data_module.R`, `dbdatawriter.R` |
| `mte_rais`, `dbrais`, `pwdrais`, `hostraispsql` | Separate RAIS PostgreSQL DB | `upload_raispsql.R` |
| `tdbname`, `userdb`, `passwddb`, `hostdbdev`, `passwddbdev` | [`prepare_db()`](https://distintivelab.github.io/beep/dev/reference/prepare_db.md) dev setup | `dbprepare.R`, `create_extend_geogroup_view.R` |

> `.Renviron` is untracked. Do not commit real credentials.

### Core schema (defined in `R/dbprepare.R`)

Data is stored in **long/tidy format** and denormalized via materialized
views:

- `data_values(mdata_id, local_id, refdate, value)` — the fact table
  (composite PK).
- `mdata` / `mdata_exts` / `mdata_timetable` — indicator metadata (name,
  class, frequency, source, last-update tracking).
- `local` / `geoloc` / `local_group` — geographic entities
  (`geoloc.geometry` stores PostGIS geometries; `local_id` follows IBGE
  codes: \<10 = region, \<100 = state, 6-digit = municipality).
- `datagroup` / `group_parent` / `mdata_group` — hierarchical grouping
  of indicators and localities (e.g. biomes, legal-Amazon, semiarid).
- `datasource` / `datasource_type` / `institution` / `officialer` —
  provenance.
- `data_class` / `data_freq` / `data_type` — classification lookups.

### Territorial levels and `local_id` blocks

`R/niveis_territoriais.R` is the single source of the conventions below
(ROADMAP-niveis-submunicipais.md). `geoloc.geoloc_id` is BIGINT and
`local.nivel_tipo` records the level; submunicipal codes carry their own
municipality as the 7-digit prefix:

| Level | `geoloc_id` width | `local_id` block | Notes |
|----|----|----|----|
| municipality | 7 | malha 2024 1..5571, PNAD 5572..7087 (or up to the “Brasil” row), then append after it | 6-digit codes always mean municipality (RAIS prefix map) |
| bairro | 11-12 | 1000000..1999999 | derived from the Census (dissolve of tracts), [`incorporar_bairros()`](https://distintivelab.github.io/beep/dev/reference/incorporar_bairros.md) |
| area de ponderacao | 13 | 2000000..2999999 | [`incorporar_areas_ponderacao()`](https://distintivelab.github.io/beep/dev/reference/incorporar_areas_ponderacao.md) |
| setor censitario | 15-16 | 100000..999999 | [`incorporar_setores_censitarios()`](https://distintivelab.github.io/beep/dev/reference/incorporar_setores_censitarios.md) |

Loads are **append-only** (`local_id` is never renumbered —
`data_values` references it) and idempotent by code via
[`ampliar_nivel_territorial()`](https://distintivelab.github.io/beep/dev/reference/ampliar_nivel_territorial.md).
Provenance goes to
`niveis_carga (nivel_tipo, fonte, escopo, ano, n_localidades, carregado_em)`.
Submunicipal levels deliberately have **no row in
`recortes_geograficos`** (one row per municipality by design); the
painel resolves their context via the 7-digit prefix. Note
`R/painel_dw.R` keeps a local copy of the block limits so the painel
skeleton stays self-contained — mirror changes in both
(`tests/testthat/test-painel-esqueleto.R` enforces file sync, not this).

For TSE electoral data by bairro, the pure helpers in
`R/tse_auxiliares.R` (internal) match `(municipio, normalized name)` and
map seção→bairro from the voter-profile files; premises and limits are
documented in that file’s header — never infer a bairro silently.

**Materialized views** (refresh after writes):

- `named_datavalues` — joins `data_values` → `mdata` → `mdata_exts` →
  `datasource`.
- `geonamed_datavalues` — further joins `local` →
  `recortes_geograficos`.
- `recortes_geograficos` — built by `create_extend_geogroup_view.R`; one
  row per municipality with centroid coords, UF, region, and group
  memberships.

ER/EER diagrams live in `inst/app/www/` (`v2024-12-EER.png`,
`*ERpsql*.png`).

## Code Organization

| Path | Purpose |
|----|----|
| `R/` | Package source — the Shiny app, modules, DB helpers, utils. **This is what ships.** |
| `coleta/` | Runtime workspace (“coleta”), **not versioned** (gitignored, mirroring upstream AEDi): generated at the root where the app runs — indicator-computation scripts (`executa_atualizacao()`), `cache/` with downloaded raw datasets (DBC, CSV, XLSX, GPKG) and `*.R.log` logs land here. The versioned batch lives in each concrete project. |
| `manipula/` | “Manipula” (manipulation): transformation pipeline outputs; `metadados/` holds per-source variable lists. |
| `documenta/`, `visualiza/` | Documentation / visualization staging (each has a `cache/`). |
| `inst/app/www/` | Static assets served at `/www` (CSS, JS, logos, schema PNGs). |
| `inst/extdata/` | Demo/example CSVs used by the in-app file picker (“Demo Data” volume). |
| `inst/rmarkdown/templates/` | R Markdown template (“Data Validation Report”). |
| `inst/painel/`, `inst/painel_esqueleto/` | Painel assets and the deployable skeleton (see gotchas). |
| `inst/tema/` | CSS/JS theme files (`beep-tema.css` etc.). |
| `data/` | Lazy-loaded package data (`.rda`): `agregados`, `raismetalayoute`, `raismetalayoutv`, `sidrameta`. |
| `data-raw/` | Scripts that produce `data/*.rda` (e.g. `data_sidra.R`). |
| `modprov/` | Standalone prototype app for testing individual modules in isolation. |
| `tests/testthat/` | Golem-recommended smoke tests (UI is a taglist, server is a function, app launches). |
| `man/` | Auto-generated Rd — do not edit by hand. |
| `pkgdown/`, `.github/workflows/pkgdown.yaml` | pkgdown site config and CI deploy to `gh-pages`. |
| `admin/`, `setup_agendamento.R`, `ddlx.sql`, `devhist.R` | Ops/admin extras (Rbuildignored; `devhist.R` documents how the package was scaffolded). |

## Conventions

- **Roxygen2 with markdown** (`RoxygenNote: 7.3.2`,
  `Roxygen: list(markdown = TRUE)`). `NAMESPACE` and `man/` are
  generated — never hand-edit.
- **2-space indentation**, UTF-8, spaces for tabs (per `beep.Rproj`).
- **`Collate` order in `DESCRIPTION`** controls file load order and
  **matters** (utils define `agregfunc`, helpers define `flucol`, etc.,
  before modules use them). If you add an `R/` file, update `Collate`
  via `devtools::document()`.
- **Shiny modules** use the
  `moduleServer(id, function(input, output, session))` pattern with
  `ns <- session$ns`. UI functions take `id`; nested submodules take an
  extra `parent_session` argument.
- **Native pipe `\()`** for anonymous functions and `|>` for chaining
  are used throughout (requires R \>= 4.1).
- **Helper functions** (`flucol`, `icon_text`, `rep_br`, `insert_logo`)
  live in `R/ui_helpers.R`. Stat helpers (`somasna`, `mediasna`, `mmov`,
  etc.) and the `agregfunc` vector (user-facing aggregation labels) live
  in `R/utils.R`.
- **Logging:** `futile.logger` logs indicator-creation provenance to
  `coleta/<indicator>.R.log` and into the generated script file.
- **Naming history:** everything was bulk-renamed from AEDi/aedidb to
  beep/beepdb (files, function names like `beep_tema_*`, CSS classes
  like `beep-tema`, env var `BEEP_SCRIPT_ARGS`). Keep the `beep`
  prefixes consistent in new code.
- **Version bumps:** every commit in beep/tsebr/censoagg/tsesqlr must
  carry at least a minimal `DESCRIPTION` version bump (e.g. `9000` →
  `9001`). The user installs these packages as root into
  `/usr/local/lib/R/site-library/`; the assistant never installs — test
  with
  [`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html)
  and let the user reinstall.

## Gotchas

### Load-time side effects (install/load requirements)

All packages used via `::` or
[`library()`](https://rdrr.io/r/base/library.html) are declared in
`DESCRIPTION` `Imports`. When adding code that uses a new package, add
it to `Imports`/`Suggests` via
[`usethis::use_package()`](https://usethis.r-lib.org/reference/use_package.html).

Some `R/` files run code with side effects at build/load time:

- `upload_raispsql.R` — initializes its module globals via
  `.init_raispsql()`, called from `.onLoad` (`.onLoad` runs after the
  namespace is writable but before lazy-data registration, so the block
  loads `raismetalayoutv/e` with
  `data(..., envir = asNamespace("beep"))`). Placeholders are defined at
  file top level (required: bindings created fresh in `.onLoad` are lost
  to the lazy-load shadow) and overwritten by the init block. It
  connects to the RAIS PostgreSQL DB (`conrais`, `avinforais`, …);
  without the RAIS DB or its env vars (`mte_rais`, `dbrais`, `pwdrais`,
  `hostraispsql`) load only emits a **warning** (`conrais=NULL`, empty
  choices for source type 12). (Also: never add `rm(list = ls())` at a
  file’s top level — it wiped objects of every earlier `Collate` entry
  during build and broke `R CMD INSTALL`.)
- `create_extend_geogroup_view.R` — tries to connect to the dev PostGIS
  DB at load, but tolerates failure (`con <- tryCatch(..., error = ...)`
  → warning).
- `upload_datasus.R` / `upload_inep.R` — read
  [`datasus::metatabnet`](https://rdrr.io/pkg/datasus/man/metatabnet.html)
  and `educabR::metainep`/`metaideb` at load (just needs those packages
  installed).

### Painel skeleton is duplicated (keep in sync)

The painel sources exist in TWO places that must stay byte-identical:
`R/painel_*.R` + `R/mod_panel_*.R` (used by launcher mode,
[`panel_app()`](https://distintivelab.github.io/beep/dev/reference/panel_app.md))
and `inst/painel_esqueleto/R/` (copied verbatim by
[`deploy_panel()`](https://distintivelab.github.io/beep/dev/reference/deploy_panel.md)
/
[`atualizar_painel()`](https://distintivelab.github.io/beep/dev/reference/atualizar_painel.md);
`www/` assets likewise live once in `inst/painel/`).
`tests/testthat/test-painel-esqueleto.R` enforces the sync — edit one
copy, [`file.copy()`](https://rdrr.io/r/base/files.html) to the other,
and update both `exatas` in `R/deploy_panel.R` and `compartilhados` in
the test when adding/renaming a file. Skeleton R files are plain (no
`%%PLACEHOLDER%%`; those only exist in `app.R`, `README.md`,
`R/app_ui.R`). New R files must be added to `exatas` or
[`deploy_panel()`](https://distintivelab.github.io/beep/dev/reference/deploy_panel.md)
will not copy them and generated apps break. The skeleton has its own
two-tier DW cache (`painel_cache.R`, `cache/` dir at runtime, TTLs per
data kind;
[`painel_cache_limpar()`](https://distintivelab.github.io/beep/dev/reference/painel_cache_limpar.md)
after ETL, `painel_sem_cache=1` to bypass). Map basemap is chosen at
runtime by `painel_basemap.R`: Carto tiles require `CARTO_API_KEY`
(appended as `?key=`); without it the map uses the tile-less
labourvaluesdatapanel pattern (IBGE UF outlines from the DW).
`PAINEL_BASEMAP` forces `carto`/`neutro`. The Região tab opens on a
locality summary card (last value of each composite indicator per
objetivo, from
[`painel_hierarquia()`](https://distintivelab.github.io/beep/dev/reference/painel_hierarquia.md)/[`painel_compostos()`](https://distintivelab.github.io/beep/dev/reference/painel_compostos.md)/[`painel_valores_local_todos()`](https://distintivelab.github.io/beep/dev/reference/painel_valores_local_todos.md))
plus a “Mostrar mais” accordeon with per-indicator mini-plots, and
defaults to the municipal level
([`painel_nivel_default()`](https://distintivelab.github.io/beep/dev/reference/painel_nivel_default.md)).
The globe (`inst/painel/painel-globe.js`) draws the whole world behind
the UFs (countries from the `maps` package, asset
`inst/painel/painel-mundo.geojson` regenerated by
`data-raw/painel_mundo.R`, served via the `painel_recursos` resource
path) with Google-Earth-like zoom (buttons + mouse wheel, clamped
1x-256x with dynamic d3 precision). Its layers follow the selected
territorial level: light levels draw their own IBGE delimitations from
the DW
([`painel_geo_nivel()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_nivel.md),
simplified in SQL, hard cap of 700 features), while heavy levels
(e.g. municipal) keep the UF base and highlight the chosen locality
([`painel_geo_local()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_local.md))
over its parent state
([`painel_geo_pai_uf()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_pai_uf.md)),
animating the zoom so the whole state fits. Clicking an area with data
picks a locality of the current level (UF mode resolves it via
[`painel_local_top_uf()`](https://distintivelab.github.io/beep/dev/reference/painel_local_top_uf.md)).
User-visible strings must say “banco de dados do painel”, never “DW do
beep”; internal comments/identifiers may keep the generic “DW”.

### `eval(parse(text = ...))` is pervasive

Submodules emit R code as strings and the parent module `eval`s it. This
is intentional (it lets users see/edit the exact call) but means
**untrusted input becomes executed R code**. Treat the `upload_file`
input as code, not data.

### Materialized views need refreshing

After any direct write to `data_values` / `mdata` (outside
`db_datawrite`), run:

``` sql
REFRESH MATERIALIZED VIEW named_datavalues;
REFRESH MATERIALIZED VIEW geonamed_datavalues;
```

Otherwise the app’s indicator picker (which queries
`geonamed_datavalues`) won’t see new data.

### Cache directories are created at runtime

[`run_app()`](https://distintivelab.github.io/beep/dev/reference/run_app.md)
creates `coleta/cache`, `manipula/cache`, `documenta/cache`,
`visualiza/cache` under the current working directory if missing. Run
the app from the project root, not from `inst/` or a temp dir.

### IBGE local_id encoding

`local_id` / `geoloc_id` follow IBGE conventions: single-digit =
macro-region, two-digit = UF (state), seven-digit (first six =
municipality code) = municipality. `db_datawrite` matches incoming
`local` values (numeric IBGE codes or `"CODE Name"` strings) against the
`local` table. Unmatched locals are silently dropped from the write.

## Testing

Tests are minimal — `tests/testthat/test-golem-recommended.R` checks
that
[`app_ui()`](https://distintivelab.github.io/beep/dev/reference/app_ui.md)
returns a shinytaglist, `app_server` is a function, and the app process
launches. There is **no unit coverage** for the DB layer or modules; the
“app launches” test spawns a subprocess via `processx` and checks it
stays alive. To run:

``` r

devtools::test()
```
