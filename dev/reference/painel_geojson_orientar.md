# Reorienta os aneis de um GeoJSON para o cliente do globo (d3-geo)

O d3-geo decide o interior de um poligono esferico pela orientacao dos
aneis, na convencao oposta ao RFC 7946: exterior no sentido horario
(area com sinal negativa em graus) e furos no anti-horario. As malhas do
IBGE (UFs, municipios) ja vem assim, mas as geometrias derivadas do
Censo 2022 (bairros, subdistritos, setores, areas de ponderacao,
gravadas pelos incorporar\_\*) chegam invertidas; sem normalizacao o
globo desenha o complemento de cada feicao (o disco inteiro pintado) e a
tela fica em branco com o azulado translucido da selecao por cima. O
ajuste e local ao GeoJSON enviado ao navegador (globo: nivel, destaque,
contexto e malha); as geometrias do banco nao mudam e o driver GeoJSON
do GDAL nao tem opcao equivalente (RFC7946=YES nao e suportado na
escrita).

## Usage

``` r
painel_geojson_orientar(texto)
```
