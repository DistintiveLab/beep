# Reorientacao de aneis do GeoJSON para o globo (d3-geo) --------------------
# O d3-geo interpreta exteriores anti-horarios como o complemento da feicao
# (disco inteiro pintado); painel_geojson() normaliza para exterior horario
# e furo anti-horario, a convencao das malhas IBGE que ja renderizam certo.

.area_anel <- function(anel) {
  m <- matrix(unlist(anel), ncol = 2, byrow = TRUE)
  n <- nrow(m)
  if (n < 4) return(0)
  sum(m[seq_len(n - 1), 1] * m[2:n, 2] -
        m[2:n, 1] * m[seq_len(n - 1), 2]) / 2
}

# Anel j de um Polygon (j = 1 e o exterior) e anel k do poligono j de um
# MultiPolygon, ja como lista de pares [lon, lat]
.anel_poligono <- function(gj, i = 1, j = 1) {
  gj$features[[i]]$geometry$coordinates[[j]]
}
.anel_multi <- function(gj, i = 1, j = 1, k = 1) {
  gj$features[[i]]$geometry$coordinates[[j]][[k]]
}

test_that("painel_geojson_orientar inverte anel exterior anti-horario (Censo 2022)", {
  # quadrado anti-horario (RFC 7946): o d3-geo desenharia o complemento
  pol <- sf::st_polygon(list(rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 1), c(0, 0))))
  x <- sf::st_sf(code = "1", label = "a",
                 geometry = sf::st_sfc(pol, crs = 4326))
  gj <- jsonlite::fromJSON(beep:::painel_geojson(x), simplifyVector = FALSE)
  expect_equal(abs(.area_anel(.anel_poligono(gj))), 1)  # area preservada...
  expect_lt(.area_anel(.anel_poligono(gj)), 0)          # ...e agora horaria
  expect_identical(gj$features[[1]]$properties$code, "1")
})

test_that("painel_geojson_orientar preserva anel exterior horario (malha IBGE)", {
  pol <- sf::st_polygon(list(rbind(c(0, 0), c(0, 1), c(1, 1), c(1, 0), c(0, 0))))
  x <- sf::st_sf(code = "2", label = "b",
                 geometry = sf::st_sfc(pol, crs = 4326))
  gj <- jsonlite::fromJSON(beep:::painel_geojson(x), simplifyVector = FALSE)
  expect_lt(.area_anel(.anel_poligono(gj)), 0)
  # idempotente: reorientar de novo nao muda nada
  texto <- beep:::painel_geojson(x)
  gj2 <- jsonlite::fromJSON(beep:::painel_geojson_orientar(texto),
                            simplifyVector = FALSE)
  expect_identical(.anel_poligono(gj2), .anel_poligono(gj))
})

test_that("painel_geojson_orientar trata furos e MultiPolygon", {
  # exterior CCW + furo CW (RFC 7946): ambos viram para a convencao d3
  ext <- rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 1), c(0, 0))
  furo <- rbind(c(.25, .25), c(.25, .75), c(.75, .75), c(.75, .25), c(.25, .25))
  pol <- sf::st_polygon(list(ext, furo))
  x <- sf::st_sf(code = "3", label = "c",
                 geometry = sf::st_sfc(pol, crs = 4326))
  gj <- jsonlite::fromJSON(beep:::painel_geojson(x), simplifyVector = FALSE)
  aneis <- gj$features[[1]]$geometry$coordinates
  expect_lt(.area_anel(aneis[[1]]), 0)
  expect_gt(.area_anel(aneis[[2]]), 0)
  # MultiPolygon com um CCW e um CW: os dois exteriores terminam horarios
  mp <- sf::st_multipolygon(list(
    list(rbind(c(2, 0), c(3, 0), c(3, 1), c(2, 1), c(2, 0))),
    list(rbind(c(4, 0), c(4, 1), c(5, 1), c(5, 0), c(4, 0)))))
  xm <- sf::st_sf(code = "4", label = "d",
                  geometry = sf::st_sfc(mp, crs = 4326))
  gjm <- jsonlite::fromJSON(beep:::painel_geojson(xm), simplifyVector = FALSE)
  expect_lt(.area_anel(.anel_multi(gjm, 1, 1)), 0)
  expect_lt(.area_anel(.anel_multi(gjm, 1, 2)), 0)
})

test_that("painel_geojson_orientar nao derruba entrada sem features", {
  expect_identical(
    beep:::painel_geojson_orientar("{\"type\":\"FeatureCollection\"}"),
    "{\"type\":\"FeatureCollection\"}")
})

test_that("geojson viaja como objeto JSON na mensagem do Shiny", {
  # painel_geojson() retorna a classe "json" do jsonlite; o serializer de
  # mensagens do Shiny usa json_verbatim=TRUE e embute o campo verbatim
  # como OBJETO no JSON da mensagem (nao como string escapada). O cliente
  # do globo (inst/painel/painel-globe.js) aceita objeto ou string; este
  # teste fixa o contrato do transporte para nenhum lado mudar sozinho
  # (regressao do globo em branco: JSON.parse de objeto lanca excecao).
  pol <- sf::st_polygon(list(rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 1), c(0, 0))))
  x <- sf::st_sf(code = "1", label = "a",
                 geometry = sf::st_sfc(pol, crs = 4326))
  gj <- beep:::painel_geojson(x)
  expect_s3_class(gj, "json")
  # mesmo efeito do wrapper do Shiny com jsonlite puro
  msg <- jsonlite::toJSON(list(geojson = gj), auto_unbox = TRUE,
                          json_verbatim = TRUE)
  expect_match(msg, '"geojson":\\{"type"', fixed = FALSE)
  # o wrapper instalado do Shiny produz o mesmo objeto verbatim
  skip_if_not_installed("shiny")
  expect_match(shiny:::toJSON(list(geojson = gj)), '"geojson":\\{"type"')
})
