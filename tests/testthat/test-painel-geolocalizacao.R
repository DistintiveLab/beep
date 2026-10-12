# Geolocalizacao opcional da aba Regiao (painel_geolocalizacao=1): helpers
# puros de painel_dw.R, testados offline com sf (Imports). O botao em si
# depende do navegador, então o que se testa é a escolha da localidade mais
# próxima (contém o ponto, senão a de representação interna mais próxima) e
# os defaults de nível via painel_nivel.

quadrado <- function(lon0, lon1, lat0, lat1, code) {
  sf::st_sf(code = code,
    geometry = sf::st_as_sfc(list(sf::st_polygon(list(matrix(
      c(lon0, lat0, lon1, lat0, lon1, lat1, lon0, lat1, lon0, lat0),
      ncol = 2, byrow = TRUE)))), crs = 4326))
}

geo <- rbind(quadrado(-49.5, -48.5, -20, -19, "3000001"),
             quadrado(-47.5, -46.5, -17, -16, "3000002"))

test_that("ponto dentro da feicao devolve a propria feicao", {
  expect_identical(beep:::painel_geo_mais_proxima(geo, -19.5, -49),
                   "3000001")
  expect_identical(beep:::painel_geo_mais_proxima(geo, -16.5, -47.2),
                   "3000002")
})

test_that("ponto fora de todas devolve a feicao mais proxima", {
  expect_identical(beep:::painel_geo_mais_proxima(geo, -22, -50),
                   "3000001")
  expect_identical(beep:::painel_geo_mais_proxima(geo, -15.5, -47),
                   "3000002")
})

test_that("geo vazio ou coordenada invalida devolve NA", {
  vazio <- sf::st_sf(code = character(0), geometry = sf::st_sfc(crs = 4326))
  expect_identical(beep:::painel_geo_mais_proxima(vazio, -19.5, -49),
                   NA_character_)
  expect_identical(beep:::painel_geo_mais_proxima(NULL, -19.5, -49),
                   NA_character_)
  expect_identical(beep:::painel_geo_mais_proxima(geo, NA_real_, -49),
                   NA_character_)
  expect_identical(beep:::painel_geo_mais_proxima(geo, -19.5, NA_real_),
                   NA_character_)
})

niveis <- data.frame(
  nivel_id = c("2", "7", "subdistrito"),
  rotulo = c("Município", "Setor censitário", "Subdistrito/RA"),
  n_locais = c(5571L, 100L, 33L))

test_that("nivel default honra a variavel painel_nivel quando existe no catalogo", {
  expect_identical(beep:::painel_nivel_default(niveis, padrao = "subdistrito"),
                   "subdistrito")
  expect_identical(beep:::painel_nivel_default(niveis, padrao = " 7 "), "7")
})

test_that("sem painel_nivel (ou com valor fora do catalogo) cai no municipal", {
  expect_identical(beep:::painel_nivel_default(niveis, padrao = ""), "2")
  expect_identical(beep:::painel_nivel_default(niveis, padrao = "inexistente"), "2")
})

test_that("catalogo sem municipal (ou vazio) cai na UF", {
  sem_mun <- data.frame(nivel_id = "subdistrito", rotulo = "Subdistrito/RA")
  expect_identical(beep:::painel_nivel_default(sem_mun, padrao = ""), "2")
  expect_identical(beep:::painel_nivel_default(NULL, padrao = "subdistrito"),
                   "2")
})

test_that("geolocalizacao so liga com painel_geolocalizacao=1", {
  antiga <- Sys.getenv("painel_geolocalizacao")
  on.exit(if (nzchar(antiga)) Sys.setenv(painel_geolocalizacao = antiga) else
    Sys.unsetenv("painel_geolocalizacao"), add = TRUE)
  Sys.setenv(painel_geolocalizacao = "1")
  expect_true(beep:::painel_geolocalizacao_ativa())
  Sys.setenv(painel_geolocalizacao = "0")
  expect_false(beep:::painel_geolocalizacao_ativa())
  Sys.unsetenv("painel_geolocalizacao")
  expect_false(beep:::painel_geolocalizacao_ativa())
})
