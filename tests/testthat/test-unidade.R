# Unidade do indicador (dataunit_num do mdata_exts): o percentual "%"
# exibe x100 com sufixo; frames e caches antigos sem a coluna seguem NA

test_that("painel_unidade_normaliza da trim e vira NA em vazio", {
  u <- beep:::painel_unidade_normaliza(c(" % ", "", NA, "habitantes"))
  expect_identical(u, c("%", NA_character_, NA_character_, "habitantes"))
})

test_that("painel_eh_percent so liga com dataunit_num = %", {
  expect_true(beep:::painel_eh_percent("%"))
  expect_true(beep:::painel_eh_percent(" % "))
  expect_false(beep:::painel_eh_percent(NA_character_))
  expect_false(beep:::painel_eh_percent(""))
  expect_false(beep:::painel_eh_percent("habitantes"))
  expect_false(beep:::painel_eh_percent(NULL))
})

test_that("painel_num exibe x100 com sufixo % e mantem o padrao atual", {
  expect_identical(beep:::painel_num(0.1938426, "%"), "19,38 %")
  expect_identical(beep:::painel_num(0.1938426), "0,193843")
  expect_identical(beep:::painel_num(0.1938426, NA_character_), "0,193843")
  expect_identical(beep:::painel_num(0.1938426, "habitantes"), "0,193843")
  expect_identical(beep:::painel_num(19.5, "%"), "1.950 %")
  expect_identical(beep:::painel_num(c(0.1, 0.25), "%"), c("10 %", "25 %"))
})

test_that("painel_resumo_linhas carrega a unidade e tolera frames sem ela", {
  valores <- data.frame(mdata_id = 1L,
                        refdate = as.Date("2022-10-02"),
                        value = 0.1938426)
  ind <- data.frame(mdata_id = 1L, rotulo = "Um", grupo = "G", raiz = "R",
                    unidade = "%")
  r <- beep:::painel_resumo_linhas(ind, valores)
  expect_identical(r$unidade, "%")
  sem_unidade <- data.frame(mdata_id = 1L, rotulo = "Um", grupo = "G",
                            raiz = "R")
  r2 <- beep:::painel_resumo_linhas(sem_unidade, valores)
  expect_identical(r2$unidade, NA_character_)
})

test_that("painel_resumo_fontes e membros propagam a unidade do catalogo", {
  fontes <- data.frame(
    mdata_id = c(2L, 1L), orig_name = c("taxa", "n_homens"),
    data_name = c(NA_character_, NA_character_),
    data_class_id = c(1L, 1L), unidade = c("%", NA_character_),
    fonte = c("TSE", "IBGE"))
  valores <- data.frame(
    mdata_id = c(1L, 2L),
    refdate = as.Date(c("2022-01-01", "2022-10-02")),
    value = c(42, 0.19))
  r <- beep:::painel_resumo_fontes(fontes, valores)
  expect_identical(r$unidade[r$mdata_id == 2L], "%")
  expect_identical(r$unidade[r$mdata_id == 1L], NA_character_)

  membros <- data.frame(mdata_id = 5L, orig_name = "taxa_abstencao",
                        data_name = "Taxa de abstenção",
                        data_class_id = 1L, unidade = "%",
                        fonte = "beep - estimação própria")
  vm <- data.frame(mdata_id = 5L, refdate = as.Date("2022-10-02"),
                   value = 0.09)
  r2 <- beep:::painel_resumo_membros(membros, vm)
  expect_identical(r2$unidade, "%")
})

test_that("planilhas registram Unidade e mantem valores crus no percentual", {
  valores <- data.frame(
    mdata_id = c(1L, 1L, 2L),
    refdate = as.Date(c("2022-10-02", "2022-10-30", "2022-10-02")),
    value = c(0.1938, 0.21, 5))
  mdata <- data.frame(
    mdata_id = c(1L, 2L), orig_name = c("taxa", "n_homens"),
    data_name = c("Taxa", "Homens"), data_desc = c("d1", "d2"),
    unidade = c("%", NA_character_))
  arq <- tempfile(fileext = ".xlsx")
  on.exit(unlink(arq), add = TRUE)
  beep:::painel_xlsx_regiao(arq, valores, mdata, "X", "Município")
  tab <- openxlsx::read.xlsx(arq, sheet = "dados", startRow = 6)
  # valores crus: o estilo 0.0% e so display (o Excel exibe x100)
  expect_equal(tab[["2022"]][tab$Código == "taxa"], 0.21)
  expect_equal(tab[["2022"]][tab$Código == "n_homens"], 5)
  md <- openxlsx::read.xlsx(arq, sheet = "metadados")
  expect_equal(md$Unidade[md$id == 1], "%")
  expect_true(is.na(md$Unidade[md$id == 2]))

  por_data <- list("2022-10-02" = data.frame(
    local_id = 11L, refdate = as.Date("2022-10-02"), value = 0.1938))
  arq2 <- tempfile(fileext = ".xlsx")
  beep:::painel_xlsx_indicador(arq2, por_data, c("Alfa" = 11), "Taxa",
                               "Município", unidade = "%")
  ctx <- openxlsx::read.xlsx(arq2, sheet = "metadados", colNames = FALSE)
  expect_equal(ctx[[1]][5], "Unidade")
  expect_equal(ctx[[2]][5], "%")
  tab2 <- openxlsx::read.xlsx(arq2, sheet = "2022-10-02")
  expect_equal(tab2$Valor, 0.1938)
})

test_that("UI do upload traz o seletor de unidade do indicador", {
  ui <- as.character(beep::upload_data_ui("data"))
  expect_true(any(grepl("unidade_indicador", ui, fixed = TRUE)))
  expect_true(any(grepl("Unidade do indicador", ui, fixed = TRUE)))
  expect_true(any(grepl("por cento", ui, fixed = TRUE)))
})
