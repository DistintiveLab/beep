# Roda todos (ou os indicados) scripts de coleta

Modelo A (versões de carga): antes do lote, executa pg_dump do beepdb
(beepdb_v\_.dump, ver versao_carga_inicio) e registra a versão com o
commit git do repo. Depois do lote, fecha a versão com o resumo (n
ok/erro).

## Usage

``` r
atualizar_indicadores(
  apenas = NULL,
  dir_dump = "~/backups_beepdb",
  snapshot = TRUE,
  verificar_novidade = TRUE,
  raiz = .beep_raiz()
)
```

## Arguments

- apenas:

  vetor de nomes (sem .R) para restringir; default todos

- dir_dump:

  diretório dos snapshots (default ~/backups_beepdb)

- snapshot:

  lógico (default TRUE); FALSE pula o pg_dump

- verificar_novidade:

  lógico (default TRUE); FALSE desativa a pré-verificação C5 e força a
  coleta mesmo sem novidades na fonte

- raiz:

  raiz do projeto dono do lote (diretório com coleta/); define o
  `projeto` do controle de execucao. Default: cwd com coleta/
