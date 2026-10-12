# Grupo Resumo do painel: os indicadores que aparecem como cartões no
# "Resumo da região" são escolhidos aqui e gravados no DW como um
# datagroup de nome fixo (ver [beep_grupo_resumo_nome]) com vínculos em
# mdata_group. O painel lê o grupo fail-open: sem ele (ou vazio) cai nos
# compostos por eixo/objetivo ou no agrupamento por fonte.
#
# O nome do grupo precisa ser o mesmo que o painel procura
# (painel_grupo_resumo_nome em R/painel_dw.R); um teste guarda a
# consistência entre as duas constantes.

#' Nome do grupo Resumo no catálogo do DW
#' @keywords internal
beep_grupo_resumo_nome <- "Resumo"

#' Lê os membros atuais do grupo Resumo no DW
#'
#' @param con conexão aberta com o DW; por padrão abre uma com as variáveis
#'   de ambiente `user`, `password`, `host` e `dbname` (mesmos defaults de
#'   [atualizar_grupos_indicadores()])
#' @return data.frame com `mdata_id` e `orig_name` (ordem do `mdata_id`);
#'   zero linhas quando o grupo não existe ou não tem vínculos
ler_grupo_resumo <- function(con = NULL) {
  fechar <- is.null(con)
  if (fechar) {
    con <- DBI::dbConnect(RPostgres::Postgres(),
                          user = Sys.getenv("user", "beep"),
                          password = Sys.getenv("password", "aEd1#man@gR"),
                          host = Sys.getenv("host", "127.0.0.1"),
                          dbname = Sys.getenv("dbname", "beepdb"))
    on.exit(DBI::dbDisconnect(con), add = TRUE)
  }
  DBI::dbGetQuery(con, paste(
    "SELECT m.mdata_id, m.orig_name FROM mdata m",
    "JOIN mdata_group g ON g.mdata_id = m.mdata_id",
    "JOIN datagroup d ON d.datagroup_id = g.datagroup_id",
    "WHERE d.datagroup_name = 'Resumo'",
    "ORDER BY m.mdata_id"))
}

#' Plano de sincronização do grupo Resumo (função pura)
#'
#' Recebe os vínculos atuais ao grupo e os ids desejados e devolve o que
#' falta inserir e o que sobra remover, sempre restrito ao grupo Resumo.
#'
#' @param desejados integer com os mdata_id que devem pertencer ao grupo
#' @param atuais integer com os mdata_id hoje ligados ao grupo
#' @param grupo_id datagroup_id do grupo Resumo
#' @return lista com `inserir` e `remover` (integer, sem ordem garantida)
#' @keywords internal
grupo_resumo_plano <- function(desejados, atuais, grupo_id = NA_integer_) {
  desejados <- as.integer(desejados)
  desejados <- desejados[!is.na(desejados)]
  atuais <- as.integer(atuais)
  atuais <- atuais[!is.na(atuais)]
  if (!length(desejados)) desejados <- integer(0)
  if (!length(atuais)) atuais <- integer(0)
  list(inserir = setdiff(desejados, atuais),
       remover = setdiff(atuais, desejados))
}

#' Define o grupo Resumo do painel no DW
#'
#' Idempotente: garante o `datagroup` "Resumo" (criando quando falta) e
#' sincroniza os vínculos de `mdata_group` com exatamente os indicadores
#' pedidos, inserindo os que faltam e removendo os excedentes somente
#' deste grupo (vínculos de outros grupos nunca são tocados). Conjunto
#' vazio remove todos os membros e deixa o grupo declarado.
#'
#' @param mdata_ids integer (ou conversível) com os mdata_id desejados
#' @param con conexão aberta com o DW; por padrão abre uma com as variáveis
#'   de ambiente `user`, `password`, `host` e `dbname`
#' @param verbose imprime o resumo do que foi feito
#' @return invisivel, uma lista com `grupo_id`, `inserir` e `remover`
#' @export
atualizar_grupo_resumo <- function(mdata_ids = integer(0), con = NULL,
                                   verbose = TRUE) {
  fechar <- is.null(con)
  if (fechar) {
    con <- DBI::dbConnect(RPostgres::Postgres(),
                          user = Sys.getenv("user", "beep"),
                          password = Sys.getenv("password", "aEd1#man@gR"),
                          host = Sys.getenv("host", "127.0.0.1"),
                          dbname = Sys.getenv("dbname", "beepdb"))
    on.exit(DBI::dbDisconnect(con), add = TRUE)
  }
  desejados <- as.integer(mdata_ids)
  if (any(is.na(desejados)))
    stop("mdata_ids com valores nao inteiros ou NA", call. = FALSE)
  desejados <- unique(desejados)

  existentes <- DBI::dbGetQuery(con, "SELECT mdata_id FROM mdata")$mdata_id
  desconhecidos <- setdiff(desejados, existentes)
  if (length(desconhecidos))
    stop("mdata_id sem indicador no catalogo: ",
         paste(desconhecidos, collapse = ", "), call. = FALSE)

  grupo <- DBI::dbGetQuery(con, paste(
    "SELECT datagroup_id FROM datagroup",
    "WHERE datagroup_name = 'Resumo'"))
  if (!NROW(grupo)) {
    grupo_id <- as.integer(DBI::dbGetQuery(con, paste(
      "SELECT coalesce(max(datagroup_id), 0) + 1 AS id",
      "FROM datagroup"))$id)
    DBI::dbAppendTable(con, "datagroup",
                       data.frame(datagroup_id = grupo_id,
                                  datagroup_name = "Resumo",
                                  datagroup_desc = paste(
                                    "Indicadores escolhidos para o resumo",
                                    "da regiao do painel (via beep::run_app)")))
    if (verbose)
      message("grupo Resumo declarado no catalogo (datagroup_id ", grupo_id, ")")
  } else {
    grupo_id <- as.integer(grupo$datagroup_id[1])
  }

  atuais <- DBI::dbGetQuery(con, sprintf(paste(
    "SELECT g.mdata_id FROM mdata_group g",
    "WHERE g.datagroup_id = %d"), grupo_id))$mdata_id
  plano <- grupo_resumo_plano(desejados, atuais, grupo_id)

  if (length(plano$inserir))
    DBI::dbAppendTable(con, "mdata_group",
                       data.frame(mdata_id = as.integer(plano$inserir),
                                  datagroup_id = grupo_id))
  if (length(plano$remover))
    invisible(DBI::dbExecute(con, sprintf(paste(
      "DELETE FROM mdata_group",
      "WHERE datagroup_id = %d AND mdata_id IN (%s)"),
      grupo_id, paste(plano$remover, collapse = ","))))

  if (verbose)
    message(sprintf("grupo Resumo sincronizado: %d indicadores (+%d, -%d)",
                    length(desejados), length(plano$inserir),
                    length(plano$remover)))
  invisible(list(grupo_id = grupo_id, inserir = plano$inserir,
                 remover = plano$remover))
}
