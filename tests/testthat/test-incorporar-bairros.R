# Testes offline de F4: dissolve de bairros a partir de setores e
# auxiliares puros do TSE (normalizacao, casamento, mapa secao->bairro,
# agregacao de votos). Sem banco e sem rede — o caminho com gravacao no DW
# e coberto por T8 em test-niveis-dw.R.

.quad <- function(x0, y0) {
  sf::st_polygon(list(matrix(
    c(x0, y0, x0 + 1, y0, x0 + 1, y0 + 1, x0, y0 + 1, x0, y0),
    ncol = 2, byrow = TRUE)))
}

.sem_msg <- function(expr) {
  withCallingHandlers(expr, message = function(m)
    invokeRestart("muffleMessage"))
}

test_that(".resolver_codigo_bairro monta codigos completos", {
  mun <- rep("3106203", 6)
  expect_identical(
    beep:::.resolver_codigo_bairro(c("12", "31062030501", "54321",
                                     "AB", "", NA), mun),
    c("31062030012", "31062030501", "310620354321", NA_character_,
      NA_character_, NA_character_))
})

test_that(".resolver_codigo_bairro rejeita larguras intermediarias", {
  expect_error(beep:::.resolver_codigo_bairro("1234567", "3106203"),
               "nem codigo completo")
})

test_that("dissolve agrupa setores por bairro e deriva o codigo", {
  setores <- sf::st_sf(
    code_tract = c("310620305001001", "310620305001002",
                   "310620305002001"),
    nm_bairro = c("Centro", "Centro", "Jardim das Rosas"),
    code_bairro = c("1", "1", "2"),
    geometry = sf::st_sfc(.quad(0, 0), .quad(1, 0), .quad(5, 5),
                          crs = 4326))
  # sem col_bairro: auto-deteccao precisa achar code_bairro (e nao nm_bairro)
  bairros <- .sem_msg(
    beep:::.dissolver_bairros_setores(setores))
  expect_s3_class(bairros, "sf")
  expect_identical(nrow(bairros), 2L)
  expect_identical(bairros$code_bairro, c("31062030001", "31062030002"))
  expect_identical(bairros$nm_bairro, c("Centro", "Jardim das Rosas"))
  expect_identical(sf::st_crs(bairros)$epsg, 4326L)
  # as duas primeiras quadras caem no bairro 1; a terceira, no bairro 2
  pt <- sf::st_sfc(sf::st_point(c(0.5, 0.5)), sf::st_point(c(1.5, 0.5)),
                   sf::st_point(c(5.5, 5.5)), crs = 4326)
  expect_identical(sf::st_intersects(pt, bairros)[[1]], 1L)
  expect_identical(sf::st_intersects(pt, bairros)[[2]], 1L)
  expect_identical(sf::st_intersects(pt, bairros)[[3]], 2L)
})

test_that("dissolve aceita codigos completos (11-12d) como-is", {
  setores <- sf::st_sf(
    code_bairro = c("31062030501", "310620354321"),
    geometry = sf::st_sfc(.quad(0, 0), .quad(3, 3), crs = 4326))
  bairros <- .sem_msg(beep:::.dissolver_bairros_setores(setores))
  expect_identical(bairros$code_bairro, c("31062030501", "310620354321"))
  expect_identical(bairros$nm_bairro, c(NA_character_, NA_character_))
})

test_that("setores sem bairro ficam fora do dissolve (nunca inferir)", {
  setores <- sf::st_sf(
    code_tract = c("310620305001001", "310620305001002"),
    code_bairro = c("1", NA),
    nm_bairro = c("Centro", "Sem bairro"),
    geometry = sf::st_sfc(.quad(0, 0), .quad(2, 2), crs = 4326))
  expect_message(beep:::.dissolver_bairros_setores(setores),
                 "sem bairro")
  bairros <- .sem_msg(beep:::.dissolver_bairros_setores(setores))
  expect_identical(nrow(bairros), 1L)
  expect_identical(bairros$code_bairro, "31062030001")

  todos_na <- sf::st_sf(code_bairro = c(NA, "-"),
                         geometry = sf::st_sfc(.quad(0, 0), .quad(1, 1),
                                               crs = 4326))
  expect_error(.sem_msg(beep:::.dissolver_bairros_setores(todos_na)),
               "nenhum setor com bairro")
})

test_that("dissolve exige colunas que nao consegue deduzir", {
  expect_error(
    .sem_msg(beep:::.dissolver_bairros_setores(
      sf::st_sf(a = 1, geometry = sf::st_sfc(.quad(0, 0), crs = 4326)))),
    "informe col_bairro")
  # sufixo curto sem coluna de setor para derivar o municipio
  expect_error(
    .sem_msg(beep:::.dissolver_bairros_setores(
      sf::st_sf(code_bairro = "7", nome = "X",
                geometry = sf::st_sfc(.quad(0, 0), crs = 4326)))),
    "informe col_setor")
})

test_that("tse_normalizar_nome remove acentos, pontuacao e sentinelas", {
  expect_identical(beep:::tse_normalizar_nome("São Cristóvão"),
                   "SAO CRISTOVAO")
  expect_identical(beep:::tse_normalizar_nome("  Vila   Nova "),
                   "VILA NOVA")
  expect_identical(beep:::tse_normalizar_nome("Bairro (Velho)"),
                   "BAIRRO VELHO")
  expect_identical(beep:::tse_normalizar_nome("SA\u0303O JOS\u00c9"),
                   "SAO JOSE")
  expect_identical(beep:::tse_normalizar_nome(c("-1", "-", "", NA)),
                   rep(NA_character_, 4))
})

test_that("tse_casar_bairros casa por municipio + nome normalizado", {
  dw <- data.frame(
    codigo = c("31062030001", "31062030002"),
    local_id = c(1000001L, 1000002L),
    local_name = c("Centro", "Jardim das Rosas"))
  r <- beep:::tse_casar_bairros(
    municipio = c("3106203", "3106203", "3106203", "3106203", NA),
    bairro = c("Centro", "  jardim DAS rosas", "Vila Nova", "Centro",
               "Centro"),
    dw = dw)
  expect_identical(nrow(r$casados), 2L)
  expect_identical(r$casados$codigo, c("31062030001", "31062030002"))
  expect_identical(r$casados$local_id, c(1000001L, 1000002L))
  expect_identical(r$casados$nome_normalizado,
                   c("CENTRO", "JARDIM DAS ROSAS"))
  expect_identical(nrow(r$nao_casados), 2L)
  vn <- which(r$nao_casados$municipio == "3106203")
  sm <- which(is.na(r$nao_casados$municipio))
  expect_identical(r$nao_casados$bairro[vn], "Vila Nova")
  expect_identical(r$nao_casados$bairro[sm], "Centro")
  expect_identical(r$nao_casados$n_ocorrencias, c(1L, 1L))
  expect_identical(r$resumo, list(n_linhas = 5L, n_pares_unicos = 4L,
                                  n_casados = 2L, n_nao_casados = 2L,
                                  n_ambiguos_dw = 0L))
})

test_that("tse_casar_bairros trata homonimos no DW como ambiguos", {
  dw <- data.frame(
    codigo = c("31062030001", "31062030002", "31062030003"),
    local_id = c(1000001L, 1000002L, 1000003L),
    local_name = c("Centro", "Centro", "Jardim"))
  r <- beep:::tse_casar_bairros(c("3106203", "3106203"),
                                c("Centro", "Jardim"), dw)
  expect_identical(nrow(r$casados), 1L)
  expect_identical(r$casados$codigo, "31062030003")
  expect_identical(nrow(r$ambiguos_dw), 2L)
  expect_identical(r$resumo$n_ambiguos_dw, 2L)
})

test_that("tse_mapa_secao_bairro mapeia secoes sem inferir nada", {
  perfil <- data.frame(
    CD_MUNICIPIO = c("3106203", "3106203", "3106203", "3106203",
                     "3106203"),
    NR_ZONA = c(1, 1, 1, 1, 2),
    NR_SECAO = c(1, 1, 2, 2, 1),
    NM_BAIRRO = c("Centro", "Centro", "Jardim", "Vila Nova", "Centro"))
  r <- beep:::tse_mapa_secao_bairro(perfil)
  m <- r$mapa
  expect_identical(nrow(m), 3L)
  expect_identical(m$bairro, c("CENTRO", NA_character_, "CENTRO"))
  expect_identical(m$situacao, c("bairro_unico", "bairros_multiplos",
                                 "bairro_unico"))
  expect_identical(nrow(r$ambiguas), 1L)
  expect_identical(r$ambiguas$n_bairros, 2L)
  expect_identical(r$resumo, list(n_secoes = 3L, n_bairro_unico = 2L,
                                  n_sem_bairro = 0L, n_ambiguas = 1L))

  sem <- beep:::tse_mapa_secao_bairro(data.frame(
    CD_MUNICIPIO = "3106203", NR_ZONA = 1, NR_SECAO = 9,
    NM_BAIRRO = "-1"))
  expect_identical(sem$mapa$situacao, "sem_bairro")
  expect_identical(sem$resumo$n_sem_bairro, 1L)

  expect_error(beep:::tse_mapa_secao_bairro(perfil[, 1:3]),
               "colunas ausentes")
})

test_that("tse_agregar_votacao soma por bairro, zona e sem mapa", {
  mapa <- beep:::tse_mapa_secao_bairro(data.frame(
    CD_MUNICIPIO = c("3106203", "3106203", "3106203", "3106203",
                     "3106203", "3106203"),
    NR_ZONA = c(1, 1, 1, 1, 1, 2),
    NR_SECAO = c(1, 1, 2, 2, 3, 1),
    NM_BAIRRO = c("Centro", "Centro", "Jardim", "Vila Nova", "-1",
                  "Centro")))
  votacao <- data.frame(
    CD_MUNICIPIO = c("3106203", "3106203", "3106203", "3106203",
                     "3106203", "9999999"),
    NR_ZONA = c(1, 1, 1, 1, 2, 1),
    NR_SECAO = c(1, 1, 2, 3, 1, 1),
    NR_VOTAVEL = c("A", "B", "A", "B", "A", "A"),
    QT_VOTOS = c(10L, 5L, 3L, 7L, 4L, 2L))
  res <- beep:::tse_agregar_votacao(votacao, mapa,
                                    col_votavel = "NR_VOTAVEL")
  # secao 1 zona 1 (Centro, 10+5) + secao 1 zona 2 (Centro, 4)
  expect_identical(res$bairro$municipio, c("3106203", "3106203"))
  expect_identical(res$bairro$bairro, c("CENTRO", "CENTRO"))
  expect_identical(res$bairro$NR_VOTAVEL, c("A", "B"))
  expect_identical(res$bairro$votos, c(14, 5))
  # secao 2 (ambigua) e secao 3 (sem bairro) caem na zona 1
  expect_identical(res$zona$municipio, c("3106203", "3106203"))
  expect_identical(res$zona$zona, c("1", "1"))
  expect_identical(res$zona$NR_VOTAVEL, c("A", "B"))
  expect_identical(res$zona$votos, c(3, 7))
  # municipio fora do mapa
  expect_identical(res$sem_mapa$municipio, "9999999")
  expect_identical(res$sem_mapa$votos, 2)
  expect_identical(res$resumo, list(n_linhas = 6L, votos_total = 31,
                                    votos_bairro = 19, votos_zona = 10,
                                    votos_sem_mapa = 2))
})

test_that("tse_agregar_votacao sem col_votavel soma tudo por bairro", {
  mapa <- beep:::tse_mapa_secao_bairro(data.frame(
    CD_MUNICIPIO = c("3106203", "3106203"),
    NR_ZONA = c(1, 1), NR_SECAO = c(1, 2),
    NM_BAIRRO = c("Centro", "Centro")))
  votacao <- data.frame(
    CD_MUNICIPIO = c("3106203", "3106203"),
    NR_ZONA = c(1, 1), NR_SECAO = c(1, 2),
    QT_VOTOS = c(10L, 5L))
  res <- beep:::tse_agregar_votacao(votacao, mapa)
  expect_identical(res$bairro$bairro, "CENTRO")
  expect_identical(res$bairro$votos, 15)
  expect_identical(res$resumo$votos_zona, 0)
  # aceita tambem o objeto completo (lista com $mapa)
  expect_identical(beep:::tse_agregar_votacao(votacao, mapa)$bairro$votos,
                   15)
})
