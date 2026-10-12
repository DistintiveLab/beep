# Roadmap: formatação de valores por indicador (percentual, moeda, índice)

Plano para que taxas e outros indicadores apareçam **formatados conforme
a sua natureza** (ex.: taxa de abstenção de `16.666667` para `16,7%`) em
todos os pontos de leitura do painel, com a definição vinda de
**metadado do indicador no DW**, e não de regras espalhadas por gráfico.

Perguntas norteadoras (formuladas na origem deste documento):

1.  O formato deve morar no catálogo do DW (tabela auxiliar), em colunas
    de `mdata_exts`, ou em convenção por nome de indicador?
2.  Onde exatamente o formato precisa ser aplicado (gráfico de linha,
    hover, banda, mapa, chips do resumo, exportação)?
3.  Como fica o retrofite de DWs já carregados (ex.: `painel_eleicoes`)
    sem regenerar carga?

Respostas curtas: **(1)** tabela auxiliar `mdata_formato` no DW seguindo
o padrão fail-open de `mdata_grafico`/`mdata_visivel` (sem migração de
schema core do beep); **(2)** um único formatador central
(`painel_fmt_valor()`) consumido por todos os pontos listados na seção
4; **(3)** `INSERT` seletivo pelo helper de administração, com defaults
por classe cobrindo o comum.

## 1. Problema

Indicadores de taxa são percentuais de 0 a 100 (ex.: `tx abstencao ra`,
16 a 23% nas RAs). Hoje o painel formata valores com
[`painel_num()`](https://distintivelab.github.io/beep/dev/reference/painel_num.md)
([`format()`](https://rdrr.io/r/base/format.html) genérico, separadores
pt-BR, até 6 dígitos significativos) ou deixa o plotly decidir (hover de
`ggplotly(tooltip = c("x","y"))` mostra o numérico cru com o separador
padrão). Consequências:

- hover do gráfico de linha/barras/lollipop mostra `16.6666666666667`;
- eixo y idem, sem unidade;
- legenda do mapa e labels mostram `16,66667`;
- chips do resumo da região idem;
- não há como distinguir percentual, número inteiro, R\$ ou índice.

## 2. Estado atual (pontos de apoio)

- [`painel_mdata_extras()`](https://distintivelab.github.io/beep/dev/reference/painel_mdata_extras.md)
  (R/painel_dw.R) já mergeia tabelas auxiliares opcionais no catálogo
  com **fail-open**: `mdata_exts` (freq/classe), `mdata_grafico` (tipo
  do gráfico), `mdata_visivel` (visibilidade). O DW sem as tabelas segue
  com defaults.
- `painel_admin.R` já tem o padrão de helper `garantir_tabela_*` +
  `INSERT` seletivo (criação idempotente quando falta).
- `data_class` já classifica indicadores no DW (classes do catálogo);
  percentuais podem ser inferidos da classe quando não houver override.
- [`painel_num()`](https://distintivelab.github.io/beep/dev/reference/painel_num.md)
  é o formatador atual, com bons separadores pt-BR — vira o motor de
  baixo nível do novo formatador, não é descartado.

## 3. Proposta de metadado: tabela auxiliar `mdata_formato`

``` sql
CREATE TABLE IF NOT EXISTS mdata_formato (
  mdata_id integer PRIMARY KEY REFERENCES mdata(mdata_id),
  formato  text    NOT NULL,  -- 'percent' | 'numero' | 'moeda' | 'indice'
  casas    integer NOT NULL DEFAULT 1,
  escala   double precision NOT NULL DEFAULT 1  -- multiplicador antes de formatar
);
```

- `formato = 'percent'`: anexa `%` (valor armazenado já em 0-100;
  `escala = 0.1` cobriria armazenamento 0-1000 ou 0-1).
- `formato = 'moeda'`: prefixo `R$` (padrão pt-BR).
- `formato = 'indice'`/`'numero'`: sem sufixo; `casas` decide decimais
  (padrão 0 para contagens, 1 a 2 para índices).
- Sem linha na tabela (ou tabela ausente): fallback por `data_class_id`
  (percentual se a classe indicar taxa/percentual) e, em última
  instância, o comportamento atual (`painel_num`), garantindo
  retrocompatibilidade total com DWs existentes.
- Catálogo:
  [`painel_mdata_extras()`](https://distintivelab.github.io/beep/dev/reference/painel_mdata_extras.md)
  ganha colunas `fmt_formato`, `fmt_casas`, `fmt_escala` (fail-open, NA
  quando ausente).
- Administração:
  `garantir_tabela_formato(con, mdata_id, formato, casas, escala)` em
  `painel_admin.R`, mesmo molde dos helpers existentes.

## 4. Pontos de aplicação (o mesmo formatador em todos)

Formatador central:

``` r

painel_fmt_valor(md, mdata_id)  # devolve function(valor) -> character pt-BR
```

construída sobre
[`painel_num()`](https://distintivelab.github.io/beep/dev/reference/painel_num.md) +
sufixo/prefixo + casas; cacheada junto do catálogo (sem nova leitura de
DW por render).

| \# | Ponto | Hoje | Com o formato |
|----|----|----|----|
| 1 | Série (linha/barras/lollipop): eixo y e hover | plotly cru | `plotly::layout(yaxis = list(tickformat))` + `hoverformat`/`text` mapeado com rótulo formatado |
| 2 | Banda (mín/máx/mediana): eixo y e hover | plotly cru | idem \#1 (mesma função de plot, herdando o formatador) |
| 3 | Mapa: legenda (`labFormat`) e tooltip das feições | `painel_num` | `painel_fmt_valor` |
| 4 | Chips do resumo da região e mini-gráficos do accordeon | `painel_num` | `painel_fmt_valor` |
| 5 | Exportação XLSX (`painel_xlsx`) | número cru | manter cru na célula + **formato de célula** do Excel (percent/moeda nativos), para não degradar dados em reanálise |
| 6 | Modal “sobre o indicador” | — | exibir unidade/formato declarado |

Detalhe de implementação para \#1/#2: `ggplotly` não aceita formatador R
direto no hover; a rota robusta é mapear `text = fmt(valor)` na `aes()`
(o tooltip já usa `c("x","y")` hoje e passa a usar `c("x","text")`) e
`tickformat` com `,` decimal via `plotly::layout` (d3-format) ou
`ggplot2::scale_y_continuous(labels = fmt)` antes do `ggplotly` (o
`style()`/[`layout()`](https://rdrr.io/r/graphics/layout.html) do plotly
respeita os labels do ggplot para ticks, e o hover cai no `text`
mapeado).

## 5. Fases

1.  **Schema + catálogo + helper** — `mdata_formato` (DDL em
    `painel_admin.R`), merge em
    [`painel_mdata_extras()`](https://distintivelab.github.io/beep/dev/reference/painel_mdata_extras.md),
    `painel_fmt_valor()` com testes offline (percent/moeda/número,
    casas, escala, fallback NA).
2.  **Série (linha/barras/lollipop)** — eixo y + hover com rótulo
    formatado; valida com `tx abstencao ra` (hover `16,7%`).
3.  **Banda** — mesmo formatador nas três camadas (mín/mediana/máx) e no
    destaque.
4.  **Mapa** — legenda e tooltips das feições.
5.  **Chips + accordeon + modal** — resumo da região e “sobre o
    indicador”.
6.  **XLSX** — formato de célula nativo do Excel por coluna de
    indicador.
7.  **Retrofit do `painel_eleicoes`** — `INSERT`s para as taxas
    (`tx_abstencao_ra`, `taxa_abstencao`) com `('percent', 1, 1)` e
    contagens com `('numero', 0, 1)`; default por classe passa a cobrir
    novos DWs.

Cada fase entra isolada, com testes e bump de versão, e nenhuma quebra
para DW sem a tabela (fail-open em toda a cadeia, como `mdata_grafico`).

## 6. Decisões em aberto

- Valores 0-1 vs 0-100 no armazenamento: padronizar documentando
  `escala`, sem conversão retroativa.
- Casas decimais por padrão para percentual: 1 (lendo `16,7%`) parece o
  equilíbrio; 2 se houver demanda por leitura fina (eixo com menos
  ticks).
- Se o formato deve também sugerir limites do eixo (ex.: percentual
  sempre 0-100) — adiar até houver caso real; o seletor de escala do
  mapa (do zero / mín-máx / quantil) já cobre a percepção de contraste.
