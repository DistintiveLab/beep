# Testes offline do submódulo tsebr: geração de call strings.
# A escrita no DW (db_datawrite) e o download (tsebr) exigem rede/
# banco e não são exerciciados aqui.

test_that("call string traz marcador de familia e codigo parseavel", {
  chamada <- gerar_call_tsebr("resultados_detalhe", 2022, "DF",
                              metrica = "abstencoes")
  expect_match(chamada, "^# tsebr-familia: resultados_detalhe")
  codigo <- sub("^[^\n]+\n", "", chamada)
  expect_silent(expr <- parse(text = codigo))
  corpo <- paste(unlist(lapply(as.list(expr), deparse)), collapse = " ")
  expect_match(corpo, "tse_detalhe_municipio")
  expect_match(corpo, "metrica\\s*=\\s*['\"]abstencoes['\"]")
  expect_match(corpo,
    "tse_municipios\\(2022,\\s*con\\s*=\\s*con,\\s*uf\\s*=\\s*['\"]DF['\"]\\)")
})

test_that("familias nominais, prestacao e candidaturas geram chamadas proprias", {
  nom <- gerar_call_tsebr("resultados_nominais", 2026, "SP",
                          cargo = "PRESIDENTE", nr_votavel = "13")
  expect_match(nom, "tse_resultados_municipio\\(2026, uf='SP'")
  expect_match(nom, "cargo=\"PRESIDENTE\"")
  expect_match(nom, "nr_votavel=\"13\"")

  prest <- gerar_call_tsebr("prestacao", 2026, "DF", tipo = "despesas")
  expect_match(prest, "^# tsebr-familia: prestacao")
  expect_match(prest, "tse_prestacao_uf\\(2026, tipo='despesas'\\)")
  expect_false(grepl("tse_municipios", prest))

  cand <- gerar_call_tsebr("candidaturas", 2026, "all", cargo = "GOVERNADOR")
  expect_match(cand, "^# tsebr-familia: candidaturas")
  expect_match(cand, "tse_candidaturas\\(2026, uf='all', cargo=\"GOVERNADOR\"\\)")
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
