# Verifica, SEM executar o script, se as dependencias declaradas permitem a execucao (mesmo contrato de verificar_novidade_fonte(): retorno list(pular, motivo); em duvida, pular = FALSE, ou seja, executa). Series proprias: declaradas no grafo (series_proprias) ou, em falta, detectadas do texto do script.

Verifica, SEM executar o script, se as dependencias declaradas permitem
a execucao (mesmo contrato de verificar_novidade_fonte(): retorno
list(pular, motivo); em duvida, pular = FALSE, ou seja, executa). Series
proprias: declaradas no grafo (series_proprias) ou, em falta, detectadas
do texto do script.

## Usage

``` r
verificar_dependencias(nome_script, raiz = .beep_raiz(), con = NULL)
```

## Arguments

- nome_script:

  nome do script de coleta (sem .R)

- raiz:

  raiz do projeto dono do lote (diretorio com coleta/)

- con:

  conexao aberta opcional
