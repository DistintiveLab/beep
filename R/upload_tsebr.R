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
                          choices = c(2026, 2024, 2022, 2020, 2018),
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
      chamada <- gerar_call_tsebr(
        familia = input$tsefam, ano = input$tseano, uf = input$tseuf,
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
                             value = "CKAN/CDN do TSE via tsebr")
      shiny::updateTextInput(session = parent_session, "upload_file",
                             value = chamada)
    })
  })
}

#' Gera a call string do submódulo tsebr (função pura, testável
#' offline): primeira linha é o marcador de família que o ramo do
#' selected_files consome; o resto é código R visível/editável no
#' painel, no mesmo contrato dos demais submódulos.
#'
#' @noRd
gerar_call_tsebr <- function(familia, ano, uf, cargo = NULL,
                             nr_votavel = NULL, metrica = NULL,
                             tipo = NULL) {
  ano <- as.integer(ano)
  uf <- if (identical(tolower(uf), "all")) "all" else toupper(uf)
  con_snippet <- paste0(
    "con <- DBI::dbConnect(RPostgres::Postgres(), ",
    "user=Sys.getenv('user','beep'), ",
    "password=Sys.getenv('password','aEd1#man@gR'), ",
    "host=Sys.getenv('host','127.0.0.1'), ",
    "dbname=Sys.getenv('dbname','beepdb'))\n",
    "mapa <- tsebr::tse_municipios(", ano, ", con=con, uf='", uf, "')\n",
    "DBI::dbDisconnect(con)\n")
  if (identical(familia, "resultados_nominais")) {
    corpo <- paste0(con_snippet,
                    "tsebr::tse_resultados_municipio(", ano,
                    ", uf='", uf, "'",
                    if (!is.null(cargo))
                      paste0(", cargo=", deparse(cargo)) else "",
                    if (!is.null(nr_votavel))
                      paste0(", nr_votavel=", deparse(nr_votavel)) else "",
                    ", mapa=mapa)")
  } else if (identical(familia, "resultados_detalhe")) {
    corpo <- paste0(con_snippet,
                    "tsebr::tse_detalhe_municipio(", ano,
                    ", uf='", uf, "', metrica='",
                    metrica %||% "abstencoes", "', mapa=mapa)")
  } else if (identical(familia, "prestacao")) {
    corpo <- paste0("tsebr::tse_prestacao_uf(", ano,
                    ", tipo='", tipo %||% "receitas", "')")
  } else if (identical(familia, "candidaturas")) {
    corpo <- paste0("tsebr::tse_candidaturas(", ano,
                    ", uf='", uf, "'",
                    if (!is.null(cargo))
                      paste0(", cargo=", deparse(cargo)) else "",
                    ")")
  } else {
    stop("gerar_call_tsebr: familia desconhecida: ", familia)
  }
  paste0("# tsebr-familia: ", familia, "\n", corpo)
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
