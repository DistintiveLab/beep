test_that(".resumo_locais_nao_casados resume descartes com amostra de codigos", {
  local <- c(110001, 110002, 530010, 530011, 530012, 530013)
  local_id <- c(NA, NA, 1L, 2L, 3L, 4L)

  res <- beep:::.resumo_locais_nao_casados(local, local_id)

  expect_equal(res$n, 2L)
  expect_equal(res$total, 6L)
  expect_equal(res$amostra, c("110001", "110002"))
})

test_that(".resumo_locais_nao_casados detecta o caso nenhum casou", {
  res <- beep:::.resumo_locais_nao_casados(c(1.1e14, 1.2e14), c(NA_integer_, NA_integer_))

  expect_equal(res$n, 2L)
  expect_equal(res$total, 2L)
  expect_equal(length(res$amostra), 2L)
})

test_that(".resumo_locais_nao_casados sem descarte devolve zero", {
  res <- beep:::.resumo_locais_nao_casados(c(110001, 530010), c(1L, 2L))

  expect_equal(res$n, 0L)
  expect_equal(res$amostra, character(0))
})

test_that(".resumo_locais_nao_casados capta amostra em 5 codigos", {
  local <- as.numeric(110001500 + 1:10)
  res <- beep:::.resumo_locais_nao_casados(local, rep(NA_integer_, 10))

  expect_equal(length(res$amostra), 5L)
})
