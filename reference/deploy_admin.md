# Materializa o painel admin do projeto (launcher)

Companheira de
[`admin_app()`](https://distintivelab.github.io/beep/reference/admin_app.md):
grava na raiz do projeto chamador uma launcher Shiny
(`<diretorio>/app.R`) que monta o painel admin somente leitura a partir
do pacote beep instalado. Launcher fino por design: correcoes e novas
abas chegam com o reinstall do beep, sem copias derivadas para
divergirem.

## Usage

``` r
deploy_admin(
  diretorio = "admin",
  raiz = NULL,
  tema = NULL,
  sobrescrever = FALSE
)
```

## Arguments

- diretorio:

  caminho do diretorio da app, relativo ao projeto (default "admin")

- raiz:

  raiz do projeto orquestrado (default: diretorio corrente); usada
  apenas para nomear o projeto no README

- tema:

  paleta do tema visual, `"govbr"` ou `"pb"` (default: NULL resolve a
  variavel de ambiente `beep_paleta` e, sem ela, `"govbr"`); fixada na
  launcher para o painel abrir sempre na mesma paleta

- sobrescrever:

  substitui um app.R ja existente (default FALSE)

## Value

caminho absoluto do diretorio da app (invisivel)

## Details

A app le o banco beepdb com as mesmas credenciais do orquestrador
(variaveis de ambiente `user`, `password`, `host`, `dbname`) e so faz
sentido em localhost/LAN. NAO publicar em host acessivel externamente
sem autenticacao na frente (shinymanager/shinyproxy/VPN): a app expoe
internals do controle e depende de acesso direto ao banco.
