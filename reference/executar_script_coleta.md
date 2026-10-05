# Executa um unico script de coleta com controle de execucao. Com verificar_novidade = TRUE, consulta antes da coleta (C5, ver R/verifica_fonte.R) o mais recente disponivel na fonte e, sem novidades, registra execucao ok e pula o script.

Executa um unico script de coleta com controle de execucao. Com
verificar_novidade = TRUE, consulta antes da coleta (C5, ver
R/verifica_fonte.R) o mais recente disponivel na fonte e, sem novidades,
registra execucao ok e pula o script.

## Usage

``` r
executar_script_coleta(arquivo, raiz = .beep_raiz(), verificar_novidade = TRUE)
```
