#' upload_pdadr submodule - UI/Server
#'
#' @description Submodulo para inserir indicadores da PDAD-A 2024
#' (IPE/DF) no DW via pacote pdadr. O call string baixa os
#' microdados com pdadr::get_pdad(), troca codigos reservados por
#' NA (limpar_reservados), deriva a coluna local a partir da tabela
#' de localidades do pdadr e devolve estimativas pre-agregadas por
#' localidade via pdadr::estimar(); o reshape para long (local,
#' periodo 31/12, valor) fica em pdad_series_long(). Nivel
#' municipio usa codigos IBGE de 7 digitos; subdistrito (RA do DF)
#' usa os de 11 digitos e exige incorporar_subdistritos() no DW
#' alvo; localidades sem subdistrito mapeado (Arapoanga, Agua
#' Quente, Area Rural) ficam de fora da estimativa.
#'
#' @param id,parent_session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList

upload_pdadr_ui <- function(id, parent_session) {
  ns <- shiny::NS(id)
  nsp <- parent_session$ns
  tagList(
    shiny::selectizeInput(
      ns("pdadbase"), "Base",
      choices = c("domicílios" = "domicilios",
                  "moradores" = "moradores"),
      selected = "domicilios", multiple = FALSE),
    shiny::selectizeInput(ns("pdadvar"), "Variáveis (filtre)",
                          choices = character(0), multiple = TRUE,
                          options = list(placeholder =
                                           "carregando dicionário...")),
    shiny::selectizeInput(
      ns("pdadtipo"), "Estatística",
      choices = c("total ponderado" = "total",
                  "média ponderada" = "media",
                  "proporção ponderada" = "proporcao"),
      selected = "total", multiple = FALSE),
    shiny::selectizeInput(
      ns("pdadnivel"), "Nível territorial",
      choices = c("município (código 7 dígitos)" = "municipio",
                  "Região Administrativa / subdistrito (DF, 11 dígitos)" =
                    "subdistrito"),
      selected = "municipio", multiple = FALSE),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] == 'subdistrito'", ns("pdadnivel")),
      shiny::helpText("O nível subdistrito grava nos blocos submunicipais ",
                      "do DW e exige incorporar_subdistritos() já rodado ",
                      "no banco alvo. As localidades sem subdistrito ",
                      "mapeado (Arapoanga, Água Quente e Área Rural) ",
                      "ficam de fora da estimativa.")),
    shiny::actionButton(ns("buscapdad"), "Obter tabela", disabled = TRUE),
    shiny::textInput(ns("urlapi"), label = "api-url"),
    shiny::textInput(nsp("upload_file"), label = "chamada")
  )
}

#' @noRd
upload_pdadr_server <- function(id, parent_session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    nsp <- parent_session$ns

    # dicionario do pdadr vem empacotado (sem rede); falha deixa o
    # select vazio com aviso, sem derrubar o app
    observe({
      escolhas <- tryCatch(
        pdad_variaveis_choices(input$pdadbase),
        error = \(e) setNames("", "dicionário indisponível - instale pdadr"))
      shiny::updateSelectizeInput(session, "pdadvar", choices = escolhas,
                                  server = TRUE, selected = character(0))
    })

    observe({
      ok <- length(input$pdadvar) > 0 && !is.null(input$pdadbase) &&
        !is.null(input$pdadtipo) && !is.null(input$pdadnivel)
      if (ok) shinyjs::enable("buscapdad") else shinyjs::disable("buscapdad")
    })

    observe({
      shiny::req(input$buscapdad, input$pdadvar, input$pdadbase,
                 input$pdadtipo, input$pdadnivel)
      chamada <- gerar_call_pdad(
        base = input$pdadbase,
        variaveis = input$pdadvar,
        tipo = input$pdadtipo,
        nivel = input$pdadnivel)
      shiny::updateTextInput(session = session, "urlapi",
                             value = "IPE/DF (microdados via pdadr)")
      shiny::updateTextInput(session = parent_session, "upload_file",
                             value = chamada)
    })
  })
}

#' Gera a call string do submodulo pdad (pura, testavel offline).
#' Sem marcador: o branch 16 do selected_files sabe que e PDAD
#' (padrao sidra). O codigo devolve lista nomeada variavel ->
#' estimativa por localidade. Deve ser single-line (o browser
#' remove \n do valor de um textInput; ver gerar_call_censo).
#'
#' @noRd
gerar_call_pdad <- function(base, variaveis, tipo, nivel) {
  base <- match.arg(as.character(base), c("domicilios", "moradores"))
  tipo <- match.arg(as.character(tipo), c("media", "total", "proporcao"))
  nivel <- match.arg(as.character(nivel), c("municipio", "subdistrito"))
  variaveis <- as.character(variaveis)
  # defesa: rotulo "A01npessoas - descricao" vindo de um selectize
  # antigo vira so o codigo
  variaveis <- sub("\\s+-\\s+.*$", "", variaveis)
  if (!length(variaveis) || !all(nzchar(variaveis)))
    stop("gerar_call_pdad: nenhuma variavel")
  vec <- deparse(variaveis)
  chave <- if (identical(nivel, "municipio")) "cod_ibge_municipio"
    else "cod_ibge_subdistrito"
  # subdistrito: localidades sem codigo IBGE de 11 digitos
  # (Arapoanga, Agua Quente, Area Rural) nao tem para onde cair e
  # saem da amostra antes de estimar
  filtro_na <- if (identical(nivel, "subdistrito"))
    'b <- b[!is.na(b$local), ]; ' else ""
  paste0(
    '{b <- pdadr::limpar_reservados(pdadr::get_pdad("', base, '")); ',
    'l <- pdadr::localidades(); ',
    'b$local <- l$', chave, '[match(b$localidade, l$valor)]; ',
    filtro_na,
    'sapply(', vec, ', function(v) pdadr::estimar(b, variavel = v, ',
    'tipo = "', tipo, '", por = "local"), simplify = FALSE)}')
}

#' Converte as estimativas do call string pdad em series long
#' (local numerico, periodo 31/12 do ano de referencia, valor =
#' estimativa), uma por variavel. Proporcoes qualitativas trazem a
#' coluna nivel (multiplas linhas por grupo) e sao abertas em uma
#' serie por nivel (nome var_nivel). Series sem nenhuma linha
#' valida (so NA) sao descartadas.
#'
#' @noRd
pdad_series_long <- function(estimativas, ano = 2024) {
  if (!inherits(estimativas, "list")) estimativas <- list(pdad = estimativas)
  if (is.null(names(estimativas)))
    names(estimativas) <- as.character(seq_along(estimativas))
  serie <- \(df) {
    ok <- which(!is.na(df$local) & !is.na(df$estimativa))
    data.frame(local = as.numeric(as.character(df$local[ok])),
               periodo = as.Date(rep(sprintf("%d-12-31", ano),
                                     length(ok))),
               valor = df$estimativa[ok])
  }
  saida <- list()
  for (nm in names(estimativas)) {
    tb <- as.data.frame(estimativas[[nm]])
    if (!is.data.frame(tb) || nrow(tb) == 0L ||
        !all(c("local", "estimativa") %in% names(tb))) next
    if ("nivel" %in% names(tb)) {
      niveis <- unique(as.character(tb$nivel))
      niveis <- niveis[!is.na(niveis)]
      for (g in niveis) {
        tg <- tb[which(as.character(tb$nivel) == g), , drop = FALSE]
        saida[[paste0(nm, "_", gsub("[^A-Za-z0-9]+", "", g))]] <- serie(tg)
      }
    } else {
      saida[[nm]] <- serie(tb)
    }
  }
  Filter(\(x) nrow(x) > 0, saida)
}

#' Rotulos do seletor de variaveis do pdadr (valor = nome da
#' coluna, rotulo = "coluna - descricao"). Colunas administrativas
#' (chaves da amostra, pesos e localidade) ficam de fora.
#'
#' @noRd
pdad_variaveis_choices <- function(base = "domicilios") {
  dic <- pdadr::dicionario(base)
  cols <- unique(dic[, c("coluna", "descricao_coluna")])
  cols <- cols[!is.na(cols$coluna) & nzchar(cols$coluna), , drop = FALSE]
  admin <- c("starttime", "A01nficha", "A01uf", "localidade",
             "setor_distrito", "morador_id", "index", "peso_dom",
             "peso_mor")
  cols <- cols[!cols$coluna %in% admin, , drop = FALSE]
  rotulos <- vapply(seq_len(nrow(cols)), \(i) {
    desc <- cols$descricao_coluna[i]
    if (is.na(desc) || !nzchar(desc)) cols$coluna[i]
    else paste0(cols$coluna[i], " - ", desc)
  }, character(1))
  setNames(as.character(cols$coluna), rotulos)
}

#' Garante linha de datasource PDAD no DW (idempotente pelo nome) e
#' devolve o id. datasource_type 1 = "url fixo" (os microdados sao
#' arquivos diretos em pdad.ipe.df.gov.br).
#'
#' @noRd
garantir_datasource_pdad <- function() {
  condw <- DBI::dbConnect(
    RPostgres::Postgres(),
    user = Sys.getenv("user", "beep"),
    password = Sys.getenv("password", "aEd1#man@gR"),
    host = Sys.getenv("host", "127.0.0.1"),
    dbname = Sys.getenv("dbname", "beepdb"))
  on.exit(DBI::dbDisconnect(condw), add = TRUE)
  existente <- DBI::dbGetQuery(
    condw, paste0("select datasource_id from datasource where ",
                  "datasource_name = 'PDAD'"))
  if (nrow(existente)) return(as.integer(existente$datasource_id[1]))
  novo <- as.integer(DBI::dbGetQuery(
    condw, "select coalesce(max(datasource_id),0) as id from datasource")$id) + 1L
  DBI::dbAppendTable(condw, "datasource", data.frame(
    datasource_id = novo,
    datasource_name = "PDAD",
    datasource_desc = "Pesquisa Distrital por Amostra de Domicílios PDAD-A 2024 (IPE/DF, pacote pdadr)",
    datasource_url = "https://pdad.ipe.df.gov.br/",
    data_freq_id = 9,
    datasource_lastupdate = as.Date(NA),
    datasource_type_id = 1,
    institution_id = NA_integer_,
    officialer_id = NA_integer_,
    datasource_delay = NA_integer_))
  novo
}
