# Planilha "todos os indicadores de uma regiao": aba "dados" com uma linha por indicador (codigo e nome) e uma coluna por ano — celula = ultima observacao do ano na localidade — e aba "metadados" com a ficha de cada indicador incluido

Planilha "todos os indicadores de uma regiao": aba "dados" com uma linha
por indicador (codigo e nome) e uma coluna por ano — celula = ultima
observacao do ano na localidade — e aba "metadados" com a ficha de cada
indicador incluido

## Usage

``` r
painel_xlsx_regiao(
  arquivo,
  valores,
  mdata,
  local_rotulo,
  nivel_rotulo,
  titulo = "Painel de Indicadores"
)
```

## Arguments

- arquivo:

  caminho do .xlsx a gravar

- valores:

  data.frame mdata_id/refdate/value de UMA localidade
  ([`painel_valores_local_todos()`](https://distintivelab.github.io/beep/dev/reference/painel_valores_local_todos.md))

- mdata:

  data.frame mdata_id/orig_name/data_name/data_desc
  ([`painel_mdata()`](https://distintivelab.github.io/beep/dev/reference/painel_mdata.md))

- local_rotulo, nivel_rotulo:

  rotulos da localidade e do nivel territorial escolhidos (cabecalho e
  nome do arquivo)

- titulo:

  titulo do painel (cabecalho)
