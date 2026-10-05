# Painel de indicadores do DW (app Shiny autonoma)

Lanca um painel leve de consulta ao DW de indicadores (beepdb): serie
temporal por nivel territorial e localidade com globo de UFs, mapa
coropletico municipal com slider de ano animado e atualizacao
incremental, e pagina Sobre. Nao abre o beep completo — util para
conferir rapidamente o que foi carregado, inclusive em servidor.

## Usage

``` r
run_panel(
  port = NULL,
  titulo = "Painel de Indicadores",
  paleta = c("govbr", "pb")
)
```

## Arguments

- port:

  porta HTTP; default escolhe uma porta livre

- titulo:

  titulo do topbar (default "Painel de Indicadores")

- paleta:

  paleta inicial, `"govbr"` (padrao) ou `"pb"` — ver
  [`panel_app()`](https://distintivelab.github.io/beep/reference/panel_app.md)

## Details

Para materializar uma app deployavel dentro de um projeto, use
[`deploy_panel()`](https://distintivelab.github.io/beep/reference/deploy_panel.md);
para obter so o objeto da app (hospedavel), use
[`panel_app()`](https://distintivelab.github.io/beep/reference/panel_app.md).

Conexao via variaveis de ambiente `user`/`password`/`host`/`dbname`
(mesmo padrao de
[`controle_con()`](https://distintivelab.github.io/beep/reference/controle_con.md)),
com defaults locais.
