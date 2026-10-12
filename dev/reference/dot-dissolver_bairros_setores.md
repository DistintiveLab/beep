# Dissolve os setores por codigo de bairro: uma feicao por bairro, nome = primeiro nome nao-vazio do grupo. Retorna sf (code_bairro, nm_bairro, geometry) com o CRS de entrada — a reprojecao para 4326 e o SQL ficam com `ampliar_nivel_territarial()`.

Dissolve os setores por codigo de bairro: uma feicao por bairro, nome =
primeiro nome nao-vazio do grupo. Retorna sf (code_bairro, nm_bairro,
geometry) com o CRS de entrada — a reprojecao para 4326 e o SQL ficam
com `ampliar_nivel_territarial()`.

## Usage

``` r
.dissolver_bairros_setores(
  setores,
  col_bairro = NULL,
  col_nome = NULL,
  col_setor = NULL
)
```
