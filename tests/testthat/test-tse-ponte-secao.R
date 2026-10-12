# Testes offline da ponte secao eleitoral x nivel submunicipal (P3/P4):
# pontuacao de locais de votacao e nucleo puro de agregacao do detalhe
# por secao. Harmonizacao KNN e gravacao no DW exigem banco acessivel
# e rodam apenas em integracao.

test_that("tse_pontuar_locais_votacao filtra coords inuteis e fora do bbox", {
  locais <- data.frame(
    cod_municipio_tse = c(97012, 97012, 97012, 97012, 97012),
    municipio = "BRASILIA",
    zona = c(1, 1, 2, 3, 4),
    secao = c(1, 1, 2, 3, 4),
    lat = c("-15,78", "-15.79", NA, 0, -60),
    lon = c("-47,93", "-47.92", NA, 0, 20),
    eleitores_secao = c(100L, 100L, 50L, 60L, 70L))
  pts <- tse_pontuar_locais_votacao(locais)
  expect_s3_class(pts, "sf")
  # virgula decimal e aceita; NA, (0,0) e ponto fora do Brasil caem
  expect_identical(nrow(pts), 2L)
  expect_true(all(!is.na(pts$lat) & !is.na(pts$lon)))
  expect_identical(sort(as.numeric(pts$zona)), c(1, 1))
})

test_that("nucleo de agregacao deduplica secao-turno antes de somar", {
  # secao 10 aparece 2x no turno 1 (cargos diferentes repetem aptos):
  # dedupe first() impede superestimacao; turnos somam
  d <- data.frame(
    uf = "DF",
    cod_municipio_tse = c("97012", "97012", "97012", "97012"),
    zona = c("1", "1", "2", "2"),
    secao = c("10", "10", "20", "20"),
    turno = c(1, 1, 1, 2),
    aptos = c(400, 400, 300, 280))
  local_chr <- c("53001080501", "53001080501",
                 "53001080501", "53001080502")
  res <- beep:::.tse_agregar_detalhe_local(d, local_chr, "aptos", 2026)
  expect_identical(nrow(res), 2L)
  expect_equal(res$valor[res$local == "53001080501"], 700)
  expect_equal(res$valor[res$local == "53001080502"], 280)
  expect_true(all(res$periodo == as.Date("2026-12-31")))
  expect_identical(res$metrica, rep("aptos", 2))
})

test_that("nucleo empilha metricas e descarta secoes sem atribuicao", {
  d <- data.frame(
    uf = "DF", cod_municipio_tse = "97012", zona = "1",
    secao = c("1", "2"), turno = 1,
    aptos = c(100, 90), abstencoes = c(20, 10))
  res <- beep:::.tse_agregar_detalhe_local(
    d, c(NA_character_, "53001080501"), c("aptos", "abstencoes"), 2022)
  expect_identical(nrow(res), 2L)
  expect_equal(res$valor[res$metrica == "aptos"], 90)
  expect_equal(res$valor[res$metrica == "abstencoes"], 10)
  expect_true(all(res$periodo == as.Date("2022-12-31")))
})
