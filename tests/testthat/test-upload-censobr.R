# Testes offline do submódulo censo (geração de call strings e
# contrato do branch). Downloads do censobr e escrita no DW não
# são exerciciados aqui.

# replica o strip do selected_files: marcador separado por "; "
# (single-line — o browser remove \n de textInput) ou "\n" (antigo)
stripar_marcador <- function(s)
  sub("^[^;]*;\\s*", "", sub("^[^\n]+\n", "", s))

test_that("call string microdados: single-line, marcador, variaveis e funcao", {
  chamada <- gerar_call_censo("microdados", "pessoas", 2022,
                              c("V0001", "V1005"), "municipio",
                              funcao = "soma_pond")
  expect_match(chamada, "^# censo-origem: microdados; censoagg::")
  expect_false(grepl("\n", chamada))
  expr <- parse(text = stripar_marcador(chamada))[[1]]
  expect_match(paste(deparse(expr), collapse = " "), "agregar_microdados")
  expect_match(paste(deparse(expr), collapse = " "),
               "variaveis = c\\(\"V0001\", \"V1005\"\\)")
  expect_match(paste(deparse(expr), collapse = " "), 'funcao = "soma_pond"')
})

test_that("call string tracts com recorte", {
  chamada <- gerar_call_censo("tracts", "Basico", 2022, "V0001",
                              "municipio", corte = "V0001 > 0")
  expect_match(chamada, "^# censo-origem: tracts;")
  expect_match(chamada, "agregar_setores")
  expect_match(chamada, 'corte\\s*=\\s*"V0001 > 0"')
})

test_that("rotulo de selectize antigo e reduzido ao codigo", {
  chamada <- gerar_call_censo(
    "tracts", "Pessoas", 2022,
    c("demografia_V01006 - Quantidade de moradores",
      "demografia_V01007 - Homens"),
    "setor")
  expect_match(chamada,
               'variaveis=c\\("demografia_V01006", "demografia_V01007"\\)')
})

test_that("sem variaveis ou origem desconhecida abortam", {
  expect_error(gerar_call_censo("microdados", "pessoas", 2022,
                                character(0), "municipio"),
               "nenhuma variavel")
  expect_error(gerar_call_censo("tracts", "Pessoas", 2022,
                                " - so rotulo", "municipio"),
               "nenhuma variavel")
  expect_error(gerar_call_censo("ibge_ftp", "x", 2022, "V1", "municipio"),
               "origem desconhecida")
})

test_that("contrato do branch: lista vira serie por variavel (mirror)", {
  dados <- list(
    V0001 = data.frame(local = "5300108",
                       periodo = as.Date("2022-12-31"), valor = 10),
    V0002 = data.frame(local = "5300108",
                       periodo = as.Date("2022-12-31"), valor = 3))
  if (!inherits(dados, "list")) dados <- list(censo = dados)
  combinada <- data.table::rbindlist(
    lapply(names(dados), \(nm) transform(dados[[nm]], variavel = nm)),
    fill = TRUE)
  expect_setequal(combinada$variavel, c("V0001", "V0002"))
  expect_identical(nrow(combinada), 2L)
})

test_that("UI do submodulo censo renderiza com parent_session real", {
  sess_fake <- list(ns = function(x) paste0("data:", x))
  ui <- upload_censobr_ui(shiny::NS("data", "censo"), parent_session = sess_fake)
  expect_s3_class(ui, "shiny.tag.list")
  html <- paste(capture.output(print(ui)), collapse = " ")
  expect_match(html, "data:upload_file", fixed = TRUE)
  # bases fixas da UI existem no dicionario 2022 (fallback antes do
  # update dinamico; nomes antigos como "Instrucao" nao existem)
  skip_if_not_installed("censoagg")
  dic <- tryCatch(censoagg::censo_variaveis(2022, "tracts"), error = \(e) NULL)
  skip_if(is.null(dic))
  bases_ui <- c("Basico", "Domicilios", "Entorno", "Indigenas", "Obitos",
                "Pessoas", "Quilombolas", "ResponsavelRenda")
  expect_true(all(bases_ui %in% unique(dic$dataset)))
})
