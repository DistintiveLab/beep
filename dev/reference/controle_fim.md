# Fecha a execucao e atualiza o estado atual do script

Fecha a execucao e atualiza o estado atual do script

## Usage

``` r
controle_fim(
  nome_script,
  hist_id,
  sucesso,
  etapa = "coleta",
  linhas = NA_integer_,
  mensagem = "",
  hash_estado = NA_character_,
  por = Sys.info()[["user"]],
  projeto = "beep"
)
```

## Arguments

- projeto:

  nome do projeto (raiz do lote) dono do script
