# Carrega a semente de dependencias (coleta/dependencias.csv) para o DW

Um
[`definir_dependencias()`](https://distintivelab.github.io/beep/reference/definir_dependencias.md)
por script do manifesto. Depois de carregada, a verificacao em execucao
le direto do DW (o CSV segue como fallback e como registro versionado no
git do projeto).

## Usage

``` r
carregar_dependencias(arquivo, raiz = .beep_raiz(), con = NULL)
```

## Arguments

- arquivo:

  caminho do CSV (default: `<raiz>/coleta/dependencias.csv`)

- raiz:

  raiz do projeto dono do lote

- con:

  conexao aberta opcional

## Value

invisivel data.frame (script, n_deps, n_series_proprias)
