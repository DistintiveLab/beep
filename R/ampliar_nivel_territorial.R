# Incorporacao generica de um nivel territorial submunicipal no DW
#
# Maquina unica por tras de [incorporar_setores_censitarios()],
# [incorporar_areas_ponderacao()] e [incorporar_bairros()] (roadmap F2/F4):
# valida os codigos, garante o schema (BIGINT + nivel_tipo), insere as
# geometrias em geoloc e as localidades em local com local_id alocado
# dentro do bloco do tipo (MAX+1 confinado ao bloco, sempre APPEND —
# nunca renumerar ids existentes, data_values referencia local_id).
#
# A insercao e set-based (tabela temporaria + INSERT SELECT) porque um
# lote de setores por UF tem ~100-400 mil feicoes e um loop de dbExecute
# por linha seria inviavel.

#' Incorpora um nivel territorial submunicipal a partir de um sf de feicoes
#'
#' O sf precisa trazer o codigo longo do nivel (digitos apenas; largura
#' validada contra o registro de [niveis_territoriais_tipos]) e, opcionalmente,
#' um nome. Feicoes cujo codigo ja existe em `geoloc` sao puladas
#' (idempotente por codigo). As novas ganham `local_id` sequencial dentro do
#' bloco do tipo e `nivel_tipo` preenchido. A matview `recortes_geograficos`
#' NAO e regenerada: ela e uma visao por municipio de proposito; niveis
#' submunicipais nao participam dos recortes.
#'
#' @param dados sf com a coluna de codigo (`col_codigo`) e opcionalmente
#'   nome (`col_nome`), geometria em EPSG:4326 ou reprojetavel
#' @param tipo um de `niveis_blocos_local_id$tipo`: "setor",
#'   "area_ponderacao", "bairro"
#' @param col_codigo,col_nome nomes das colunas de codigo/nome no sf
#' @param con conexao DBI com o DW; default abre o beepdb local
#' @param simplificar dTolerance (graus) da simplificacao no SQL
#'   (ST_SimplifyPreserveTopology); default 0.001 — mais fino que o 0.01
#'   dos municipios porque feicoes submunicipais sao pequenas
#' @param refrescar atualizar as matviews named/geonamed_datavalues ao fim?
#'   Custa alguns minutos em DW grande; o ETL em lote prefere refrescar uma
#'   unica vez no fim de tudo
#' @return data.frame invisivel com os codigos incorporados e seus local_ids
#' @export
ampliar_nivel_territorial <- function(dados, tipo,
                                      col_codigo = NULL, col_nome = NULL,
                                      con = NULL, simplificar = 0.001,
                                      refrescar = FALSE) {
  stopifnot(inherits(dados, "sf"))
  tipo <- match.arg(as.character(tipo)[1],
                    niveis_blocos_local_id$tipo)
  bloco <- niveis_blocos_local_id[
    niveis_blocos_local_id$tipo == tipo, ]

  if (is.null(col_codigo)) {
    padrao <- switch(tipo,
                     setor = "setor|tract|census",
                     area_ponderacao = "ponder|weight",
                     bairro = "bairro")
    cand <- grep(padrao, names(dados), value = TRUE,
                 ignore.case = TRUE)
    if (!length(cand)) {
      stop("ampliar_nivel_territorial: informe col_codigo (nenhuma ",
           "coluna casa com '", padrao, "' em ", paste(names(dados),
                                                       collapse = ", "), ")")
    }
    col_codigo <- cand[1]
  }
  if (is.null(col_nome)) {
    cand <- intersect(c("nm_bairro", "nome", "name", "nm_setor"),
                      names(dados))
    col_nome <- if (length(cand)) cand[1] else NA_character_
  }

  codigos <- validar_codigos_nivel(dados[[col_codigo]], tipo)
  nomes <- if (!is.na(col_nome) && col_nome %in% names(dados)) {
    normalizar_codigo_geoloc(dados[[col_nome]])
  } else rep(NA_character_, length(codigos))

  .con_nossa <- is.null(con)
  if (.con_nossa) {
    con <- DBI::dbConnect(
      RPostgres::Postgres(),
      user = Sys.getenv("user", "beep"),
      password = Sys.getenv("password", "aEd1#man@gR"),
      host = Sys.getenv("host", "127.0.0.1"),
      dbname = Sys.getenv("dbname", "beepdb"))
  }
  on.exit(if (.con_nossa) DBI::dbDisconnect(con), add = TRUE)

  preparar_niveis_submunicipais(con = con)

  wkt <- sf::st_as_text(sf::st_geometry(sf::st_transform(dados, 4326)),
                        digits = 15)
  lote <- data.frame(codigo = codigos, nome = nomes, wkt = wkt)

  DBI::dbBegin(con)
  inseridos <- NULL
  tryCatch({
    DBI::dbExecute(con,
                   "DROP TABLE IF EXISTS tmp_ampliar_nivel")
    DBI::dbExecute(con, paste(
      "CREATE TEMP TABLE tmp_ampliar_nivel (",
      "codigo TEXT, nome TEXT, wkt TEXT)"))
    DBI::dbAppendTable(con, "tmp_ampliar_nivel", lote)

    DBI::dbExecute(con, sprintf(paste(
      "INSERT INTO geoloc (geoloc_id, geometry)",
      "SELECT s.codigo::bigint,",
      "ST_SimplifyPreserveTopology(ST_GeomFromText(s.wkt, 4326), %s)",
      "FROM tmp_ampliar_nivel s",
      "WHERE NOT EXISTS (SELECT 1 FROM geoloc g",
      "WHERE g.geoloc_id = s.codigo::bigint)"),
      format(simplificar, scientific = FALSE)))

    DBI::dbExecute(con, sprintf(paste(
      "INSERT INTO local (local_id, geoloc_id, local_name, nivel_tipo)",
      "SELECT (SELECT coalesce(max(local_id), %d) FROM local",
      "        WHERE local_id >= %d AND local_id <= %d)",
      "       + row_number() OVER (ORDER BY s.codigo),",
      "       s.codigo::bigint,",
      "       coalesce(NULLIF(s.nome, ''), s.codigo), '%s'",
      "FROM tmp_ampliar_nivel s",
      "WHERE NOT EXISTS (SELECT 1 FROM local l",
      "WHERE l.geoloc_id = s.codigo::bigint)"),
      bloco$bloco_inicio - 1L, bloco$bloco_inicio,
      bloco$bloco_fim, tipo))

    inseridos <- DBI::dbGetQuery(con, paste(
      "SELECT l.geoloc_id::text AS codigo, l.local_id, l.local_name",
      "FROM local l JOIN tmp_ampliar_nivel s",
      "ON l.geoloc_id = s.codigo::bigint AND l.nivel_tipo =", 
      DBI::dbQuoteString(con, tipo)))
    DBI::dbExecute(con, "DROP TABLE tmp_ampliar_nivel")
    DBI::dbCommit(con)
  }, error = function(e) {
    try(DBI::dbRollback(con), silent = TRUE)
    try(DBI::dbExecute(con, "DROP TABLE IF EXISTS tmp_ampliar_nivel"),
        silent = TRUE)
    stop("ampliar_nivel_territorial(", tipo, ") falhou: ",
         conditionMessage(e))
  })

  message("ampliar_nivel_territorial: ", tipo, " — ",
          nrow(inseridos), " localidades no DW (",
          length(unique(codigos)) - nrow(inseridos), " ja existentes)")

  if (refrescar) {
    DBI::dbExecute(con, "refresh materialized view named_datavalues;")
    DBI::dbExecute(con, "refresh materialized view geonamed_datavalues;")
  }
  invisible(inseridos)
}
