# Recursos de cabecalho (meta, núcleo do tema, CSS/JS do painel, Gov.br) e div raiz da paleta

O núcleo do tema (beep-tema.css/js: variáveis –p-\* e o toggle
gov.br/pb) entra ANTES dos assets locais — assets do projeto (esqueleto)
têm precedência, com fallback para o embutido no pacote (mesma resolução
local-primeiro de
[`painel_marca_src()`](https://distintivelab.github.io/beep/dev/reference/painel_marca_src.md)).

## Usage

``` r
painel_recursos(assets_dir, paleta = c("govbr", "pb"))
```
