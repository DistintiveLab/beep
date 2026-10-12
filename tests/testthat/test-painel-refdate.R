# Consultas por refdate exato: serie completa por data, rotulo de aba ISO
# e ranking no dia exato (migracao do slider por data do mapa) -------------

test_that("painel_rotulo_aba usa ISO nos anos de varios pontos e ano sozinho no resto", {
  r <- beep:::painel_rotulo_aba
  # dois turnos num ano: datas completas ISO ("/" e proibido em nome de aba)
  expect_identical(
    r(as.Date(c("2022-10-02", "2022-10-30", "2026-10-04"))),
    c("2022-10-02", "2022-10-30", "2026"))
  # ano com ponto unico fica so com o ano
  expect_identical(r(as.Date(c("2026-10-04"))), "2026")
  expect_identical(r(as.Date(character(0))), character(0))
})

test_that("painel_valores_por_data guarda NA sem tocar no banco", {
  v <- beep:::painel_valores_por_data(NULL, NA)
  expect_identical(names(v), c("local_id", "refdate", "value", "ano"))
  expect_identical(nrow(v), 0L)
})

test_that("painel_valores_por_data_cache guarda NA sem tocar no banco", {
  v <- beep:::painel_valores_por_data_cache(NA)
  expect_identical(names(v), c("local_id", "refdate", "value", "ano"))
  expect_identical(nrow(v), 0L)
})

test_that("painel_ranking_local traz o ramo exato por data e mantem o de ano", {
  sql <- paste(deparse(body(beep:::painel_ranking_local)), collapse = "")
  # com refdate valido: comparacao no dia exato
  expect_true(grepl("AND v.refdate = date '%s'", sql, fixed = TRUE))
  # sem refdate: faixa make_date do contrato historico preservada
  expect_true(grepl("make_date(%d, 1, 1)", sql, fixed = TRUE))
})

test_that("chave do cache de ranking distingue o dia exato do ano fechado", {
  dep <- gsub("\\s+", " ",
              paste(deparse(body(beep:::painel_ranking_local_cache)),
                    collapse = ""))
  expect_true(grepl('format(refdate, "%Y%m%d")', dep, fixed = TRUE))
  expect_true(grepl('"ano"', dep, fixed = TRUE))
  # repassa o refdate para a consulta
  expect_true(grepl("painel_ranking_local(con, mdata_id, local_id, ano, refdate)",
                    dep, fixed = TRUE))
})
