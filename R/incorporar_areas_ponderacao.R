# Areas de ponderacao do Censo 2010 (geobr read_weighting_area) — nivel
# derivado dos setores com codigo proprio (13 digitos: municipio 7d +
# sequencial). O wrapper espelha incorporar_setores_censitarios: baixa,
# incorpora via ampliar_nivel_territorial(tipo="area_ponderacao") e registra
# a carga em niveis_carga. (Para o Censo 2022 a AP nao foi divulgada como
# malha oficial; quando for, o mesmo caminho serve.)

#' Incorpora a malha de areas de ponderacao de UFs/municipios
#'
#' Baixa via [geobr::read_weighting_area()] (Censo 2010) e insere cada area
#' com [ampliar_nivel_territorial()] (tipo "area_ponderacao": `geoloc_id` =
#' codigo de 13 digitos, `local_id` no bloco 2000000-2999999). O municipio
#' pai e o prefixo 7d do codigo; sem vinculo em `recortes_geograficos`.
#' Cargas repetidas sao idempotentes por codigo e ficam registradas em
#' `niveis_carga`.
#'
#' @param con conexao DBI com o DW; default abre o beepdb local
#' @param ufs `"all"` ou vetor de codigos de UF (2 digitos) ou municipio
#'   IBGE (7 digitos) para carga parcial
#' @param ano Censo de referencia (2010 — unico com malha de AP publicada)
#' @param simplificar dTolerance (graus) da simplificacao no SQL
#' @param refrescar atualizar as matviews named/geonamed_datavalues ao fim?
#' @return invisivel data.frame (escopo, n_localidades) com o resumo da
#'   carga — o mesmo registro vai para a tabela `niveis_carga`
#' @export
incorporar_areas_ponderacao <- function(con = NULL, ufs = "all",
                                        ano = 2010, simplificar = 0.001,
                                        refrescar = FALSE) {
  escopos <- .validar_ufs_niveis(ufs)
  if (!requireNamespace("geobr", quietly = TRUE)) {
    stop("incorporar_areas_ponderacao requer o pacote geobr ",
         "(install.packages('geobr'))")
  }

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

  resumo <- data.frame(escopo = character(0), n_localidades = integer(0))
  for (esc in escopos) {
    malha <- tryCatch(
      geobr::read_weighting_area(code_weighting = esc, year = as.integer(ano),
                                 simplified = TRUE, showProgress = TRUE),
      error = function(e) NULL)
    if (is.null(malha) || !inherits(malha, "sf") || !nrow(malha)) {
      stop("incorporar_areas_ponderacao: geobr nao retornou a malha de ",
           "areas de ponderacao para '", esc, "' (ano ", ano,
           ") — sem rede, ou o geobr instalado nao publica esse ano;",
           if (ano != 2010) " a malha oficial de AP e a do Censo 2010" else "",
           "; use ano = 2010")
    }
    message("incorporar_areas_ponderacao: '", esc, "' — ",
            nrow(malha), " areas baixadas, incorporando...")
    inseridos <- ampliar_nivel_territorial(
      malha, "area_ponderacao", col_codigo = "code_weighting", con = con,
      simplificar = simplificar)
    .registrar_carga_nivel(con, "area_ponderacao", "geobr/areas_ponderacao",
                           esc, ano, nrow(inseridos))
    resumo <- rbind(resumo, data.frame(
      escopo = esc, n_localidades = nrow(inseridos)))
  }

  if (refrescar) {
    DBI::dbExecute(con, "refresh materialized view named_datavalues;")
    DBI::dbExecute(con, "refresh materialized view geonamed_datavalues;")
  }
  invisible(resumo)
}
