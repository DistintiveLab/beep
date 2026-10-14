# Testes offline do submódulo pdad (geração de call strings,
# reshape de estimativas e contrato do branch). Download da PDAD e
# escrita no DW não são exerciciados aqui.

test_that("call string município: single-line, base, tipo e variáveis", {
  chamada <- gerar_call_pdad("domicilios", c("A01npessoas", "A02quartos"),
                             "total", "municipio")
  expect_false(grepl("\n", chamada))
  expect_match(chamada, 'pdadr::get_pdad("domicilios")', fixed = TRUE)
  expect_match(chamada,
               "l$cod_ibge_municipio[match(b$localidade, l$valor)]",
               fixed = TRUE)
  expect_match(chamada, 'c("A01npessoas", "A02quartos")', fixed = TRUE)
  expect_match(chamada, 'tipo = "total"', fixed = TRUE)
  expect_match(chamada, 'por = "local"', fixed = TRUE)
  # sem marcador de familia/origem: o branch 16 sabe que e PDAD
  expect_false(grepl("^#", chamada))
  # sem o filtro de NA (exclusivo do nivel subdistrito)
  expect_false(grepl("is.na(b$local)", chamada, fixed = TRUE))
})

test_that("call string subdistrito troca a chave e derruba NAs", {
  chamada <- gerar_call_pdad("moradores", "B01idade", "media", "subdistrito")
  expect_match(chamada, "l$cod_ibge_subdistrito[", fixed = TRUE)
  expect_match(chamada, "b <- b[!is.na(b$local), ];", fixed = TRUE)
  expect_match(chamada, 'pdadr::get_pdad("moradores")', fixed = TRUE)
  expect_match(chamada, 'tipo = "media"', fixed = TRUE)
})

test_that("rótulo de selectize antigo é reduzido ao código", {
  chamada <- gerar_call_pdad("domicilios",
                             c("A01npessoas - Total de moradores",
                               "A02quartos"),
                             "proporcao", "municipio")
  expect_match(chamada, '"A01npessoas"', fixed = TRUE)
  expect_false(grepl("Total de moradores", chamada, fixed = TRUE))
})

test_that("sem variáveis ou argumentos inválidos abortam", {
  expect_error(gerar_call_pdad("domicilios", character(0),
                               "total", "municipio"),
               "nenhuma vari")
  expect_error(gerar_call_pdad("domicilios", " - só rótulo",
                               "total", "municipio"),
               "nenhuma vari")
  expect_error(gerar_call_pdad("pessoas", "A01", "total", "municipio"))
  expect_error(gerar_call_pdad("domicilios", "A01", "soma", "municipio"))
  expect_error(gerar_call_pdad("domicilios", "A01", "total", "setor"))
})

test_that("pdad_series_long: long com período 31/12 e local numérico", {
  est <- list(A01npessoas = data.frame(
    local = c("5300108", "5208707"),
    estimativa = c(123.4, 987.6), n = c(100L, 50L)))
  serie <- pdad_series_long(est)
  expect_identical(names(serie), "A01npessoas")
  expect_identical(serie$A01npessoas$local, c(5300108, 5208707))
  expect_identical(serie$A01npessoas$periodo,
                   as.Date(c("2024-12-31", "2024-12-31")))
  expect_identical(serie$A01npessoas$valor, c(123.4, 987.6))
})

test_that("pdad_series_long: proporção abre uma série por nível e NAs caem", {
  est <- list(
    C02 = data.frame(
      local = c("5300108", "5300108", "5300108", "5300108"),
      nivel = c("Feminino", "Masculino", "Feminino", "Feminino"),
      estimativa = c(0.6, 0.4, 0.55, NA), n = 10L),
    Vazia = data.frame(local = c(NA_character_, "5300108"),
                       estimativa = c(1, NA)))
  serie <- pdad_series_long(est)
  expect_setequal(names(serie), c("C02_Feminino", "C02_Masculino"))
  expect_identical(nrow(serie$C02_Feminino), 2L)
  expect_identical(nrow(serie$C02_Masculino), 1L)
})

test_that("pdad_series_long: não-lista é embrulhada como pdad", {
  df <- data.frame(local = "5300108", estimativa = 42)
  serie <- pdad_series_long(df)
  expect_identical(names(serie), "pdad")
  expect_identical(serie$pdad$valor, 42)
})

test_that("UI do submódulo pdad renderiza com parent_session real", {
  sess_fake <- list(ns = function(x) paste0("data:", x))
  ui <- upload_pdadr_ui(shiny::NS("data", "pdad"), parent_session = sess_fake)
  expect_s3_class(ui, "shiny.tag.list")
  html <- paste(capture.output(print(ui)), collapse = " ")
  expect_match(html, "data:upload_file", fixed = TRUE)
  expect_match(html, 'value="subdistrito"', fixed = TRUE)
  # conditionalPanel escapa aspas simples como &#39; no atributo
  # data-display-if — normaliza antes de comparar
  cond <- gsub("&#39;", "'", html)
  expect_match(cond, "== 'subdistrito'", fixed = TRUE)
})

test_that("picker de fontes agrupa por instituição em optgroups", {
  ui <- upload_data_ui("data")
  expect_s3_class(ui, "shiny.tag.list")
  html <- paste(capture.output(print(ui)), collapse = " ")
  for (grupo in c("Arquivo/URL", "Dados abertos", "IBGE", "IPEA", "BCB",
                  "DATASUS", "RAIS", "INEP", "TSE", "IPE/DF")) {
    expect_match(html, paste0('<optgroup label="', grupo, '">'),
                 fixed = TRUE)
  }
  # valores numericos preservados (1..16): comparacoes existentes
  # de input$sourcetype nao mudam
  for (v in as.character(1:16)) {
    expect_match(html, paste0('value="', v, '"'), fixed = TRUE)
  }
})

test_that("picker de variáveis exclui colunas administrativas", {
  skip_if_not_installed("pdadr")
  esc <- pdad_variaveis_choices("domicilios")
  admin <- c("starttime", "A01nficha", "A01uf", "localidade",
             "setor_distrito", "morador_id", "index", "peso_dom",
             "peso_mor")
  expect_false(any(unname(esc) %in% admin))
  expect_true("A01npessoas" %in% unname(esc))
})
