# Grupo Resumo do painel: constantes compartilhadas, núcleo do resumo,
# fallback por fonte, membros do grupo e plano de sincronização

test_that("nome do grupo Resumo e o mesmo no painel e no app", {
  expect_identical(beep:::beep_grupo_resumo_nome,
                   beep:::painel_grupo_resumo_nome)
  expect_identical(beep:::painel_grupo_resumo_nome, "Resumo")
})

test_that("painel_resumo_linhas devolve tabela tipada vazia", {
  vazio <- beep:::painel_resumo_linhas(NULL, NULL)
  expect_identical(nrow(vazio), 0L)
  expect_identical(names(vazio),
                   c("grupo", "raiz", "mdata_id", "rotulo", "valor",
                     "refdate", "valor_ant", "refdate_ant"))
  expect_s3_class(vazio$refdate, "Date")
})

test_that("painel_resumo_linhas pega o mais recente e o anterior", {
  ind <- data.frame(mdata_id = 1L, rotulo = "Um", grupo = "G", raiz = "R")
  valores <- data.frame(
    mdata_id = c(1L, 1L, 1L),
    refdate = as.Date(c("2020-01-01", "2022-01-01", "2021-01-01")),
    value = c(10, 30, 20))
  r <- beep:::painel_resumo_linhas(ind, valores)
  expect_identical(r$refdate, as.Date("2022-01-01"))
  expect_equal(r$valor, 30)
  expect_equal(r$valor_ant, 20)
  expect_identical(r$refdate_ant, as.Date("2021-01-01"))
  # data de corte atras da primeira observacao tira o indicador
  expect_identical(nrow(beep:::painel_resumo_linhas(
    ind, valores, refdate = as.Date("2019-01-01"))), 0L)
})

test_that("painel_resumo_fontes rotula com a fonte e ordena por fonte", {
  fontes <- data.frame(
    mdata_id = c(2L, 1L, 3L),
    orig_name = c("abstencoes", "n_homens", "taxa"),
    data_name = c(NA_character_, "Homens", "Taxa de abstenção"),
    data_class_id = c(1L, 1L, 1L),
    fonte = c("TSE", "IBGE Censo", "TSE"))
  valores <- data.frame(
    mdata_id = c(1L, 2L, 2L, 3L),
    refdate = as.Date(c("2022-01-01", "2018-01-01", "2022-01-01",
                        "2022-01-01")),
    value = c(100, 5, 6, 0.12))
  r <- beep:::painel_resumo_fontes(fontes, valores)
  expect_identical(nrow(r), 3L)
  # ordenacao por fonte (IBGE Censo antes de TSE) e mdata_id dentro da fonte
  expect_identical(r$mdata_id, c(1L, 2L, 3L))
  expect_identical(r$grupo, c("IBGE Censo", "TSE", "TSE"))
  expect_identical(unique(r$raiz), "Por fonte")
  expect_identical(r$rotulo[1], "Homens \u2014 IBGE Censo")
  expect_identical(r$rotulo[2], "abstencoes \u2014 TSE")
  expect_equal(r$valor[r$mdata_id == 2L], 6)
  expect_identical(r$refdate_ant[r$mdata_id == 2L], as.Date("2018-01-01"))
  # sem fonte cadastrada entra no rotulo como grupo
  s <- fontes
  s$fonte <- NA_character_
  rs <- beep:::painel_resumo_fontes(s, valores)
  expect_identical(unique(rs$grupo), "Sem fonte cadastrada")
})

test_that("painel_resumo_membros rotula membros com a fonte quando ha", {
  membros <- data.frame(
    mdata_id = c(5L, 1L),
    orig_name = c("taxa_abstencao", "n_homens"),
    data_name = c("Taxa de abstenção", NA_character_),
    data_class_id = c(1L, 1L),
    fonte = c("beep - estimação própria", NA_character_))
  valores <- data.frame(
    mdata_id = c(5L, 1L),
    refdate = as.Date(c("2022-10-02", "2022-07-31")),
    value = c(0.09, 42))
  r <- beep:::painel_resumo_membros(membros, valores)
  expect_identical(r$mdata_id, c(5L, 1L))
  expect_identical(unique(r$grupo), "Resumo")
  expect_identical(r$rotulo[1],
                   paste0("Taxa de abstenção \u2014 beep - estimação própria"))
  expect_identical(r$rotulo[2], "n_homens")
  # vazio devolve tabela tipada
  expect_identical(nrow(beep:::painel_resumo_membros(
    data.frame(), valores)), 0L)
})

test_that("grupo_resumo_plano calcula insercoes e remocoes", {
  plano <- beep:::grupo_resumo_plano(c(1L, 2L, 3L), c(2L, 4L))
  expect_setequal(plano$inserir, c(1L, 3L))
  expect_setequal(plano$remover, 4L)
  vazio <- beep:::grupo_resumo_plano(integer(0), c(1L, 2L), 99L)
  expect_identical(vazio$inserir, integer(0))
  expect_setequal(vazio$remover, c(1L, 2L))
  iguais <- beep:::grupo_resumo_plano(c(7L, 7L), 7L)
  expect_identical(iguais$inserir, integer(0))
  expect_identical(iguais$remover, integer(0))
  com_na <- beep:::grupo_resumo_plano(c(1L, NA), c(1L))
  expect_identical(com_na$inserir, integer(0))
})

test_that("UI do upload traz o painel do grupo Resumo", {
  ui <- as.character(beep::upload_data_ui("data"))
  expect_true(any(grepl("grupo_resumo_vars", ui, fixed = TRUE)))
  expect_true(any(grepl("Salvar grupo Resumo", ui, fixed = TRUE)))
})
