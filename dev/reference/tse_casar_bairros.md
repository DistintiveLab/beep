# Casa bairros do TSE com bairros do DW por (municipio, nome normalizado)

Casa bairros do TSE com bairros do DW por (municipio, nome normalizado)

## Usage

``` r
tse_casar_bairros(municipio, bairro, dw)
```

## Arguments

- municipio:

  vetor de codigos IBGE de municipio (7 digitos) do lado TSE, um por
  linha de votacao

- bairro:

  vetor de nomes de bairro do lado TSE (mesmo comprimento)

- dw:

  data.frame com as colunas `codigo` (bairro 11-12 digitos, texto),
  `local_id` e `local_name` — saida de `ampliar_nivel_territarial()` ou
  consulta ao DW

## Value

lista: `casados` (pares unicos municipio/bairro com codigo e local_id do
DW), `nao_casados` (pares unicos sem casamento, com contagem de
ocorrencias), `ambiguos_dw` (bairros do DW cujo nome normalizado repete
no mesmo municipio — nunca casam) e `resumo`
