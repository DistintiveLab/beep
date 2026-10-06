# Banda de contexto min/mediana/max do indicador no nivel territorial aberto, com a serie da localidade selecionada em destaque — porte da plotabanda_destaque do painel_DAHU, sobre o corte transversal do cache achatado [`painel_valores_por_ano_cache()`](https://distintivelab.github.io/beep/dev/reference/painel_valores_por_ano_cache.md). Series anuais/bienais agregam por ano inteiro no eixo x; as demais mantem a data. Contexto todo-NA (nenhum valor finito no periodo) devolve banda vazia sem erro. As camadas de contexto (banda e mediana) saem sem marcadores — e assim que o mod_panel_regiao identifica, no plotly, quais traces silenciar

Banda de contexto min/mediana/max do indicador no nivel territorial
aberto, com a serie da localidade selecionada em destaque — porte da
plotabanda_destaque do painel_DAHU, sobre o corte transversal do cache
achatado
[`painel_valores_por_ano_cache()`](https://distintivelab.github.io/beep/dev/reference/painel_valores_por_ano_cache.md).
Series anuais/bienais agregam por ano inteiro no eixo x; as demais
mantem a data. Contexto todo-NA (nenhum valor finito no periodo) devolve
banda vazia sem erro. As camadas de contexto (banda e mediana) saem sem
marcadores — e assim que o mod_panel_regiao identifica, no plotly, quais
traces silenciar

## Usage

``` r
painel_plot_banda(
  d,
  local_id,
  titulo = NULL,
  cor = "#1351B4",
  rotulo_x = "Ano"
)
```
