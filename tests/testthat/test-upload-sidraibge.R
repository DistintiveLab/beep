# Testes offline do submódulo SIDRA: choices de palavras-chave.
# Downloads e escrita no DW não são exerciciados aqui.

test_that("choices de palavras-chave cobrem o sidrameta inteiro", {
  skip_if_not_installed("sidra")
  # data.frame (value, label) com TODAS as linhas: sidrameta virou
  # data.table no pacote sidra e sidrameta[1:2] devolvia 2 LINHAS
  # (2 opcoes no selectize) em vez das 2 colunas
  choices <- sidrameta[, c("value", "label")]
  expect_s3_class(choices, "data.frame")
  expect_named(choices, c("value", "label"))
  expect_gt(nrow(choices), 1000)
  expect_false(any(is.na(choices$value)))
  expect_false(any(is.na(choices$label)))
})

test_that("desctabela cobre tabela sem classificacoes e falha com erro claro", {
  skip_if_offline()
  skip_if_not_installed("sidra")
  # 4709 nao tem classificacoes: bug 1:length(NULL) do sidra::tab_meta
  m <- desctabela(4709)
  expect_true(is.list(m))
  expect_false(is.null(m$nivelTerritorial))
  expect_false(is.null(m$variaveis))
  # tabela inexistente: erro claro, nao NULL silencioso
  expect_error(desctabela(99999999), "desctabela")
})
