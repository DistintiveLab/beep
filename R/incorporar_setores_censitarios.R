# Carregadores das malhas submunicipais do IBGE via geobr (roadmap F2)
#
# Setores censitarios e areas de ponderacao sao niveis "oficiais": o codigo
# longo (15-16d setor, 13d AP) ja identifica o pai (municipio = prefixo 7d),
# por isso nao ganham vinculo em recortes_geograficos — a matview e uma
# linha por municipio de proposito e o contexto geografico do setor e o do
# pai. A maquina generica de insercao e [ampliar_nivel_territorial()]; estes
# wrappers cuidam do download (geobr), do particionamento por UF/municipio
# e do registro de proveniencia em `niveis_carga` (o que foi carregado, de
# onde, quando — insumo para remocao/atualizacao seletiva).

#' Valida o parametro `ufs` dos carregadores de niveis: "all", codigos de
#' UF (2 digitos) ou de municipio (7 digitos)
#' @keywords internal
.validar_ufs_niveis <- function(ufs) {
  escopos <- if (identical(ufs, "all")) "all" else as.character(ufs)
  if (anyNA(escopos) || !length(escopos) ||
      !all(escopos == "all" | grepl("^[0-9]{2}$|^[0-9]{7}$", escopos))) {
    stop("ufs invalido: use \"all\", codigos de UF (2 digitos) ou de ",
         "municipio IBGE (7 digitos); recebido: ",
         paste(utils::head(escopos, 5), collapse = ", "))
  }
  unique(escopos)
}

#' Registra/atualiza uma carga de nivel submunicipal na tabela de
#' proveniencia `niveis_carga` (criada por preparar_niveis_submunicipais)
#' @keywords internal
.registrar_carga_nivel <- function(con, tipo, fonte, escopo, ano, n) {
  DBI::dbExecute(con, paste(
    "INSERT INTO niveis_carga",
    "(nivel_tipo, fonte, escopo, ano, n_localidades)",
    "VALUES ($1, $2, $3, $4, $5)",
    "ON CONFLICT (nivel_tipo, fonte, escopo, ano) DO UPDATE SET",
    "n_localidades = EXCLUDED.n_localidades,",
    "carregado_em = now()"),
    params = list(tipo, fonte, as.character(escopo)[1],
                  as.integer(ano)[1], as.integer(n)))
}

#' Incorpora a malha de setores censitarios de UFs/municipios
#'
#' Baixa a malha do Censo via [geobr::read_census_tract()] e insere cada
#' setor com [ampliar_nivel_territorial()] (tipo "setor": `geoloc_id` =
#' codigo do setor em 15-16 digitos, `local_id` no bloco 100000-999999,
#' `nivel_tipo = "setor"`; o municipio pai e o prefixo 7d do codigo, sem
#' vinculo em `recortes_geograficos`). Cargas repetidas sao idempotentes
#' por codigo e ficam registradas em `niveis_carga`.
#'
#' @param con conexao DBI com o DW; default abre o beepdb local
#' @param ufs `"all"` ou vetor de codigos de UF (2 digitos) ou municipio
#'   IBGE (7 digitos) — a malha nacional completa e uma operacao de
#'   minutos-horas e ~GB de geometria; o uso comum e por estado ou municipio
#' @param ano Censo de referencia: 2010 (zone `"urban"`/`"rural"`/`"all"`)
#'   ou 2022, quando a malha publicada/geobr disponivel nao exigir zona
#' @param zone zona dos setores no Censo 2010 (default `"all"`)
#' @param simplificar dTolerance (graus) da simplificacao no SQL
#' @param refrescar atualizar as matviews named/geonamed_datavalues ao fim?
#'   Custa minutos em DW grande; ETL em lote prefere refrescar uma unica vez
#' @return invisivel data.frame (escopo, n_localidades) com o resumo da
#'   carga — o mesmo registro vai para a tabela `niveis_carga`
#' @export
incorporar_setores_censitarios <- function(con = NULL, ufs = "all",
                                           ano = 2022, zone = "all",
                                           simplificar = 0.001,
                                           refrescar = FALSE) {
  escopos <- .validar_ufs_niveis(ufs)
  if (!requireNamespace("geobr", quietly = TRUE)) {
    stop("incorporar_setores_censitarios requer o pacote geobr ",
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
    args <- list(code_tract = esc, year = as.integer(ano),
                 simplified = TRUE, showProgress = TRUE)
    if (ano == 2010) args$zone <- zone
    malha <- tryCatch(do.call(geobr::read_census_tract, args),
                      error = function(e) NULL)
    if (is.null(malha) || !inherits(malha, "sf") || !nrow(malha)) {
      stop("incorporar_setores_censitarios: geobr nao retornou a malha de ",
           "setores para '", esc, "' (ano ", ano,
           ") — sem rede, ou o geobr instalado nao publica esse ano;",
           if (ano != 2010) " tente ano = 2010, cuja malha e garantida" else "",
           "; confira tambem o parametro zone")
    }
    message("incorporar_setores_censitarios: '", esc, "' — ",
            nrow(malha), " setores baixados, incorporando...")
    inseridos <- ampliar_nivel_territorial(
      malha, "setor", col_codigo = "code_tract", con = con,
      simplificar = simplificar)
    .registrar_carga_nivel(con, "setor", "geobr/setores_censitarios",
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
