# Testes offline do submódulo TSE: geração de call strings.
# Downloads do tsebr e escrita no DW não são exerciciados aqui.

test_that("call string traz marcador de familia e codigo parseavel", {
  chamada <- gerar_call_tsebr("resultados_detalhe", 2022, "DF",
                              metrica = "abstencoes")
  expect_match(chamada, "^# tsebr-familia: resultados_detalhe")
  codigo <- sub("^[^\n]+\n", "", chamada)
  expect_silent(expr <- parse(text = paste0("{\n", codigo, "\n}")))
  corpo <- paste(deparse(expr[[1]]), collapse = " ")
  expect_match(corpo, "tse_detalhe_municipio")
  expect_match(corpo, "abstencoes")
  # mapa TSE x IBGE resolvido internamente pelo tsebr (env vars do DW)
  expect_false(grepl("tse_municipios", corpo))
})

test_that("familias nominais, prestacao e candidaturas geram chamadas proprias", {
  nom <- gerar_call_tsebr("resultados_nominais", 2026, "SP",
                          cargo = "PRESIDENTE", nr_votavel = "13")
  expect_match(nom, "tse_resultados_municipio")
  expect_match(nom, "cargo=.PRESIDENTE.")
  expect_match(nom, "nr_votavel=.13.")

  prest <- gerar_call_tsebr("prestacao", 2026, "DF", tipo = "despesas")
  expect_match(prest, "^# tsebr-familia: prestacao")
  expect_match(prest, "tse_prestacao_uf")
  expect_false(grepl("tse_municipios", prest))

  cand <- gerar_call_tsebr("candidaturas", 2026, "all", cargo = "GOVERNADOR")
  expect_match(cand, "^# tsebr-familia: candidaturas")
  expect_match(cand, "tse_candidaturas")
  expect_match(cand, "GOVERNADOR")
})

test_that("extracao do marcador replica a logica do selected_files", {
  chamada <- gerar_call_tsebr("prestacao", 2026, "DF", tipo = "receitas")
  fam <- sub("^# tsebr-familia: ([a-z_]+).*", "\\1", chamada)
  expect_identical(fam, "prestacao")
})

test_that("familia desconhecida aborta", {
  expect_error(gerar_call_tsebr("perfil_secao", 2026, "DF"),
               "familia desconhecida")
})
