# Auxiliares puros para dados eleitorais (TSE) por bairro (roadmap F4)
#
# Funcoes internas, sem dependencia do pacote tsebr (os arquivos crus vem
# de tsebr/download manual; aqui so casamos e agregamos). PREMISSAS E
# LIMITES DA CORRESPONDENCIA SECAO -> BAIRRO:
#
# 1. Secao eleitoral (TSE) e setor censitario (IBGE) sao recortes
#    INDEPENDENTES: nao existe tabela oficial de equivalencia. A unica
#    ponte auditavel e o bairro declarado no perfil do eleitorado por
#    secao (quando divulgado), usado por tse_mapa_secao_bairro().
# 2. O bairro do cadastro eleitoral pode divergir do bairro derivado do
#    Censo (nome e abrangencia). tse_casar_bairros() casa por
#    (municipio, normalizacao de nome); o que nao casa fica no relatorio
#    de nao-casados — nunca aproximado.
# 3. Secoes cujo perfil traz mais de um bairro distinto ficam SEM bairro
#    (NA) e sao listadas como ambiguas; nenhuma inferencia (mais
#    frequente, maior, etc.).
# 4. A agregacao "por zona" (tse_agregar_votacao) reune apenas as secoes
#    sem bairro determinavel; a zona TSE nao corresponde a nenhum recorte
#    do DW e serve so como fallback auditavel.
# 5. Normalizacao de nome remove diacriticos/pontuacao e colapsa
#    espacos; homonimos dentro do mesmo municipio no lado do DW sao
#    ambiguos e nao casam.

#' Remove diacriticos (compostos e combining marks) sem dependencias
#' @keywords internal
.tse_tirar_diacriticos <- function(x) {
  x <- gsub("[\u0300-\u036f]", "", x, perl = TRUE)
  chartr(
    paste0("\u00e1\u00e0\u00e2\u00e3\u00e4\u00e9\u00e8\u00ea\u00eb",
           "\u00ed\u00ec\u00ee\u00ef\u00f3\u00f2\u00f4\u00f5\u00f6",
           "\u00fa\u00f9\u00fb\u00fc\u00e7",
           "\u00c1\u00c0\u00c2\u00c3\u00c4\u00c9\u00c8\u00ca\u00cb",
           "\u00cd\u00cc\u00ce\u00cf\u00d3\u00d2\u00d4\u00d5\u00d6",
           "\u00da\u00d9\u00db\u00dc\u00c7"),
    paste0("aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC"),
    x)
}

#' Normaliza um nome de bairro/localidade para casamento: maiusculas, sem
#' acentos nem pontuacao, espacos colapsados. Sentinelas de ausencia do
#' TSE ("", "-1", "-") viram NA.
#' @keywords internal
tse_normalizar_nome <- function(x) {
  x <- as.character(x)
  fora <- is.na(x) | x %in% c("", "-1", "-")
  x <- .tse_tirar_diacriticos(x)
  x <- toupper(x)
  x <- gsub("[^A-Z0-9]+", " ", x)
  x <- trimws(gsub(" +", " ", x))
  x[fora] <- NA_character_
  x
}

#' Casa bairros do TSE com bairros do DW por (municipio, nome
#' normalizado)
#'
#' @param municipio vetor de codigos IBGE de municipio (7 digitos) do
#'   lado TSE, um por linha de votacao
#' @param bairro vetor de nomes de bairro do lado TSE (mesmo comprimento)
#' @param dw data.frame com as colunas `codigo` (bairro 11-12 digitos,
#'   texto), `local_id` e `local_name` — saida de
#'   [ampliar_nivel_territarial()] ou consulta ao DW
#' @return lista: `casados` (pares unicos municipio/bairro com codigo e
#'   local_id do DW), `nao_casados` (pares unicos sem casamento, com
#'   contagem de ocorrencias), `ambiguos_dw` (bairros do DW cujo nome
#'   normalizado repete no mesmo municipio — nunca casam) e `resumo`
#' @keywords internal
tse_casar_bairros <- function(municipio, bairro, dw) {
  stopifnot(is.data.frame(dw),
            all(c("codigo", "local_id", "local_name") %in% names(dw)))
  municipio <- normalizar_codigo_geoloc(municipio)
  nome <- tse_normalizar_nome(bairro)

  dw2 <- data.frame(
    municipio = substr(normalizar_codigo_geoloc(dw$codigo), 1, 7),
    nome = tse_normalizar_nome(dw$local_name),
    codigo = normalizar_codigo_geoloc(dw$codigo),
    local_id = dw$local_id,
    local_name = as.character(dw$local_name))
  dw2 <- dw2[!is.na(dw2$nome) & nzchar(dw2$nome), ]

  chave_dw <- paste(dw2$municipio, dw2$nome, sep = "\r")
  dup <- duplicated(chave_dw) | duplicated(chave_dw, fromLast = TRUE)
  ambiguos_dw <- dw2[dup, , drop = FALSE]
  dw2 <- dw2[!dup, , drop = FALSE]
  pos <- setNames(seq_len(nrow(dw2)), chave_dw[!dup])

  chave <- paste(municipio, nome, sep = "\r")
  sem <- is.na(municipio) | is.na(nome)
  chave[sem] <- sprintf("\001ausente%d", seq_along(chave))[sem]
  idx <- unname(pos[chave])
  casou <- !is.na(idx) & !sem

  u <- !duplicated(chave)
  casados <- if (any(casou & u)) {
    data.frame(
      municipio = municipio[casou & u],
      bairro = bairro[casou & u],
      nome_normalizado = nome[casou & u],
      codigo = dw2$codigo[idx[casou & u]],
      local_id = dw2$local_id[idx[casou & u]],
      local_name = dw2$local_name[idx[casou & u]],
      row.names = NULL)
  } else {
    data.frame(municipio = character(0), bairro = character(0),
               nome_normalizado = character(0), codigo = character(0),
               local_id = integer(0), local_name = character(0))
  }

  nc <- u & !casou
  tb <- table(chave[nc])
  chave_nc <- names(tb)
  partes <- strsplit(chave_nc, "\r", fixed = TRUE)
  lin <- match(chave_nc, chave)
  nao_casados <- data.frame(
    municipio = ifelse(is.na(municipio[lin]), NA_character_,
                       vapply(partes, `[`, character(1), 1)),
    bairro = ifelse(is.na(nome[lin]), NA_character_, bairro[lin]),
    n_ocorrencias = as.integer(tb))

  list(casados = casados,
       nao_casados = nao_casados,
       ambiguos_dw = ambiguos_dw,
       resumo = list(
         n_linhas = length(chave),
         n_pares_unicos = sum(u),
         n_casados = nrow(casados),
         n_nao_casados = nrow(nao_casados),
         n_ambiguos_dw = nrow(ambiguos_dw)))
}

#' Mapa secao -> bairro a partir do perfil do eleitorado por secao
#'
#' Uma linha por (municipio, zona, secao). Secoes com um unico bairro no
#' perfil ganham esse bairro; com bairros multiplos ficam NA e sao
#' listadas em `ambiguas`; sem bairro algum ficam NA. Nada e inferido.
#'
#' @param perfil data.frame do perfil do eleitorado por secao (uma linha
#'   por estrato; o bairro se repete nas linhas da mesma secao)
#' @param col_municipio,col_zona,col_secao,col_bairro nomes das colunas
#'   no perfil (defaults no padrao dos arquivos do TSE)
#' @return lista: `mapa` (municipio, zona, secao, bairro, situacao),
#'   `ambiguas` (secoes com bairros multiplos e quantos distintos),
#'   `resumo`
#' @keywords internal
tse_mapa_secao_bairro <- function(perfil,
                                  col_municipio = "CD_MUNICIPIO",
                                  col_zona = "NR_ZONA",
                                  col_secao = "NR_SECAO",
                                  col_bairro = "NM_BAIRRO") {
  falta <- setdiff(c(col_municipio, col_zona, col_secao, col_bairro),
                   names(perfil))
  if (length(falta)) {
    stop("tse_mapa_secao_bairro: colunas ausentes no perfil: ",
         paste(falta, collapse = ", "))
  }
  d <- data.frame(
    municipio = normalizar_codigo_geoloc(perfil[[col_municipio]]),
    zona = normalizar_codigo_geoloc(perfil[[col_zona]]),
    secao = normalizar_codigo_geoloc(perfil[[col_secao]]),
    bairro = tse_normalizar_nome(perfil[[col_bairro]]))

  ch <- paste(d$municipio, d$zona, d$secao, sep = "\r")
  sp <- split(d$bairro, factor(ch, levels = unique(ch)))
  mapa <- data.frame(
    municipio = vapply(strsplit(names(sp), "\r", fixed = TRUE),
                       `[`, character(1), 1),
    zona = vapply(strsplit(names(sp), "\r", fixed = TRUE),
                  `[`, character(1), 2),
    secao = vapply(strsplit(names(sp), "\r", fixed = TRUE),
                   `[`, character(1), 3),
    bairro = rep(NA_character_, length(sp)),
    n_bairros = rep(0L, length(sp)))
  for (i in seq_along(sp)) {
    v <- unique(sp[[i]][!is.na(sp[[i]])])
    mapa$n_bairros[i] <- length(v)
    if (length(v) == 1) mapa$bairro[i] <- v
  }
  mapa$situacao <- ifelse(mapa$n_bairros == 1, "bairro_unico",
                          ifelse(mapa$n_bairros == 0, "sem_bairro",
                                 "bairros_multiplos"))
  ambiguas <- mapa[mapa$situacao == "bairros_multiplos",
                   c("municipio", "zona", "secao", "n_bairros"),
                   drop = FALSE]

  list(mapa = mapa,
       ambiguas = ambiguas,
       resumo = list(
         n_secoes = nrow(mapa),
         n_bairro_unico = sum(mapa$situacao == "bairro_unico"),
         n_sem_bairro = sum(mapa$situacao == "sem_bairro"),
         n_ambiguas = nrow(ambiguas)))
}

#' Agrega a votacao nominal por secao em bairro (e zona, para as secoes
#' sem bairro determinavel)
#'
#' @param votacao data.frame da votacao nominal por secao
#' @param mapa saida de [tse_mapa_secao_bairro()] ou o seu elemento
#'   `$mapa`
#' @param col_municipio,col_zona,col_secao nomes das colunas de chave no
#'   arquivo de votacao (defaults no padrao TSE)
#' @param col_votos nome da coluna de votos
#' @param col_votavel opcional: coluna (numero ou nome) do candidato para
#'   manter o detalhe por votavel na agregacao
#' @return lista: `bairro` (votos por municipio+bairro[+votavel]),
#'   `zona` (votos das secoes sem bairro, por municipio+zona[+votavel]),
#'   `sem_mapa` (secoes da votacao ausentes do mapa, com os votos),
#'   `resumo`
#' @keywords internal
tse_agregar_votacao <- function(votacao, mapa,
                                col_municipio = "CD_MUNICIPIO",
                                col_zona = "NR_ZONA",
                                col_secao = "NR_SECAO",
                                col_votos = "QT_VOTOS",
                                col_votavel = NULL) {
  if (is.list(mapa) && !is.data.frame(mapa) && !is.null(mapa$mapa)) {
    mapa <- mapa$mapa
  }
  stopifnot(is.data.frame(mapa), is.data.frame(votacao))
  falta <- setdiff(c(col_municipio, col_zona, col_secao, col_votos,
                     col_votavel), names(votacao))
  falta <- falta[!is.na(falta)]
  if (length(falta)) {
    stop("tse_agregar_votacao: colunas ausentes na votacao: ",
         paste(falta, collapse = ", "))
  }

  votos <- as.numeric(votacao[[col_votos]])
  votos[is.na(votos)] <- 0
  vm <- normalizar_codigo_geoloc(votacao[[col_municipio]])
  vz <- normalizar_codigo_geoloc(votacao[[col_zona]])
  vs <- normalizar_codigo_geoloc(votacao[[col_secao]])
  vot <- if (!is.null(col_votavel)) {
    as.character(votacao[[col_votavel]])
  } else rep(NA_character_, length(votos))

  ch_v <- paste(vm, vz, vs, sep = "\r")
  ch_m <- paste(mapa$municipio, mapa$zona, mapa$secao, sep = "\r")
  pos <- setNames(seq_len(nrow(mapa)), ch_m)
  idx <- unname(pos[ch_v])
  no_mapa <- !is.na(idx)
  vb <- rep(NA_character_, length(votos))
  vb[no_mapa] <- mapa$bairro[idx[no_mapa]]
  com <- no_mapa & !is.na(vb)

  # agrupa somando votos pelas colunas-chave nomeadas (vetores locais)
  .agrupar <- function(linhas, chaves, nomes) {
    if (!length(linhas)) {
      out <- as.data.frame(setNames(
        rep(list(character(0)), length(nomes)), nomes))
      out$votos <- numeric(0)
      return(out)
    }
    vets <- lapply(chaves, function(k) get(k)[linhas])
    ch <- do.call(paste, c(vets, sep = "\r"))
    soma <- rowsum(votos[linhas], group = ch)
    partes <- strsplit(rownames(soma), "\r", fixed = TRUE)
    out <- as.data.frame(setNames(
      lapply(seq_along(nomes), function(j)
        vapply(partes, `[`, character(1), j)), nomes))
    out$votos <- as.numeric(soma[, 1])
    out
  }

  chaves_v <- if (!is.null(col_votavel)) c("vot") else character(0)
  bairro <- .agrupar(which(com), c("vm", "vb", chaves_v),
                     c("municipio", "bairro",
                       if (!is.null(col_votavel)) col_votavel))
  zona <- .agrupar(which(no_mapa & is.na(vb)), c("vm", "vz", chaves_v),
                   c("municipio", "zona",
                     if (!is.null(col_votavel)) col_votavel))
  sem_mapa <- .agrupar(which(!no_mapa), c("vm", "vz", "vs", chaves_v),
                       c("municipio", "zona", "secao",
                         if (!is.null(col_votavel)) col_votavel))

  list(bairro = bairro, zona = zona, sem_mapa = sem_mapa,
       resumo = list(
         n_linhas = length(votos),
         votos_total = sum(votos),
         votos_bairro = sum(bairro$votos),
         votos_zona = sum(zona$votos),
         votos_sem_mapa = sum(sem_mapa$votos)))
}
