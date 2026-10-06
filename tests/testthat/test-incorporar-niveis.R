# Testes offline dos carregadores de niveis submunicipais (F2):
# validacao de argumentos pura, sem banco e sem rede. O caminho completo
# (download → ampliar → niveis_carga) e coberto em test-niveis-dw.R com
# geobr mockado.

test_that(".validar_ufs_niveis aceita all, UF 2d e municipio 7d", {
  expect_identical(beep:::.validar_ufs_niveis("all"), "all")
  expect_identical(beep:::.validar_ufs_niveis(11), "11")
  expect_identical(beep:::.validar_ufs_niveis(c("11", 12)), c("11", "12"))
  expect_identical(beep:::.validar_ufs_niveis("1100203"), "1100203")
  expect_identical(beep:::.validar_ufs_niveis(c(11, 11)), "11") # dedup
})

test_that(".validar_ufs_niveis rejeita formatos invalidos", {
  expect_error(beep:::.validar_ufs_niveis("RO"), "ufs invalido")
  expect_error(beep:::.validar_ufs_niveis(1), "ufs invalido")
  expect_error(beep:::.validar_ufs_niveis(110020), "ufs invalido") # 6d
  expect_error(beep:::.validar_ufs_niveis(c("11", "abc")), "ufs invalido")
  expect_error(beep:::.validar_ufs_niveis(NA_character_), "ufs invalido")
})

test_that("carregadores validam ufs antes de qualquer outra coisa", {
  # geobr pode ate estar ausente: a validacao vem primeiro
  expect_error(incorporar_setores_censitarios(ufs = "RO"), "ufs invalido")
  expect_error(incorporar_areas_ponderacao(ufs = "bad"), "ufs invalido")
})
