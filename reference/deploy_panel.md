# Deploy do painel de indicadores no projeto corrente

Materializa uma app Shiny do painel em `diretorio` do projeto onde for
chamada (default `painel/`), pronta para hospedar — Shiny Server (aponte
o site para o diretorio) ou `rsconnect::deployApp()` (shinyapps.io/Posit
Connect) — ou rodar localmente com `shiny::runApp(diretorio)`. Dois
modos:

## Usage

``` r
deploy_panel(
  diretorio = "painel",
  titulo = "Painel de Indicadores",
  paleta = c("govbr", "pb"),
  esqueleto = TRUE,
  sobrescrever = FALSE
)
```

## Arguments

- diretorio:

  caminho do diretorio da app, relativo ao projeto (default "painel")

- titulo:

  titulo do topbar da app gerada

- paleta:

  paleta inicial da app gerada: `"govbr"` (padrao, azul Gov.br) ou
  `"pb"` (preto e branco com o roxo da Distintive); o visitante pode
  trocar no botao do topo em qualquer caso

- esqueleto:

  modo de geracao: TRUE (default) copia o esqueleto adaptavel; FALSE
  gera so a launcher sobre o pacote beep

- sobrescrever:

  substitui arquivos ja existentes no diretorio (default FALSE)

## Value

caminho absoluto do diretorio da app (invisivel)

## Details

- `esqueleto = TRUE` (default): copia **minimamente funcional e
  autonoma** do painel — o projeto passa a ser dono do codigo e
  adaptar/criar/mudar abas, layout e marca e o esperado. Sao criados
  `app.R`, `R/` (modulos das abas, blocos de UI componiveis, camada de
  dados `painel_dw.R` e marca configuravel `branding.R`), `www/`
  (CSS/JS/logo), um `README.md` de instrucoes e
  `esqueleto_manifest.json` (versao do beep gerador + SHA-256 de cada
  arquivo). A copia nao depende do pacote beep em execucao — so das
  dependencias comuns (shiny, leaflet, plotly, DBI/RPostgres e
  shinyGovBRstyle; ver README gerado).

- `esqueleto = FALSE`: app launcher fina — `app.R` de uma linha chamando
  [`panel_app()`](https://distintivelab.github.io/beep/reference/panel_app.md)
  e README. Toda a logica continua no pacote beep instalado, e
  atualizacoes do painel chegam com o reinstall do pacote. Ideal quando
  o projeto nao pretende customizar.

Esqueletos ja gerados absorvem melhorias do beep com
[`atualizar_painel()`](https://distintivelab.github.io/beep/reference/atualizar_painel.md),
que preserva arquivos com edicoes locais.
