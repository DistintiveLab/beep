# Painel admin (somente leitura) do lote de um projeto

App Shiny autonoma de monitoramento do orquestrador para o projeto
chamador: status de cada script de coleta (com o motivo pelo qual foi
pulado, inclusive dependencias), grafo de dependencias declarado,
frescor das series no banco e historico das execucoes. Somente leitura
por design: disparar execucoes continua sendo via cron ou app beep (o
gatilho manual exige lock single-flight, ver
`roadmap_dependencias_orquestrador.md`).

## Usage

``` r
admin_app(raiz = NULL, projeto = NULL, titulo = NULL, tema = NULL)
```

## Arguments

- raiz:

  raiz do projeto orquestrado (default: diretorio corrente); define o
  lote (`coleta/`) e o projeto no controle (`basename`)

- projeto:

  nome do projeto no controle_execucao (default: `.nome_projeto(raiz)`);
  informar explicitamente para monitorar um lote hospedado em outro
  caminho

- titulo:

  titulo da janela/aba

- tema:

  paleta do tema gov.br/pb: `"govbr"` (azul) ou `"pb"` (preto e branco
  com o roxo da Distintive); default (NULL) resolve pela variavel de
  ambiente `beep_paleta`. O botao de alternancia na navbar troca em
  tempo real e persiste no navegador

## Value

objeto `shiny_app` (usar via
[`deploy_admin()`](https://distintivelab.github.io/beep/dev/reference/deploy_admin.md)
ou [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html))

## Details

Companheira de
[`deploy_admin()`](https://distintivelab.github.io/beep/dev/reference/deploy_admin.md),
que materializa uma launcher desta app na raiz do projeto. Conexao:
banco beepdb via variaveis de ambiente (`user`, `password`, `host`,
`dbname`), as mesmas do orquestrador.
