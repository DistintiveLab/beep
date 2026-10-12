# Planilha "um indicador por data": uma aba por data de referencia, cada uma com todas as localidades do nivel territorial com dados naquela data (codigo, nome e valor do refdate exato), mais aba "metadados" com o contexto

Planilha "um indicador por data": uma aba por data de referencia, cada
uma com todas as localidades do nivel territorial com dados naquela data
(codigo, nome e valor do refdate exato), mais aba "metadados" com o
contexto

## Usage

``` r
painel_xlsx_indicador(
  arquivo,
  por_data,
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

- por_data:

  lista nomeada (rotulo de data de
  [`painel_rotulo_aba()`](https://distintivelab.github.io/beep/dev/reference/painel_rotulo_aba.md))
  de data.frames local_id/refdate/value JA restritos ao nivel
  territorial escolhido e JA no refdate exato
  ([`painel_valores_refdate()`](https://distintivelab.github.io/beep/dev/reference/painel_valores_refdate.md));
  as abas seguem a ordem fornecida (refdates ascendentes no caller,
  rótulos ISO ordenam lexicograficamente)

- locais:

  vetor nomeado local_id -\> rotulo do nivel
  ([`painel_locais_nivel()`](https://distintivelab.github.io/beep/dev/reference/painel_locais_nivel.md))

- rotulo_indicador, nivel_rotulo:

  rotulos do indicador e do nivel territorial escolhidos (cabecalho e
  nome do arquivo)

- titulo:

  titulo do painel (cabecalho)

- codigos:

  vetor nomeado local_id (texto) -\> codigo de exibicao da localidade
  (ex.: codigo IBGE dos municipios,
  [`painel_codigo_mun_cache()`](https://distintivelab.github.io/beep/dev/reference/painel_codigo_mun_cache.md));
  localidades fora do vetor mantem o local_id, e a coluna inteira vira
  texto
