#' upload_tsebr submodule - UI Function
#'
#' @description Submodule to add data from the TSE open data
#' portal via the {tsebr} package (CKAN discovery + CDN download
#' with SHA-512 verification). Familias disponiveis: resultados
#' nominais e detalhe de secao (agregados ao municipio), prestacao
#' de contas (totais por UF) e candidaturas (export CSV de
#' referencia, sem gravacao no DW). Perfis do eleitorado por secao
#' ficam no pacote (tsebr::tse_perfis_secao) ate o DW suportar
#' niveis submunicipais.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList selectizeInput uiOutput

# Anos TSE habilitados no painel (ATE SEGUNDA ORDEM): restrito aos
# pleitos com banco pre-carregado via tsesqlr — o tsedb cobre 2022 e
# 2026. Amplie este vetor (e reabra o seletor) quando novos anos
# entrarem no banco.
tse_anos_painel <- c(2022L, 2026L)

upload_tsebr_ui <- function(id, parent_session) {
  ns <- shiny::NS(id)
  nsp <- parent_session$ns
  tagList(
    shiny::selectizeInput(
      ns("tsefam"), "Família de dados",
      choices = c(
        "votação nominal (votos por município)" = "resultados_nominais",
        "detalhe da votação (aptos/abstenções/nulos/brancos por município)" =
          "resultados_detalhe",
        "prestação de contas (totais por UF)" = "prestacao",
        "candidaturas (referência, só CSV)" = "candidaturas"),
      selected = "resultados_detalhe", multiple = FALSE),
    shiny::selectizeInput(ns("tseano"), "Ano eleitoral",
                          choices = c(
                            "Todos os anos (2022 e 2026)" = "todos",
                            rev(tse_anos_painel)),
                          selected = 2022, multiple = FALSE),
    shiny::selectizeInput(ns("tseuf"), "UF",
                          choices = c("AC", "AL", "AM", "AP", "BA", "CE",
                                      "DF", "ES", "GO", "MA", "MG", "MS",
                                      "MT", "PA", "PB", "PE", "PI", "PR",
                                      "RJ", "RN", "RO", "RR", "RS", "SC",
                                      "SE", "SP", "TO", "all"),
                          selected = "DF", multiple = FALSE),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] == 'resultados_nominais'",
                          ns("tsefam")),
      shiny::textInput(ns("tsecargo"), "Cargo (regex)",
                       value = "PRESIDENTE", width = "200px"),
      shiny::textInput(ns("tsenrvotavel"), "Nº do votável (opcional)",
                       value = "", width = "120px")),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] == 'resultados_detalhe'",
                          ns("tsefam")),
      shiny::selectizeInput(ns("tsemetrica"), "Métrica",
                            choices = c("aptos", "comparecimento",
                                        "abstencoes", "votos_nulos",
                                        "votos_brancos"),
                            selected = "abstencoes", multiple = FALSE)),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] == 'prestacao'", ns("tsefam")),
      shiny::selectizeInput(ns("tsetipo"), "Tipo",
                            choices = c("receitas", "despesas"),
                            selected = "receitas", multiple = FALSE)),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] == 'candidaturas'", ns("tsefam")),
      shiny::textInput(ns("tsecargoref"), "Cargo (regex, opcional)",
                       value = "", width = "200px")),
    shiny::actionButton(ns("buscatsebr"), "Obter tabela", disabled = TRUE),
    shiny::textInput(ns("urlapi"), label = "api-url"),
    shiny::textInput(nsp("upload_file"), label = "chamada")
  )
}

#' upload_tsebr Server Functions
#'
#' @noRd
upload_tsebr_server <- function(id, parent_session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    nsp <- parent_session$ns

    observe({
      ok <- !is.null(input$tsefam) && !is.null(input$tseano) &&
        !is.null(input$tseuf)
      if (ok) shinyjs::enable("buscatsebr") else shinyjs::disable("buscatsebr")
    })

    observe({
      shiny::req(input$buscatsebr, input$tsefam, input$tseano, input$tseuf)
      fonte <- resolver_fonte_tse(input$tsefam, input$tseano, input$tseuf)
      chamada <- gerar_call_tsebr(
        familia = input$tsefam, ano = input$tseano, uf = input$tseuf,
        fonte = fonte,
        cargo = if (identical(input$tsefam, "candidaturas")) {
          if (is.null(input$tsecargoref) || !nzchar(input$tsecargoref)) NULL
          else input$tsecargoref
        } else if (is.null(input$tsecargo) || !nzchar(input$tsecargo)) NULL
        else input$tsecargo,
        nr_votavel = if (is.null(input$tsenrvotavel) ||
                         !nzchar(input$tsenrvotavel)) NULL
                    else input$tsenrvotavel,
        metrica = input$tsemetrica, tipo = input$tsetipo)
      shiny::updateTextInput(session = session, "urlapi",
                             value = if (identical(fonte, "tsesqlr"))
                               "banco tsedb via tsesqlr (sem download)" else
                                 "CKAN/CDN do TSE via tsebr")
      shiny::updateTextInput(session = parent_session, "upload_file",
                             value = chamada)
    })
  })
}

#' Decide a origem dos dados TSE: banco pré-carregado ou download
#'
#' Política (duas camadas de cache): se o tsesqlr está instalado, o
#' banco responde e TODOS os anos pedidos do escopo já estão
#' carregados em `cargas`, a consulta vai direto ao banco tsedb
#' (instantânea, sem download); caso contrário cai no download do
#' CKAN/CDN via tsebr. Famílias sem cobertura no banco (detalhe,
#' prestação) sempre baixam.
#'
#' @param familia Familia do submódulo (`resultados_nominais`,
#'   `candidaturas`, ...)
#' @param ano Ano do seletor (valor, vetor ou "todos")
#' @param uf Sigla da UF ou "all"
#' @return "tsesqlr" ou "tsebr"
#' @noRd
resolver_fonte_tse <- function(familia, ano, uf) {
  tipo <- switch(familia,
                 resultados_nominais = "resultados",
                 candidaturas = "candidatos",
                 NULL)
  if (is.null(tipo)) return("tsebr")
  if (!requireNamespace("tsesqlr", quietly = TRUE)) return("tsebr")
  anos <- if (is.null(ano) || identical(ano, "todos")) tse_anos_painel else
    sort(unique(as.integer(ano)))
  # versao antiga do tsesqlr (sem tsesqlr_disponivel) ou banco fora do
  # ar: cai no download sem quebrar o modulo
  ok <- tryCatch(
    tsesqlr::tsesqlr_disponivel(tipo, anos, uf),
    error = \(e) FALSE)
  if (!isTRUE(ok)) return("tsebr")
  "tsesqlr"
}

#' Gera a call string do submódulo tsebr (função pura, testável
#' offline): primeira linha é o marcador de família que o ramo do
#' selected_files consome; o resto é código R visível/editável no
#' painel, no mesmo contrato dos demais submódulos.
#'
#' @param fonte "tsebr" (download CKAN/CDN; default) ou "tsesqlr"
#'   (banco pré-carregado; decidido por resolver_fonte_tse())
#' @noRd
gerar_call_tsebr <- function(familia, ano, uf, cargo = NULL,
                             nr_votavel = NULL, metrica = NULL,
                             tipo = NULL, fonte = "tsebr") {
  # "todos" (ou NULL) -> todos os anos HABILITADOS no painel (ate
  # segunda ordem, 2022 e 2026 — o tsedb pre-carregado via tsesqlr
  # cobre apenas esses)
  anos <- if (is.null(ano) || identical(ano, "todos")) tse_anos_painel else
    sort(unique(as.integer(ano)))
  ano_param <- paste0("c(", paste(anos, collapse = ", "), ")")
  ano_mapa <- max(anos)
  uf <- if (identical(tolower(uf), "all")) "all" else toupper(uf)
  mapa_arg <- if (identical(fonte, "tsesqlr"))
    paste0(", mapa=tsebr::tse_mapa_municipios(", ano_mapa, ", '", uf, "')") else ""
  if (identical(familia, "resultados_nominais")) {
    corpo <- if (identical(fonte, "tsesqlr"))
      paste0("tsesqlr::tsesqlr_resultados_municipio(ano = ", ano_param,
              ", uf='", uf, "'",
              if (!is.null(cargo))
                paste0(", cargo=", deparse(cargo)) else "",
              if (!is.null(nr_votavel))
                paste0(", nr_votavel=", deparse(nr_votavel)) else "",
              mapa_arg, ")") else
      paste0("tsebr::tse_resultados_municipio(ano = ", ano_param,
              ", uf='", uf, "'",
              if (!is.null(cargo))
                paste0(", cargo=", deparse(cargo)) else "",
              if (!is.null(nr_votavel))
                paste0(", nr_votavel=", deparse(nr_votavel)) else "",
              ")")
  } else if (identical(familia, "resultados_detalhe")) {
    corpo <- paste0("tsebr::tse_detalhe_municipio(ano = ", ano_param,
                    ", uf='", uf, "', metrica='",
                    metrica %||% "abstencoes", "')")
  } else if (identical(familia, "prestacao")) {
    corpo <- paste0("tsebr::tse_prestacao_uf(ano = ", ano_param,
                    ", tipo='", tipo %||% "receitas", "')")
  } else if (identical(familia, "candidaturas")) {
    corpo <- if (identical(fonte, "tsesqlr"))
      paste0("tsesqlr::tsesqlr_candidatos(ano = ", ano_param,
              ", uf='", uf, "'",
              if (!is.null(cargo))
                paste0(", cargo=", deparse(cargo)) else "",
              ")") else
      paste0("tsebr::tse_candidaturas(ano = ", ano_param,
              ", uf='", uf, "'",
              if (!is.null(cargo))
                paste0(", cargo=", deparse(cargo)) else "",
              ")")
  } else {
    stop("gerar_call_tsebr: familia desconhecida: ", familia)
  }
  # marcador e codigo na MESMA linha, separados por "; ": o browser
  # remove \n do valor de um textInput, o que colava marcador e
  # codigo num comentario unico e anulava o eval
  paste0("# tsebr-familia: ", familia, "; ", corpo)
}

# coalescencia: usa o %||% ja definido em executa_atualizacao.R
# (Collate anterior); sem redefinicao aqui para nao alterar a
# semantica existente (que trata vetor vazio como nulo)

#' Garante uma linha de datasource para o TSE no DW e devolve o id
#'
#' O datasource_type 4 ("ckan") descreve a origem do tsebr; a
#' linha em `datasource` e criada sob demanda (idempotente pelo
#' nome) para os ramos de escrita do painel.
#'
#' @noRd
garantir_datasource_tse <- function() {
  condw <- DBI::dbConnect(
    RPostgres::Postgres(),
    user = Sys.getenv("user", "beep"),
    password = Sys.getenv("password", "aEd1#man@gR"),
    host = Sys.getenv("host", "127.0.0.1"),
    dbname = Sys.getenv("dbname", "beepdb"))
  on.exit(DBI::dbDisconnect(condw), add = TRUE)
  existente <- DBI::dbGetQuery(
    condw, paste0("select datasource_id from datasource where ",
                  "datasource_name = 'TSE'"))
  if (nrow(existente)) return(as.integer(existente$datasource_id[1]))
  novo <- as.integer(DBI::dbGetQuery(
    condw, "select coalesce(max(datasource_id),0) as id from datasource")$id) + 1L
  DBI::dbAppendTable(condw, "datasource", data.frame(
    datasource_id = novo,
    datasource_name = "TSE",
    datasource_desc = "Tribunal Superior Eleitoral (dados abertos, via tsebr)",
    datasource_url = "https://dadosabertos.tse.jus.br/",
    data_freq_id = 9,
    datasource_lastupdate = as.Date(NA),
    datasource_type_id = 4,
    institution_id = NA_integer_,
    officialer_id = NA_integer_,
    datasource_delay = NA_integer_))
  novo
}
