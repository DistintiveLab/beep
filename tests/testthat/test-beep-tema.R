# Núcleo do tema gov.br/pb (T1): variáveis, toggle e helpers ---------------

test_that("núcleo do tema existe e define as duas paletas", {
  tema_dir <- system.file("tema", package = "beep")
  skip_if_not(nzchar(tema_dir))
  css <- readLines(file.path(tema_dir, "beep-tema.css"), warn = FALSE)
  css <- paste(css, collapse = "\n")
  # paleta gov.br (default) e pb (classe no body), mesmas cores do painel
  expect_true(grepl(":root", css, fixed = TRUE))
  expect_true(grepl("body.beep-pb", css, fixed = TRUE))
  for (hex in c("#1351B4", "#0C3F91", "#FFCD07", "#1B1B1B", "#78529D",
                "#5E3F82", "#C9B9DE"))
    expect_true(grepl(hex, css, fixed = TRUE), info = paste("sem", hex))
  # sem regras específicas do painel no núcleo
  expect_false(grepl("painel-", css))
  js <- readLines(file.path(tema_dir, "beep-tema.js"), warn = FALSE)
  js <- paste(js, collapse = "\n")
  expect_true(grepl("beep-pb", js, fixed = TRUE))
  expect_true(grepl("'beep_paleta'", js, fixed = TRUE))
  expect_true(grepl("beep_tema_raiz", js, fixed = TRUE))
  expect_true(grepl("beep:paleta", js, fixed = TRUE))
})

test_that("beep_tema_paleta_default lê a env beep_paleta com fallback", {
  expect_identical(beep:::beep_tema_paleta_default(), "govbr")
  expect_identical(beep:::beep_tema_paleta_default("pb"), "pb")
  expect_identical(
    withr::with_envvar(c(beep_paleta = "pb"), beep:::beep_tema_paleta_default()),
    "pb")
  expect_identical(
    withr::with_envvar(c(beep_paleta = "govbr"), beep:::beep_tema_paleta_default("pb")),
    "govbr")
  expect_error(beep:::beep_tema_paleta_default("outra"), "govbr|pb")
  expect_error(
    withr::with_envvar(c(beep_paleta = "x"), beep:::beep_tema_paleta_default()),
    "govbr|pb")
})

test_that("beep_tema_recursos devolve css+js+div raiz com data-paleta", {
  for (paleta in c("govbr", "pb")) {
    r <- beep:::beep_tema_recursos(paleta)
    html <- paste(as.character(r), collapse = "")
    # includeCSS/includeScript inline o conteudo (nao linkam por nome)
    expect_true(grepl("body.beep-pb", html, fixed = TRUE))
    expect_true(grepl("beep:paleta", html, fixed = TRUE))
    expect_true(grepl("beep_tema_raiz", html, fixed = TRUE))
    expect_true(grepl(paste0('data-paleta="', paleta, '"'), html,
                      fixed = TRUE))
  }
  expect_error(beep:::beep_tema_recursos("outra"), "govbr|pb")
})

test_that("beep_tema_botao marca classe e estado inicial acessível", {
  b <- beep:::beep_tema_botao("meu_btn")
  expect_identical(b$name, "button")
  expect_identical(b$attribs$id, "meu_btn")
  expect_identical(b$attribs$class, "beep-tema-btn")
  expect_identical(b$attribs$`aria-pressed`, "true")
  expect_identical(as.character(b$children[[1]]), "Preto e branco")
})
