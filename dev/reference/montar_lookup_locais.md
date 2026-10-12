# Monta o lookup de codigos de local para local_id do DW

Prioridade: prefixo IBGE 6d do MUNICIPIO (RAIS) \> proprio local_id \>
geoloc_id completo (texto normalizado — códigos submunicipais de 11-16
digitos resolvem aqui pelo codigo cheio). O prefixo 6d vem SOMENTE das
linhas de municipio (largura 7 do geoloc_id), na ordem de local_id: um
setor censitario cujo prefixo 6d e o codigo de municipio nao pode
sombrear o municipio (roadmap F1), e as Regioes Imediatas (geoloc 6d que
collide com o prefixo do municipio, 1100023 -\> 110002) ficam fora do
mapa de prefixo — codigo 6d de entrada e sempre municipio na semantica
RAIS/IBGE. O local_id vem antes do geoloc_id completo porque derivacoes
DW-\>DW (padrao A5b) repassam local_ids, e os ids pequenos dos
municipios collidem com geoloc_ids de agregados (1=Alta Floresta vs
1=Norte, 53=Acrelandia vs 53=DF), o que despachava series municipais
para regiao/UF/DF (bug de cobertura municipal, segunda ordem, corrigido
2026-09-22). Series agregadas devem ser passadas por local_id.
Municipios incorporados apos o bloco territorial do seeder (acima do
local_id da linha "Brasil"; ver incorporar_municipio_ibge) tambem entram
no prefixo 6d.

## Usage

``` r
montar_lookup_locais(locais)
```

## Arguments

- locais:

  data.frame com `local_id` e `geoloc_id` (tabela `local`)
