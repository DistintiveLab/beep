# ROADMAP — Fontes TSE/Censo multi-anos + níveis submunicipais

Objetivo: a aba de inserção de fontes passa a gravar **séries temporais**
(`local`, `periodo`, `valor` — um período por ano) e passa a suportar
**níveis submunicipais** (setor censitário, bairro) além do municipal.

Estado de partida (0.9.2.9001): fonte TSE/Censo em modo indicador único —
um ano, município — com bug de eval (multi-expressões) e leitura de
`agregar_setores` restrita a município/setor sem bairro.

## F0 — Correção imediata (bug write_delim)

- **Causa**: o call string do TSE emite várias expressões (`con <- ...`,
  `mapa <- ...`, chamada final). `eval(parse(text = codigo))` avalia
  apenas a **primeira** (a conexão!) e `readr::write_csv` recebe um
  objeto de conexão → `is.data.frame(x) is not TRUE`.
- **Correção**: envolver em bloco `{ }` na avaliação
  (`eval(parse(text = paste0("{", codigo, "}")))`) e travar
  `if (!is.data.frame(tabela)) stop(...)` nos ramos 14/15 com mensagem
  de diagnóstico. Testes com call string real.

## F1 — tsebr: séries multi-anos

- `tse_anos_disponiveis(tipo)`: federais 1998..2026 (de 4 em 4),
  municipais 1996..2024; `c("federal","municipal","todas")`.
- `tse_resultados_municipio()`, `tse_detalhe_municipio()`,
  `tse_perfis_secao()`, `tse_prestacao_uf()`, `tse_candidaturas()`:
  parâmetro `anos = NULL` (default: todos da família do cargo) —
  itera, empilha (uma linha por ano), `periodo` = 31/12 de cada ano.
- Mapa TSE×IBGE construído a partir do ano mais recente do intervalo
  (códigos TSE são estáveis entre anos).

## F2 — Painel TSE multi-anos

- Seletor "Ano" ganha **"todos os anos"**; o call string emitido passa
  `anos = tsebr::tse_anos_disponiveis("federal")` (explícito/editável).
- `db_datawrite` recebe a série completa em uma única `mdata`
  (`data_freq_id` 4-anual? — não: `periodo` anual com `data_freq_id` 9).
- Progresso por ano (barra) — downloads são pesados.

## F3 — censoagg: setores e bairros

- `agregar_setores(nivel = "setor")`: já suportado — gravar direto nos
  blocos submunicipais (geoloc 15-16d; 15d é exato em double).
- **Bairro**: requer o mapa setor→bairro produzido por
  `incorporar_bairros()`. Persistir a correspondência (setor_code →
  bairro_local_id) em tabela (`setores_bairros`) na incorporação e
  expor `agregar_bairros(dataset, variaveis, mapa)` que dissolve
  por bairro antes de agregar. (Sem o mapa, bairro fica indisponível
  com aviso — não inferir por geometria em runtime.)

## F4 — Painel censo

- "Nível territorial" ganha **setor censitário** (grava nos blocos
  submunicipais; o painel já exibe o nível).
- Bairro entra quando F3.F4 estiver no banco (via setores_bairros).

## F5 — Robustez

- `limpar` do seeder passa a truncar também `datagroup` dos recortes
  (idempotência de re-execução — hoje re-executar duplica grupos).
- `dbdatawriter`: `geoloc_id` BIGINT → substr/ match por `::text`
  (códigos 15-16d não cabem com precisão em double acima de 2^53).
