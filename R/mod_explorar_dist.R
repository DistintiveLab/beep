#' UI das distribuicoes do indicador (aba "Distribuições")
#' @keywords internal
mod_explorar_dist_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::fluidRow(
    shinydashboard::box(
      width = 12, title = "Distribuições",
      shiny::selectizeInput(
        ns("indicador"), "Indicador", choices = NULL,
        options = list(placeholder = "Selecione um indicador",
                       maxOptions = 200)),
      shiny::selectInput(ns("data"), "Data (histograma)", choices = NULL),
      shiny::checkboxInput(ns("log"), "Escala logarítmica (caudas pesadas)",
                           value = FALSE),
      plotly::plotlyOutput(ns("hist")),
      plotly::plotlyOutput(ns("box"))))
}

#' Server das distribuicoes: histograma da data escolhida e boxplot da
#' serie toda por data de referencia (rotulo curto do slider por data),
#' sobre a serie completa
#' @keywords internal
mod_explorar_dist_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    catalogo <- shiny::reactive({
      con <- explorar_con()
      if (is.null(con)) return(NULL)
      on.exit(DBI::dbDisconnect(con), add = TRUE)
      tryCatch(painel_mdata(con), error = function(e) NULL)
    })
    shiny::observe({
      md <- catalogo()
      if (is.null(md)) return(NULL)
      shiny::updateSelectizeInput(
        session, "indicador", choices = setNames(md$mdata_id, md$rotulo))
    })
    serie <- shiny::reactive({
      if (!length(input$indicador) || !nzchar(input$indicador))
        return(NULL)
      con <- explorar_con()
      if (is.null(con)) return(NULL)
      on.exit(DBI::dbDisconnect(con), add = TRUE)
      tryCatch(painel_valores_por_data(con, as.integer(input$indicador)),
               error = function(e) NULL)
    })
    datas <- shiny::reactive({
      s <- serie()
      if (is.null(s)) return(as.Date(character(0)))
      sort(unique(s$refdate[is.finite(s$value)]))
    })
    rotulos <- shiny::reactive({
      d <- datas()
      if (!length(d)) return(setNames(character(0), character(0)))
      setNames(painel_rotulo_data(d), as.character(d))
    })
    shiny::observe({
      d <- datas()
      if (!length(d)) return(NULL)
      shiny::updateSelectInput(session, "data", choices = rotulos(),
                               selected = as.character(max(d)))
    })
    eixo <- function(p) {
      if (isTRUE(input$log))
        p + ggplot2::scale_y_log10() else p
    }
    output$hist <- plotly::renderPlotly({
      shiny::req(input$data)
      s <- serie()
      if (is.null(s)) return(NULL)
      r <- rotulos()
      chave <- as.character(input$data)[1]
      tit <- if (chave %in% names(r)) unname(r[chave]) else chave
      d <- s[s$refdate == as.Date(chave) & is.finite(s$value), ]
      if (!NROW(d)) return(NULL)
      p <- ggplot2::ggplot(d, ggplot2::aes(.data$value)) +
        ggplot2::geom_histogram(
          bins = 40, fill = "#1351B4", color = "white", na.rm = TRUE) +
        ggplot2::labs(x = "valor", y = "localidades",
                      title = sprintf("Histograma - %s", tit))
      plotly::ggplotly(eixo(p)) |> plotly::config(displayModeBar = FALSE)
    })
    output$box <- plotly::renderPlotly({
      s <- serie()
      if (is.null(s)) return(NULL)
      d <- s[is.finite(s$value), ]
      if (!NROW(d)) return(NULL)
      niveis <- painel_rotulo_data(sort(unique(d$refdate)))
      d$data_rotulo <- factor(painel_rotulo_data(d$refdate), levels = niveis)
      p <- ggplot2::ggplot(d, ggplot2::aes(.data$data_rotulo, .data$value)) +
        ggplot2::geom_boxplot(fill = "#1351B4", alpha = 0.6, na.rm = TRUE) +
        ggplot2::labs(x = "Data", y = "valor", title = "Boxplot por data")
      plotly::ggplotly(eixo(p)) |> plotly::config(displayModeBar = FALSE)
    })
  })
}
