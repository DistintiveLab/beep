# Niveis territoriais do DW (beepdb): constantes, regras e migracao
#
# Fonte unica das convencoes de bloco de `local_id` e das larguras de
# `geoloc_id` (ROADMAP-niveis-submunicipais.md, F1). O DW convive com duas
# numeracoes do bloco de largura 7: a historica de producao (municipios
# 1..5570, estratos PNAD 5571..7086, Brasil = 7087) e a gerada pelo
# populate_initialdb com a malha 2024 (municipios 1..5571 — Boa Esperanca
# do Norte incluida —, estratos PNAD a partir de 5572, linha "Brasil"
# dinâmica, municipios incorporados com append apos ela; ver
# [incorporar_municipio_ibge()]). A fronteira inferior fixa e 5572; a
# superior, em banco, e o local_id da linha "Brasil" (fallback 7087 —
# `bloco_fim` abaixo). Os niveis submunicipais entram em blocos
# proprios, sempre com APPEND — nunca renumerar ids existentes:
#
#   setor censitario     local_id >= 100000    geoloc_id 15-16 digitos
#   bairro               local_id >= 1000000   geoloc_id 11-12 digitos
#   area de ponderacao   local_id >= 2000000   geoloc_id 13 digitos
#
# Codigos submunicipais nao cabem no int4 do `geoloc_id` original (setor
# chega a 16 digitos ~ 5.3e15, acima do int4 mas abaixo de 2^53), por isso a
# migracao para BIGINT (ver [preparar_niveis_submunicipais()]).
#
# ATENCAO: R/painel_dw.R (e sua copia em inst/painel_esqueleto/R/) mantem
# copias LOCAIS dos limites de bloco de proposito — o esqueleto do painel e
# autocontido e nao pode depender deste arquivo. Qualquer mudanca aqui deve
# ser espelhada la (teste test-painel-esqueleto.R vigia a sincronia).

#' Limite do bloco de municipios da malha 2024 (1..5571)
#' @keywords internal
niveis_municipio_limite_id <- 5572L

#' Fim do bloco PNAD (regioes de interesse). Valor estatico de fallback —
#' em banco, a fronteira superior real e o local_id da linha "Brasil"
#' (7087 na numeracao antiga de producao; ~6412 no seeder malha 2024).
#' Passar `bloco_fim` nas helpers quando houver a tabela `local` em maos.
#' @keywords internal
niveis_pnad_bloco_fim <- 7087L

#' Primeiro bloco submunicipal (setores); tudo >= e submunicipal
#' @keywords internal
niveis_submunicipal_inicio <- 100000L

#' Blocos de local_id por tipo de nivel submunicipal (inicio/fim inclusive)
#' @keywords internal
niveis_blocos_local_id <- data.frame(
  tipo = c("setor", "bairro", "area_ponderacao"),
  bloco_inicio = c(100000L, 1000000L, 2000000L),
  bloco_fim = c(999999L, 1999999L, 2999999L)
)

#' Registro dos tipos de nivel territorial: rotulo do painel e larguras
#' (em digitos) aceitas para o geoloc_id. As larguras dos niveis
#' convencionais vem da convencao IBGE ja adotada pelo DW; as submunicipais
#' aceitam mais de uma largura porque a composicao oficial varia entre
#' censos (setor 2022 pode vir com 15 ou 16 digitos conforme a fonte; bairro
#' e mun7 + 4~5). O identificador semantico e o `nivel_tipo` gravado no
#' `local` — a largura so resolve o rotulo no painel.
#' @keywords internal
niveis_territoriais_tipos <- data.frame(
  tipo = c("regiao", "uf", "rgint", "microrregiao", "rgim",
           "municipio", "pnad", "bairro", "area_ponderacao", "setor"),
  rotulo = c("Região", "Unidade da Federação",
             "Região geográfica intermediária", "Microrregião",
             "Região geográfica imediata", "Município",
             "Região de interesse PNAD", "Bairro",
             "Área de ponderação", "Setor censitário"),
  largura_min = c(1L, 2L, 4L, 5L, 6L, 7L, 7L, 11L, 13L, 15L),
  largura_max = c(1L, 2L, 4L, 5L, 6L, 7L, 7L, 12L, 13L, 16L)
)

#' Um local_id e municipio? (bloco malha 2024 + incorporados apos a
#' linha "Brasil", excluindo os blocos submunicipais). `bloco_fim`
#' recebe a fronteira superior dinamica (local_id da linha "Brasil")
#' quando disponivel; o default e o fallback estatico.
#' @keywords internal
eh_municipio_id <- function(local_id, bloco_fim = niveis_pnad_bloco_fim) {
  (local_id < niveis_municipio_limite_id |
     local_id > bloco_fim) &
    local_id < niveis_submunicipal_inicio
}

#' Um local_id pertence a zona de carga "municipal" do sanitize do
#' [db_datawrite()]? Preserva a semantica historica (municipios + agregados
#' convencionais + faixa PNAD 5572..5599 que sempre passou pelo filtro),
#' excluindo apenas os blocos submunicipais novos. `bloco_fim` e a
#' fronteira superior dinamica (linha "Brasil").
#' @keywords internal
eh_zona_carga_municipal <- function(local_id, bloco_fim = niveis_pnad_bloco_fim) {
  (local_id < 6000L | local_id >= bloco_fim) &
    local_id < niveis_submunicipal_inicio
}

#' Normaliza um codigo de localidade (geoloc_id ou equivalente) para texto
#' exato, sem notacao cientifica — Bigint volta do RPostgres como
#' integer64 (bit64) ou numeric, e `as.character()` de double grande
#' produz "1.1002e+14". Codigo real brasileiro tem no maximo 16 digitos
#' (UF 11..53 a esquerda ~ 5.3e15 < 2^53), entao o caminho numerico e
#' exato em double.
#' @keywords internal
normalizar_codigo_geoloc <- function(x) {
  if (inherits(x, "integer64")) {
    as.character(x)
  } else if (is.numeric(x)) {
    format(x, scientific = FALSE, trim = TRUE)
  } else {
    trimws(as.character(x))
  }
}

#' O codigo (ja normalizado ou nao) e submunicipal (9+ digitos)?
#' @keywords internal
eh_codigo_submunicipal <- function(x) {
  nchar(normalizar_codigo_geoloc(x)) >= 9L
}

#' Tipo de nivel territorial pela largura do geoloc_id. Largura 7 e ambigua
#' (municipio OU regiao PNAD — separaveis apenas pelo bloco de local_id);
#' devolve "municipio" com essa ressalva documentada. Largura fora do
#' registro devolve NA.
#' @keywords internal
nivel_tipo_por_largura <- function(largura) {
  largura <- as.integer(largura)
  out <- rep(NA_character_, length(largura))
  for (i in seq_len(nrow(niveis_territoriais_tipos))) {
    regra <- niveis_territoriais_tipos[i, ]
    acerta <- !is.na(largura) &
      largura >= regra$largura_min & largura <= regra$largura_max
    out[acerta & is.na(out)] <- regra$tipo
  }
  out
}

#' Valida codigos submunicipais de um tipo: digitos apenas, largura dentro
#' do registro. Devolve os codigos normalizados; erro cita as larguras
#' observadas para diagnostico.
#' @keywords internal
validar_codigos_nivel <- function(codigos, tipo) {
  regra <- niveis_territoriais_tipos[niveis_territoriais_tipos$tipo == tipo, ]
  if (!nrow(regra)) stop("validar_codigos_nivel: tipo desconhecido: ", tipo)
  codigos <- normalizar_codigo_geoloc(codigos)
  if (any(!grepl("^[0-9]+$", codigos) | is.na(codigos))) {
    stop("validar_codigos_nivel: codigo nao numerico em ", tipo)
  }
  larguras <- table(nchar(codigos))
  fora <- larguras[as.integer(names(larguras)) < regra$largura_min |
                     as.integer(names(larguras)) > regra$largura_max]
  if (length(fora)) {
    stop("validar_codigos_nivel: larguras fora do registro para ", tipo,
         " (", regra$largura_min, "-", regra$largura_max, "): ",
         paste(names(fora), fora, sep = "d x", collapse = ", "))
  }
  codigos
}

#' Proximo local_id livre dentro do bloco de um tipo submunicipal
#' (alocacao por MAX+1 confinada ao bloco)
#' @keywords internal
proximo_local_id_bloco <- function(con, tipo) {
  bloco <- niveis_blocos_local_id[niveis_blocos_local_id$tipo == tipo, ]
  if (!nrow(bloco)) stop("proximo_local_id_bloco: tipo sem bloco: ", tipo)
  as.integer(DBI::dbGetQuery(con, sprintf(paste(
    "SELECT coalesce(max(local_id), %d) AS m FROM local",
    "WHERE local_id >= %d AND local_id <= %d"),
    bloco$bloco_inicio - 1L, bloco$bloco_inicio, bloco$bloco_fim))$m) + 1L
}

## ---------------------------------------------------------------- ##
## Migracao do schema: geoloc_id -> BIGINT + local.nivel_tipo       ##
## ---------------------------------------------------------------- ##

#' Matviews que dependem (direta ou transitivamente) de tabelas base,
#' com definicao e indices — a maquinaria de pg_rewrite/pg_depend segue
#' a mesma abordagem de `.salvar_dependentes_recortes()`
#' (create_extend_geogroup_view.R), generalizada para varias tabelas
#' e fechada por transitividade.
#' @keywords internal
.salvar_dependentes_tabelas <- function(con, tabelas) {
  vistas <- character(0)
  defs <- list()
  alvo <- tabelas
  repeat {
    arr <- paste(sprintf("'%s'", alvo), collapse = ", ")
    q <- tryCatch(DBI::dbGetQuery(con, sprintf(paste(
      "SELECT DISTINCT c.relname AS mv, pg_get_viewdef(c.oid, true) AS def",
      "FROM pg_depend d",
      "JOIN pg_rewrite r ON r.oid = d.objid",
      "AND d.classid = 'pg_rewrite'::regclass",
      "JOIN pg_class c ON c.oid = r.ev_class AND c.relkind = 'm'",
      "WHERE d.refclassid = 'pg_class'::regclass",
      "AND d.refobjid = ANY (ARRAY[%s]::regclass[])",
      "AND d.deptype = 'n'"), arr)), error = function(e) NULL)
    novas <- setdiff(q$mv, vistas)
    if (!length(novas)) break
    vistas <- c(vistas, novas)
    for (nm in novas) defs[[nm]] <- q$def[q$mv == nm][1]
    alvo <- c(tabelas, vistas)
  }
  idx <- if (length(vistas)) {
    DBI::dbGetQuery(con, sprintf(paste(
      "SELECT indexdef FROM pg_indexes WHERE schemaname = 'public'",
      "AND tablename IN (%s)"),
      paste(sprintf("'%s'", vistas), collapse = ", ")))
  } else data.frame(indexdef = character(0))
  list(mvs = vistas, defs = defs, idx = idx$indexdef)
}

#' Recria as matviews salvas em ordem de dependencia: passadas sucessivas
#' tentando criar cada uma ate todas existirem (ou estourar o limite).
#' Cada tentativa roda entre SAVEPOINT/ROLLBACK TO: a funcao e chamada
#' dentro da transacao da migracao e, no PostgreSQL, UMA instrucao falha
#' aborta a transacao inteira ("current transaction is aborted") — sem
#' savepoint, a primeira tentativa prematura derrubaria todas as demais.
#' @keywords internal
.recriar_dependentes_tabelas <- function(con, salvos) {
  pendentes <- salvos$defs
  for (passo in seq_len(length(pendentes) + 1L)) {
    if (!length(pendentes)) break
    for (nm in names(pendentes)) {
      sp <- sprintf("sp_recria_%s", nm)
      DBI::dbExecute(con, sprintf("SAVEPOINT %s", sp))
      ok <- tryCatch({
        DBI::dbExecute(con, sprintf(
          "CREATE MATERIALIZED VIEW %s AS %s", nm, pendentes[[nm]]))
        DBI::dbExecute(con, sprintf("RELEASE SAVEPOINT %s", sp))
        TRUE
      }, error = function(e) {
        try(DBI::dbExecute(con, sprintf("ROLLBACK TO SAVEPOINT %s", sp)),
            silent = TRUE)
        FALSE
      })
      if (ok) pendentes[[nm]] <- NULL
    }
  }
  if (length(pendentes)) {
    stop("preparar_niveis_submunicipais: nao consegui recriar: ",
         paste(names(pendentes), collapse = ", "))
  }
  for (d in salvos$idx) try(DBI::dbExecute(con, d), silent = TRUE)
}

#' Prepara o DW para niveis territoriais submunicipais (idempotente)
#'
#' 1. `geoloc.geoloc_id` e `local.geoloc_id` passam a BIGINT (codigos de
#'    setor chegam a 16 digitos). Matviews dependentes sao salvas
#'    (definicao + indices), dropadas com CASCADE e recriadas depois do
#'    ALTER — o PostgreSQL recusa alterar coluna usada por view/regra.
#'    Chaves estrangeiras que apontam para `geoloc(geoloc_id)` (ex.:
#'    `fk_geoloc_geoloc_id` criada pelo `prepare_db`) sao dropadas e
#'    recriadas com a mesma definicao.
#' 2. `local` ganha a coluna `nivel_tipo` (texto), com backfill pela
#'    largura do geoloc_id e pelo bloco PNAD de local_id; niveis
#'    submunicipais novos recebem o tipo dos loaders
#'    ([ampliar_nivel_territorial()]).
#'
#' Tudo em uma transacao: falha em qualquer passo deixa o banco como estava.
#' Bancos ja migrados sao no-op (verifica o tipo da coluna antes de agir).
#'
#' @param con conexao DBI com o DW; default abre o beepdb local
#' @return invisivel TRUE
#' @export
preparar_niveis_submunicipais <- function(con = NULL) {
  .con_nossa <- is.null(con)
  if (.con_nossa) {
    con <- DBI::dbConnect(
      RPostgres::Postgres(),
      user = Sys.getenv("user", "beep"),
      password = Sys.getenv("password", "aEd1#man@gR"),
      host = Sys.getenv("host", "127.0.0.1"),
      dbname = Sys.getenv("dbname", "beepdb"))
  }
  on.exit(if (.con_nossa) DBI::dbDisconnect(con), add = TRUE)

  tipos <- vapply(c("geoloc", "local"), function(tb) {
    unname(DBI::dbGetQuery(con, sprintf(paste(
      "SELECT data_type FROM information_schema.columns",
      "WHERE table_name = '%s' AND column_name = 'geoloc_id'"), tb))$data_type[1])
  }, character(1))
  precisa_bigint <- any(!is.na(tipos) & tipos != "bigint")

  tem_nivel_tipo <- length(DBI::dbGetQuery(con, paste(
    "SELECT 1 FROM information_schema.columns",
    "WHERE table_name = 'local' AND column_name = 'nivel_tipo'"))[[1]]) > 0

  if (!precisa_bigint && tem_nivel_tipo) return(invisible(TRUE))

  # FKs que referenciam geoloc(geoloc_id): salvar definicao, dropar,
  # recriar apos o ALTER
  fks <- DBI::dbGetQuery(con, paste(
    "SELECT conrelid::regclass::text AS tabela, conname,",
    "pg_get_constraintdef(oid) AS def",
    "FROM pg_constraint",
    "WHERE contype = 'f' AND confrelid = 'geoloc'::regclass"))

  DBI::dbBegin(con)
  tryCatch({
    salvos <- list()
    if (precisa_bigint) {
      if (nrow(fks)) {
        for (i in seq_len(nrow(fks))) DBI::dbExecute(con, sprintf(
          "ALTER TABLE %s DROP CONSTRAINT IF EXISTS %s",
          fks$tabela[i], fks$conname[i]))
      }
      salvos <- .salvar_dependentes_tabelas(con, c("geoloc", "local"))
      for (mv in salvos$mvs) DBI::dbExecute(con, sprintf(
        "DROP MATERIALIZED VIEW IF EXISTS %s CASCADE", mv))
      DBI::dbExecute(con, paste(
        "ALTER TABLE geoloc ALTER COLUMN geoloc_id TYPE BIGINT",
        "USING geoloc_id::bigint"))
      DBI::dbExecute(con, paste(
        "ALTER TABLE local ALTER COLUMN geoloc_id TYPE BIGINT",
        "USING geoloc_id::bigint"))
      .recriar_dependentes_tabelas(con, salvos)
      if (nrow(fks)) {
        for (i in seq_len(nrow(fks))) DBI::dbExecute(con, sprintf(
          "ALTER TABLE %s ADD CONSTRAINT %s %s",
          fks$tabela[i], fks$conname[i], fks$def[i]))
      }
    }
    DBI::dbExecute(con, paste(
      "ALTER TABLE local ADD COLUMN IF NOT EXISTS nivel_tipo TEXT"))
    DBI::dbExecute(con, sprintf(paste(
      "UPDATE local SET nivel_tipo = CASE",
      "WHEN length(geoloc_id::text) = 7 AND local_id >= %d",
      "AND local_id <= %d THEN 'pnad'",
      "WHEN length(geoloc_id::text) = 1 THEN 'regiao'",
      "WHEN length(geoloc_id::text) = 2 THEN 'uf'",
      "WHEN length(geoloc_id::text) = 4 THEN 'rgint'",
      "WHEN length(geoloc_id::text) = 5 THEN 'microrregiao'",
      "WHEN length(geoloc_id::text) = 6 THEN 'rgim'",
      "WHEN length(geoloc_id::text) = 8 THEN 'mesorregiao'",
      "WHEN length(geoloc_id::text) BETWEEN 11 AND 12 THEN 'bairro'",
      "WHEN length(geoloc_id::text) = 13 THEN 'area_ponderacao'",
      "WHEN length(geoloc_id::text) BETWEEN 15 AND 16 THEN 'setor'",
      "WHEN length(geoloc_id::text) = 7 THEN 'municipio'",
      "ELSE nivel_tipo END",
      "WHERE nivel_tipo IS NULL"),
      niveis_municipio_limite_id, niveis_pnad_bloco_fim))
    DBI::dbExecute(con, paste(
      "CREATE INDEX IF NOT EXISTS local_nivel_tipo_idx ON local (nivel_tipo)"))
    DBI::dbCommit(con)
  }, error = function(e) {
    try(DBI::dbRollback(con), silent = TRUE)
    stop("preparar_niveis_submunicipais falhou: ", conditionMessage(e))
  })
  invisible(TRUE)
}
