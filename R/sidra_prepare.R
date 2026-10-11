# MIGRADO PARA PACOTE SIDRA
####Pega infos para compor buscas


#input n. tabela
#"https://sidra.ibge.gov.br/t/8694/n1/all/n3/all/v/7167,7168/p/all/c11046/all/d/v7167%205,v7168%205"

filtratabs <- \(x="A70"){
  rc <- substr(x,1,1)
  xa <- substr(x,start=2,nchar(x))
  sidra::tab_agr(x)$tabelas
}

# Metadados minimos direto da API v3 (fallback): o sidra::tab_meta
# quebra em tabela SEM classificacoes (bug 1:length(NULL) -> 1:0 no
# pacote, ex. tabela 4709) e devolve NULL em timeout de 2s. Aqui o
# timeout e maior e so entram os campos que o modulo usa
# (nivelTerritorial e variaveis).
.meta_api_v3 <- \(tabela) {
  resp <- tryCatch(
    httr::GET(paste0("https://servicodados.ibge.gov.br/api/v3/agregados/",
                     tabela, "/metadados"),
              httr::timeout(15)),
    error = \(e) NULL)
  if (is.null(resp) || httr::status_code(resp) != 200) return(NULL)
  j <- tryCatch(
    jsonlite::fromJSON(httr::content(resp, "text"),
                       simplifyVector = FALSE),
    error = \(e) NULL)
  if (is.null(j)) return(NULL)
  list(
    nivelTerritorial = unlist(j$nivelTerritorial),
    variaveis = data.frame(
      id = vapply(j$variaveis, \(v) as.character(v$id), character(1)),
      nome = vapply(j$variaveis, \(v) v$nome, character(1))))
}

desctabela <- \(tabela=1705){
  # sidra::tab_meta devolve NULL quando a API do SIDRA nao responde a
  # tempo (timeout de 2s dentro do pacote) e para em tabelas sem
  # classificacao: sem guarda, o chamador faz NULL$nivelTerritorial
  # ("$ operator is invalid for atomic vectors"). Retentativa, depois
  # fallback direto na API e, em ultima instancia, erro claro.
  puxar <- function() tryCatch(sidra::tab_meta(tabela), error = \(e) NULL)
  m <- puxar()
  if (is.null(m) || !is.list(m) || is.null(m$variaveis)) {
    Sys.sleep(1.5)
    m <- puxar()
  }
  if (is.null(m) || !is.list(m) || is.null(m$variaveis)) m <- .meta_api_v3(tabela)
  if (is.null(m) || !is.list(m) || is.null(m$variaveis)) {
    stop("desctabela: metadados da tabela ", tabela,
         " indisponiveis (API do SIDRA sem resposta); tente novamente ",
         "em instantes")
  }
  m
}
