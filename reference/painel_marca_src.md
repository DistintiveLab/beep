# Resolve o src de uma marca (logo) do painel (funciona fora do app)

Procura o arquivo informado no diretorio de assets — no esqueleto gerado
por
[`deploy_panel()`](https://distintivelab.github.io/beep/reference/deploy_panel.md)
e o proprio `www/` local — com fallback para o `www/` embutido no pacote
(inst/app/www) via resource path; URLs http(s) passam direto.
[`painel_logo_src()`](https://distintivelab.github.io/beep/reference/painel_logo_src.md)
e o caso particular da marca do topbar (variavel `beep_logo`); a aba
Sobre reutiliza para logos de apoio.

## Usage

``` r
painel_marca_src(logo, assets_dir = NULL)
```

## Arguments

- logo:

  nome do arquivo da marca (ou URL http/https)

- assets_dir:

  diretorio de assets do painel; default tenta "www" no diretorio
  corrente e cai para o embutido no pacote
