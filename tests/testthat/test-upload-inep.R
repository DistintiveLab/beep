
test_that("choices do INEP nao carregam NA do metainep", {
  skip_if_not_installed("edubr")
  expect_false(any(is.na(gruposinep)))
  expect_false(any(is.na(names(gruposinep))))
  expect_false(any(is.na(variaveisideb)))
  expect_false(any(is.na(recortes)))
  # UI renderiza (o crash era no choicesWithNames do selectizeInput)
  ui <- upload_inep_ui(shiny::NS("data", "inep"),
                       parent_session = list(ns = \(x) paste0("data:", x)))
  expect_s3_class(ui, "shiny.tag.list")
})
