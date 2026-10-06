# Acrescenta ao catalogo as colunas opcionais do painel: periodicidade (freq_name, de mdata_exts/data_freq), classe do indicador (data_class_id, de mdata_exts), tipo do grafico em destaque (tipo_grafico, de mdata_grafico) e visibilidade nos seletores (visivel, de mdata_visivel). Fail-open: DW sem as tabelas auxiliares segue com defaults (freq/classe ausentes, "linha", visivel)

Acrescenta ao catalogo as colunas opcionais do painel: periodicidade
(freq_name, de mdata_exts/data_freq), classe do indicador
(data_class_id, de mdata_exts), tipo do grafico em destaque
(tipo_grafico, de mdata_grafico) e visibilidade nos seletores (visivel,
de mdata_visivel). Fail-open: DW sem as tabelas auxiliares segue com
defaults (freq/classe ausentes, "linha", visivel)

## Usage

``` r
painel_mdata_extras(con, md)
```
