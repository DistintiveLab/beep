# Cria preventivamente os diretorios de cache que o script referencia (convencao coleta/cache//…): write_csv nao cria diretorio-pai, e o lote roda sobre projetos cujo cache pode ainda nao existir (ex.: clone novo na VPS). A deteccao e por regex sobre o texto bruto (readLines), que tolera scripts com construtos que quebram varredura da arvore de parse (ex.: subscript vazio dfi, ) e ate scripts que nao parseiam. Falha de criacao vira erro claro do script (permissao).

Cria preventivamente os diretorios de cache que o script referencia
(convencao coleta/cache//…): write_csv nao cria diretorio-pai, e o lote
roda sobre projetos cujo cache pode ainda nao existir (ex.: clone novo
na VPS). A deteccao e por regex sobre o texto bruto (readLines), que
tolera scripts com construtos que quebram varredura da arvore de parse
(ex.: subscript vazio dfi, ) e ate scripts que nao parseiam. Falha de
criacao vira erro claro do script (permissao).

## Usage

``` r
.preparar_cache_script(arquivo, raiz)
```
