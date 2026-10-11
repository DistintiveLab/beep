# Testes offline do submódulo TSE: geração de call strings.
# Downloads do tsebr e escrita no DW não são exerciciados aqui.

# replica o strip do selected_files: marcador separado por "; "
# (single-line — o browser remove \n de textInput) ou "\n" (antigo)
stripar_marcador <- function(s)
  sub("^[^;]*;\\s*", "", sub("^[^\n]+\n", "", s))

test_that("call string traz marcador de familia e codigo parseavel", {
  chamada <- gerar_call_tsebr("resultados_detalhe", 2022, "DF",
                              metrica = "abstencoes")
  expect_match(chamada, "^# tsebr-familia: resultados_detalhe")
  expect_false(grepl("\n", chamada))
  codigo <- stripar_marcador(chamada)
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

test_that("anos TSE restritos a 2022 e 2026 (ate segunda ordem)", {
  expect_identical(tse_anos_painel, c(2022L, 2026L))
  # "todos" resolve para os anos habilitados, nao para o catalogo cheio
  chamada <- gerar_call_tsebr("resultados_nominais", "todos", "DF")
  expect_match(chamada, "ano = c\\(2022, 2026\\)")
  # candidaturas agora recebem vetor de anos explicito
  cand <- gerar_call_tsebr("candidaturas", "todos", "DF")
  expect_match(cand, "ano = c\\(2022, 2026\\)")
  # ano especifico segue como antes
  um <- gerar_call_tsebr("candidaturas", 2022, "DF")
  expect_match(um, "ano = c\\(2022\\)")
})

test_that("fonte tsesqlr gera consulta ao banco com mapa, sem download", {
  chamada <- gerar_call_tsebr("resultados_nominais", 2022, "DF",
                              cargo = "PRESIDENTE", nr_votavel = "13",
                              fonte = "tsesqlr")
  expect_match(chamada, "tsesqlr::tsesqlr_resultados_municipio")
  expect_match(chamada, "mapa=tsebr::tse_mapa_municipios\\(2022, 'DF'\\)")
  expect_false(grepl("tse_resultados_municipio", chamada))
  # parseavel pelo ramo do selected_files
  codigo <- stripar_marcador(chamada)
  expect_silent(parse(text = paste0("{\n", codigo, "\n}")))

  cand <- gerar_call_tsebr("candidaturas", "todos", "DF", fonte = "tsesqlr")
  expect_match(cand, "tsesqlr::tsesqlr_candidatos")
  expect_match(cand, "ano = c\\(2022, 2026\\)")
})

test_that("familias sem cobertura no banco seguem no tsebr", {
  # detalhe cai no tsebr quando o tsedb nao o cobre (pode ter sido
  # carregado depois); prestacao e familias fora do switch nunca consultam
  # o banco
  skip_if_not(requireNamespace("tsesqlr", quietly = TRUE))
  if (!isTRUE(tryCatch(
    tsesqlr::tsesqlr_disponivel("detalhe", 2022L, "DF"),
    error = \(e) FALSE))) {
    expect_identical(beep:::resolver_fonte_tse("resultados_detalhe", 2022, "DF"),
                     "tsebr")
  }
  expect_identical(beep:::resolver_fonte_tse("prestacao", 2026, "DF"),
                   "tsebr")
  expect_identical(beep:::resolver_fonte_tse("familia_fora_do_switch", 2022, "DF"),
                   "tsebr")
})

test_that("resolver_fonte_tse prefere o banco quando o escopo esta carregado", {
  skip_if_not(requireNamespace("tsesqlr", quietly = TRUE))
  # tsesqlr antigo (sem tsesqlr_disponivel): usar a arvore dev se
  # existir, senao pular sem erro
  if (!"tsesqlr_disponivel" %in% getNamespaceExports("tsesqlr")) {
    dev <- "/home/distintive/pRojetos/tsesqlr"
    skip_if_not(dir.exists(dev))
    pkgload::load_all(dev, quiet = TRUE)
  }
  skip_if_not(isTRUE(tryCatch(
    tsesqlr::tsesqlr_disponivel("resultados", 2022, "DF"),
    error = \(e) FALSE)))
  expect_identical(beep:::resolver_fonte_tse("resultados_nominais", 2022, "DF"),
                   "tsesqlr")
  # escopo ausente no banco -> download (2024 nao entra no tsedb;
  # 2026 ja esta carregado para todas as UFs)
  expect_identical(beep:::resolver_fonte_tse("resultados_nominais", 2024, "SP"),
                   "tsebr")
})

test_that("guarda de consolidacao detecta serie parcial antes de gravar", {
  codigo <- "tsebr::tse_detalhe_municipio(ano = c(2022, 2026), uf='all', metrica='abstencoes')"
  parcial <- data.frame(local = 5300108, periodo = as.Date("2022-12-31"),
                        valor = 1)
  expect_identical(anos_tse_faltando(codigo, parcial), 2026L)
  completa <- rbind(parcial,
                    data.frame(local = 5300108,
                               periodo = as.Date("2026-12-31"), valor = 2))
  expect_identical(anos_tse_faltando(codigo, completa), integer(0))
  # ano unico e chamada sem bloco ano=c(...) nao bloqueiam
  expect_identical(anos_tse_faltando("x(ano = c(2022))", parcial), integer(0))
  expect_identical(anos_tse_faltando("x()", parcial), integer(0))
  # ano fora de faixa e tabela sem coluna periodo ignoram a guarda
  expect_identical(anos_tse_faltando(codigo, data.frame(a = 1)), integer(0))
})
