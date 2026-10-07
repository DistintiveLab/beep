# Gravacao de series no DW beepdb a partir dos scripts de coleta
# (padrao A5b, replicado de rais_vinculos_s38.R em 2026-09-03)
#
# Encapsula: conexao, metadados do mdata existente, mapeamento IBGE
# 6 digitos (RAIS) -> geoloc_id 7 digitos (DW), e recarga completa com
# db_datawrite(replace=TRUE) — transacional, mdata_id estavel.
#
#serie: data.frame com colunas `local` (IBGE 6 ou 7 digitos, ou local_id
#          do DW), `periodo` (Date) e `valor` (numeric).

#' Anos disponiveis no mte_rais (tabelas rais_vinculo_YYYY)
#' @export
anos_rais <- function(con) {
  sort(as.numeric(gsub("\\D", "", grep("^rais_vinculo_[0-9]+$",
    DBI::dbGetQuery(con, "SELECT table_name FROM information_schema.tables
                     WHERE table_schema='public' AND table_name ~ '^rais_vinculo_[0-9]+$'")$table_name,
    value = TRUE))))
}

#' Monta o lookup de codigos de local para local_id do DW
#'
#' Prioridade: prefixo IBGE 6d do MUNICIPIO (RAIS) > proprio local_id >
#' geoloc_id completo (texto normalizado — códigos submunicipais de 11-16
#' digitos resolvem aqui pelo codigo cheio). O prefixo 6d vem SOMENTE das
#' linhas de municipio (largura 7 do geoloc_id), na ordem de local_id: um
#' setor censitario cujo prefixo 6d e o codigo de municipio nao pode
#' sombrear o municipio (roadmap F1), e as Regioes Imediatas (geoloc 6d que
#' collide com o prefixo do municipio, 1100023 -> 110002) ficam fora do
#' mapa de prefixo — codigo 6d de entrada e sempre municipio na semantica
#' RAIS/IBGE.
#' O local_id vem antes do geoloc_id completo porque derivacoes DW->DW
#' (padrao A5b) repassam local_ids, e os ids pequenos dos municipios
#' collidem com geoloc_ids de agregados (1=Alta Floresta vs 1=Norte,
#' 53=Acrelandia vs 53=DF), o que despachava series municipais para
#' regiao/UF/DF (bug de cobertura municipal, segunda ordem, corrigido
#' 2026-09-22). Series agregadas devem ser passadas por local_id.
#' Municipios incorporados apos o bloco territorial do seeder
#' (acima do local_id da linha "Brasil"; ver incorporar_municipio_ibge)
#' tambem entram no prefixo 6d.
#'
#' @param locais data.frame com `local_id` e `geoloc_id` (tabela `local`)
#' @keywords internal
montar_lookup_locais <- function(locais) {
  limite_br <- suppressWarnings(locais$local_id[
    locais$local_name == "Brasil"][1])
  if (is.na(limite_br)) limite_br <- niveis_pnad_bloco_fim
  geo_txt <- normalizar_codigo_geoloc(locais$geoloc_id)
  ordem <- order(locais$local_id)
  mun7 <- ordem[eh_municipio_id(locais$local_id, bloco_fim = limite_br) &
                  nchar(geo_txt) == 7L]
  lookup <- c(
    setNames(locais$local_id[mun7], substr(geo_txt[mun7], 1, 6)),
    setNames(locais$local_id, as.character(locais$local_id)),
    setNames(locais$local_id, geo_txt))
  lookup[!duplicated(names(lookup))]
}

#' Grava (recalculando por completo ou acrescentando) a serie de um indicador
#'
#' @param orig_name nome do indicador em mdata
#' @param serie data.frame com `local`, `periodo`, `valor`
#' @param modo `"replace"` (default) ou `"append"`
#' @export
gravar_serie_dw <- function(orig_name, serie, modo = c("replace", "append")) {
  modo <- match.arg(modo)
  stopifnot(all(c("local", "periodo", "valor") %in% names(serie)))
  con_beep <- DBI::dbConnect(
    RPostgres::Postgres(),
    user = Sys.getenv("user", "beep"),
    password = Sys.getenv("password", "aEd1#man@gR"),
    host = Sys.getenv("host", "127.0.0.1"),
    dbname = Sys.getenv("dbname", "beepdb"))

  md <- DBI::dbGetQuery(con_beep,
    "SELECT * FROM mdata WHERE orig_name = $1", params = list(orig_name))
  if (nrow(md) != 1) {
    DBI::dbDisconnect(con_beep)
    message("gravar_serie_dw: mdata '", orig_name, "' ausente - nao gravado")
    return(invisible(FALSE))
  }
  exts <- DBI::dbGetQuery(con_beep,
    "SELECT * FROM mdata_exts WHERE mdata_id = $1", params = list(md$mdata_id))
  metadf <- list(md[, c("orig_name", "data_name", "data_desc")],
                 exts[, setdiff(names(exts), "mdata_id")])

  locais <- DBI::dbGetQuery(con_beep,
    "SELECT local_id, geoloc_id FROM local")

  # lookup triplo: prefixo IBGE 6d da RAIS, proprio local_id (agregados:
  # Brasil, UF, regioes... e derivacoes DW->DW) ou geoloc_id completo (7d).
  # O prefixo 6d TEM PRIORIDADE sobre o geoloc como texto (colisao RGINT,
  # 1100023 -> 110002) e o local_id TEM PRIORIDADE sobre o geoloc pequeno
  # de agregados (colisao 1=Alta Floresta vs 1=Norte; bug de cobertura
  # municipal, corrigido 2026-09-22).
  lookup <- montar_lookup_locais(locais)

  # chave por texto normalizado: preserva codigos submunicipais longos
  # (15-16 digitos exatos em double, < 2^53) que as.numeric + as.character
  # nao destruiria, mas format(scientific=FALSE) garante
  chave <- normalizar_codigo_geoloc(serie$local)
  lid <- lookup[chave]
  serie <- serie[!is.na(lid), ]
  lid <- lid[!is.na(lid)]
  datadf <- data.frame(local = as.numeric(lid),
                       periodo = serie$periodo,
                       valor = serie$valor)
  # defesa contra fan-out de joins: 1 ponto por (local, periodo)
  datadf <- datadf[!duplicated(datadf[, c("local", "periodo")]), ]

  if (modo == "append") {
    # remove apenas os refdates trazidos pela serie e reinsere (upsert por
    # refdate), preservando o historico anterior
    periodos <- sort(unique(datadf$periodo))
    DBI::dbBegin(con_beep)
    tryCatch({
      in_dates <- paste(sprintf("DATE '%s'", as.character(periodos)),
                        collapse = ", ")
      DBI::dbExecute(con_beep, sprintf(
        "DELETE FROM data_values WHERE mdata_id = %d AND refdate IN (%s)",
        md$mdata_id, in_dates))
      DBI::dbAppendTable(con_beep, "data_values",
        data.frame(mdata_id = md$mdata_id,
                   local_id = datadf$local,
                   refdate = datadf$periodo,
                   value = datadf$valor))
      DBI::dbExecute(con_beep,
        "UPDATE mdata_timetable SET last_refdate = GREATEST(last_refdate, $2),
            last_update = current_date WHERE mdata_id = $1",
        params = list(md$mdata_id, max(periodos)))
      DBI::dbExecute(con_beep, "refresh materialized view named_datavalues;")
      DBI::dbExecute(con_beep, "refresh materialized view geonamed_datavalues;")
      DBI::dbCommit(con_beep)
    }, error = function(e) {
      try(DBI::dbRollback(con_beep), silent = TRUE)
      stop("gravar_serie_dw(append) falhou: ", conditionMessage(e))
    })
    DBI::dbDisconnect(con_beep)
    message("DW atualizado (append): ", orig_name, " refdates ",
            paste(format(periodos), collapse = ", "), " (", nrow(datadf), " pontos)")
    return(invisible(TRUE))
  }

  beep:::db_datawrite(metadf, datadf, construct = NULL,
                      sanitize = FALSE, replace = TRUE)
  DBI::dbDisconnect(con_beep)
  message("DW atualizado: ", orig_name, " ate ", max(serie$periodo),
          " (", nrow(serie), " pontos)")
  invisible(TRUE)
}
