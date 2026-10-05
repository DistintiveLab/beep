# App do painel de indicadores (objeto shinyApp)

Constroi o objeto `shinyApp` do painel de indicadores do DW (beepdb):
aba "Região" com série temporal por nível territorial e localidade
(região, UF, divisões do IBGE ou município) e globo interativo de UFs,
aba "Mapa" coroplético municipal com slider de ano animado, paleta
divergente centrada em 0 (invertível), ajuda por indicador e atualização
incremental (apenas cores e tooltips atravessam a conexão após a
primeira carga da geometria) e aba "Sobre" com informações do autor e
apoio da Distintive. Estrutura visual adaptada do labourvaluesdatapanel:
topbar com marca, abas realçadas e rodapé. E o motor por tras de
[`run_panel()`](https://distintivelab.github.io/beep/reference/run_panel.md)
e da app launcher gerada por
[`deploy_panel()`](https://distintivelab.github.io/beep/reference/deploy_panel.md)
— como ultima expressao de um `app.R` hospedavel, basta
`beep::panel_app()`.

## Usage

``` r
panel_app(
  titulo = "Painel de Indicadores",
  paleta = c("govbr", "pb"),
  assets_dir = NULL
)
```

## Arguments

- titulo:

  titulo do topbar (default "Painel de Indicadores")

- paleta:

  paleta inicial: `"govbr"` (padrao, azul Gov.br) ou `"pb"` (preto e
  branco com toques do roxo da Distintive). O visitante pode trocar no
  botao do topo; a escolha fica salva no navegador

- assets_dir:

  diretorio com os assets do painel (CSS/JS); default o embutido no
  pacote (inst/painel) — o esqueleto gerado por
  [`deploy_panel()`](https://distintivelab.github.io/beep/reference/deploy_panel.md)
  passa o proprio `www/` local

## Details

Marca configuravel por variaveis de ambiente (sobrepoem os argumentos;
ver R/painel_branding.R): `painel_titulo`, `painel_subtitulo`,
`painel_paleta` e `painel_contato`.

Conexao via variaveis de ambiente `user`/`password`/`host`/`dbname`
(mesmo padrao de
[`controle_con()`](https://distintivelab.github.io/beep/reference/controle_con.md)),
com defaults locais.
