# Planilha "um indicador por ano": uma aba por ano, cada uma com todas as localidades do nivel territorial com dados naquele ano (codigo, nome e valor da ultima observacao do ano), mais aba "metadados" com o contexto

Planilha "um indicador por ano": uma aba por ano, cada uma com todas as
localidades do nivel territorial com dados naquele ano (codigo, nome e
valor da ultima observacao do ano), mais aba "metadados" com o contexto

## Usage

``` r
painel_xlsx_indicador(
  arquivo,
  por_ano,
  locais,
  rotulo_indicador,
  nivel_rotulo,
  titulo = "Painel de Indicadores",
  codigos = NULL
)
```

## Arguments

- arquivo:

  caminho do .xlsx a gravar

- por_ano:

  lista nomeada (ano em texto) de data.frames local_id/refdate/value JA
  restritos ao nivel territorial escolhido e JA na regua de ultima
  observacao do ano
  ([`painel_valores_ano()`](https://distintivelab.github.io/beep/reference/painel_valores_ano.md))

- locais:

  vetor nomeado local_id -\> rotulo do nivel
  ([`painel_locais_nivel()`](https://distintivelab.github.io/beep/reference/painel_locais_nivel.md))

- rotulo_indicador, nivel_rotulo:

  rotulos do indicador e do nivel territorial escolhidos (cabecalho e
  nome do arquivo)

- titulo:

  titulo do painel (cabecalho)

- codigos:

  vetor nomeado local_id (texto) -\> codigo de exibicao da localidade
  (ex.: codigo IBGE dos municipios,
  [`painel_codigo_mun_cache()`](https://distintivelab.github.io/beep/reference/painel_codigo_mun_cache.md));
  localidades fora do vetor mantem o local_id, e a coluna inteira vira
  texto
