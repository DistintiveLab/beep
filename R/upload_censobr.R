#' upload_censobr submodule - UI/Server
#'
#' @description Submodulo para inserir indicadores do Censo
#' IBGE no DW via pacote censoagg (ponte para o censobr).
#' Dicionarios de variaveis sao resolvidos sob demanda
#' (censoagg::censo_variaveis; snapshot lazy do censoagg ou
#' censobr ao vivo), sem download no .onLoad.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList selectizeInput uiOutput

upload_censobr_ui <- function(id, parent_session) {
  ns <- shiny::NS(id)
  nsp <- parent_session$ns
  tagList(
    shiny::selectizeInput(
      ns("censtipo"), "Origem",
      choices = c("microdados da amostra (ponderado)" = "microdados",
                  "agregados por setor censo 2022" = "tracts"),
      selected = "tracts", multiple = FALSE),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] == 'microdados'", ns("censtipo")),
      shiny::helpText("Atencao: o microdado publico de 2022 (IBGE) ",
                      "nao traz codigo de municipio nem pesos; para 2022, ",
                      "prefira os agregados por setor ou importe o acesso ",
                      "controlado (censobr::import_microdata22). Microdados ",
                      "de 2010 funcionam ponderados."),
      shiny::selectizeInput(ns("censds"), "Dataset",
                            choices = c("pessoas", "domicilios", "familias"),
                            selected = "pessoas", multiple = FALSE)),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] == 'tracts'", ns("censtipo")),
      shiny::selectizeInput(ns("censdst"), "Base de agregados",
                            choices = c("Basico", "Domicilio", "Pessoas",
                                        "Instrucao", "Morador",
                                        "DomicilioRenda"),
                            selected = "Basico", multiple = FALSE)),
    shiny::selectizeInput(ns("censvar"), "Variaveis (filtre)",
                          choices = character(0), multiple = TRUE,
                          options = list(placeholder =
                                           "carregando dicionario...")),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] == 'microdados'", ns("censtipo")),
      shiny::selectizeInput(ns("censfun"), "Funcao",
                            choices = c("soma ponderada" = "soma_pond",
                                        "media ponderada" = "media_pond",
                                        "soma" = "soma",
                                        "media" = "media"),
                            selected = "soma_pond", multiple = FALSE)),
    shiny::selectizeInput(ns("censnivel"), "Nivel territorial",
                          choices = c("município" = "municipio",
                                      "setor censitário (origem tracts)" = "setor",
                                      "Brasil" = "brasil"),
                          selected = "municipio", multiple = FALSE),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] == 'setor' && input['%s'] != 'tracts'",
                          ns("censnivel"), ns("censtipo")),
      shiny::helpText("Setor só está disponível na origem tracts; é gravado",
                      "nos blocos submunicipais do DW (requer",
                      "incorporar_setores_censitarios() rodada antes).")),
    shiny::textInput(ns("censcorte"), "Recorte (expressao R, opcional)",
                     value = "", width = "300px"),
    shiny::actionButton(ns("buscacenso"), "Obter tabela", disabled = TRUE),
    shiny::textInput(ns("urlapi"), label = "api-url"),
    shiny::textInput(nsp("upload_file"), label = "chamada")
  )
}

#' @noRd
upload_censobr_server <- function(id, parent_session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    nsp <- parent_session$ns

    # dicionario: snapshot do censoagg (lazy) ou censobr ao vivo;
    # falha deixa o select vazio com aviso, sem derrubar o app
    observe({
      tipo <- if (identical(input$censtipo, "tracts")) "tracts" else
        "microdata"
      ds_atual <- if (identical(input$censtipo, "tracts")) input$censdst
        else input$censds
      escolhas <- tryCatch({
        dic <- censoagg::censo_variaveis(2022, tipo)
        if ("dataset" %in% names(dic)) {
          # dplyr::filter descarta linhas com dataset NA (abas do xlsx
          # sem mapeamento, ex. religiao/geografia) — indexacao base-R
          # com NA as manteria como linhas all-NA
          dic <- dplyr::filter(dic, !is.na(dataset), dataset == ds_atual)
        }
        dic <- dic[!is.na(dic$variavel) & nzchar(dic$variavel), , drop = FALSE]
        dic <- dic[!is.na(dic$variavel) & nzchar(dic$variavel), , drop = FALSE]
        rotulos <- paste0(dic$variavel, " - ", dic$descricao)
        names(rotulos) <- dic$variavel
        rotulos
      }, error = \(e) {
        c("dicionario indisponivel - instale censoagg/censobr" = "")
      })
      shiny::updateSelectizeInput(session, "censvar", choices = escolhas,
                                  server = TRUE, selected = character(0))
    })

    observe({
      ok <- length(input$censvar) > 0 && !is.null(input$censds) &&
        !is.null(input$censnivel)
      if (ok) shinyjs::enable("buscacenso") else shinyjs::disable("buscacenso")
    })

    observe({
      shiny::req(input$buscacenso, input$censvar, input$censds,
                 input$censnivel)
      chamada <- gerar_call_censo(
        tipo = input$censtipo,
        dataset = if (identical(input$censtipo, "tracts")) input$censdst
        else input$censds,
        ano = 2022,
        variaveis = input$censvar, nivel = input$censnivel,
        funcao = input$censfun,
        corte = if (is.null(input$censcorte) || !nzchar(input$censcorte))
          NULL else input$censcorte)
      shiny::updateTextInput(session = session, "urlapi",
                             value = "IBGE (censobr/arrow via censoagg)")
      shiny::updateTextInput(session = parent_session, "upload_file",
                             value = chamada)
    })
  })
}

#' Gera a call string do submódulo censo (pura, testavel offline).
#' 1a linha: marcador "# censo-origem:"; o resto, codigo editavel
#' que devolve lista nomeada variavel -> long(local, periodo,
#' valor).
#'
#' @noRd
gerar_call_censo <- function(tipo, dataset, ano, variaveis, nivel,
                             funcao = NULL, corte = NULL) {
  variaveis <- as.character(variaveis)
  if (!length(variaveis)) stop("gerar_call_censo: nenhuma variavel")
  vec <- deparse(variaveis)
  if (identical(tipo, "microdados")) {
    funcao <- funcao %||% "soma_pond"
    corpo <- paste0(
      "censoagg::agregar_microdados(dataset='", dataset, "', ano=", ano,
      ", variaveis=", vec, ", nivel='", nivel, "', funcao='", funcao, "'",
      if (!is.null(corte)) paste0(", corte=", deparse(corte)) else "",
      ")")
  } else if (identical(tipo, "tracts")) {
    corpo <- paste0(
      "censoagg::agregar_setores(dataset='", dataset, "', ano=", ano,
      ", variaveis=", vec, ", nivel='", nivel, "'",
      if (!is.null(corte)) paste0(", corte=", deparse(corte)) else "",
      ")")
  } else {
    stop("gerar_call_censo: origem desconhecida: ", tipo)
  }
  paste0("# censo-origem: ", tipo, "\n", corpo)
}

#' Garante linha de datasource IBGE-Censo no DW (idempotente pelo
#' nome) e devolve o id. datasource_type 6 = "ibge_ftp".
#'
#' @noRd
garantir_datasource_censo <- function() {
  condw <- DBI::dbConnect(
    RPostgres::Postgres(),
    user = Sys.getenv("user", "beep"),
    password = Sys.getenv("password", "aEd1#man@gR"),
    host = Sys.getenv("host", "127.0.0.1"),
    dbname = Sys.getenv("dbname", "beepdb"))
  on.exit(DBI::dbDisconnect(condw), add = TRUE)
  existente <- DBI::dbGetQuery(
    condw, paste0("select datasource_id from datasource where ",
                  "datasource_name = 'IBGE Censo'"))
  if (nrow(existente)) return(as.integer(existente$datasource_id[1]))
  novo <- as.integer(DBI::dbGetQuery(
    condw, "select coalesce(max(datasource_id),0) as id from datasource")$id) + 1L
  DBI::dbAppendTable(condw, "datasource", data.frame(
    datasource_id = novo,
    datasource_name = "IBGE Censo",
    datasource_desc = "Censo Demografico IBGE (censobr, agregado via censoagg)",
    datasource_url = "https://ftp.ibge.gov.br/Censos/",
    data_freq_id = 9,
    datasource_lastupdate = as.Date(NA),
    datasource_type_id = 6,
    institution_id = NA_integer_,
    officialer_id = NA_integer_,
    datasource_delay = NA_integer_))
  novo
}
