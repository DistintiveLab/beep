# Cliente do globo (inst/painel/painel-globe.js) sem navegador: o harness
# node em scripts/harness-globe.js carrega o JS real com DOM falso e envia
# uma mensagem no formato do observe de mod_panel_globe.R nas duas formas
# de transporte do geojson. Regressao do globo em branco: a classe "json"
# do jsonlite viaja como OBJETO (json_verbatim=TRUE do serializer do
# Shiny) e o cliente fazia JSON.parse do objeto, que lanca excecao
# silenciada; o globo "carregava" com zero feicoes em todos os niveis.

test_that("cliente do globo aceita geojson como objeto e como string", {
  skip_if(Sys.which("node") == "", "node ausente")
  harness <- testthat::test_path("scripts", "harness-globe.js")
  for (forma in c("objeto", "string")) {
    saida <- suppressWarnings(system2(
      "node", shQuote(c(harness, forma)), stdout = TRUE, stderr = TRUE))
    expect_match(paste(saida, collapse = "\n"),
                 paste0("^OK ", forma, "\\b"), fixed = FALSE,
                 info = paste(saida, collapse = "\n"))
  }
})
