#' populate_initialdb — seeder territorial do DW beep
#'
#' Portado de pndr_dashboard/data-raw/populate_initialdb.R (o
#' primeiro seeder do ecossistema AEDi/beep) para preencher
#' `local`/`geoloc` e os grupos territoriais de um DW recem-criado
#' por `prepare_db()`, mantendo as convencoes que o ecossistema
#' consome: `local_id` 1..~5570 municipios, estratos PNAD na faixa
#' 5571..7087 (geoloc_id sintetico), micro/mesorregioes antigas
#' deslocadas para 8 digitos (10000000+), Brasil = max(local_id)+1.
#'
#' Carga: municipios, micror e mesorregioes (IBGE 1990), UFs,
#' macrorregioes, Brasil, regioes imediatas/intermediarias (2020),
#' estratos PNAD Contínua, e os grupos territoriais (Faixa de
#' Fronteira, Amazonia Legal, Semiarido, SUDENE, Tipologia PNDR
#' 2018, regioes, UF/Regiao) com `local_group`/`group_parent`.
#'
#' NAO carrega indicadores (mdata/data_values/mdata_exts):
#' esses vem dos pipelines de cada projeto.
#'
#' Uso: `data-raw/populate_initialdb.R | populate_initialdb()`
#' (requer conexao ao Postgres do DW e os pacotes Suggests
#' geobr/readODS/rvest (brazilmaps não é mais usado: a v1.0.0
#' quebrou API e o geobr cobre todos os níveis).
#'
#' @param con Conexao DBI aberta no DW alvo; se NULL, abre com as
#'   env vars padrao do beep (user/password/host/dbname).
#' @param dir_dadostat Diretorio com insumos opcionais do projeto
#'   (tipologia2018_ajustada.csv e manual do painel PNDR); so usado
#'   com `pndr_groups = TRUE`.
#' @param pndr_groups Criar os grupos de desenvolvimento regional
#'   (Tipologia PNDR 2018, Eixos/Objetivos)? Default FALSE - a view
#'   `recortes_geograficos` tolera a ausencia (colunas NA). Os
#'   recortes territoriais universais (Faixa de Fronteira, Amazonia
#'   Legal, Semiarido, SUDENE, regioes, UF/Regiao) sempre entram.
#' @param pnadc_inicio Primeiro `local_id` do bloco de estratos PNAD
#'   (default 5572: municípios da malha 2024 ocupam 1..5571).
#' @param limpar Truncar `local_group`/`local`/`geoloc` antes de
#'   popular (default TRUE - torna o seeder re-executavel).
#' @param dbtype "pgsql" (unico suportado; sqlite não tem PostGIS).
#' @export
populate_initialdb <- \(con = NULL, dbtype = "pgsql",
                        dir_dadostat = NULL, pndr_groups = FALSE,
                        pnadc_inicio = 5572L, limpar = TRUE) {
  stopifnot(dbtype == "pgsql")
  if (is.null(con)) {
    con <- DBI::dbConnect(RPostgres::Postgres(),
                          user = Sys.getenv("user", "beep"),
                          password = Sys.getenv("password", "aEd1#man@gR"),
                          host = Sys.getenv("host", "127.0.0.1"),
                          dbname = Sys.getenv("dbname", "beepdb"))
  }

  if (isTRUE(limpar)) {
    DBI::dbExecute(con, "DELETE FROM local_group")
    DBI::dbExecute(con, "DELETE FROM local")
    DBI::dbExecute(con, "DELETE FROM geoloc")
  }

  ## retries: o CDN do IPEA devolve 0 bytes esporadicamente apos
  ## downloads grandes (cache corrompido -> leitura NULL)
  ler_geobr_seguro <- function(leitor, ...) {
    ## backoff crescente: o CDN do IPEA limita IP sob sequencias de
    ## downloads grandes; 0 bytes/cache corrompido conta como falha
    esperas <- c(5, 15, 45, 90)
    for (tent in seq_along(esperas)) {
      d <- tryCatch(leitor(...), error = \(e) NULL)
      if (!is.null(d) && nrow(d) > 0) return(d)
      if (tent < length(esperas)) Sys.sleep(esperas[tent])
    }
    NULL
  }

  ## pre-aquece o cache do geobr: download_gpkg grava no tempdir da
  ## sessao; o CDN do IPEA devolve 0 bytes sob carga, entao baixamos
  ## via httr2 (com retry/backoff) para o caminho que o geobr espera
  aquecer_gpkg <- function(geo, year, simplified = TRUE) {
    md <- tryCatch(geobr:::download_metadata(), error = \(e) return(invisible(NULL)))
    linha <- md[md$geo == geo & md$year == year, ]
    if (!nrow(linha)) return(invisible(NULL))
    urlgp <- linha$download_path[1]
    if (isTRUE(simplified) && any(grepl("_simplified", linha$download_path,
                                        fixed = TRUE))) {
      urlgp <- linha$download_path[grepl("_simplified", linha$download_path,
                                         fixed = TRUE)][1]
    }
    dest <- fs::path(fs::path_temp(), basename(urlgp))
    if (file.exists(dest) && file.size(dest) > 0) return(invisible(NULL))
    tryCatch({
      httr2::request(urlgp) |>
        httr2::req_retry(max_tries = 3, backoff = \(t) 5 * 2^(t - 1)) |>
        httr2::req_perform(path = dest)
      cat("cache geobr pre-aquecido:", basename(urlgp), "\n")
    }, error = \(e) warning("pre-aquecimento falhou (", basename(urlgp),
                            "): ", conditionMessage(e)))
    invisible(NULL)
  }
  aquecer_gpkg("municipality", 2024, simplified = TRUE)
  aquecer_gpkg("state", 2020, simplified = TRUE)
  aquecer_gpkg("micro_region", 2019, simplified = TRUE)
  aquecer_gpkg("meso_region", 2019, simplified = TRUE)
  aquecer_gpkg("immediate_regions", 2020, simplified = TRUE)
  aquecer_gpkg("intermediate_regions", 2020, simplified = TRUE)
  aquecer_gpkg("semiarid", 2022, simplified = TRUE)
  aquecer_gpkg("amazonia_legal", 2012, simplified = TRUE)

  ## cargas geobr (mantido ativamente pelo ipea) - usadas pelo
  ## retwritegeo e pelos vinculos territoriais adiante
  geobrcities <- ler_geobr_seguro(geobr::read_municipality,
                                  year = 2024, simplified = TRUE)
  if (is.null(geobrcities)) stop("malha municipal 2024 indisponivel")
  geobrimmediater <- ler_geobr_seguro(geobr::read_immediate_region,
                                      year = 2020, simplified = TRUE)
  geobrintermr <- ler_geobr_seguro(geobr::read_intermediate_region,
                                   year = 2020)
  geobrstates <- ler_geobr_seguro(geobr::read_state, year = 2020)
  if (is.null(geobrstates)) stop("malha de UFs indisponivel")
  ## cargas opcionais (recortes): falha de download nao aborta o
  ## seeder — o bloco correspondente e pulado com aviso e a matview
  ## recortes_geograficos nasce sem a coluna
  geobrsemiarid <- ler_geobr_seguro(geobr::read_semiarid, year = 2022)
  geobramazonia_legal <- ler_geobr_seguro(geobr::read_amazon, year = 2012)
  cat("LOADS: cities=", !is.null(geobrcities), " states=", !is.null(geobrstates),
      " semiarid=", !is.null(geobrsemiarid), "\n")
  if (is.null(geobrsemiarid)) warning("semiarido indisponivel - recorte nao criado")
  if (is.null(geobramazonia_legal)) warning("amazonia legal indisponivel - recorte nao criado")

  ## niveles -> leitor geobr + colunas de codigo/nome
  espec_retwritegeo <- list(
    City        = list(dados = function() geobrcities,
                       code = "code_muni", nome = "name_muni"),
    MicroRegion = list(dados = function() geobr::read_micro_region(year = 2019, simplified = TRUE),
                       code = "code_micro", nome = "name_micro"),
    MesoRegion  = list(dados = function() geobr::read_meso_region(year = 2019, simplified = TRUE),
                       code = "code_meso", nome = "name_meso"),
    State       = list(dados = function() geobrstates,
                       code = "code_state", nome = "name_state"),
    Region      = list(dados = function() geobr::read_region(year = 2020),
                       code = "code_region", nome = "name_region"))

  ## buffer em metros: CRS geografico exige projecao metrica
  ## (o original bufferizava 500 GRAUS em SIRGAS 2000)
  buffer_metrico <- \(geom, metros) {
    sf::st_transform(
      sf::st_buffer(sf::st_transform(geom, 5880), metros),
      crs = "+proj=longlat +datum=WGS84 +no_defs")
  }

  retwritegeo <- \(levelgeo = "City") {
    cat("populate: lendo", levelgeo, "\n")
    geoloc <- if (levelgeo == "Brazil") {
      # read_country so traz a geometria: id/nome manuais, como no
      # seeder original (geoloc_id = MAX(local_id)+1, fora das faixas
      # de width dos demais niveis)
      geom_pais <- ler_geobr_seguro(geobr::read_country,
                                    year = 2019, simplified = TRUE)
      sf::st_sf(
        geoloc_id = 1 + as.numeric(DBI::dbGetQuery(con, "select MAX(local_id) from local")),
        nome = "Brasil", geometry = sf::st_geometry(geom_pais))
    } else {
      esp <- espec_retwritegeo[[levelgeo]]
      stopifnot(!is.null(esp), !is.null(esp$dados))
      d <- ler_geobr_seguro(esp$dados)
      cat("RW-DBG:", levelgeo, "| d nrow:", tryCatch(nrow(d), error = \(e) -1),
          "| geobrstates nrow:", tryCatch(nrow(geobrstates), error = \(e) -1), "\n")
      stopifnot(!is.null(d))
      sf::st_sf(
        geoloc_id = as.numeric(d[[esp$code]]),
        nome = as.character(d[[esp$nome]]),
        geometry = sf::st_geometry(d)) |>
        dplyr::arrange(geoloc_id)
    }
    geoloc <- sf::st_transform(geoloc, crs = "+proj=longlat +datum=WGS84 +no_defs")
    local <- geoloc |>
      dplyr::select(geoloc_id, local_name = nome) |>
      dplyr::mutate(across(local_name, stringr::str_to_title),
                    across(local_name, \(x) gsub(" D([^ ]+) ", " d\\1 ", x))) |>
      sf::st_drop_geometry()
    geoloc <- geoloc |> dplyr::select(geoloc_id, geometry)

    sf::st_write(geoloc, con, append = TRUE)
    if (levelgeo == "Brazil") {
      DBI::dbAppendTable(con, "local", cbind(local_id = local$geoloc_id, local))
    } else {
      DBI::dbAppendTable(con, "local", local)
    }
  }

  ## 1) Municipios, micro e mesorregioes (IBGE 1990) ---------------
  retwritegeo()
  retwritegeo("MicroRegion")
  retwritegeo("MesoRegion")

  ## micro/meso (4 digitos) entram como 8 digitos para nao
  ## colidir com codigos de setor censitario 2010 (8 digitos)
  DBI::dbExecute(con, "BEGIN TRANSACTION")
  DBI::dbExecute(con, "ALTER TABLE local DROP CONSTRAINT fk_geoloc_geoloc_id;")
  DBI::dbExecute(con, "UPDATE geoloc SET geoloc_id=10000000+geoloc_id WHERE geoloc_id>1000 AND geoloc_id<10000;")
  DBI::dbExecute(con, "UPDATE local SET geoloc_id=10000000+geoloc_id WHERE geoloc_id>1000 AND geoloc_id<10000;")
  DBI::dbExecute(con, "ALTER TABLE local ADD CONSTRAINT fk_geoloc_geoloc_id
                   FOREIGN KEY (geoloc_id) REFERENCES geoloc(geoloc_id);")
  DBI::dbExecute(con, "END TRANSACTION")
  ## mapa codigo IBGE (7d) -> local_id (nesta altura, so municipios)
  mapa_mun <- DBI::dbGetQuery(con, paste(
    "SELECT local_id, geoloc_id::bigint AS code_muni FROM local",
    "WHERE length(geoloc_id::text) = 7"))

  ## 2) UF e macrorregiao -------------------------------------------
  retwritegeo("State")
  retwritegeo("Region")

  ## 4) Regioes imediatas/intermediarias (geobr 2020) ----------------
  ## SUDENE (ODS do geoftp IBGE)
  ibgesudene <- tryCatch({
    tmp_file_sudene <- tempfile(fileext = ".ods")
    download.file("http://geoftp.ibge.gov.br/organizacao_do_territorio/estrutura_territorial/area_atuacao_SUDENE/2021/SUDENE_2021.ods",
                  tmp_file_sudene)
    readODS::read_ods(tmp_file_sudene)$CD_MUN
  }, error = \(e) { warning("SUDENE indisponivel: ", conditionMessage(e)); NULL })

  ## Faixa de Fronteira (shapefile do geoftp IBGE)
  ffront <- tryCatch({
    dir.create('/tmp/ffront', showWarnings = FALSE)
    f <- "/tmp/ffront/ffront.zip"
    download.file("https://geoftp.ibge.gov.br/organizacao_do_territorio/estrutura_territorial/municipios_da_faixa_de_fronteira/2022/Sedes_Municipios_Faixa_de_Fronteira_Cidades_Gemeas_2022_shp.zip", f)
    utils::unzip(f, exdir = "/tmp/ffront", overwrite = TRUE)
    sf::st_transform(sf::read_sf("/tmp/ffront/Sedes_Municipios_Faixa_de_Fronteira_Cidades_Gemeas_2022.shp"),
                     crs = "+proj=longlat +datum=WGS84 +no_defs")
  }, error = \(e) { warning("faixa de fronteira indisponivel: ", conditionMessage(e)); NULL })

  ## associacao municipio x regioes (buffer de 500 m para casar bordas)
  juntaspa <- sf::st_join(
    geobrcities,
    buffer_metrico(geobrimmediater |>
                     dplyr::select(dplyr::contains("immediate")), 500),
    join = sf::st_within)
  juntaspa <- sf::st_join(
    juntaspa,
    buffer_metrico(geobrintermr |>
                     dplyr::select(dplyr::contains("intermediate")), 500),
    join = sf::st_within)
  juntaspa <- sf::st_transform(juntaspa, crs = "+proj=longlat +datum=WGS84 +no_defs")

  ## 3) Estratos PNAD Contínua ---------------------------------------
  ## codigo sintetico = cod_estrato + UF + regiao (2+1 primeiros digitos)
  pnadcem <- tempfile(fileext = ".csv")
  download.file("https://painel.ibge.gov.br/saibamais/files/Municipios_por_Estratos.csv",
                pnadcem)
  extratosmun <- readr::read_csv2(pnadcem)
  extratosmun <- geobrcities |>
    dplyr::left_join(extratosmun, by = c("code_muni" = "Código do Município"))
  extrlocs <- extratosmun |>
    dplyr::mutate(codmun = paste0(`Código do estrato`,
                                  substr(`Código do estrato`, 1, 2),
                                  substr(`Código do estrato`, 1, 1))) |>
    dplyr::group_by(codmun, `Nome abreviado do estrato`) |>
    dplyr::summarise() |> dplyr::ungroup()

  newloce <- max(DBI::dbGetQuery(con, "SELECT MAX(local_id) FROM local;")$max,
                 pnadc_inicio - 1L, na.rm = TRUE)

  geoloc <- extrlocs |>
    dplyr::select(geoloc_id = codmun, geometry = geom) |>
    sf::st_transform(crs = "+proj=longlat +datum=WGS84 +no_defs")
  sf::st_write(geoloc, con, append = TRUE)

  locale <- extrlocs |> sf::st_drop_geometry() |>
    dplyr::mutate(local_id = (newloce + 1):(newloce + nrow(extrlocs))) |>
    dplyr::select(local_id, geoloc_id = codmun,
                  local_name = `Nome abreviado do estrato`)
  DBI::dbAppendTable(con, "local", locale)

  geoloc <- geobrintermr |>
    dplyr::select(geoloc_id = code_intermediate, geometry = geom) |>
    sf::st_transform(crs = "+proj=longlat +datum=WGS84 +no_defs")
  sf::st_write(geoloc, con, append = TRUE)

  geoloc <- geobrimmediater |>
    dplyr::select(geoloc_id = code_immediate, geometry = geom) |>
    sf::st_transform(crs = "+proj=longlat +datum=WGS84 +no_defs")
  sf::st_write(geoloc, con, append = TRUE)

  newloc <- DBI::dbGetQuery(con, "SELECT MAX(local_id) FROM local;")$max

  local <- geobrintermr |> sf::st_drop_geometry() |>
    dplyr::mutate(local_id = (newloc + 1):(newloc + nrow(geobrintermr))) |>
    dplyr::select(local_id, geoloc_id = code_intermediate,
                  local_name = name_intermediate)
  DBI::dbAppendTable(con, "local", local)

  local <- geobrimmediater |> sf::st_drop_geometry() |>
    dplyr::mutate(local_id = (newloc + nrow(geobrintermr) + 1):
                    (newloc + nrow(geobrintermr) + nrow(geobrimmediater))) |>
    dplyr::select(local_id, geoloc_id = code_immediate,
                  local_name = name_immediate)
  DBI::dbAppendTable(con, "local", local)


  ## 5) Brasil --------------------------------------------------------
  retwritegeo("Brazil")

  ## 6) Grupos territoriais -------------------------------------------
  tip2018 <- NULL
  manualhtml <- NULL
  if (pndr_groups && !is.null(dir_dadostat) && dir.exists(dir_dadostat)) {
    tippath <- file.path(dir_dadostat, "tipologia2018_ajustada.csv")
    if (file.exists(tippath)) tip2018 <- readr::read_csv(tippath)
    manualpath <- file.path(dir_dadostat,
        "Painel de Indicadores", "Cálculo Painel de Indicadores",
        "Manual_Painel.html")
    if (file.exists(manualpath)) manualhtml <- rvest::read_html(manualpath)
  }

  ## Eixos/Objetivos/Tipologia PNDR: apenas com pndr_groups=TRUE
  get_datagroup <- \(pathx, grpbn, delimi) {
    grupo <- gsub("\r\n", " ", rvest::html_elements(manualhtml, xpath = pathx) |>
                    rvest::html_text())
    grupo <- grupo |> tibble::as_tibble() |>
      tidyr::separate_wider_delim(value, names = c("datagroup_id", "datagroup_desc"),
                                  delim = delimi)
    grupo$datagroup_id <- as.numeric(gsub("[^\\d]* ", "", grupo$datagroup_id))
    grupo$datagroup_name <- paste(grpbn, grupo$datagroup_id)
    grupo
  }

  grupos <- NULL
  if (pndr_groups && !is.null(manualhtml)) {
    grupos <- get_datagroup()
    grupos <- rbind(grupos, data.frame(
      datagroup_id = 8,
      datagroup_desc = "Indicadores de desenvolvimento por estratos da PNAD(não municipais)",
      datagroup_name = "Estratos PNAD"))
    pathxobj <- "//*[@id='objetivos']/ul/li"
    grupos <- dplyr::bind_rows(grupos,
      get_datagroup(pathxobj, grpbn = "Objetivo", delimi = ": ") |>
        dplyr::mutate(datagroup_id = max(grupos$datagroup_id) + datagroup_id))
    grupos <- dplyr::bind_rows(grupos, data.frame(
      datagroup_id = nrow(grupos) + 1:2,
      datagroup_name = c("Eixos", "Objetivos"),
      datagroup_desc = c("Eixos da PNDR", "Objetivos da PNDR")))
    DBI::dbAppendTable(con, "datagroup", grupos)
  } else {
    warning("populate_initialdb: manual do painel PNDR ausente (dir_dadostat) - ",
            "grupos Eixos/Objetivos nao criados")
  }

  ## Tipologia PNDR 2018 (apenas com pndr_groups=TRUE)
  dgidtipologia <- NULL
  localg <- NULL
  if (pndr_groups) {
    dgidtipologia <- DBI::dbGetQuery(con, "SELECT MAX(datagroup_id) FROM datagroup;")$max + 1
    DBI::dbAppendTable(con, "datagroup", data.frame(
      datagroup_id = dgidtipologia, datagroup_name = "Tipologia PNDR 2018",
      datagroup_desc = "Tipologia Sub-regional da Política Nacional de\nDesenvolvimento Regional (PNDR)"))

    if (!is.null(tip2018)) {
      localgroups <- unique(tip2018$`TIPOLOGIA SUB REGIONAL`)
      localgroups <- localgroups[c(5, 6, 7, 3, 1, 2, 8, 4, 9)]
      localg <- data.frame(
        datagroup_id = (dgidtipologia + 1):(dgidtipologia + length(localgroups)),
        datagroup_name = localgroups,
        datagroup_desc = paste(localgroups, "na Tipologia da PNDR - 2018"))
      DBI::dbAppendTable(con, "datagroup", localg)
    } else {
      warning("populate_initialdb: tipologia2018_ajustada.csv ausente - ",
              "subgrupos e vinculos da Tipologia nao criados")
    }
  }

  if (!is.null(ffront)) {
  ## Faixa de Fronteira
    ## Faixa de Fronteira
    maxgrpid <- DBI::dbGetQuery(con, "SELECT MAX(datagroup_id) FROM datagroup;")$max + 1
    DBI::dbAppendTable(con, "datagroup", data.frame(
      datagroup_id = maxgrpid:(maxgrpid + 2),
      datagroup_name = c("Faixa de Fronteira", "em faixa de fronteira",
                         "fora da faixa de fronteira"),
      datagroup_desc = c("Situação Quanto à Faixa de Fronteira",
                         "Município/Área em Faixa de Fronteira",
                         "Município/Área Fora da Faixa de Fronteira")))
    ffrontcdm <- (ffront |> sf::st_drop_geometry())$CD_MUN
    dgidff <- DBI::dbGetQuery(con, "SELECT datagroup_id from datagroup where datagroup_name LIKE '%em faixa%'")$datagroup_id
    local_group_ff <- geobrcities |> sf::st_drop_geometry() |>
      dplyr::left_join(mapa_mun, by = "code_muni") |>
      dplyr::transmute(local_id,
                       datagroup_id = dplyr::case_when(
                         code_muni %in% ffrontcdm ~ dgidff, TRUE ~ dgidff + 1)) |>
      dplyr::filter(!is.na(local_id))
    DBI::dbAppendTable(con, "local_group", local_group_ff)
    DBI::dbAppendTable(con, "group_parent", data.frame(
      datagroup_id = dgidff,
      datagroup_parentid = DBI::dbGetQuery(con, "SELECT datagroup_id from datagroup WHERE datagroup_name = 'Faixa de Fronteira'")$datagroup_id))
  } else warning("faixa de fronteira indisponivel - recorte nao criado")

  if (!is.null(geobramazonia_legal)) {
  ## Amazonia Legal
    ## Amazonia Legal
    maxgrpid <- DBI::dbGetQuery(con, "SELECT MAX(datagroup_id) FROM datagroup;")$max + 1
    DBI::dbAppendTable(con, "datagroup", data.frame(
      datagroup_id = maxgrpid:(maxgrpid + 2),
      datagroup_name = c("Participacação na Amazônia Legal",
                         "faz parte da Amazônia Legal",
                         "não faz parte da Amazônia Legal"),
      datagroup_desc = c("Participacação na Amazônia Legal",
                         "Município/Área faz parte da Amazônia Legal",
                         "Município/Área não faz parte da Amazônia Legal")))
    amlegalcm <- sf::st_within(geobrcities,
                             buffer_metrico(geobramazonia_legal, 500),
                             sparse = FALSE)
    dgidal <- DBI::dbGetQuery(con, "SELECT datagroup_id from datagroup where datagroup_name LIKE '%faz parte da Amaz%'")$datagroup_id
    local_group_al <- geobrcities |> sf::st_drop_geometry() |>
      dplyr::mutate(amzlegal = as.logical(amlegalcm)) |>
      dplyr::left_join(mapa_mun, by = "code_muni") |>
      dplyr::transmute(local_id,
                       datagroup_id = dplyr::case_when(
                         amzlegal ~ dgidal[1], TRUE ~ dgidal[2])) |>
      dplyr::filter(!is.na(local_id))
    DBI::dbAppendTable(con, "local_group", local_group_al)
    DBI::dbAppendTable(con, "group_parent", data.frame(
      datagroup_id = dgidal,
      datagroup_parentid = DBI::dbGetQuery(con, "SELECT datagroup_id from datagroup WHERE datagroup_name LIKE '%o na Amaz%'")$datagroup_id))
  } else warning("amazonia legal indisponivel - recorte nao criado")

  if (!is.null(geobrsemiarid)) {
  ## Semiarido
    ## Semiarido
    maxgrpid <- DBI::dbGetQuery(con, "SELECT MAX(datagroup_id) FROM datagroup;")$max + 1
    DBI::dbAppendTable(con, "datagroup", data.frame(
      datagroup_id = maxgrpid:(maxgrpid + 2),
      datagroup_name = c("Participação no Semiárido", "no Semiárido", "Fora do Semiárido"),
      datagroup_desc = c("Participação no Semiárido para Fins de Políticas Públicas",
                         "Município/Zona no Semiárido",
                         "Município/Zona Fora do Semiárido")))
    semiacn <- (geobrsemiarid |> sf::st_drop_geometry())$code_muni
    dgidsa <- DBI::dbGetQuery(con, "SELECT regexp_matches(datagroup_name,'(([^o] )|^)[dn]o Semi'), datagroup_id from datagroup")$datagroup_id
    DBI::dbAppendTable(con, "group_parent", data.frame(
      datagroup_id = dgidsa,
      datagroup_parentid = DBI::dbGetQuery(con, "SELECT datagroup_id from datagroup WHERE datagroup_name = 'Participação no Semiárido'")$datagroup_id))
    local_group_sa <- geobrcities |> sf::st_drop_geometry() |>
      dplyr::left_join(mapa_mun, by = "code_muni") |>
      dplyr::transmute(local_id,
                       datagroup_id = dplyr::case_when(
                         code_muni %in% semiacn ~ dgidsa[1], TRUE ~ dgidsa[2])) |>
      dplyr::filter(!is.na(local_id))
    DBI::dbAppendTable(con, "local_group", local_group_sa)
  } else warning("semiarido indisponivel - recorte nao criado")

  if (!is.null(ibgesudene)) {
  ## SUDENE
    ## SUDENE
    maxgrpid <- DBI::dbGetQuery(con, "SELECT MAX(datagroup_id) FROM datagroup;")$max + 1
    DBI::dbAppendTable(con, "datagroup", data.frame(
      datagroup_id = maxgrpid:(maxgrpid + 2),
      datagroup_name = c("Participação na SUDENE", "na SUDENE", "Fora da SUDENE"),
      datagroup_desc = c("Participação na SUDENE para Fins de Políticas Públicas",
                         "Município/Zona na SUDENE",
                         "Município/Zona Fora da SUDENE")))
    dgidsudene <- DBI::dbGetQuery(con, "SELECT regexp_matches(datagroup_name,'(([^o] )|^)[dn]a SUDENE'), datagroup_id from datagroup")$datagroup_id
    DBI::dbAppendTable(con, "group_parent", data.frame(
      datagroup_id = dgidsudene,
      datagroup_parentid = DBI::dbGetQuery(con, "SELECT datagroup_id from datagroup WHERE datagroup_name = 'Participação na SUDENE'")$datagroup_id))
    local_group_sudene <- geobrcities |> sf::st_drop_geometry() |>
      dplyr::left_join(mapa_mun, by = "code_muni") |>
      dplyr::transmute(local_id,
                       datagroup_id = dplyr::case_when(
                         code_muni %in% ibgesudene ~ dgidsudene[1], TRUE ~ dgidsudene[2])) |>
      dplyr::filter(!is.na(local_id))
    DBI::dbAppendTable(con, "local_group", local_group_sudene)
  } else warning("SUDENE indisponivel - recorte nao criado")


  ## Regioes Imediatas/Intermediarias + UF + Regiao
  dgidmax <- DBI::dbGetQuery(con, "SELECT MAX(datagroup_id) from datagroup;")$max + 1
  DBI::dbAppendTable(con, "datagroup", data.frame(
    datagroup_id = dgidmax:(dgidmax + 1),
    datagroup_name = c("Regiões Imediatas - IBGE 2020", "Regiões Intermediárias - IBGE 2020"),
    datagroup_desc = c("Regiões Imediatas - IBGE 2020", "Regiões Intermediárias - IBGE 2020")))
  DBI::dbAppendTable(con, "datagroup", data.frame(
    datagroup_id = (dgidmax + 2):(dgidmax + 3),
    datagroup_name = c("UF", "Região"),
    datagroup_desc = c("Unidades Federativas", "Macrorregião brasileira")))

  imrdrop <- geobrimmediater |> sf::st_drop_geometry()
  prim <- dgidmax + 4
  imreg <- data.frame(
    datagroup_id = prim:(prim - 1 + nrow(imrdrop)),
    datagroup_name = imrdrop$name_immediate,
    datagroup_desc = paste0("Região Imediata de ", imrdrop$name_immediate, ", ",
                            imrdrop$name_state))
  DBI::dbAppendTable(con, "datagroup", imreg)

  inrdrop <- geobrintermr |> sf::st_drop_geometry()
  prin <- prim + nrow(imrdrop)
  inreg <- data.frame(
    datagroup_id = prin:(prin - 1 + nrow(inrdrop)),
    datagroup_name = inrdrop$name_intermediate,
    datagroup_desc = paste0("Região Intermediária de ", inrdrop$name_intermediate,
                            ", ", inrdrop$name_state))
  DBI::dbAppendTable(con, "datagroup", inreg)

  ## vinculos municipio -> regiao imediata/intermediaria
  tabmunesp <- juntaspa |> sf::st_drop_geometry()
  harmoniza_im <- data.frame(datagroup_id = prim:(prim - 1 + nrow(imrdrop)),
                             geoloc_id = imrdrop$code_immediate)
  harmoniza_in <- data.frame(datagroup_idin = prin:(prin - 1 + nrow(inrdrop)),
                             geoloc_id = inrdrop$code_intermediate)
  tabmunesp <- tabmunesp |>
    dplyr::left_join(harmoniza_im, by = c("code_immediate" = "geoloc_id")) |>
    dplyr::left_join(harmoniza_in, by = c("code_intermediate" = "geoloc_id"))

  local <- DBI::dbGetQuery(con, "SELECT * from local;")
  # municipios: geoloc 7 digitos, fora da faixa PNAD (hack: intermediaria
  # tambem tem 7 digitos no IBGE)
  localmun <- (local |> dplyr::filter(nchar(geoloc_id) == 7,
                                      local_id < 5580 | local_id > 7086))$local_id
  DBI::dbAppendTable(con, "local_group", data.frame(
    local_id = localmun, datagroup_id = tabmunesp$datagroup_id))
  DBI::dbAppendTable(con, "local_group", data.frame(
    local_id = localmun, datagroup_id = tabmunesp$datagroup_idin))

  DBI::dbAppendTable(con, "group_parent", data.frame(
    datagroup_id = imreg$datagroup_id,
    datagroup_parentid = DBI::dbGetQuery(con, "SELECT datagroup_id from datagroup WHERE datagroup_name = 'Regiões Imediatas - IBGE 2020'")$datagroup_id))
  DBI::dbAppendTable(con, "group_parent", data.frame(
    datagroup_id = inreg$datagroup_id,
    datagroup_parentid = DBI::dbGetQuery(con, "SELECT datagroup_id from datagroup WHERE datagroup_name = 'Regiões Intermediárias - IBGE 2020'")$datagroup_id))

  ## Eixos/Objetivos -> pais e vinculos da Tipologia (pndr_groups)
  pgroups <- data.table::rbindlist(list())
  if (pndr_groups) {
    if (!is.null(manualhtml)) {
      pgeo <- \(pgroup = "Eixo") {
        data.frame(
          datagroup_id = grupos[grepl(paste0(pgroup, " "), grupos$datagroup_name), ]$datagroup_id,
          datagroup_parentid = grupos[grepl(paste0(pgroup, "s"), grupos$datagroup_name), ]$datagroup_id)
      }
      pgroups <- data.table::rbindlist(lapply(c("Eixo", "Objetivo"), pgeo))
    }
    if (!is.null(localg)) {
      pgroups <- dplyr::bind_rows(pgroups, data.frame(
        datagroup_id = (dgidtipologia + 1):(dgidtipologia + nrow(localg)),
        datagroup_parentid = dgidtipologia))
    }
  }
  if (nrow(pgroups)) DBI::dbAppendTable(con, "group_parent", pgroups)

  ## Vinculos da Tipologia por municipio
  if (pndr_groups && !is.null(tip2018)) {
    locids <- DBI::dbGetQuery(con, "SELECT local_id,geoloc_id from local WHERE local_id < 5572")
    tip2018 <- tip2018 |> dplyr::left_join(locids, by = c("code_muni" = "geoloc_id"))
    lcgroup <- tip2018 |>
      dplyr::left_join(localg, by = c("TIPOLOGIA SUB REGIONAL" = "datagroup_name")) |>
      dplyr::select(local_id, datagroup_id)
    DBI::dbAppendTable(con, "local_group", lcgroup)
  }

  ## 7) Matviews territoriais em dia apos a carga ----------------
  ## recortes_geograficos depende de local/geoloc/grupos - agora
  ## preenchidos; named/geonamed so existem se prepare_db rodou
  ## com geo=TRUE (default)
  tryCatch({
    criar_recortes_geograficos(con = con)
    DBI::dbExecute(con, "refresh materialized view named_datavalues;")
    DBI::dbExecute(con, "refresh materialized view geonamed_datavalues;")
  }, error = \(e) warning("populate_initialdb: matviews nao atualizados (",
                          conditionMessage(e), ") - rode com geo=TRUE ",
                          "no prepare_db ou crie-os manualmente"))

  invisible(TRUE)
}
