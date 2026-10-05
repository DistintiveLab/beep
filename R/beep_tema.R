# Tema gov.br / preto-e-branco compartilhado (núcleo T1) --------------------
#
# Porta o sistema de paletas do painel de indicadores (R/painel_ui.R +
# www/painel.css/js) para o pacote: variáveis --p-* das duas paletas
# (gov.br azul #1351B4; preto e branco com o roxo Distintive #78529D),
# alternância em tempo real pela classe beep-pb no <body>, persistência
# em localStorage (chave beep_paleta) e default institucional pela env
# beep_paleta. Consomem o núcleo: o admin_app() (T2), o app beep (T3) e
# o próprio painel (T4). Sem sync server aqui por design: quem precisa
# avisar o Shiny (o painel recore gráficos) escuta o evento "beep:paleta"
# despachado pelo beep-tema.js.

#' Paleta inicial dos apps beep (usa a variável de ambiente `beep_paleta`)
#'
#' Análogo ao [beep::painel_brand_paleta()] do painel: a env sobrepõe o
#' default, então o admin e o app beep de um projeto podem nascer pb via
#' `.Renviron` sem tocar em código. Valores: "govbr" (padrão) ou "pb".
#' @keywords internal
beep_tema_paleta_default <- function(default = "govbr") {
  match.arg(Sys.getenv("beep_paleta", default), c("govbr", "pb"))
}

#' Recursos do núcleo do tema: CSS + JS + base Gov.br + div raiz
#'
#' Inclui as variáveis/toggle de paleta (inst/tema), a base Rawline/Gov.br
#' do shinyGovBRstyle (servida do próprio pacote, sem CDN externo) e a div
#' raiz `#beep_tema_raiz` com o `data-paleta` inicial lido pelo JS.
#' Colocar uma única vez por app, junto aos recursos de cabeçalho.
#' @keywords internal
beep_tema_recursos <- function(paleta = c("govbr", "pb")) {
  paleta <- match.arg(paleta)
  tema_dir <- system.file("tema", package = "beep")
  if (!nzchar(tema_dir) ||
      !file.exists(file.path(tema_dir, "beep-tema.css")))
    stop("núcleo do tema ausente nesta instalação do beep — reinstale",
         " o pacote", call. = FALSE)
  shiny::tagList(
    htmltools::includeCSS(file.path(tema_dir, "beep-tema.css")),
    htmltools::includeScript(file.path(tema_dir, "beep-tema.js")),
    shinyGovBRstyle::use_govbr(),
    shiny::tags$div(id = "beep_tema_raiz", `data-paleta` = paleta,
                    class = "hidden"))
}

#' Botão de alternância da paleta (classe `beep-tema-btn`)
#'
#' O beep-tema.js resolve o clique, troca o rótulo ("Preto e branco" /
#' "Cores Gov.br") e mantém `aria-pressed`. O id é livre (evite colisões
#' com inputs Shiny: botões puros não registram input).
#' @keywords internal
beep_tema_botao <- function(id = "beep_tema_btn") {
  shiny::tags$button(id = id, type = "button", class = "beep-tema-btn",
                     `aria-pressed` = "true", "Preto e branco")
}
