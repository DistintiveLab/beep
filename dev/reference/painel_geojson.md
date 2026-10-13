# GeoJSON (string) de um objeto sf para mensagens Shiny ao cliente, com aneis reorientados para o d3-geo do globo (ver [`painel_geojson_orientar()`](https://distintivelab.github.io/beep/dev/reference/painel_geojson_orientar.md)). O retorno carrega a classe "json" do jsonlite e o serializer de mensagens do Shiny (json_verbatim=TRUE) o embute como objeto JSON na mensagem: no navegador, o campo chega como objeto, nao como string, e o cliente do globo aceita as duas formas (ver tests/testthat/test-painel-geojson.R)

GeoJSON (string) de um objeto sf para mensagens Shiny ao cliente, com
aneis reorientados para o d3-geo do globo (ver
[`painel_geojson_orientar()`](https://distintivelab.github.io/beep/dev/reference/painel_geojson_orientar.md)).
O retorno carrega a classe "json" do jsonlite e o serializer de
mensagens do Shiny (json_verbatim=TRUE) o embute como objeto JSON na
mensagem: no navegador, o campo chega como objeto, nao como string, e o
cliente do globo aceita as duas formas (ver
tests/testthat/test-painel-geojson.R)

## Usage

``` r
painel_geojson(x)
```
