# Package index

## All functions

- [`add_external_resources()`](https://distintivelab.github.io/beep/dev/reference/add_external_resources.md)
  : Add External Resources for beep

- [`admin_app()`](https://distintivelab.github.io/beep/dev/reference/admin_app.md)
  : Painel admin (somente leitura) do lote de um projeto

- [`ampliar_nivel_territorial()`](https://distintivelab.github.io/beep/dev/reference/ampliar_nivel_territorial.md)
  : Incorpora um nivel territorial submunicipal a partir de um sf de
  feicoes

- [`anos_rais()`](https://distintivelab.github.io/beep/dev/reference/anos_rais.md)
  : Anos disponiveis no mte_rais (tabelas rais_vinculo_YYYY)

- [`app_server()`](https://distintivelab.github.io/beep/dev/reference/app_server.md)
  : App Server Code

- [`app_ui()`](https://distintivelab.github.io/beep/dev/reference/app_ui.md)
  : App UI

- [`aquecer_painel()`](https://distintivelab.github.io/beep/dev/reference/aquecer_painel.md)
  : Aquece o cache de disco do painel DW apos um ETL

- [`atualizar_grupos_indicadores()`](https://distintivelab.github.io/beep/dev/reference/atualizar_grupos_indicadores.md)
  : Declara e reconcilia os grupos tematicos do catalogo no DW

- [`atualizar_indicadores()`](https://distintivelab.github.io/beep/dev/reference/atualizar_indicadores.md)
  : Roda todos (ou os indicados) scripts de coleta

- [`atualizar_painel()`](https://distintivelab.github.io/beep/dev/reference/atualizar_painel.md)
  : Atualiza um esqueleto de painel ja gerado, preservando edicoes
  locais

- [`body_ui()`](https://distintivelab.github.io/beep/dev/reference/body_ui.md)
  : Body UI

- [`carregar_dependencias()`](https://distintivelab.github.io/beep/dev/reference/carregar_dependencias.md)
  : Carrega a semente de dependencias (coleta/dependencias.csv) para o
  DW

- [`contact_item()`](https://distintivelab.github.io/beep/dev/reference/contact_item.md)
  : Contact Item

- [`contact_menu()`](https://distintivelab.github.io/beep/dev/reference/contact_menu.md)
  : Contact Menu

- [`controle_fim()`](https://distintivelab.github.io/beep/dev/reference/controle_fim.md)
  : Fecha a execucao e atualiza o estado atual do script

- [`controle_inicio()`](https://distintivelab.github.io/beep/dev/reference/controle_inicio.md)
  : Registra o inicio de uma execucao (retorna id do historico p/ fechar
  depois)

- [`controle_preparar()`](https://distintivelab.github.io/beep/dev/reference/controle_preparar.md)
  : Cria (se ausentes) as tabelas de controle e versoes de carga no
  beepdb

- [`db_datawrite()`](https://distintivelab.github.io/beep/dev/reference/db_datawrite.md)
  :

  Do some checking, sanitizing and write to backend database
  [`db_datawrite()`](https://distintivelab.github.io/beep/dev/reference/db_datawrite.md)
  does some checking, sanitizing and writes new data to backend database

- [`definir_dependencias()`](https://distintivelab.github.io/beep/dev/reference/definir_dependencias.md)
  : Define o grafo de dependencias de um script no DW

- [`definir_tipo_grafico()`](https://distintivelab.github.io/beep/dev/reference/definir_tipo_grafico.md)
  : Define o tipo do grafico em destaque de um indicador no painel

- [`definir_visibilidade()`](https://distintivelab.github.io/beep/dev/reference/definir_visibilidade.md)
  : Esconde ou revela um indicador nos seletores do painel

- [`deploy_admin()`](https://distintivelab.github.io/beep/dev/reference/deploy_admin.md)
  : Materializa o painel admin do projeto (launcher)

- [`deploy_panel()`](https://distintivelab.github.io/beep/dev/reference/deploy_panel.md)
  : Deploy do painel de indicadores no projeto corrente

- [`executar_script_coleta()`](https://distintivelab.github.io/beep/dev/reference/executar_script_coleta.md)
  : Executa um unico script de coleta com controle de execucao. Com
  verificar_novidade = TRUE, consulta antes da coleta (C5, ver
  R/verifica_fonte.R) o mais recente disponivel na fonte e, sem
  novidades, registra execucao ok e pula o script.

- [`explorar_n_min`](https://distintivelab.github.io/beep/dev/reference/explorar_n_min.md)
  : Limiar do badge visual de "n insuficiente" (nada e escondido: o n
  aparece sempre junto ao r)

- [`flucol()`](https://distintivelab.github.io/beep/dev/reference/flucol.md)
  : Fluid Column - Shiny fluidRow + Column

- [`garantir_indice_valores()`](https://distintivelab.github.io/beep/dev/reference/garantir_indice_valores.md)
  :

  Garante o indice de `local_id` na tabela `data_values` do DW

- [`gravar_serie_dw()`](https://distintivelab.github.io/beep/dev/reference/gravar_serie_dw.md)
  : Grava (recalculando por completo ou acrescentando) a serie de um
  indicador

- [`header_buttons()`](https://distintivelab.github.io/beep/dev/reference/header_buttons.md)
  : Header Buttons Server Module

- [`header_buttons_ui()`](https://distintivelab.github.io/beep/dev/reference/header_buttons_ui.md)
  : Header Buttons UI Module

- [`header_ui()`](https://distintivelab.github.io/beep/dev/reference/header_ui.md)
  : Header UI

- [`icon_text()`](https://distintivelab.github.io/beep/dev/reference/icon_text.md)
  : Icon Text

- [`incorporar_areas_ponderacao()`](https://distintivelab.github.io/beep/dev/reference/incorporar_areas_ponderacao.md)
  : Incorpora a malha de areas de ponderacao do Censo

- [`incorporar_bairros()`](https://distintivelab.github.io/beep/dev/reference/incorporar_bairros.md)
  : Incorpora bairros derivados dos setores censitarios

- [`incorporar_municipio_ibge()`](https://distintivelab.github.io/beep/dev/reference/incorporar_municipio_ibge.md)
  : Incorpora um municipio criado depois da carga original do DW

- [`incorporar_setores_censitarios()`](https://distintivelab.github.io/beep/dev/reference/incorporar_setores_censitarios.md)
  : Incorpora a malha de setores censitarios de UFs/municipios

- [`insert_logo()`](https://distintivelab.github.io/beep/dev/reference/insert_logo.md)
  : Insert Logo

- [`ler_controle()`](https://distintivelab.github.io/beep/dev/reference/ler_controle.md)
  : Le o controle de um script (ou de todos)

- [`ler_dependencias()`](https://distintivelab.github.io/beep/dev/reference/ler_dependencias.md)
  : Le a semente de dependencias versionada no projeto

- [`listar_scripts_coleta()`](https://distintivelab.github.io/beep/dev/reference/listar_scripts_coleta.md)
  : Lista os scripts de coleta executaveis (sem .ignore)

- [`mod_panel_globe_ui()`](https://distintivelab.github.io/beep/dev/reference/mod_panel_globe_ui.md)
  : panel_globe UI Function

- [`painel_municipio_filtro()`](https://distintivelab.github.io/beep/dev/reference/painel_municipio_filtro.md)
  :

  Fragmento SQL que seleciona apenas municipios (alias `l` no chamador)

- [`panel_app()`](https://distintivelab.github.io/beep/dev/reference/panel_app.md)
  : App do painel de indicadores (objeto shinyApp)

- [`populate_initialdb()`](https://distintivelab.github.io/beep/dev/reference/populate_initialdb.md)
  : populate_initialdb — seeder territorial do DW beep

- [`preparar_niveis_submunicipais()`](https://distintivelab.github.io/beep/dev/reference/preparar_niveis_submunicipais.md)
  : Migra o schema do DW para aceitar niveis territoriais submunicipais

- [`prepare_db()`](https://distintivelab.github.io/beep/dev/reference/prepare_db.md)
  : Prepare app_db

- [`rep_br()`](https://distintivelab.github.io/beep/dev/reference/rep_br.md)
  : Repeat tags\$br

- [`right_sidebar_ui()`](https://distintivelab.github.io/beep/dev/reference/right_sidebar_ui.md)
  : Right Sidebar UI

- [`run_app()`](https://distintivelab.github.io/beep/dev/reference/run_app.md)
  : Run the Shiny Application

- [`run_panel()`](https://distintivelab.github.io/beep/dev/reference/run_panel.md)
  : Painel de indicadores do DW (app Shiny autonoma)

- [`sidebar_ui()`](https://distintivelab.github.io/beep/dev/reference/sidebar_ui.md)
  : Sidebar UI

- [`upload_data_ui()`](https://distintivelab.github.io/beep/dev/reference/upload_data_ui.md)
  : Upload Data Module - UI

- [`verificar_necessidade_atualizacao()`](https://distintivelab.github.io/beep/dev/reference/verificar_necessidade_atualizacao.md)
  : C3: verifica, por orig_name do mdata, se o indicador ja esta
  atualizado no DW

- [`versao_carga_fim()`](https://distintivelab.github.io/beep/dev/reference/versao_carga_fim.md)
  : Fecha o ciclo de carga registrando o resumo e aplicando
  retencao/espelho

- [`versao_carga_inicio()`](https://distintivelab.github.io/beep/dev/reference/versao_carga_inicio.md)
  : Registra o inicio de um ciclo de carga (modelo A: snapshot por
  ciclo)
