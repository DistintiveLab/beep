# Registra o inicio de uma execucao (retorna id do historico p/ fechar depois)

Registra o inicio de uma execucao (retorna id do historico p/ fechar
depois)

## Usage

``` r
controle_inicio(
  nome_script,
  etapa = "coleta",
  por = Sys.info()[["user"]],
  projeto = "beep"
)
```

## Arguments

- projeto:

  nome do projeto (raiz do lote) dono do script
