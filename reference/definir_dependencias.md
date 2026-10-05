# Define o grafo de dependencias de um script no DW

Grava em `controle_execucao.dependencias_json` (UPSERT da linha
`(projeto, nome_script)`; `projeto` = basename da raiz).

## Usage

``` r
definir_dependencias(
  nome_script,
  deps,
  series_proprias = character(0),
  raiz = .beep_raiz(),
  con = NULL
)
```

## Arguments

- nome_script:

  nome do script (sem .R)

- deps:

  data.frame com colunas `serie`, `regua`, `acao` - ou vetor de nomes de
  series (assume regua "proprio" e acao "pular")

- series_proprias:

  series gravadas pelo script quando o parse do arquivo nao as encontra
  (default: deteccao automatica na verificacao)

- raiz:

  raiz do projeto dono do lote

- con:

  conexao aberta opcional

## Value

invisivel TRUE
