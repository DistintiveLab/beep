# Testes de integracao dos niveis territoriais submunicipais contra um DW
# PostgreSQL+PostGIS local de arranque.
#
# Sao env-gated: rodam apenas com BEEP_TEST_DW definido (nome do banco),
# ex.:
#
#   BEEP_TEST_DW=beepdbtest Rscript -e \
#     'pkgload::load_all(quiet=TRUE); testthat::test_file(
#        "tests/testthat/test-niveis-dw.R", reporter="summary")'
#
# Pre-requisitos (montados uma vez por who):
#   CREATE ROLE beep LOGIN PASSWORD '...' CREATEDB;
#   CREATE DATABASE beepdbtest OWNER beep; + CREATE EXTENSION postgis;
# O fixture reseta o banco inteiro (DROP OWNED BY beep CASCADE) — nunca
# aponte BEEP_TEST_DW para o DW de producao.

.db_teste <- Sys.getenv("BEEP_TEST_DW", "beepdbtest")
.user_teste <- Sys.getenv("user", "beep")
.pass_teste <- Sys.getenv("password", "aEd1#man@gR")
.host_teste <- Sys.getenv("host", "127.0.0.1")

.con_niveis_dw <- function() {
  DBI::dbConnect(RPostgres::Postgres(), dbname = .db_teste,
                 user = .user_teste, password = .pass_teste,
                 host = .host_teste)
}

.tipo_coluna <- function(con, tabela, coluna) {
  unname(DBI::dbGetQuery(con, sprintf(paste(
    "SELECT data_type FROM information_schema.columns",
    "WHERE table_name = '%s' AND column_name = '%s'"),
    tabela, coluna))$data_type[1])
}

# Fixture: roda uma unica vez por arquivo; reseta e remonta o DW de teste
# (schema completo via prepare_db geo=FALSE + recortes + 2 localidades)
.fixture_niveis_dw <- local({
  feito <- FALSE
  function() {
    if (feito) return(invisible(TRUE))
    con <- .con_niveis_dw()
    DBI::dbExecute(con, "DROP OWNED BY beep CASCADE")
    DBI::dbDisconnect(con)

    invisible(capture.output(suppressMessages(suppressWarnings(
      prepare_db(tdbname = .db_teste, type = "pgsql", userdb = .user_teste,
                 passwddb = .pass_teste, hostdb = .host_teste, geo = FALSE)
    ))))

    con <- .con_niveis_dw()
    # familias extras alem do catalogo: reproduz o cenario de producao em
    # que parent_grupos (11) excede os previos_nmcols (9) e o mapeamento
    # posicional de nomecol cai no ramo do janitor
    DBI::dbWriteTable(con, "datagroup", data.frame(
      datagroup_id = as.integer(99001:99009),
      datagroup_name = sprintf("fam %d", 99001:99009),
      datagroup_desc = "fixture niveis submunicipais"), append = TRUE)
    DBI::dbWriteTable(con, "group_parent", data.frame(
      datagroup_id = as.integer(99001:99009),
      datagroup_parentid = as.integer(99001:99009)), append = TRUE)

    # criar_recortes_geograficos usa mutate()/across() sem namespace
    # (upstream roda com dplyr attached)
    suppressPackageStartupMessages(library(dplyr))
    criar_recortes_geograficos(con = con)

    for (sql in c(
      "INSERT INTO geoloc (geoloc_id, geometry) VALUES (1100203, ST_SetSRID(ST_MakePoint(-63.0,-8.8),4326))",
      "INSERT INTO geoloc (geoloc_id, geometry) VALUES (1100078, ST_SetSRID(ST_MakePoint(-63.9,-8.7),4326))",
      "INSERT INTO local (local_id, geoloc_id, local_name) VALUES (1, 1100203, 'Porto Velho (teste)')",
      "INSERT INTO local (local_id, geoloc_id, local_name) VALUES (5600, 1100078, 'Regiao PNAD (teste)')")) {
      DBI::dbExecute(con, sql)
    }
    DBI::dbDisconnect(con)
    feito <<- TRUE
    invisible(TRUE)
  }
})

test_that("T1: banco recem-criado pelo prepare_db ja nasce migrado", {
  skip_if(!nzchar(Sys.getenv("BEEP_TEST_DW")),
          "DW de teste local ausente (defina BEEP_TEST_DW)")
  .fixture_niveis_dw()

  con <- .con_niveis_dw()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  expect_identical(.tipo_coluna(con, "geoloc", "geoloc_id"), "bigint")
  expect_identical(.tipo_coluna(con, "local", "geoloc_id"), "bigint")
  expect_identical(.tipo_coluna(con, "local", "nivel_tipo"), "text")
  expect_gt(length(DBI::dbGetQuery(con, paste(
    "SELECT 1 FROM pg_indexes",
    "WHERE indexname = 'local_nivel_tipo_idx'"))[[1]]), 0L)
})

test_that("T2: preparar_niveis_submunicipais migra um banco antigo (integer)", {
  skip_if(!nzchar(Sys.getenv("BEEP_TEST_DW")),
          "DW de teste local ausente (defina BEEP_TEST_DW)")
  .fixture_niveis_dw()

  con <- .con_niveis_dw()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  ## degradar ate o estado pre-migracao: matviews salvas e dropadas,
  ## FK dropada, nivel_tipo fora e geoloc_id de volta a integer
  defs_antigas <- DBI::dbGetQuery(con, paste(
    "SELECT c.relname AS mv, pg_get_viewdef(c.oid, true) AS def",
    "FROM pg_class c WHERE c.relkind = 'm'",
    "AND c.relname IN ('recortes_geograficos','geonamed_datavalues')"))
  idx_antigos <- DBI::dbGetQuery(con, paste(
    "SELECT indexdef FROM pg_indexes WHERE schemaname = 'public'",
    "AND tablename IN ('recortes_geograficos','geonamed_datavalues')"))$indexdef
  fk_antiga <- DBI::dbGetQuery(con, paste(
    "SELECT conname, pg_get_constraintdef(oid) AS def",
    "FROM pg_constraint",
    "WHERE contype = 'f' AND confrelid = 'geoloc'::regclass"))
  expect_identical(fk_antiga$conname[1], "fk_geoloc_geoloc_id")

  for (sql in c(
    "DROP MATERIALIZED VIEW geonamed_datavalues",
    "DROP MATERIALIZED VIEW recortes_geograficos",
    sprintf("ALTER TABLE local DROP CONSTRAINT %s", fk_antiga$conname[1]),
    "ALTER TABLE local DROP COLUMN nivel_tipo",
    "ALTER TABLE geoloc ALTER COLUMN geoloc_id TYPE integer USING geoloc_id::integer",
    "ALTER TABLE local ALTER COLUMN geoloc_id TYPE integer USING geoloc_id::integer",
    sprintf("ALTER TABLE local ADD CONSTRAINT %s %s",
            fk_antiga$conname[1], fk_antiga$def[1]))) {
    DBI::dbExecute(con, sql)
  }
  ordem_criacao <- c("recortes_geograficos", "geonamed_datavalues")
  for (mv in ordem_criacao) {
    DBI::dbExecute(con, sprintf("CREATE MATERIALIZED VIEW %s AS %s", mv,
                               defs_antigas$def[defs_antigas$mv == mv]))
  }
  for (d in idx_antigos) DBI::dbExecute(con, d)
  expect_identical(.tipo_coluna(con, "local", "geoloc_id"), "integer")

  ## migrar de volta
  expect_identical(beep:::preparar_niveis_submunicipais(con = con), TRUE)
  expect_error(beep:::preparar_niveis_submunicipais(con = con), NA)

  expect_identical(.tipo_coluna(con, "geoloc", "geoloc_id"), "bigint")
  expect_identical(.tipo_coluna(con, "local", "geoloc_id"), "bigint")
  expect_identical(.tipo_coluna(con, "local", "nivel_tipo"), "text")

  niveis <- DBI::dbGetQuery(con, paste(
    "SELECT local_id, nivel_tipo FROM local ORDER BY local_id"))
  expect_identical(niveis$nivel_tipo, c("municipio", "pnad"))

  fk_nova <- DBI::dbGetQuery(con, paste(
    "SELECT conname, pg_get_constraintdef(oid) AS def",
    "FROM pg_constraint",
    "WHERE contype = 'f' AND confrelid = 'geoloc'::regclass"))
  expect_gte(nrow(fk_nova), 1L)
  expect_identical(fk_nova$def[fk_nova$conname == fk_antiga$conname[1]],
                   fk_antiga$def[1])

  defs_novas <- DBI::dbGetQuery(con, paste(
    "SELECT c.relname AS mv, pg_get_viewdef(c.oid, true) AS def",
    "FROM pg_class c WHERE c.relkind = 'm'",
    "AND c.relname IN ('recortes_geograficos','geonamed_datavalues')"))
  expect_setequal(defs_novas$mv, defs_antigas$mv)
  for (mv in defs_antigas$mv) {
    expect_identical(defs_novas$def[defs_novas$mv == mv],
                     defs_antigas$def[defs_antigas$mv == mv])
  }
})

test_that("T3: ampliar_nivel_territorial aloca blocos e e idempotente", {
  skip_if(!nzchar(Sys.getenv("BEEP_TEST_DW")),
          "DW de teste local ausente (defina BEEP_TEST_DW)")
  .fixture_niveis_dw()

  polis <- c(
    "POLYGON((-63.0 -8.0, -62.9 -8.0, -62.9 -8.1, -63.0 -8.1, -63.0 -8.0))",
    "POLYGON((-62.9 -8.0, -62.8 -8.0, -62.8 -8.1, -62.9 -8.1, -62.9 -8.0))",
    "POLYGON((-48.0 -15.0, -47.9 -15.0, -47.9 -15.1, -48.0 -15.1, -48.0 -15.0))")
  setores <- sf::st_sf(
    code_tract = c("110020305020001", "110020305020002", "120040305020001"),
    geometry = sf::st_as_sfc(polis), crs = 4326)
  bairros <- sf::st_sf(
    code_bairro = "310620305012",
    geometry = sf::st_as_sfc(
      "POLYGON((-44.0 -19.0, -43.9 -19.0, -43.9 -19.1, -44.0 -19.1, -44.0 -19.0))"),
    crs = 4326)
  aps <- sf::st_sf(
    code_weighting = "3106203050123",
    geometry = sf::st_as_sfc(
      "POLYGON((-44.1 -19.0, -44.0 -19.0, -44.0 -19.2, -44.1 -19.2, -44.1 -19.0))"),
    crs = 4326)

  con <- .con_niveis_dw()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  r_setor <- ampliar_nivel_territorial(setores, "setor",
                                       col_codigo = "code_tract", con = con)
  r_bairro <- ampliar_nivel_territorial(bairros, "bairro", con = con)
  r_ap <- ampliar_nivel_territorial(aps, "area_ponderacao",
                                    col_codigo = "code_weighting", con = con)

  codigos <- beep:::normalizar_codigo_geoloc(r_setor$codigo)
  expect_setequal(codigos, setores$code_tract)
  expect_true(all(r_setor$local_id >= 100000L & r_setor$local_id <= 999999L))
  expect_true(all(r_bairro$local_id >= 1000000L & r_bairro$local_id <= 1999999L))
  expect_true(all(r_ap$local_id >= 2000000L & r_ap$local_id <= 2999999L))

  loc <- DBI::dbGetQuery(con,
    "SELECT local_id, geoloc_id, nivel_tipo, local_name FROM local ORDER BY local_id")
  sel_setor <- loc$local_id >= 100000 & loc$local_id <= 999999
  expect_identical(loc$nivel_tipo[sel_setor], rep("setor", sum(sel_setor)))
  expect_identical(loc$nivel_tipo[loc$local_id == 1000000L], "bairro")
  expect_identical(loc$nivel_tipo[loc$local_id == 2000000L], "area_ponderacao")
  # geoloc_id volta do RPostgres como integer64: normalizar preserva o codigo
  expect_setequal(beep:::normalizar_codigo_geoloc(
    loc$geoloc_id[loc$nivel_tipo == "setor"]), setores$code_tract)
  expect_identical(loc$local_name[loc$local_id == 1000000L], "310620305012")
  # geometria round-trip: setor 1 cobre o ponto interno do poligono original
  dentro <- DBI::dbGetQuery(con, paste(
    "SELECT count(*) AS n FROM geoloc",
    "WHERE geoloc_id = 110020305020001",
    "AND ST_Contains(geometry, ST_SetSRID(ST_MakePoint(-62.95, -8.05), 4326))"))
  expect_identical(as.numeric(dentro$n), 1)

  ## idempotencia: mesmos local_ids, contagem estavel
  n_antes <- nrow(loc)
  r2 <- ampliar_nivel_territorial(setores, "setor",
                                  col_codigo = "code_tract", con = con)
  expect_identical(r2$local_id, r_setor$local_id)
  expect_identical(as.numeric(DBI::dbGetQuery(
    con, "SELECT count(*) AS n FROM local")$n), as.numeric(n_antes))
})

test_that("T4: gravar_serie_dw resolve setor (15d) e municipio (7d)", {
  skip_if(!nzchar(Sys.getenv("BEEP_TEST_DW")),
          "DW de teste local ausente (defina BEEP_TEST_DW)")
  .fixture_niveis_dw()

  con <- .con_niveis_dw()
  DBI::dbExecute(con, paste(
    "INSERT INTO mdata (mdata_id, orig_name, data_name, data_desc)",
    "VALUES (910001, 'teste_setor_dw', 'Teste setor DW', 'fixture niveis')"))
  DBI::dbExecute(con, paste(
    "INSERT INTO mdata_timetable (mdata_id, last_refdate, last_update)",
    "VALUES (910001, '2020-12-31', '2020-12-31')"))

  polis <- c(
    "POLYGON((-63.0 -8.0, -62.9 -8.0, -62.9 -8.1, -63.0 -8.1, -63.0 -8.0))",
    "POLYGON((-48.0 -15.0, -47.9 -15.0, -47.9 -15.1, -48.0 -15.1, -48.0 -15.0))")
  setores <- sf::st_sf(
    code_tract = c("110020305020001", "120040305020001"),
    geometry = sf::st_as_sfc(polis), crs = 4326)
  ampliar_nivel_territorial(setores, "setor", col_codigo = "code_tract",
                            con = con)

  # lookup triplo no cenario real: prefixo 6d so de municipio, setor pelo
  # codigo completo, PNAD fora do mapa de prefixo
  locais <- DBI::dbGetQuery(con, "SELECT local_id, geoloc_id FROM local")
  lookup <- beep:::montar_lookup_locais(locais)
  expect_identical(unname(lookup["110020"]), 1L)       # prefixo 6d Porto Velho
  expect_identical(unname(lookup["1100203"]), 1L)      # geoloc 7d
  expect_identical(unname(lookup["5600"]), 5600L)      # local_id PNAD
  expect_identical(unname(lookup["1100078"]), 5600L)   # geoloc PNAD pelo codigo cheio
  expect_identical(unname(lookup["110020305020001"]), 100000L)
  expect_true(is.na(lookup["110002"]))                   # RGIM fora do prefixo
  # o mapa de prefixo 6d so tem municipio (chaves 6d que nao sao local_id)
  chaves6 <- setdiff(names(lookup)[nchar(names(lookup)) == 6L],
                     as.character(locais$local_id))
  expect_identical(chaves6, "110020")

  DBI::dbDisconnect(con)

  envs <- c("user", "password", "host", "dbname")
  antigos <- Sys.getenv(envs)
  Sys.setenv(user = .user_teste, password = .pass_teste,
             host = .host_teste, dbname = .db_teste)
  on.exit({
    for (nm in envs) {
      if (nzchar(antigos[[nm]])) Sys.setenv(nm = antigos[[nm]])
      else Sys.unsetenv(nm)
    }
  }, add = TRUE)

  serie <- data.frame(
    local = c("110020305020001", "1100203"),
    periodo = as.Date(c("2020-12-31", "2020-12-31")),
    valor = c(42, 7))
  expect_true(suppressMessages(
    gravar_serie_dw("teste_setor_dw", serie, modo = "append")))

  con <- .con_niveis_dw()
  dv <- DBI::dbGetQuery(con, paste(
    "SELECT local_id, value FROM data_values",
    "WHERE mdata_id = 910001 ORDER BY local_id"))
  expect_identical(dv$local_id, c(1L, 100000L))
  expect_identical(dv$value, c(7, 42))
  tt <- DBI::dbGetQuery(con, paste(
    "SELECT last_refdate, last_update FROM mdata_timetable",
    "WHERE mdata_id = 910001"))
  expect_identical(format(tt$last_refdate), "2020-12-31")
  ndv <- DBI::dbGetQuery(con, paste(
    "SELECT count(*) AS n FROM named_datavalues",
    "WHERE orig_name = 'teste_setor_dw'"))
  expect_identical(as.numeric(ndv$n), 2)
})

test_that("T5: incorporar_setores_censitarios (geobr mockado) registra niveis_carga", {
  skip_if(!nzchar(Sys.getenv("BEEP_TEST_DW")),
          "DW de teste local ausente (defina BEEP_TEST_DW)")
  skip_if(!requireNamespace("geobr", quietly = TRUE), "geobr ausente")
  .fixture_niveis_dw()

  malha <- sf::st_sf(
    code_tract = c("110020325020001", "110020325020002"),
    geometry = sf::st_as_sfc(c(
      "POLYGON((-63.2 -8.2, -63.1 -8.2, -63.1 -8.3, -63.2 -8.3, -63.2 -8.2))",
      "POLYGON((-63.1 -8.2, -63.0 -8.2, -63.0 -8.3, -63.1 -8.3, -63.1 -8.2))")),
    crs = 4326)
  fake_tract <- function(code_tract, year, simplified, showProgress, zone = NULL)
    malha
  testthat::local_mocked_bindings(read_census_tract = fake_tract,
                                  .package = "geobr")

  con <- .con_niveis_dw()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  r <- withCallingHandlers(
    incorporar_setores_censitarios(con = con, ufs = "11", ano = 2010),
    message = function(m) invokeRestart("muffleMessage"))

  expect_identical(r$escopo, "11")
  expect_identical(r$n_localidades, 2L)
  ids <- DBI::dbGetQuery(con, paste(
    "SELECT local_id, nivel_tipo FROM local",
    "WHERE geoloc_id IN (110020325020001, 110020325020002)"))
  expect_true(all(ids$local_id >= 100000L & ids$local_id <= 999999L))
  expect_identical(ids$nivel_tipo, c("setor", "setor"))

  carga <- DBI::dbGetQuery(con, paste(
    "SELECT nivel_tipo, fonte, escopo, ano, n_localidades FROM niveis_carga",
    "WHERE nivel_tipo = 'setor'"))
  expect_identical(nrow(carga), 1L)
  expect_identical(carga$fonte, "geobr/setores_censitarios")
  expect_identical(carga$escopo, "11")
  expect_identical(as.integer(carga$ano), 2010L)
  expect_identical(as.integer(carga$n_localidades), 2L)

  ## re-carga e idempotente: mesmos ids, upsert em niveis_carga
  r2 <- withCallingHandlers(
    incorporar_setores_censitarios(con = con, ufs = "11", ano = 2010),
    message = function(m) invokeRestart("muffleMessage"))
  expect_identical(r2$n_localidades, 2L)
  expect_identical(DBI::dbGetQuery(con, paste(
    "SELECT local_id FROM local WHERE geoloc_id IN",
    "(110020325020001, 110020325020002) ORDER BY local_id"))$local_id,
    ids$local_id[order(ids$local_id)])
  expect_identical(as.numeric(DBI::dbGetQuery(con, paste(
    "SELECT count(*) AS n FROM niveis_carga",
    "WHERE nivel_tipo = 'setor'"))$n), 1)
})

test_that("T6: incorporar_areas_ponderacao (geobr mockado) usa bloco AP", {
  skip_if(!nzchar(Sys.getenv("BEEP_TEST_DW")),
          "DW de teste local ausente (defina BEEP_TEST_DW)")
  skip_if(!requireNamespace("geobr", quietly = TRUE), "geobr ausente")
  .fixture_niveis_dw()

  malha <- sf::st_sf(
    code_weighting = "1100203250501",
    geometry = sf::st_as_sfc(
      "POLYGON((-63.3 -8.0, -63.2 -8.0, -63.2 -8.1, -63.3 -8.1, -63.3 -8.0))"),
    crs = 4326)
  fake_wa <- function(code_weighting, year, simplified, showProgress) malha
  testthat::local_mocked_bindings(read_weighting_area = fake_wa,
                                  .package = "geobr")

  con <- .con_niveis_dw()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  r <- withCallingHandlers(
    incorporar_areas_ponderacao(con = con, ufs = 11),
    message = function(m) invokeRestart("muffleMessage"))

  expect_identical(r$escopo, "11")
  expect_identical(r$n_localidades, 1L)
  ids <- DBI::dbGetQuery(con, paste(
    "SELECT local_id, nivel_tipo FROM local",
    "WHERE geoloc_id = 1100203250501"))
  expect_true(ids$local_id >= 2000000L & ids$local_id <= 2999999L)
  expect_identical(ids$nivel_tipo, "area_ponderacao")
  carga <- DBI::dbGetQuery(con, paste(
    "SELECT nivel_tipo, escopo, ano FROM niveis_carga",
    "WHERE nivel_tipo = 'area_ponderacao'"))
  expect_identical(nrow(carga), 1L)
  expect_identical(carga$escopo, "11")
  expect_identical(as.integer(carga$ano), 2010L)
})

test_that("T7: painel traduz codigos submunicipais e desenha irmaos do foco", {
  skip_if(!nzchar(Sys.getenv("BEEP_TEST_DW")),
          "DW de teste local ausente (defina BEEP_TEST_DW)")
  .fixture_niveis_dw()

  # municipios proprios do teste (1302603, 1400283): irmaos deterministicos
  # mesmo acumulando estado dos testes anteriores
  polis <- c(
    "POLYGON((-51.2 1.0, -51.1 1.0, -51.1 0.9, -51.2 0.9, -51.2 1.0))",
    "POLYGON((-51.1 1.0, -51.0 1.0, -51.0 0.9, -51.1 0.9, -51.1 1.0))",
    "POLYGON((-61.1 2.0, -61.0 2.0, -61.0 1.9, -61.1 1.9, -61.1 2.0))")
  setores <- sf::st_sf(
    code_tract = c("130260305020001", "130260305020002", "140028305020001"),
    geometry = sf::st_as_sfc(polis), crs = 4326)
  con <- .con_niveis_dw()
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  r <- ampliar_nivel_territorial(setores, "setor",
                                 col_codigo = "code_tract", con = con)
  r_dois <- r$local_id[r$codigo %in% c("130260305020001", "130260305020002")]

  ## aba Baixar: setor (15d) e municipio (7d) traduzidos pelo geoloc_id;
  ## PNAD (largura 7, bloco 5572..7087) segue mostrando o local_id
  cod <- beep:::painel_codigo_mun(con)
  expect_identical(unname(cod["1"]), "1100203")
  expect_setequal(unname(cod[as.character(r$local_id)]),
                  as.character(r$codigo))
  expect_false("5600" %in% names(cod))

  ## globo: irmaos do municipio em foco tesselam o nivel (mesma largura,
  ## mesmo prefixo 7d); municipio sem feicoes do nivel ou acima do teto
  ## volta vazio (degradacao)
  irmaos <- beep:::painel_geo_irmaos_mun(con, mun = "1302603", larg = 15)
  expect_setequal(as.integer(irmaos$code), r_dois)
  expect_true(all(grepl("^1302603", sf::st_drop_geometry(irmaos)$label)))
  expect_identical(nrow(beep:::painel_geo_irmaos_mun(
    con, mun = "1400283", larg = 15)), 1L)
  expect_identical(nrow(beep:::painel_geo_irmaos_mun(
    con, mun = "1302603", larg = 13)), 0L)
  expect_identical(nrow(beep:::painel_geo_irmaos_mun(
    con, mun = "1302603", larg = 15, max_feicoes = 1L)), 0L)
})

test_that("T8: incorporar_bairros dissolve setores e registra niveis_carga", {
  skip_if(!nzchar(Sys.getenv("BEEP_TEST_DW")),
          "DW de teste local ausente (defina BEEP_TEST_DW)")
  .fixture_niveis_dw()

  # municipio proprio do teste (3509502): bairros e irmaos deterministicos
  polis <- c(
    "POLYGON((-47.2 -23.6, -47.1 -23.6, -47.1 -23.7, -47.2 -23.7, -47.2 -23.6))",
    "POLYGON((-47.1 -23.6, -47.0 -23.6, -47.0 -23.7, -47.1 -23.7, -47.1 -23.6))",
    "POLYGON((-46.9 -23.6, -46.8 -23.6, -46.8 -23.7, -46.9 -23.7, -46.9 -23.6))")
  setores <- sf::st_sf(
    code_tract = c("350950205001001", "350950205001002", "350950205002001"),
    nm_bairro = c("Centro Teste", "Centro Teste", "Jardim Teste"),
    code_bairro = c("1", "1", "2"),
    geometry = sf::st_as_sfc(polis), crs = 4326)
  con <- .con_niveis_dw()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  r <- withCallingHandlers(
    incorporar_bairros(setores, con = con, ano = 2022),
    message = function(m) invokeRestart("muffleMessage"))

  expect_identical(r$escopo, "3509502")
  expect_identical(r$n_localidades, 2L)
  loc <- DBI::dbGetQuery(con, paste(
    "SELECT local_id, local_name, nivel_tipo FROM local",
    "WHERE geoloc_id IN (35095020001, 35095020002)",
    "ORDER BY geoloc_id"))
  expect_true(all(loc$local_id >= 1000000L & loc$local_id <= 1999999L))
  expect_identical(loc$nivel_tipo, c("bairro", "bairro"))
  expect_identical(loc$local_name, c("Centro Teste", "Jardim Teste"))

  # dissolve: o bairro 1 cobre as duas quadras contiguas (area ~2x)
  area <- as.numeric(DBI::dbGetQuery(con, paste(
    "SELECT ST_Area(geometry) AS a FROM geoloc",
    "WHERE geoloc_id = 35095020001"))$a)
  expect_true(area > 0.015)

  carga <- DBI::dbGetQuery(con, paste(
    "SELECT fonte, escopo, ano, n_localidades FROM niveis_carga",
    "WHERE nivel_tipo = 'bairro'"))
  expect_identical(nrow(carga), 1L)
  expect_identical(carga$fonte, "dissolve_setores")
  expect_identical(carga$escopo, "3509502")
  expect_identical(as.integer(carga$ano), 2022L)
  expect_identical(as.integer(carga$n_localidades), 2L)

  ## re-carga e idempotente: mesmos ids, upsert em niveis_carga, e o
  ## painel (F3) tesselam os bairros como irmaos do municipio em foco
  r2 <- withCallingHandlers(
    incorporar_bairros(setores, con = con, ano = 2022),
    message = function(m) invokeRestart("muffleMessage"))
  expect_identical(r2$n_localidades, 2L)
  expect_identical(DBI::dbGetQuery(con, paste(
    "SELECT local_id FROM local WHERE geoloc_id IN",
    "(35095020001, 35095020002) ORDER BY local_id"))$local_id,
    loc$local_id[order(loc$local_id)])
  expect_identical(as.numeric(DBI::dbGetQuery(con, paste(
    "SELECT count(*) AS n FROM niveis_carga",
    "WHERE nivel_tipo = 'bairro'"))$n), 1)
  expect_identical(nrow(beep:::painel_geo_irmaos_mun(
    con, mun = "3509502", larg = 11)), 2L)
})

