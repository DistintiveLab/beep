# Bairros derivados dos setores censitarios (roadmap F4)
#
# O bairro nao tem malha oficial nacional: a codificacao preferida e a
# DERIVADA DO CENSO (atributo de bairro nos setores/CNEFE, quando presente),
# com geometria obtida por dissolve dos setores e codigo estavel
# municipio(7d) + sequencial(4-5d). O codigo TSE de bairro, quando existir,
# chega por tabela de correspondencia (municipio, normalizacao de nome) —
# ver R/tse_auxiliares.R. O dissolve e local (sf em memoria, sem geobr);
# a gravacao no DW reusa [ampliar_nivel_territarial()] e a proveniencia vai
# para `niveis_carga` (fonte "dissolve_setores", um escopo por municipio).

#' Constroi o codigo completo de bairro a partir do atributo bruto dos
#' setores: codigo ja completo (11-12 digitos) passa direto; sufixo curto
#' (1-5 digitos) e zerado a esquerda para 4 e prefixado com o municipio
#' (prefixo 7d do codigo do setor). Valores nao numericos/vazios viram NA
#' (o setor fica fora do dissolve — nunca inferir bairro).
#' @keywords internal
.resolver_codigo_bairro <- function(bruto, mun7) {
  bruto <- normalizar_codigo_geoloc(bruto)
  fora <- is.na(bruto) | !grepl("^[0-9]+$", bruto) | !nzchar(bruto)
  bruto[fora] <- NA_character_
  larg <- ifelse(is.na(bruto), 0L, nchar(bruto))

  sufixo <- !is.na(bruto) & larg >= 1 & larg <= 5
  if (any(sufixo)) {
    if (any(!grepl("^[0-9]{7}$", mun7[sufixo]))) {
      stop("incorporar_bairros: setor sem codigo de 7+ digitos para ",
           "prefixar o sufixo de bairro — confira a coluna de codigo ",
           "do setor")
    }
    suf <- bruto[sufixo]
    curto <- nchar(suf) < 5
    suf[curto] <- substring(paste0("0000", suf[curto]),
                            nchar(suf[curto]) + 1)
    bruto[sufixo] <- paste0(mun7[sufixo], suf)
  }

  meio <- !is.na(bruto) & larg >= 6 & larg <= 10
  if (any(meio)) {
    stop("incorporar_bairros: valores de bairro com ",
         paste(sort(unique(larg[meio])), collapse = "/"),
         " digitos nao sao nem codigo completo (11-12) nem sufixo ",
         "curto (1-5) — corrija a coluna de bairro")
  }
  bruto
}

#' Dissolve os setores por codigo de bairro: uma feicao por bairro, nome =
#' primeiro nome nao-vazio do grupo. Retorna sf (code_bairro, nm_bairro,
#' geometry) com o CRS de entrada — a reprojecao para 4326 e o SQL ficam
#' com [ampliar_nivel_territarial()].
#' @keywords internal
.dissolver_bairros_setores <- function(setores, col_bairro = NULL,
                                       col_nome = NULL, col_setor = NULL) {
  stopifnot(inherits(setores, "sf"))
  if (is.null(col_bairro)) {
    cand <- grep("bairro", names(setores), value = TRUE,
                 ignore.case = TRUE)
    cand <- cand[!grepl("^nm_|nome|^name", cand, ignore.case = TRUE)]
    if (!length(cand)) {
      stop("incorporar_bairros: informe col_bairro (nenhuma coluna de ",
           "codigo de bairro em ",
           paste(names(setores), collapse = ", "), ")")
    }
    col_bairro <- cand[1]
  }
  if (is.null(col_nome)) {
    cand <- intersect(c("nm_bairro", "nome", "name", "nm_setor"),
                      names(setores))
    col_nome <- if (length(cand)) cand[1] else NA_character_
  }

  mun7 <- rep(NA_character_, nrow(setores))
  bruto <- normalizar_codigo_geoloc(setores[[col_bairro]])
  curto <- !is.na(bruto) & grepl("^[0-9]+$", bruto) &
    nchar(bruto) >= 1 & nchar(bruto) <= 5
  if (any(curto)) {
    if (is.null(col_setor)) {
      cand <- grep("setor|tract|census", names(setores),
                   value = TRUE, ignore.case = TRUE)
      if (!length(cand)) {
        stop("incorporar_bairros: informe col_setor — sufixos curtos de ",
             "bairro precisam do codigo do setor para derivar o municipio")
      }
      col_setor <- cand[1]
    }
    mun7 <- substr(normalizar_codigo_geoloc(setores[[col_setor]]), 1, 7)
  }

  codigos <- .resolver_codigo_bairro(setores[[col_bairro]], mun7)
  n_sem <- sum(is.na(codigos))
  if (n_sem) {
    message("incorporar_bairros: ", n_sem, " setor(es) sem bairro ",
            "informado — fora do dissolve")
  }
  if (all(is.na(codigos))) {
    stop("incorporar_bairros: nenhum setor com bairro informado")
  }

  nomes <- if (!is.na(col_nome) && col_nome %in% names(setores)) {
    trimws(as.character(setores[[col_nome]]))
  } else rep(NA_character_, length(codigos))
  nomes[!is.na(nomes) & !nzchar(nomes)] <- NA_character_

  geoms <- sf::st_geometry(setores)
  idx <- split(which(!is.na(codigos)), codigos[!is.na(codigos)])
  nm_bairro <- vapply(idx, function(i) {
    v <- nomes[i]
    v <- v[!is.na(v)]
    if (length(v)) v[1] else NA_character_
  }, character(1))
  geoms_b <- lapply(idx, function(i) sf::st_union(geoms[i]))

  sf::st_sf(
    data.frame(code_bairro = names(idx), nm_bairro = nm_bairro),
    geometry = sf::st_sfc(do.call(c, geoms_b),
                          crs = sf::st_crs(setores)))
}

#' Incorpora bairros derivados dos setores censitarios
#'
#' Dissolve os setores por bairro (codigo derivado do Censo: municipio
#' 7 digitos + sequencial 4-5; codigos completos de 11-12 digitos tambem
#' sao aceitos como-is) e grava cada bairro com
#' [ampliar_nivel_territarial()] (tipo "bairro": `geoloc_id` de 11-12
#' digitos, `local_id` no bloco 1000000-1999999). Setores sem bairro
#' informado ficam de fora — o bairro nunca e inferido. Cargas repetidas
#' sao idempotentes por codigo e registradas em `niveis_carga` com fonte
#' "dissolve_setores" (uma linha por municipio; `ano` e apenas
#' proveniencia — com o default `NA` cada carga gera uma linha nova, pois
#' NULL nunca colide no UNIQUE; passe um `ano` fixo para atualizar a mesma
#' linha).
#'
#' @param setores sf de setores censitarios com atributo de bairro
#'   (`col_bairro`) e, quando o atributo for sufixo curto (1-5 digitos),
#'   o codigo do setor (`col_setor`, auto-detetavel) para derivar o
#'   municipio pai; CRS qualquer (reprojetado para 4326 na gravacao)
#' @param col_bairro,col_nome,col_setor nomes das colunas de bairro
#'   (codigo), nome e codigo de setor no sf; defaults por auto-deteccao
#' @param con conexao DBI com o DW; default abre o beepdb local
#' @param simplificar dTolerance (graus) da simplificacao no SQL
#' @param refrescar atualizar as matviews named/geonamed_datavalues ao fim?
#'   Custa minutos em DW grande; ETL em lote prefere refrescar uma unica vez
#' @param ano ano de referencia do atributo de bairro (proveniencia em
#'   `niveis_carga`; default NA — ver nota acima)
#' @return invisivel data.frame (escopo, n_localidades) com o resumo da
#'   carga por municipio — o mesmo registro vai para `niveis_carga`
#' @export
incorporar_bairros <- function(setores, col_bairro = NULL, col_nome = NULL,
                               col_setor = NULL, con = NULL,
                               simplificar = 0.001, refrescar = FALSE,
                               ano = NA_integer_) {
  bairros <- .dissolver_bairros_setores(setores, col_bairro = col_bairro,
                                        col_nome = col_nome,
                                        col_setor = col_setor)

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

  message("incorporar_bairros: ", nrow(bairros), " bairros dissolvidos, ",
          "incorporando...")
  inseridos <- ampliar_nivel_territorial(
    bairros, "bairro", col_codigo = "code_bairro",
    col_nome = "nm_bairro", con = con, simplificar = simplificar)

  tb <- table(substr(inseridos$codigo, 1, 7))
  resumo <- data.frame(escopo = names(tb),
                       n_localidades = as.integer(tb))
  for (i in seq_len(nrow(resumo))) {
    .registrar_carga_nivel(con, "bairro", "dissolve_setores",
                           resumo$escopo[i], ano,
                           resumo$n_localidades[i])
  }

  if (refrescar) {
    DBI::dbExecute(con, "refresh materialized view named_datavalues;")
    DBI::dbExecute(con, "refresh materialized view geonamed_datavalues;")
  }
  invisible(resumo)
}
