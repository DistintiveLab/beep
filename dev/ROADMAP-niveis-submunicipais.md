# Roadmap: níveis territoriais submunicipais (bairro e setor censitário)

Plano para ampliar o ecossistema territorial do `beep` além do nível
municipal, viabilizando **dados eleitorais (TSE)** e
**microdados/tabulações do Censo IBGE por bairro ou setor censitário**,
sem obrigar bancos que não precisam disso a carregarem o volume extra.

Perguntas norteadoras (formuladas na origem deste documento):

1.  A opção de ampliar/popular níveis submunicipais deve ser uma flag de
    ambiente, ou um módulo independente da população inicial do banco?
2.  A largura dos códigos de setor censitário e de bairro colide com os
    intervalos já povoados por padrão?
3.  A diferenciação `local_id` (id sequencial interno) vs `geoloc_id`
    (código IBGE externo) já resolve essas colisões?

Respostas curtas: **(1)** módulo independente, com env var apenas como
conveniência de configuração; **(2)** as larguras novas não colidem
entre si nem com 1–8, mas há colisões indiretas via faixas de `local_id`
e via tipo do campo; **(3)** parcialmente — o armazenamento sim, as
regras de negócio não (análise completa na seção 3).

## 1. Objetivo e escopo

- Novos níveis territoriais no DW: **setor censitário** (Censo IBGE),
  **área de ponderação** (subproduto natural, agregação de setores) e
  **bairro** (codificação composta, geometria derivada dos setores
  quando possível).
- Fontes-alvo: malhas e tabulações por setor do Censo IBGE (2022, com
  2010 como retrocompatibilidade opcional) e dados eleitorais do TSE
  (votação por seção/zona e eleitorado, agregados por bairro).
- Fora de escopo (por enquanto): endereços (CNEFE) como nível;
  internacional; níveis intraurbanos não-oficiais (prefeituras).

## 2. Estado atual (pontos de apoio e de atrito)

### 2.1 Identidade de nível = largura do `geoloc_id`

O nível territorial de uma localidade é inferido da **largura em dígitos
do `geoloc_id`**: 1 grande região, 2 UF, 4 RGINT, 5 microrregião, 6
RGIM, 7 município, `7p` PNAD, 8 mesorregião (`painel_niveis_rotulo`,
`R/painel_dw.R:325`); o filtro SQL vem de
[`painel_nivel_parse()`](https://distintivelab.github.io/beep/dev/reference/painel_nivel_parse.md)
(`R/painel_dw.R:358`, `length(g.geoloc_id::text) = N`). O painel só
lista níveis que possuem dados
([`painel_niveis()`](https://distintivelab.github.io/beep/dev/reference/painel_niveis.md),
`R/painel_dw.R:396`) — níveis novos **aparecem sozinhos** no seletor
quando alguém grava dados neles.

### 2.2 Blocos de `local_id`

- `1..5570`: municípios históricos (Brasília incluída);
- `5571..7087`: bloco reservado às regiões de interesse PNAD (146
  usadas);
- `7088+`: municípios incorporados depois da carga original
  ([`incorporar_municipio_ibge()`](https://distintivelab.github.io/beep/dev/reference/incorporar_municipio_ibge.md)).

`local_id` é **sequencial interno** (nunca renumerado; `data_values` o
referencia) e `geoloc_id` carrega o **código externo IBGE** — essa
separação é o que permitiu, p. ex., o bloco PNAD dividir a largura 7 sem
mexer nos municípios.

### 2.3 Regras “é município” espalhadas por faixa de `local_id`

Este é o principal ponto de atrito. Hoje ser município é decidido por
`local_id < 5571 OU local_id > 7087` (variantes `< 6000 | > 7087`), em:

| Onde | O que faz |
|----|----|
| [`montar_lookup_locais()`](https://distintivelab.github.io/beep/dev/reference/montar_lookup_locais.md) (`R/gravar_serie_dw.R:37`) | inclui o local no lookup por prefixo IBGE 6d |
| [`db_datawrite()`](https://distintivelab.github.io/beep/dev/reference/db_datawrite.md) sanitize (`R/dbdatawriter.R:92` e `:101`) | monta `geoloc_idc = substr(geoloc_id, 1, 6)` e junta por ele |
| [`painel_municipio_filtro()`](https://distintivelab.github.io/beep/dev/reference/painel_municipio_filtro.md) (`R/painel_dw.R:345`), usado em `painel_geo_mun` (`:109`), `painel_codigo_mun` (`:129`), `painel_nivel_parse` (`:370`) e `painel_geo_local` (`:582`) | seleciona municípios para mapa/base do globo/código da aba Baixar |

### 2.4 Padrões prontos para reuso

- [`incorporar_municipio_ibge()`](https://distintivelab.github.io/beep/dev/reference/incorporar_municipio_ibge.md)
  (`R/incorporar_municipio_ibge.R`): o modelo de “adicionar localidades
  depois” — baixa malha, insere geometria simplificada (0,01°), aloca
  `local_id` por append, vincula recortes do pai e regenera
  `recortes_geograficos` preservando matviews dependentes.
- Níveis pesados no globo: base das UFs + destaque da localidade +
  contexto do pai
  ([`painel_geo_local()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_local.md),
  [`painel_geo_pai_uf()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_pai_uf.md)),
  com teto de feições — padrão a estender para “setores/bairros do
  município em foco”.
- Cache de duas camadas com TTLs por tipo de leitura
  (`R/painel_cache.R`).

## 3. Análise de colisão (a pergunta central)

**A separação `local_id`/`geoloc_id` resolve o armazenamento, mas não as
regras.** Três bloqueios concretos:

1.  **`geoloc_id` é INTEGER (int4)** — criado a partir dos tribbles de
    `dbprepare` com `as.integer` (`R/dbprepare.R:37-39`, `:59-62`). int4
    vai até 2 147 483 647 (10 dígitos, e nem todos). Códigos
    submunicipais não cabem:

    - setor censitário: ~15-16 dígitos (composição
      UF+mun+distrito+subdistrito+ setor; confirmar exatamente na
      documentação da malha do Censo 2022);
    - área de ponderação: ~13 dígitos (verificar);
    - bairro: não há código nacional oficial único; a construção natural
      é **composta** — geocódigo do município (7d) + código do bairro no
      município (TSE: numérico pequeno; Censo: atributo dos setores) —
      dando 11-12 dígitos, também estourando int4. → exige migração para
      **BIGINT** (int8 acomoda 18-19 dígitos; cobre tudo) ou código
      externo em coluna auxiliar texto/numérica com surrogate interno.

2.  **Colisão indireta via faixa de `local_id`**: qualquer bloco
    submunicipal novo acima de 7087 seria tratado como município pelas
    regras da seção 2.3. Efeito prático duplo: (a) o prefixo 6d do
    setor/bairro é **exatamente** o código do município pai — entraria
    em disputa com o próprio município no
    [`montar_lookup_locais()`](https://distintivelab.github.io/beep/dev/reference/montar_lookup_locais.md)/`db_datawrite`; (b)
    [`painel_geo_mun()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_mun.md)/
    [`painel_codigo_mun()`](https://distintivelab.github.io/beep/dev/reference/painel_codigo_mun.md)
    passariam a devolver setores no mapa municipal e na coluna “Código”
    das planilhas (o filtro deles não confere largura).

3.  **Largura como identidade de nível**: larguras novas (11 bairro, 13
    área de ponderação, 16 setor — valores exatos a fixar na F0) **não
    colidem** com nenhuma em uso (1, 2, 4, 5, 6, 7, 8) nem entre si;
    cada largura vira um nível distinto automaticamente, inclusive na
    chave do seletor e do cache. A condição é reservar **uma largura por
    tipo** (fixando o número de dígitos do código do bairro com
    zero-à-esquerda) — se dois tipos dividirem a mesma largura,
    precisarão do padrão de sufixo (`"7p"`) ou de coluna explícita de
    tipo. Recomenda-se os dois: largura única por tipo **e** coluna de
    tipo (seção 5, F1).

Conclusão para a memória do autor: a diferenciação
`local_id`/`geoloc_id` **não** basta sozinha; ela precisa ser
complementada por (i) BIGINT no `geoloc_id`, (ii) regras “é município”
que considerem largura/tipo, e (iii) uma largura reservada por tipo
submunicipal.

## 4. Decisão de design: env var vs módulo independente

**Recomendação: módulo independente, com env var apenas como
conveniência.**

- [`prepare_db()`](https://distintivelab.github.io/beep/dev/reference/prepare_db.md)
  continua criando o banco municipal padrão, intacto — bancos de painéis
  que não usam submunicipal não pagam volume algum (cenário majoritário;
  ver volumes na F0).
- Um carregador dedicado, seguindo o padrão `incorporar_*`:
  - `incorporar_setores_censitarios(con, ufs = ..., ano = 2022)`
  - `incorporar_areas_ponderacao(con, ufs = ...)`
  - `incorporar_bairros(con, ufs = ..., fonte = c("censo", "tse"))`
    (candidatos a wrappers de um genérico
    [`ampliar_nivel_territorial()`](https://distintivelab.github.io/beep/dev/reference/ampliar_nivel_territorial.md)).
- Env vars (`beep_niveis_submunicipais`, `beep_nivel_bairro_fonte` etc.)
  não decidem **se** o banco é ampliado — isso é ato explícito do
  carregador — mas podem configurar defaults do carregador e do painel
  (p. ex. nível de abertura). Auto-descoberta já existe:
  [`painel_niveis()`](https://distintivelab.github.io/beep/dev/reference/painel_niveis.md)
  só lista níveis com dados.
- Vantagens do módulo: auditável (o carregador registra o que criou,
  como o manifest do esqueleto do painel), reversível (remoção por
  tipo), testável isoladamente, e com potencial para outros níveis
  futuros (distrito, subdistrito, região metropolitana, seção eleitoral)
  sem novo desenho.

### Alternativa avaliada e rejeitada: bloco municipal contíguo com placeholders

Considerou-se reservar `local_id` 1..5599 para municípios, com
5572..5599 como linhas marcadas como “vazio”, para que “é município”
virasse um único `local_id <= 5599`. Rejeitado porque:

- exigiria **renumerar** o bloco PNAD (gravado em produção na faixa
  alta, 6941..7086), violando a invariante “nunca renumerar ids
  existentes” (`data_values` os referencia) — e `prepare_db` nem povoa
  `local`; o bloco vive no DW de produção, fora do alcance de migração
  simples do pacote;
- a reserva de 28 slots é pequena demais: o Brasil cria municípios em
  lotes (propostas em tramitação superam 28 com folga) e os novos já
  entram por append em 7088+ — a contiguidade voltaria a quebrar,
  recriando o problema;
- linhas-fantasma na tabela `local` poluem listagens como
  [`painel_locais()`](https://distintivelab.github.io/beep/dev/reference/painel_locais.md)
  e criam uma convenção nova (“excluir os vazios”) que todo consumidor
  precisaria lembrar — o oposto de simplificar;
- a coluna `nivel_tipo` da F1 já entrega o mesmo benefício
  (`WHERE nivel_tipo = 'município'`), sem migração e imune ao
  crescimento do bloco.

O que se aproveita da intuição: a **fonte única de constantes de bloco**
(item da F1 abaixo) torna os blocos, contíguos ou não, irrelevantes para
quem escreve filtro.

## 5. Fases

### F0 — Auditoria e spike (sem mudança de schema)

- Fixar as larguras oficiais e volumes reais: composição exata do código
  de setor 2022 e 2010, código da área de ponderação, código/atributo de
  bairro nos produtos do Censo (malha de setores, CNEFE) e do TSE;
  contagens (setores ~316 mil em 2010 e ~450 mil em 2022, a confirmar;
  áreas de ponderação; bairros) e tamanho das malhas (GPKG nacional).
- Inventariar todos os pontos com regra por faixa de `local_id` ou por
  largura (grep de `5571|7087|6000|eh_mun|painel_municipio_filtro`) —
  checklist de migração (a seção 2.3 é o ponto de partida).
- Spike BIGINT: migrar `geoloc_id` num banco clone e validar o fluxo
  completo (RPostgres/bit64 ou leitura como texto/numeric; joins em
  views e matviews; `dbWriteTable`/DDL do `prepare_db`; `ddlx.sql`).
- Protótipo descartável: um município com seus setores carregados, do
  insert à exibição no painel (globo com destaque municipal).

**Critério de pronto:** tabela de larguras/volumes fechada; spike BIGINT
verde; lista de arquivos-a-tocar revisada.

### F1 — Fundação de schema (retrocompatível, idempotente)

- Migração `geoloc_id` INTEGER→BIGINT (`ALTER TABLE ... TYPE bigint`),
  com recriação das views/matviews dependentes (`named_datavalues`,
  `geonamed_datavalues`, join com `recortes_geograficos.codigo_ibge` —
  submunicipais ficam com contexto NULL nesse join, LEFT JOIN já
  tolera). Padrão
  [`controle_preparar()`](https://distintivelab.github.io/beep/dev/reference/controle_preparar.md)
  de migração idempotente.
- Coluna explícita de tipo de nível em `local` (p. ex.
  `local.nivel_tipo`: `municipio|pnad|setor|bairro|ponderacao|...`),
  povuada por convenção de largura nos bancos existentes (backfill) e
  exigida nos carregadores novos. As regras “é município” (seção 2.3)
  passam a usar tipo/largura, não só faixa de id — matando a ambiguidade
  de vez.
- Reserva documentada dos blocos de `local_id` submunicipais (proposta:
  setores `100000+`, bairros `1000000+`, áreas de ponderação `2000000+`
  — todos int4, fora da zona de crescimento dos municípios
  incorporados), com alocação por `MAX(local_id) + 1` dentro do tipo
  (padrão `incorporar_municipio_ibge`).
- **Fonte única das constantes de bloco**: os limiares hoje vivem
  duplicados e divergentes como literais (`<5571`, `<6000`, `<5800`,
  `>7087` em `gravar_serie_dw.R`, `dbdatawriter.R`, `painel_dw.R` e
  `create_extend_geogroup_view.R`) — centralizar num arquivo só (p. ex.
  `R/niveis_territoriais.R`) com a tabela canônica de blocos e helpers
  `eh_municipio_id()` / `eh_municipio_geoloc()`, de modo que a
  contiguidade (ou não) dos blocos deixe de importar para quem escreve
  filtro.
- Testes de regressão do
  [`montar_lookup_locais()`](https://distintivelab.github.io/beep/dev/reference/montar_lookup_locais.md)
  com setores presentes: o prefixo 6d do setor **não** pode sombrear o
  município; séries com códigos longos resolvem pelo geoloc completo.

**Critério de pronto:** banco migrado passa em toda a suíte atual +
testes novos de não-colisão.

### F2 — Carregador IBGE (setor censitário e área de ponderação)

- [`incorporar_setores_censitarios()`](https://distintivelab.github.io/beep/dev/reference/incorporar_setores_censitarios.md):
  malha de setores por UF (GPKG), geometria simplificada (0,01°; avaliar
  0,001° seletivo para áreas urbanas densas), `geoloc_id` = código do
  setor (bigint), `local` com tipo setor e pai = município; sem vínculo
  em `recortes_geograficos` (herda contexto do pai na leitura);
  regeneração segura de matviews.
- [`incorporar_areas_ponderacao()`](https://distintivelab.github.io/beep/dev/reference/incorporar_areas_ponderacao.md):
  nível derivado — dissolve dos setores (ou malha oficial de APs) +
  código próprio.
- Parâmetro `ufs =` para carga parcial (a nacional completa é operação
  de minutos-horas e ~GB de geometria; a majoritária dos usos será por
  estado ou município).
- Registro do que foi carregado (tabela/manifest de proveniência,
  análoga ao `esqueleto_manifest.json` do painel) para suportar
  remoção/atualização.

**Critério de pronto:** DW de teste com setores de 1+ UF; painel exibe
nível “setor” com dados de brinquedo gravados via
[`gravar_serie_dw()`](https://distintivelab.github.io/beep/dev/reference/gravar_serie_dw.md).

### F3 — Camada de dados (escrita, leitura e painel)

- Lookup de escrita:
  [`montar_lookup_locais()`](https://distintivelab.github.io/beep/dev/reference/montar_lookup_locais.md)
  passa a resolver códigos longos (11-16d) pelo geoloc completo, com
  prioridade determinística por largura (6d do município continua
  valendo só para municípios);
  [`db_datawrite()`](https://distintivelab.github.io/beep/dev/reference/db_datawrite.md)
  e o sanitize do upload (`geoloc_idc` por `substr`) filtrados por tipo
  município.
- Agregações DW→DW pela hierarquia de pai: setor→área de
  ponderação→bairro→ município (dissolve em SQL/R, scripts A5b padrão).
- Painel: rótulos novos em `painel_niveis_rotulo` (`"11"` Bairro, `"13"`
  Área de ponderação, `"16"` Setor censitário — chaves exatas conforme
  F0); globo trata os níveis submunicipais como pesados (base UF +
  município em foco + setores/bairros dele, teto de feições por
  município; generalizar
  [`painel_geo_mun_uf()`](https://distintivelab.github.io/beep/dev/reference/painel_geo_mun_uf.md));
  aba Baixar com tradução de código por nível (generalizar
  [`painel_codigo_mun_cache()`](https://distintivelab.github.io/beep/dev/reference/painel_codigo_mun_cache.md));
  ranking municipal continua ignorando níveis submunicipais.
- Performance: catálogo via `EXISTS` continua O(local) (~450 mil linhas
  na `local` é pouco para o Postgres); selectize já é `server = TRUE`;
  geometria de setor nunca sai inteira (só do município em foco).
- **Manter a duplicação do esqueleto em dia**: `R/painel_dw.R` existe em
  duas cópias (pacote e `inst/painel_esqueleto/R/`) — o teste de sync
  (`test-painel-esqueleto.R`) e as listas `exatas`/`compartilhados`
  precisam acompanhar qualquer arquivo novo.

**Critério de pronto:** série de censo por setor e uma agregada por
bairro visíveis de ponta a ponta (Região, Mapa, Globo, Baixar).

### F4 — Bairro e dados eleitorais (TSE)

- Definição do bairro: **preferir a codificação derivada do Censo**
  (atributo de bairro nos setores/CNEFE, quando presente) para ter
  geometria por dissolve e código estável; código TSE do bairro chega
  por tabela de correspondência `(município, normalização de nome)` —
  auditável, com relatório de não-casados.
- Carregador TSE: votação nominal por seção → agregação por bairro/zona;
  eleitorado por bairro/zona quando divulgado; candidaturas por
  município (base para eventual perfil eleitoral).
- Correspondência seção eleitoral ↔︎ setor/bairro: o ponto difícil (seção
  não equivale a setor; não há sobreposição exata) — documentar
  premissas e limites; nunca inferir silently.
- Microdados do Censo: confirmar veículos de divulgação por setor
  (tabulações SIDRA por setor, microdados, CNEFE) e plugar como fontes
  no `verifica_fonte()`/orquestrador.

**Critério de pronto:** indicador de teste “votação X por bairro” no
painel, com proveniência e nota metodológica sobre a correspondência.

### F5 — Fechamento

- Testes (lookup com códigos longos, níveis, sync do esqueleto), NEWS,
  AGENTS.md (seção do DW atualizada com blocos/larguras submunicipais),
  docs do carregador e exemplo reproduzível (vignette ou README do
  módulo).

## 6. Riscos e mitigações

| Risco | Mitigação |
|----|----|
| int4→bigint em bancos em produção (views, drivers R) | spike na F0; migração idempotente transacional; manter leitura R por texto quando conveniente |
| Volume de geometrias (setores ~450 mil; GPKG nacional na casa de GB) | carga por UF/município; simplificação; geometria opcional (só centroide) para níveis só-de-dados |
| Largura usada como identidade de nível | uma largura por tipo + coluna `nivel_tipo`; documentar tabela de larguras no AGENTS.md |
| Bairro sem código oficial único | código composto mun+bairro com zero-à-esquerda; correspondência auditada com relatório |
| Regras por faixa de id esquecidas em algum canto | inventário grep na F0 + teste de não-colisão que roda com setores presentes |
| Duplicação pacote/esqueleto do painel | seguir o teste de sync; atualizar `exatas`/`compartilhados` |
| Divergência do upstream AEDi | módulos novos em arquivos próprios (`incorporar_*.R`), fáceis de re-portar |
| Custo de atualização censitária (2022→2030) | carregadores versionados por `ano`; blocos de `local_id` nunca renumerados |

## 7. Referências rápidas de código

- Níveis e filtros: `R/painel_dw.R` — `painel_niveis_rotulo` (:325),
  `painel_municipio_limite_id`/`painel_pnad_bloco_fim` (:341),
  `painel_municipio_filtro` (:345), `painel_nivel_parse` (:358),
  `painel_niveis` (:396).
- Escrita: `R/gravar_serie_dw.R` — `montar_lookup_locais` (:36);
  `R/dbdatawriter.R` — sanitize (:87-111).
- Schema: `R/dbprepare.R` — tribbles `geoloc` (:37) e `local` (:59);
  `R/create_extend_geogroup_view.R` — `recortes_geograficos` (1 linha
  por município, blocos 5570/7087 em :32-35).
- Modelo de incorporação: `R/incorporar_municipio_ibge.R`.
