# Monta o lookup de codigos de local para local_id do DW

Prioridade: prefixo IBGE 6d (RAIS) \> proprio local_id \> geoloc_id
completo. O prefixo 6d vem primeiro porque o geoloc_id das Regioes
Imediatas tem 6 digitos e collide com o codigo 6d do municipio (1100023
-\> 110002). O local_id vem antes do geoloc_id completo porque
derivacoes DW-\>DW (padrao A5b) repassam local_ids, e os ids pequenos
dos municipios collidem com geoloc_ids de agregados (1=Alta Floresta vs
1=Norte, 53=Acrelandia vs 53=DF), o que despachava series municipais
para regiao/UF/DF (bug de cobertura municipal, segunda ordem, corrigido
2026-09-22). Series agregadas devem ser passadas por local_id.
Municipios incorporados apos o bloco PNAD (local_id \> 7087; ver
incorporar_municipio_ibge) tambem entram no prefixo 6d.

## Usage

``` r
montar_lookup_locais(locais)
```

## Arguments

- locais:

  data.frame com `local_id` e `geoloc_id` (tabela `local`)
