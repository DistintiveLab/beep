# Ponte secao eleitoral (TSE) <-> nivel submunicipal do DW (roadmap F5/P3)
#
# Tabela de harmonizacao permanente `tse_secao_bairro` no DW: uma linha por
# (ano, uf, nivel_tipo, municipio TSE, zona, secao), atribuindo a cada secao
# de votacao uma localidade submunicipal (bairro, subdistrito/RA ou setor
# censitario). PREMISSAS E LIMITES (coerentes com R/tse_auxiliares.R):
#
# 1. Secao eleitoral e recortes do IBGE sao INDEPENDENTES; nao existe
#    equivalencia oficial. A ponte principal (metodo "ponto") usa as
#    coordenadas oficiais do local de votacao publicadas no
#    eleitorado_local_votacao e o vizinho mais proximo (KNN PostGIS) no
#    nivel pedido, aceito so se dentro de `raio_m` metros.
# 2. O metodo "nome" (fallback, so para nivel bairro e com mapa de
#    municipios) casa o bairro declarado pelo TSE com o bairro do DW por
#    (municipio, nome normalizado) — reusa tse_mapa_secao_bairro() e
#    tse_casar_bairros(); o que nao casa fica sem atribuicao.
# 3. Secao cujos pontos casam com MAIS de uma localidade distinta do nivel
#    fica SEM atribuicao com metodo "conflito" (campos NULL): nenhuma
#    inferencia por maioria. Conflito tem prioridade sobre ponto e nome.
# 4. Grava-se linha para TODA secao do arquivo, atribuida ou nao: o cruzamento
#    e auditavel — cobertura e conflitos ficam explicitos na propria tabela.
# 5. A carga e idempotente por (ano, uf, nivel_tipo): reprocessar um trecho
#    apaga e regrava so aquele trecho, sem tocar outros niveis.
#
# A ponte alimenta tse_detalhe_secao(): o detalhe da votacao por secao
# (aptos/comparecimento/abstencoes/nulos/brancos) agregado ao nivel
# harmonizado, com a mesma semantica de agregacao do
# tsebr::tse_detalhe_municipio() para manter comparabilidade com as series
# municipais do DW.

#' Garante a tabela de harmonizacao secao x nivel submunicipal no DW
#' (idempotente) e o indice GiST de geometria usado pelo KNN.
#' @noRd
garantir_tabela_harmonizacao_secao <- function(con = NULL) {
  fechar <- is.null(con)
  if (fechar) {
    con <- DBI::dbConnect(
      RPostgres::Postgres(),
      user = Sys.getenv("user", "beep"),
      password = Sys.getenv("password", "aEd1#man@gR"),
      host = Sys.getenv("host", "127.0.0.1"),
      dbname = Sys.getenv("dbname", "beepdb"))
  }
  on.exit(if (fechar) DBI::dbDisconnect(con), add = TRUE)
  DBI::dbExecute(con, paste(
    "CREATE TABLE IF NOT EXISTS tse_secao_bairro (",
    "ano INT NOT NULL,",
    "uf TEXT NOT NULL,",
    "nivel_tipo TEXT NOT NULL,",
    "cod_municipio_tse TEXT NOT NULL,",
    "municipio TEXT,",
    "zona TEXT NOT NULL,",
    "secao TEXT NOT NULL,",
    "bairro_local_id INT,",
    "bairro_codigo TEXT,",
    "bairro_nome TEXT,",
    "metodo TEXT,",
    "PRIMARY KEY (ano, uf, nivel_tipo, cod_municipio_tse, zona, secao))"))
  DBI::dbExecute(con, paste(
    "COMMENT ON TABLE tse_secao_bairro IS",
    "'Harmonizacao secao eleitoral (TSE) x nivel submunicipal do DW;",
    "metodo: ponto (KNN no local de votacao), nome (bairro declarado,",
    "so nivel bairro), conflito (multiplos vizinhos, sem atribuicao),",
    "NULL (sem atribuicao). Regravadavel por (ano, uf, nivel_tipo).'"))
  DBI::dbExecute(con, paste(
    "CREATE INDEX IF NOT EXISTS geoloc_geometry_gist",
    "ON geoloc USING gist (geometry)"))
  invisible(TRUE)
}

#' Extrai colunas de coordenada do data.frame de locais de votacao
#' (auto-deteccao lat/lon, decimais com virgula toleradas)
#' @keywords internal
.tse_coords_locais <- function(locais) {
  col_lat <- grep("^lat(itude)?$", names(locais), ignore.case = TRUE,
                  value = TRUE)[1]
  col_lon <- grep("^lon(g)?$", names(locais), ignore.case = TRUE,
                  value = TRUE)[1]
  if (is.na(col_lat) || is.na(col_lon)) {
    stop("tse: colunas de coordenada nao encontradas em locais ",
         "(esperado 'lat'/'lon')")
  }
  num <- function(x) {
    x <- trimws(as.character(x))
    x[x %in% c("", "-1", "NA")] <- NA_character_
    as.numeric(sub(",", ".", x, fixed = TRUE))
  }
  list(lat = num(locais[[col_lat]]), lon = num(locais[[col_lon]]))
}

#' Converte os locais de votacao em pontos espaciais (sf POINT, EPSG:4326)
#'
#' Filtra linhas sem coordenada util (NA/0) ou fora do bounding box do
#' Brasil. Serve para inspecao e mapas; [tse_harmonizar_secoes()] aceita
#' tanto a saida desta funcao quanto o data.frame bruto.
#'
#' @param locais data.frame de saida de
#'   `tsebr::tse_locais_votacao()` (ou equivalente com `lat`/`lon`).
#' @return objeto `sf` de POINT com as colunas originais e `lat`/`lon`.
#' @export
tse_pontuar_locais_votacao <- function(locais) {
  coords <- .tse_coords_locais(locais)
  d <- as.data.frame(locais)
  d$lat <- coords$lat
  d$lon <- coords$lon
  ok <- !is.na(d$lat) & !is.na(d$lon) & d$lat != 0 & d$lon != 0 &
    d$lat >= -33.9 & d$lat <= 5.4 &
    d$lon >= -73.99 & d$lon <= -32.3
  sf::st_as_sf(d[ok, , drop = FALSE], coords = c("lon", "lat"),
               crs = 4326, remove = FALSE)
}

#' Harmoniza secoes de votacao com um nivel submunicipal do DW e grava a
#' tabela `tse_secao_bairro`
#'
#' Atribuicao principal por ponto (metodo "ponto"): para cada linha de
#' local de votacao com coordenada util, o vizinho mais proximo do nivel
#' pedido (`bairro`, `subdistrito`, `setor` ou `area_ponderacao` do DW) via
#' KNN PostGIS, aceito so se a distancia geodesica ficar dentro de
#' `raio_m` metros. Secoes que casam com mais de uma localidade distinta
#' viram "conflito" (sem atribuicao, campos NULL). Fallback por nome
#' (metodo "nome", so para `nivel = "bairro"` e com `mapa_municipios`):
#' casa o bairro declarado pelo TSE com o bairro do DW reutilizando os
#' auxiliares puros de `tse_auxiliares.R`.
#'
#' Grava uma linha para TODA secao do arquivo, atribuida ou nao, apagando
#' antes o trecho `(ano, uf, nivel_tipo)` (idempotente por trecho).
#'
#' @param con conexao DBI com o DW; default abre pelo idiom dos
#'   `garantir_*` (env vars `user`/`password`/`host`/`dbname`).
#' @param locais data.frame de `tsebr::tse_locais_votacao()` (ou sf de
#'   [tse_pontuar_locais_votacao()]).
#' @param ano,uf ano e sigla da UF processados (chave do trecho gravado).
#' @param raio_m raio maximo em metros entre o local de votacao e o
#'   vizinho mais proximo (default 2000).
#' @param nivel nivel do DW a atribuir: `"auto"` (bairro se houver no DW,
#'   senao subdistrito), ou um de `"bairro"`, `"subdistrito"`, `"setor"`,
#'   `"area_ponderacao"`.
#' @param mapa_municipios vetor nomeado cod_municipio_tse -> codigo IBGE
#'   de 7 digitos, exigido pelo metodo "nome" (nivel bairro).
#' @return lista com `nivel`, `raio_m`, `n_secoes`, `por_metodo`
#'   (secoes e eleitores por metodo), `cobertura_eleitores`, `conflitos`
#'   (secoes com multiplos vizinhos) e `concordancia` (cheque ponto x
#'   nome, quando ambos existem).
#' @export
tse_harmonizar_secoes <- function(con = NULL, locais, ano, uf,
                                  raio_m = 2000,
                                  nivel = c("auto", "bairro", "subdistrito",
                                            "setor", "area_ponderacao"),
                                  mapa_municipios = NULL) {
  nivel <- match.arg(nivel)
  ano <- as.integer(ano)
  uf <- toupper(as.character(uf))
  fechar <- is.null(con)
  if (fechar) {
    con <- DBI::dbConnect(
      RPostgres::Postgres(),
      user = Sys.getenv("user", "beep"),
      password = Sys.getenv("password", "aEd1#man@gR"),
      host = Sys.getenv("host", "127.0.0.1"),
      dbname = Sys.getenv("dbname", "beepdb"))
  }
  on.exit(if (fechar) DBI::dbDisconnect(con), add = TRUE)
  garantir_tabela_harmonizacao_secao(con)

  if (inherits(locais, "sf")) {
    xy <- sf::st_coordinates(locais)
    locais <- as.data.frame(locais)
    locais$lon <- xy[, 1]
    locais$lat <- xy[, 2]
  } else {
    locais <- as.data.frame(locais)
    coords <- .tse_coords_locais(locais)
    locais$lat <- coords$lat
    locais$lon <- coords$lon
  }
  chaves <- c("cod_municipio_tse", "zona", "secao")
  falta <- setdiff(chaves, names(locais))
  if (length(falta)) {
    stop("tse_harmonizar_secoes: colunas ausentes em locais: ",
         paste(falta, collapse = ", "))
  }

  disponiveis <- DBI::dbGetQuery(
    con, "select distinct nivel_tipo from local where nivel_tipo is not null")
  if (nivel == "auto") {
    nivel <- if ("bairro" %in% disponiveis$nivel_tipo) "bairro" else
      if ("subdistrito" %in% disponiveis$nivel_tipo) "subdistrito" else
        stop("tse_harmonizar_secoes: DW sem nivel submunicipal ",
             "(bairro/subdistrito); niveis disponiveis: ",
             paste(disponiveis$nivel_tipo, collapse = ", "))
  }
  if (!nivel %in% disponiveis$nivel_tipo) {
    stop("tse_harmonizar_secoes: nivel '", nivel, "' inexistente no DW; ",
         "disponiveis: ", paste(disponiveis$nivel_tipo, collapse = ", "))
  }

  ## Base: uma linha por linha do arquivo, chaves TSE em texto exato.
  base <- data.frame(
    cod_municipio_tse = normalizar_codigo_geoloc(locais$cod_municipio_tse),
    municipio = trimws(as.character(locais$municipio)),
    zona = normalizar_codigo_geoloc(locais$zona),
    secao = normalizar_codigo_geoloc(locais$secao),
    lat = locais$lat,
    lon = locais$lon,
    eleitores = if ("eleitores_secao" %in% names(locais)) {
      suppressWarnings(as.integer(locais$eleitores_secao))
    } else NA_integer_)

  ## B2 ponto: vizinho mais proximo do nivel, dentro do raio (geography
  ## => metros). Tabela temporaria SEM "on commit drop": o autocommit do
  ## RPostgres derrubaria a tabela entre statementes. JIT off: o LLVM
  ## do servidor 15 compila bitcode do PostGIS com versao invalida e
  ## MATA o backend em KNN pesado (5418 setores); sem JIT o KNN por
  ## indice GiST nao perde nada.
  tryCatch(DBI::dbExecute(con, "set jit = off"), error = function(e) NULL)
  dentro <- !is.na(base$lat) & !is.na(base$lon) &
    base$lat != 0 & base$lon != 0 &
    base$lat >= -33.9 & base$lat <= 5.4 &
    base$lon >= -73.99 & base$lon <= -32.3
  pontos <- base[dentro, ]
  pontos <- pontos[!duplicated(
    paste(pontos$cod_municipio_tse, pontos$zona, pontos$secao,
          pontos$lat, pontos$lon, sep = "\r")), , drop = FALSE]
  pontos$gid <- seq_len(nrow(pontos))
  casados_ponto <- if (nrow(pontos)) {
    DBI::dbExecute(con, "DROP TABLE IF EXISTS tse_pontos_tmp")
    on.exit(DBI::dbExecute(con, "DROP TABLE IF EXISTS tse_pontos_tmp"),
            add = TRUE)
    DBI::dbWriteTable(con, "tse_pontos_tmp",
                      pontos[c("gid", "cod_municipio_tse", "municipio",
                               "zona", "secao", "lat", "lon")],
                      temporary = TRUE, overwrite = TRUE)
    res_knn <- DBI::dbGetQuery(con, paste(
      "select p.gid, b.local_id, b.local_name, b.codigo",
      "from tse_pontos_tmp p",
      "cross join lateral (",
      "  select l.local_id, l.local_name,",
      "         cast(g.geoloc_id as text) as codigo, g.geometry",
      "  from local l join geoloc g on g.geoloc_id = l.geoloc_id",
      "  where l.nivel_tipo = $1",
      "  order by g.geometry <-> st_setsrid(st_makepoint(p.lon, p.lat), 4326)",
      "  limit 1) b",
      "where st_distance(cast(b.geometry as geography),",
      "      cast(st_setsrid(st_makepoint(p.lon, p.lat), 4326) as geography)",
      "      ) <= $2"),
      params = list(nivel, raio_m))
    if (is.null(res_knn)) {
      stop("tse_harmonizar_secoes: consulta KNN falhou ",
           "(conexao caiu? ver log do PostgreSQL)")
    }
    res_knn
  } else {
    data.frame(gid = integer(0), local_id = integer(0),
               local_name = character(0), codigo = character(0))
  }

  ## Agregado por secao: 1 vizinho distinto => ponto; >1 => conflito.
  viz <- merge(pontos, casados_ponto, by = "gid", all.x = TRUE)
  viz$chave <- paste(viz$cod_municipio_tse, viz$zona, viz$secao, sep = "\r")
  local_da_secao <- vapply(split(viz$local_id, viz$chave), function(x) {
    x <- unique(x[!is.na(x)])
    if (length(x) == 1) x else NA_real_
  }, numeric(1))
  n_vizinhos <- vapply(split(viz$local_id, viz$chave), function(x) {
    length(unique(x[!is.na(x)]))
  }, integer(1))
  conflito <- names(n_vizinhos)[n_vizinhos > 1]

  ## B1 nome: so nivel bairro com mapa de municipios (auxiliares puros).
  ## Chaves do B1 vivem no espaco IBGE (municipio de 7 digitos).
  b1_por_secao <- NULL
  if (nivel == "bairro" && !is.null(mapa_municipios)) {
    dw_bairros <- DBI::dbGetQuery(
      con, paste("select l.local_id, l.local_name,",
                 "cast(g.geoloc_id as text) as codigo",
                 "from local l join geoloc g on g.geoloc_id = l.geoloc_id",
                 "where l.nivel_tipo = 'bairro'"))
    bairro_orig <- if ("bairro" %in% names(locais)) locais$bairro else
      rep(NA_character_, nrow(locais))
    pseudo <- data.frame(
      CD_MUNICIPIO = unname(mapa_municipios[base$cod_municipio_tse]),
      NR_ZONA = base$zona,
      NR_SECAO = base$secao,
      NM_BAIRRO = bairro_orig)
    mapa_b1 <- tse_mapa_secao_bairro(pseudo)
    unicos <- mapa_b1$mapa[mapa_b1$mapa$situacao == "bairro_unico", ]
    cas <- tse_casar_bairros(unicos$municipio, unicos$bairro, dw_bairros)
    pos_cas <- match(paste(unicos$municipio, unicos$bairro, sep = "\r"),
                     paste(cas$casados$municipio,
                           cas$casados$nome_normalizado, sep = "\r"))
    b1_por_secao <- stats::setNames(
      cas$casados$local_id[pos_cas],
      paste(unicos$municipio, unicos$zona, unicos$secao, sep = "\r"))
    b1_por_secao <- b1_por_secao[!is.na(b1_por_secao)]
  }

  ## Uma linha por secao (todas, atribuidas ou nao).
  base$chave <- paste(base$cod_municipio_tse, base$zona, base$secao,
                      sep = "\r")
  max_eleitores <- tapply(base$eleitores, base$chave, function(x) {
    x <- x[!is.na(x)]
    if (!length(x)) NA_integer_ else max(x)
  })
  u <- !duplicated(base[chaves])
  linhas <- base[u, c("cod_municipio_tse", "municipio", "zona", "secao")]
  linhas$chave <- paste(linhas$cod_municipio_tse, linhas$zona,
                        linhas$secao, sep = "\r")
  linhas$eleitores <- as.integer(max_eleitores[linhas$chave])
  linhas$bairro_local_id <- as.integer(local_da_secao[linhas$chave])
  linhas$bairro_local_id[linhas$chave %in% conflito] <- NA_integer_
  linhas$metodo <- ifelse(linhas$chave %in% conflito, "conflito",
                          ifelse(!is.na(linhas$bairro_local_id), "ponto",
                                 NA_character_))

  ## Fallback/concordancia por nome: mapear chave TSE -> chave IBGE.
  linhas$ibge <- if (!is.null(mapa_municipios)) {
    unname(mapa_municipios[linhas$cod_municipio_tse])
  } else NA_character_
  if (!is.null(b1_por_secao)) {
    chave_ibge_linha <- ifelse(is.na(linhas$ibge), NA_character_,
                              paste(linhas$ibge, linhas$zona, linhas$secao,
                                    sep = "\r"))
    sem_atrib <- is.na(linhas$bairro_local_id) & linhas$metodo != "conflito"
    b1_linha <- b1_por_secao[chave_ibge_linha]
    linhas$bairro_local_id[sem_atrib] <- as.integer(
      b1_linha[sem_atrib])
    linhas$metodo[sem_atrib] <- ifelse(is.na(linhas$bairro_local_id[sem_atrib]),
                                       NA_character_, "nome")
  }

  ## Nomes/codigos do DW para as secoes atribuidas.
  dw_do_nivel <- DBI::dbGetQuery(
    con, paste("select l.local_id, l.local_name,",
               "cast(g.geoloc_id as text) as codigo",
               "from local l join geoloc g on g.geoloc_id = l.geoloc_id",
               "where l.nivel_tipo = $1"), params = list(nivel))
  pos_dw <- match(linhas$bairro_local_id, dw_do_nivel$local_id)
  linhas$bairro_codigo <- dw_do_nivel$codigo[pos_dw]
  linhas$bairro_nome <- dw_do_nivel$local_name[pos_dw]
  linhas$bairro_local_id <- as.integer(linhas$bairro_local_id)

  gravar <- data.frame(
    ano = rep(ano, nrow(linhas)),
    uf = rep(uf, nrow(linhas)),
    nivel_tipo = rep(nivel, nrow(linhas)),
    cod_municipio_tse = linhas$cod_municipio_tse,
    municipio = linhas$municipio,
    zona = linhas$zona,
    secao = linhas$secao,
    bairro_local_id = linhas$bairro_local_id,
    bairro_codigo = linhas$bairro_codigo,
    bairro_nome = linhas$bairro_nome,
    metodo = linhas$metodo)
  DBI::dbBegin(con)
  tryCatch({
    DBI::dbExecute(con, paste(
      "delete from tse_secao_bairro",
      "where ano = $1 and uf = $2 and nivel_tipo = $3"),
      params = list(ano, uf, nivel))
    ## dbWriteTable(append) interpola valores e serve nos dois drivers
    ## (dbAppendTable gera placeholders "?" que o RPostgreSQL nao liga).
    DBI::dbWriteTable(con, "tse_secao_bairro", gravar, append = TRUE,
                      row.names = FALSE)
    DBI::dbCommit(con)
  }, error = function(e) {
    tryCatch(DBI::dbRollback(con), error = function(e2) NULL)
    stop("tse_harmonizar_secoes: falha ao gravar: ",
         conditionMessage(e))
  })

  ## Resumos.
  met <- ifelse(is.na(linhas$metodo), "(sem)", linhas$metodo)
  tb <- table(met)
  elei <- tapply(linhas$eleitores, met, sum, na.rm = TRUE)
  por_metodo <- data.frame(
    metodo = names(tb),
    n_secoes = as.integer(tb),
    eleitores = as.integer(elei[names(tb)]))
  por_metodo$eleitores[is.na(por_metodo$eleitores)] <- 0L
  atribuidas <- sum(linhas$eleitores[linhas$metodo %in%
                                       c("ponto", "nome")], na.rm = TRUE)
  total <- sum(linhas$eleitores, na.rm = TRUE)

  conflitos_df <- linhas[which(linhas$metodo == "conflito"),
                         c("municipio", "zona", "secao", "eleitores"),
                         drop = FALSE]
  rownames(conflitos_df) <- NULL

  concordancia <- NULL
  if (!is.null(b1_por_secao) && any(linhas$metodo == "ponto", na.rm = TRUE)) {
    pontos_df <- linhas[which(linhas$metodo == "ponto"), ]
    b1 <- b1_por_secao[paste(pontos_df$ibge, pontos_df$zona,
                             pontos_df$secao, sep = "\r")]
    tem_ambos <- !is.na(b1)
    diver <- pontos_df[tem_ambos &
                         as.integer(b1) != pontos_df$bairro_local_id, ]
    concordancia <- list(
      n_ambos = sum(tem_ambos),
      n_concordam = sum(tem_ambos & as.integer(b1) ==
                          pontos_df$bairro_local_id),
      n_divergem = nrow(diver),
      divergentes = utils::head(diver[c("municipio", "zona", "secao",
                                        "bairro_nome")], 20))
  }

  list(nivel = nivel, raio_m = raio_m, n_secoes = nrow(linhas),
       por_metodo = por_metodo,
       cobertura_eleitores = if (total > 0) atribuidas / total else NA_real_,
       conflitos = conflitos_df,
       concordancia = concordancia,
       gravadas = gravar)
}

#' Resumo da harmonizacao gravada em `tse_secao_bairro`
#'
#' @param con conexao DBI com o DW (default abre pelo idiom dos
#'   `garantir_*`).
#' @param ano,uf filtro do trecho; `NULL` traz todos.
#' @return lista com `por_nivel` (data.frame ano x uf x nivel x metodo com
#'   secoes e localidades distintas) e `n_secoes_total`.
#' @export
tse_resumo_harmonizacao <- function(con = NULL, ano = NULL, uf = NULL) {
  fechar <- is.null(con)
  if (fechar) {
    con <- DBI::dbConnect(
      RPostgres::Postgres(),
      user = Sys.getenv("user", "beep"),
      password = Sys.getenv("password", "aEd1#man@gR"),
      host = Sys.getenv("host", "127.0.0.1"),
      dbname = Sys.getenv("dbname", "beepdb"))
  }
  on.exit(if (fechar) DBI::dbDisconnect(con), add = TRUE)
  cond <- c(if (!is.null(ano)) "ano = $1",
            if (!is.null(uf)) "uf = $2")
  where <- if (length(cond)) paste0("where ", paste(cond, collapse = " and "))
  else ""
  params <- list(ano, toupper(as.character(uf)))[
    !vapply(list(ano, uf), is.null, logical(1))]
  por_nivel <- DBI::dbGetQuery(con, paste(
    "select ano, uf, nivel_tipo, coalesce(metodo, '(sem)') as metodo,",
    "count(*) as n_secoes,",
    "count(distinct bairro_local_id) as n_localidades",
    "from tse_secao_bairro", where,
    "group by ano, uf, nivel_tipo, coalesce(metodo, '(sem)')",
    "order by ano, uf, nivel_tipo, metodo"),
    params = params)
  list(por_nivel = por_nivel, n_secoes_total = sum(por_nivel$n_secoes))
}

#' Nucleo puro de agregacao do detalhe por secao (testavel offline):
#' dedupe `first()` por secao-turno (as metricas repetem em cada
#' cargo), descarta linhas sem local e soma por local e turno (quando
#' o detalhe traz a coluna, cada turno vira um ponto proprio com
#' periodo no domingo da eleicao) — espelho do
#' `tsebr::tse_detalhe_municipio()`.
#' @keywords internal
.tse_agregar_detalhe_local <- function(d, local_chr, metrica, a) {
  chaves <- intersect(c("uf", "cod_municipio_tse", "zona", "secao",
                        "turno"), names(d))
  grupos_local <- c("local", intersect("turno", names(d)))
  data.table::rbindlist(lapply(metrica, function(m) {
    d |>
      dplyr::select(dplyr::all_of(c(chaves, m))) |>
      dplyr::mutate(valor = as.numeric(.data[[m]]),
                    local = local_chr, .keep = "unused") |>
      dplyr::group_by(dplyr::across(dplyr::all_of(chaves))) |>
      dplyr::summarise(valor = dplyr::first(valor),
                       local = dplyr::first(local), .groups = "drop") |>
      dplyr::filter(!is.na(local)) |>
      dplyr::group_by(dplyr::across(dplyr::all_of(grupos_local))) |>
      dplyr::summarise(valor = sum(valor, na.rm = TRUE),
                       .groups = "drop") |>
      dplyr::mutate(metrica = m, ano = as.integer(a),
                    periodo = if ("turno" %in% grupos_local) {
                      tsebr::tse_periodo_eleicao(a, .data$turno)
                    } else {
                      as.Date(paste0(a, "-12-31"))
                    })
  }), fill = TRUE)
}

#' Detalhe da votacao por secao agregado ao nivel municipal ou submunicipal
#'
#' Espelha a semantica de `tsebr::tse_detalhe_municipio()` (dedupe
#' `first()` por secao-turno — as metricas do detalhe repetem em cada
#' cargo da mesma secao — e soma por localidade), mas agrega pela
#' localidade do nivel `agregar_por` atribuida as secoes na tabela de
#' harmonizacao `tse_secao_bairro` (preenchida por
#' [tse_harmonizar_secoes()]). A soma por municipio bate, portanto, com
#' a serie municipal do tsebr — o cheque natural de sanidade.
#'
#' Com `agregar_por = "municipio"` a harmonizacao nao e usada: o mapeio
#' e direto pelo `tsebr::tse_mapa_municipios()` (codigo TSE -> IBGE de
#' 7 digitos), reproduzindo o `tse_detalhe_municipio()`.
#'
#' Secoes sem atribuicao (sem harmonizacao previa, conflito ou ponto
#' fora do raio) sao descartadas com `warning()` informando a contagem:
#' nessas localidades o valor agregado fica abaixo do municipal na
#' mesma proporcao da perda.
#'
#' @param con conexao DBI com o DW (default abre pelo idiom dos
#'   `garantir_*`); usada so para ler `tse_secao_bairro` quando
#'   `agregar_por != "municipio"`.
#' @param ano ano eleitoral ou vetor (ex.: 2022, 2026).
#' @param uf sigla da UF.
#' @param metrica coluna(s) do detalhe a agregar: `aptos`,
#'   `comparecimento`, `abstencoes`, `votos_nulos` ou `votos_brancos`.
#' @param agregar_por nivel de agregacao: `subdistrito` (default),
#'   `setor`, `bairro` ou `area_ponderacao` (exigem harmonizacao previa
#'   no DW para o par ano/UF) ou `municipio` (mapa TSE x IBGE).
#' @param dest_dir diretorio de cache do download (repassado ao
#'   tsebr).
#' @return `data.frame` long: `local` (geoloc_id numerico do DW),
#'   `periodo`, `valor`, `uf`, `metrica` e `turno` quando o detalhe
#'   traz a coluna (cada turno e um ponto proprio, com `periodo` no
#'   domingo da eleicao segundo `tsebr::tse_periodo_eleicao()`, em vez
#'   do 31/12 do ano); mesmo shape do
#'   `tsebr::tse_detalhe_municipio()`, aceito de pronto pelo ramo TSE
#'   do upload de fontes.
#' @examples
#' \dontrun{
#' tse_detalhe_secao(2026, "DF", metrica = "abstencoes",
#'                   agregar_por = "subdistrito")
#' }
#' @export
tse_detalhe_secao <- function(con = NULL, ano, uf,
                              metrica = c("aptos", "comparecimento",
                                          "abstencoes", "votos_nulos",
                                          "votos_brancos"),
                              agregar_por = c("subdistrito", "setor",
                                              "municipio", "bairro",
                                              "area_ponderacao"),
                              dest_dir = NULL) {
  metrica <- match.arg(metrica, several.ok = TRUE)
  agregar_por <- match.arg(agregar_por)
  anos <- sort(unique(as.integer(ano)))
  uf <- toupper(as.character(uf))
  fechar <- is.null(con)
  if (fechar) {
    con <- DBI::dbConnect(
      RPostgres::Postgres(),
      user = Sys.getenv("user", "beep"),
      password = Sys.getenv("password", "aEd1#man@gR"),
      host = Sys.getenv("host", "127.0.0.1"),
      dbname = Sys.getenv("dbname", "beepdb"))
  }
  on.exit(if (fechar) DBI::dbDisconnect(con), add = TRUE)

  parte_ano <- function(a) {
    d <- tsebr::tse_resultados_secao(a, uf, detalhe = TRUE,
                                     dest_dir = dest_dir)
    if (is.null(d) || !nrow(d)) {
      stop("tse_detalhe_secao: detalhe de secao vazio para ", a, "/", uf)
    }
    chaves <- intersect(c("uf", "cod_municipio_tse", "zona", "secao",
                          "turno"), names(d))
    falta <- setdiff(metrica, names(d))
    if (length(falta)) {
      stop("tse_detalhe_secao: metrica(s) ausente(s) no detalhe de ", a,
           ": ", paste(falta, collapse = ", "))
    }
    d$cod_municipio_tse <- normalizar_codigo_geoloc(d$cod_municipio_tse)
    d$zona <- normalizar_codigo_geoloc(d$zona)
    d$secao <- normalizar_codigo_geoloc(d$secao)
    chave3 <- paste(d$cod_municipio_tse, d$zona, d$secao, sep = "\r")

    if (agregar_por == "municipio") {
      mapa <- tsebr::tse_mapa_municipios(a, uf)
      pos <- match(d$cod_municipio_tse,
                   normalizar_codigo_geoloc(mapa$cod_municipio_tse))
      if (anyNA(pos)) {
        stop("tse_detalhe_secao: municipio(s) TSE sem mapa IBGE em ", a,
             ": ", paste(unique(d$cod_municipio_tse[is.na(pos)]),
                         collapse = ", "))
      }
      local_chr <- normalizar_codigo_geoloc(mapa$geoloc_id[pos])
    } else {
      harm <- DBI::dbGetQuery(con, paste(
        "select cod_municipio_tse, zona, secao, bairro_codigo",
        "from tse_secao_bairro",
        "where ano = $1 and uf = $2 and nivel_tipo = $3",
        "and bairro_local_id is not null"),
        params = list(a, uf, agregar_por))
      if (is.null(harm) || !nrow(harm)) {
        stop("tse_detalhe_secao: sem harmonizacao para ", a, "/", uf,
             " no nivel '", agregar_por,
             "' — rode tse_harmonizar_secoes() antes")
      }
      pos <- match(chave3,
                   paste(normalizar_codigo_geoloc(harm$cod_municipio_tse),
                         normalizar_codigo_geoloc(harm$zona),
                         normalizar_codigo_geoloc(harm$secao),
                         sep = "\r"))
      local_chr <- ifelse(is.na(pos), NA_character_,
                          trimws(as.character(harm$bairro_codigo[pos])))
    }

    ## metricas do detalhe repetem em cada cargo da mesma secao-turno:
    ## deduplicar ANTES de somar (espelho do tse_detalhe_municipio)
    sem_local <- is.na(local_chr) &
      !duplicated(d[, chaves, with = FALSE])
    if (any(sem_local)) {
      warning("tse_detalhe_secao: ", sum(sem_local), " secao(oes)-turno de ",
              a, "/", uf, " sem atribuicao '", agregar_por,
              "' descartada(s) (sem harmonizacao ou conflito)")
    }
    .tse_agregar_detalhe_local(d, local_chr, metrica, a)
  }

  res <- data.table::rbindlist(lapply(anos, parte_ano), fill = TRUE)
  as.data.frame(res |>
    dplyr::mutate(local = as.numeric(local), uf = uf) |>
    dplyr::select(dplyr::any_of(
      c("local", "turno", "periodo", "valor", "uf", "metrica"))))
}
