# painel_paleta: dominios das cores por modo (zero, minmax, quantil) e
# inversao tambem para dados so positivos. Testes offline: so dependem de
# leaflet (Imports) e grDevices.

test_that("modo zero mantem a ancora em 0 (comportamento historico)", {
  pal <- beep:::painel_paleta(c(0.16, 0.23))
  expect_identical(toupper(pal(0)), "#FFC8C8")
  cores <- pal(c(0.16, 0.23))
  expect_false(identical(cores[[1]], cores[[2]]))
})

test_that("modo minmax estica a faixa observada ate as bordas da rampa", {
  pal <- beep:::painel_paleta(c(0.16, 0.23), escala = "minmax")
  expect_identical(toupper(pal(0.16)), "#FFC8C8")
  expect_identical(toupper(pal(0.23)), "#FF0000")
})

test_that("invertida passa a valer tambem para dados so positivos", {
  pal <- beep:::painel_paleta(c(0.16, 0.23), invertida = TRUE)
  expect_identical(toupper(pal(0)), "#FF0000")
})

test_that("modo minmax com sinais misturados parte a rampa no zero", {
  pal <- beep:::painel_paleta(c(-2, -1, 3), escala = "minmax")
  expect_identical(toupper(pal(-2)), "#FF0000")
  expect_identical(toupper(pal(0)), "#C8C8FF")
  expect_identical(toupper(pal(3)), "#0000FF")
})

test_that("modo quantil classifica por ranking em 5 classes", {
  v <- seq(0.16, 0.23, length.out = 33)
  pal <- beep:::painel_paleta(v, escala = "quantil")
  esperadas <- grDevices::colorRampPalette(c("#FFC8C8", "#FF0000"))(5)
  expect_identical(toupper(pal(min(v))), toupper(esperadas[1]))
  expect_identical(toupper(pal(max(v))), toupper(esperadas[5]))
  expect_length(unique(pal(v)), 5L)
  # fora do dominio (Inf) o leaflet avisa e trata como NA: transparente
  expect_identical(suppressWarnings(pal(c(NA_real_, Inf))),
                    c("transparent", "transparent"))
})

test_that("casos degenerados nao quebram (valor unico e so NA)", {
  pal <- beep:::painel_paleta(rep(5, 4), escala = "quantil")
  expect_match(pal(5), "^#")
  pal_mm <- beep:::painel_paleta(rep(5, 4), escala = "minmax")
  expect_match(pal_mm(5), "^#")
  pal_na <- beep:::painel_paleta(c(NA_real_, NaN))
  expect_identical(pal_na(c(1, 2)), c("transparent", "transparent"))
})
