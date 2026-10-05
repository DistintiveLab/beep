# C5: verifica, SEM executar o script, se a fonte tem dados mais recentes do que o que ja consta (DW ou cache). Retorno: list(pular = logical, motivo = character, assinatura = character(1)). Em duvida (fonte desconhecida, primeira carga, probe fora do ar), pular = FALSE, ou seja, executa a coleta.

C5: verifica, SEM executar o script, se a fonte tem dados mais recentes
do que o que ja consta (DW ou cache). Retorno: list(pular = logical,
motivo = character, assinatura = character(1)). Em duvida (fonte
desconhecida, primeira carga, probe fora do ar), pular = FALSE, ou seja,
executa a coleta.

## Usage

``` r
verificar_novidade_fonte(nome_script, raiz = .beep_raiz(), con = NULL)
```

## Arguments

- nome_script:

  nome do script de coleta (sem .R)

- raiz:

  raiz do projeto beep

- con:

  conexao aberta opcional
