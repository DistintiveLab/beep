# Localidade mais proxima de um ponto (lat/lon WGS84) entre as feicoes de um nivel: a que contem o ponto quando ha, senao a de representacao interna mais proxima. Opera sem o s2 (GEOS plano, suficiente em escala de cidade) porque malhas do Censo chegam com aneis invalidos (vertice duplicado) que derrubam a construcao da geografia s2 antes de qualquer predicado; NA quando nao ha feicoes ou coordenadas

Localidade mais proxima de um ponto (lat/lon WGS84) entre as feicoes de
um nivel: a que contem o ponto quando ha, senao a de representacao
interna mais proxima. Opera sem o s2 (GEOS plano, suficiente em escala
de cidade) porque malhas do Censo chegam com aneis invalidos (vertice
duplicado) que derrubam a construcao da geografia s2 antes de qualquer
predicado; NA quando nao ha feicoes ou coordenadas

## Usage

``` r
painel_geo_mais_proxima(geo, lat, lon)
```
