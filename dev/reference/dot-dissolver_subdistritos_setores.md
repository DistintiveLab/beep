# Dissolve os setores por codigo de subdistrito: uma feicao por subdistrito, nome = primeiro nome nao-vazio do grupo. Retorna sf (code_subdistrict, nm_subdistrict, geometry) com o CRS de entrada.

Dissolve os setores por codigo de subdistrito: uma feicao por
subdistrito, nome = primeiro nome nao-vazio do grupo. Retorna sf
(code_subdistrict, nm_subdistrict, geometry) com o CRS de entrada.

## Usage

``` r
.dissolver_subdistritos_setores(
  setores,
  col_subdistrito = NULL,
  col_nome = NULL,
  col_setor = NULL
)
```
