# Testes offline do submódulo censo (geração de call strings e
# contrato do branch). Downloads do censobr e escrita no DW não
# são exerciciados aqui.

test_that("call string microdados: marcador, lista de variaveis e funcao", {
  chamada <- gerar_call_censo("microdados", "pessoas", 2022,
                              c("V0001", "V1005"), "municipio",
                              funcao = "soma_pond")
  expect_match(chamada, "^# censo-origem: microdados")
  codigo <- sub("^[^\n]+\n", "", chamada)
  expr <- parse(text = codigo)[[1]]
  expect_match(paste(deparse(expr), collapse = " "), "agregar_microdados")
  expect_match(paste(deparse(expr), collapse = " "),
               "variaveis = c\\(\"V0001\", \"V1005\"\\)")
  expect_match(paste(deparse(expr), collapse = " "), 'funcao = "soma_pond"')
})

test_that("call string tracts com recorte", {
  chamada <- gerar_call_censo("tracts", "Basico", 2022, "V0001",
                              "municipio", corte = "V0001 > 0")
  expect_match(chamada, "^# censo-origem: tracts")
  expect_match(chamada, "agregar_setores")
  expect_match(chamada, 'corte\\s*=\\s*"V0001 > 0"')
})

test_that("sem variaveis ou origem desconhecida abortam", {
  expect_error(gerar_call_censo("microdados", "pessoas", 2022,
                                character(0), "municipio"),
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
