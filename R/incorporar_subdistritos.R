# Subdistritos derivados dos setores censitarios (roadmap P2)
#
# O subdistrito (distrito administrativo; no DF, Regiao Administrativa) e o
# recorte submunicipal OFICIAL que sempre tem geometria no Censo — o atributo
# de bairro dos setores vem vazio em municipios como Brasilia, mas o
# code_subdistrict esta sempre presente. O dissolve segue o padrao de
# [incorporar_bairros()]: sf em memoria, gravacao via
# [ampliar_nivel_territarial()] (tipo "subdistrito": `geoloc_id` de 11
# digitos — municipio 7d + sequencial 4d —, `local_id` no bloco
# 3000000-3999999) e proveniencia em `niveis_carga` (fonte
# "dissolve_setores"). A largura 11 e dividida com o bairro: quem decide o
# nivel e o `nivel_tipo` gravado em `local`, nunca a largura.

#' Constroi o codigo completo de subdistrito a partir do atributo bruto dos
#' setores: codigo ja completo (11 digitos) passa direto; sufixo curto
#' (1-4 digitos) e zerado a esquerda para 4 e prefixado com o municipio
#' (prefixo 7d do codigo do setor). Valores nao numericos/vazios viram NA
#' (o setor fica fora do dissolve — nunca inferir subdistrito).
#' @keywords internal
.resolver_codigo_subdistrito <- function(bruto, mun7) {
  bruto <- normalizar_codigo_geoloc(bruto)
  fora <- is.na(bruto) | !grepl("^[0-9]+$", bruto) | !nzchar(bruto)
  bruto[fora] <- NA_character_
  larg <- ifelse(is.na(bruto), 0L, nchar(bruto))

  sufixo <- !is.na(bruto) & larg >= 1 & larg <= 4
  if (any(sufixo)) {
    if (any(is.na(mun7[sufixo]) | !grepl("^[0-9]{7}$", mun7[sufixo]))) {
      stop("incorporar_subdistritos: setor sem codigo de 7+ digitos para ",
           "prefixar o sufixo de subdistrito — confira a coluna de ",
           "codigo do setor")
    }
    suf <- bruto[sufixo]
    curto <- nchar(suf) < 4
    suf[curto] <- substring(paste0("000", suf[curto]),
                            nchar(suf[curto]) + 1)
    bruto[sufixo] <- paste0(mun7[sufixo], suf)
  }

  meio <- !is.na(bruto) & larg >= 5 & larg <= 10
  if (any(meio)) {
    stop("incorporar_subdistritos: valores de subdistrito com ",
         paste(sort(unique(larg[meio])), collapse = "/"),
         " digitos nao sao nem codigo completo (11) nem sufixo ",
         "curto (1-4) — corrija a coluna de subdistrito")
  }
  bruto
}

#' Dissolve os setores por codigo de subdistrito: uma feicao por
#' subdistrito, nome = primeiro nome nao-vazio do grupo. Retorna sf
#' (code_subdistrict, nm_subdistrict, geometry) com o CRS de entrada.
#' @keywords internal
.dissolver_subdistritos_setores <- function(setores, col_subdistrito = NULL,
                                            col_nome = NULL,
                                            col_setor = NULL) {
  stopifnot(inherits(setores, "sf"))
  if (is.null(col_subdistrito)) {
    cand <- grep("subdistrict|distrito", names(setores),
                 value = TRUE, ignore.case = TRUE)
    cand <- cand[!grepl("^nm_|nome|^name", cand, ignore.case = TRUE)]
    if (!length(cand)) {
      stop("incorporar_subdistritos: informe col_subdistrito (nenhuma ",
           "coluna de codigo de subdistrito em ",
           paste(names(setores), collapse = ", "), ")")
    }
    col_subdistrito <- cand[1]
  }
  if (is.null(col_nome)) {
    cand <- intersect(c("name_subdistrict", "nm_subdistrito", "nome",
                        "name", "nm_setor"),
                      names(setores))
    col_nome <- if (length(cand)) cand[1] else NA_character_
  }

  mun7 <- rep(NA_character_, nrow(setores))
  bruto <- normalizar_codigo_geoloc(setores[[col_subdistrito]])
  curto <- !is.na(bruto) & grepl("^[0-9]+$", bruto) &
    nchar(bruto) >= 1 & nchar(bruto) <= 4
  if (any(curto)) {
    if (is.null(col_setor)) {
      cand <- grep("setor|tract|census", names(setores),
                   value = TRUE, ignore.case = TRUE)
      if (!length(cand)) {
        stop("incorporar_subdistritos: informe col_setor — sufixos curtos ",
             "de subdistrito precisam do codigo do setor para derivar o ",
             "municipio")
      }
      col_setor <- cand[1]
    }
    mun7 <- substr(normalizar_codigo_geoloc(setores[[col_setor]]), 1, 7)
  }

  codigos <- .resolver_codigo_subdistrito(setores[[col_subdistrito]], mun7)
  n_sem <- sum(is.na(codigos))
  if (n_sem) {
    message("incorporar_subdistritos: ", n_sem, " setor(es) sem ",
            "subdistrito informado — fora do dissolve")
  }
  if (all(is.na(codigos))) {
    stop("incorporar_subdistritos: nenhum setor com subdistrito informado")
  }

  nomes <- if (!is.na(col_nome) && col_nome %in% names(setores)) {
    trimws(as.character(setores[[col_nome]]))
  } else rep(NA_character_, length(codigos))
  nomes[!is.na(nomes) & !nzchar(nomes)] <- NA_character_

  geoms <- sf::st_geometry(setores)
  idx <- split(which(!is.na(codigos)), codigos[!is.na(codigos)])
  nm_sub <- vapply(idx, function(i) {
    v <- nomes[i]
    v <- v[!is.na(v)]
    if (length(v)) v[1] else NA_character_
  }, character(1))
  geoms_s <- lapply(idx, function(i) sf::st_union(geoms[i]))

  sf::st_sf(
    data.frame(code_subdistrict = names(idx),
               nm_subdistrict = nm_sub),
    geometry = sf::st_sfc(do.call(c, geoms_s),
                          crs = sf::st_crs(setores)))
}

#' Incorpora subdistritos derivados dos setores censitarios
#'
#' Dissolve os setores por subdistrito (codigo do Censo: municipio 7 digitos
#' + sequencial 4; codigos completos de 11 digitos tambem sao aceitos
#' como-is) e grava cada subdistrito com [ampliar_nivel_territorial()]
#' (tipo "subdistrito": `geoloc_id` de 11 digitos, `local_id` no bloco
#' 3000000-3999999). No DF as Regioes Administrativas sao exatamente os
#' subdistritos — o recorte submunicipal com geometria oficial quando o
#' Censo nao publica atributo de bairro no municipio. Setores sem
#' subdistrito informado ficam de fora — nunca inferido. Cargas repetidas
#' sao idempotentes por codigo e registradas em `niveis_carga` com fonte
#' "dissolve_setores" (uma linha por municipio; passe um `ano` fixo para
#' atualizar a mesma linha — com o default `NA` cada carga gera linha nova).
#'
#' @param setores sf de setores censitarios com atributo de subdistrito
#'   (`col_subdistrito`, ex. `code_subdistrict` da geobr
#'   `read_census_tract()`) e, quando o atributo for sufixo curto (1-4
#'   digitos), o codigo do setor (`col_setor`, auto-detetavel) para derivar
#'   o municipio pai; CRS qualquer (reprojetado para 4326 na gravacao)
#' @param col_subdistrito,col_nome,col_setor nomes das colunas de
#'   subdistrito (codigo), nome e codigo de setor no sf; defaults por
#'   auto-deteccao
#' @param con conexao DBI com o DW; default abre o beepdb local
#' @param simplificar dTolerance (graus) da simplificacao no SQL
#' @param refrescar atualizar as matviews named/geonamed_datavalues ao fim?
#'   Custa minutos em DW grande; ETL em lote prefere refrescar uma unica vez
#' @param ano ano de referencia do atributo de subdistrito (proveniencia em
#'   `niveis_carga`; default NA — ver nota acima)
#' @return invisivel data.frame (escopo, n_localidades) com o resumo da
#'   carga por municipio — o mesmo registro vai para `niveis_carga`
#' @export
incorporar_subdistritos <- function(setores, col_subdistrito = NULL,
                                    col_nome = NULL, col_setor = NULL,
                                    con = NULL, simplificar = 0.001,
                                    refrescar = FALSE,
                                    ano = NA_integer_) {
  subs <- .dissolver_subdistritos_setores(
    setores, col_subdistrito = col_subdistrito, col_nome = col_nome,
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

  message("incorporar_subdistritos: ", nrow(subs),
          " subdistritos dissolvidos, incorporando...")
  inseridos <- ampliar_nivel_territorial(
    subs, "subdistrito", col_codigo = "code_subdistrict",
    col_nome = "nm_subdistrict", con = con, simplificar = simplificar)

  tb <- table(substr(inseridos$codigo, 1, 7))
  resumo <- data.frame(escopo = names(tb),
                       n_localidades = as.integer(tb))
  for (i in seq_len(nrow(resumo))) {
    .registrar_carga_nivel(con, "subdistrito", "dissolve_setores",
                           resumo$escopo[i], ano,
                           resumo$n_localidades[i])
  }

  if (refrescar) {
    DBI::dbExecute(con, "refresh materialized view named_datavalues;")
    DBI::dbExecute(con, "refresh materialized view geonamed_datavalues;")
  }
  invisible(resumo)
}
