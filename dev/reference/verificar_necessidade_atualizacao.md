# C3: verifica, por orig_name do mdata, se o indicador ja esta atualizado no DW

Compara o max(refdate) gravado em data_values para cada orig_name com a
referencia esperada (refdate_esperada). Retorna data.frame com
necessidade de atualizacao por orig_name.

## Usage

``` r
verificar_necessidade_atualizacao(
  orig_names = NULL,
  refdate_esperada = Sys.Date(),
  con = NULL
)
```

## Arguments

- orig_names:

  vetor de orig_names (mdata); NULL = todos

- refdate_esperada:

  data de referencia que se deseja ter carregada (default: hoje). Um
  indicador precisa atualizar quando max(refdate) \< refdate_esperada.

- con:

  conexao aberta opcional
