# Testes offline das regras de niveis territoriais (roadmap F1):
# blocos de local_id, normalizacao de codigos longos, lookup do
# gravar_serie_dw e guarda submunicipal do filtro municipal do painel.
# A migracao de schema (preparar_niveis_submunicipais) exige banco e so
# roda em integracao com DW acessivel (skip abaixo).

test_that("eh_municipio_id cobre bloco historico, PNAD e submunicipais", {
  expect_true(all(eh_municipio_id(c(1L, 5570L, 5571L, 5L, 53L))))
  expect_false(any(eh_municipio_id(c(5572L, 6000L, 7087L))))
  expect_true(eh_municipio_id(7088L))
  # blocos submunicipais novos ficam fora
  expect_false(eh_municipio_id(100000L))
  expect_false(eh_municipio_id(999999L))
  expect_false(eh_municipio_id(1000000L))
  expect_false(eh_municipio_id(2000000L))
  # fronteira superior dinamica: linha "Brasil" do banco em maos
  expect_true(eh_municipio_id(6500L, bloco_fim = 6412L))
  expect_false(eh_municipio_id(6412L, bloco_fim = 6412L))
})

test_that("eh_zona_carga_municipal preserva a faixa historica e exclui submunicipais", {
  expect_true(all(eh_zona_carga_municipal(c(1L, 5000L, 5599L))))
  expect_false(all(eh_zona_carga_municipal(c(6000L, 7086L))))
  expect_true(eh_zona_carga_municipal(7087L))
  expect_true(eh_zona_carga_municipal(7088L))
  expect_false(eh_zona_carga_municipal(100000L))
  expect_false(eh_zona_carga_municipal(2500000L))
})

test_that("normalizar_codigo_geoloc nao gera notacao cientifica", {
  setor <- 110020305020001
  expect_identical(normalizar_codigo_geoloc(setor), "110020305020001")
  expect_identical(normalizar_codigo_geoloc(" 520110005 "), "520110005")
  expect_identical(normalizar_codigo_geoloc(c(1, 33)), c("1", "33"))
  if (requireNamespace("bit64", quietly = TRUE)) {
    expect_identical(
      normalizar_codigo_geoloc(bit64::as.integer64("5300103050200123" )),
      "5300103050200123")
  }
})

test_that("eh_codigo_submunicipal e nivel_tipo_por_largura seguem o registro", {
  expect_true(eh_codigo_submunicipal("110020305020001"))
  expect_false(eh_codigo_submunicipal(1100203))
  expect_identical(nivel_tipo_por_largura(c(1L, 2L, 7L, 11L, 12L, 10L, 15L, 16L)),
                   c("regiao", "uf", "municipio", "bairro", "bairro",
                     "area_ponderacao", "setor", "setor"))
  expect_true(is.na(nivel_tipo_por_largura(99L)))
})

test_that("validar_codigos_nivel aceita larguras do registro e rejeita fora", {
  expect_silent(x <- validar_codigos_nivel(
    c("110020305020001", "530010305020012"), "setor"))
  expect_error(validar_codigos_nivel(c("110020305020001", "1100023"), "setor"),
               "larguras fora do registro")
  expect_error(validar_codigos_nivel(c("1100203A5020001"), "setor"),
               "nao numerico")
  expect_error(validar_codigos_nivel("1100023", "desconhecido"),
               "tipo desconhecido")
})

test_that("prefixo 6d de setor nao sombreia municipio no lookup", {
  locais <- data.frame(
    local_id = c(1L, 6000L, 100001L, 100002L),
    geoloc_id = c(1100023, 110002, 110020305020001, 530010305020012))
  # municipio 1100023 (local_id 1), RGIM 110002 (local_id 6000),
  # setores cujo prefixo 6d e 110020/530010
  lookup <- montar_lookup_locais(locais)

  # codigo RAIS 6d resolve no municipio, nao no setor nem no RGIM
  expect_identical(unname(lookup[["110002"]]), 1L)
  # codigo cheio do setor resolve no setor
  expect_identical(unname(lookup[["110020305020001"]]), 100001L)
  expect_identical(unname(lookup[["530010305020012"]]), 100002L)
  # local_id e geoloc 7d continuam resolvendo
  expect_identical(unname(lookup[["6000"]]), 6000L)
  expect_identical(unname(lookup[["1100023"]]), 1L)
})

test_that("RGIM de 6 digitos nao captura codigo RAIS 6d do municipio", {
  locais <- data.frame(
    local_id = c(1L, 5L),
    geoloc_id = c(1100023, 110002))
  lookup <- montar_lookup_locais(locais)
  expect_identical(unname(lookup[["110002"]]), 1L)
})

test_that("filtro municipal do painel exclui os blocos submunicipais", {
  f <- painel_municipio_filtro()
  expect_match(f, "local_id < 5572", fixed = TRUE)
  expect_match(f, "local_id > 7087", fixed = TRUE)
  expect_match(f, "local_id < 100000", fixed = TRUE)
})

test_that("rotulos do painel cobrem as larguras submunicipais", {
  rot <- painel_niveis_rotulo
  expect_identical(unname(rot[["15"]]), "Setor censitário")
  expect_identical(unname(rot[["16"]]), "Setor censitário")
  expect_identical(unname(rot[["10"]]), "Área de ponderação")
  expect_identical(unname(rot[["11"]]), "Bairro")
})
