# Cartoes da equipe da aba Sobre (usa painel_equipe): entradas separadas por ";", campos "nome\|papel\|email\|foto" por "\|" (email e foto opcionais; foto = arquivo do www/ ou URL, resolvida por [`painel_marca_src()`](https://distintivelab.github.io/beep/reference/painel_marca_src.md) como avatar redondo do cartao); vazio mantem o cartao unico do autor

Cartoes da equipe da aba Sobre (usa painel_equipe): entradas separadas
por ";", campos "nome\|papel\|email\|foto" por "\|" (email e foto
opcionais; foto = arquivo do www/ ou URL, resolvida por
[`painel_marca_src()`](https://distintivelab.github.io/beep/reference/painel_marca_src.md)
como avatar redondo do cartao); vazio mantem o cartao unico do autor

## Usage

``` r
painel_brand_equipe(
  default = paste("Rodrigo Emmanuel Santana Borges|",
    "Desenvolvedor e cientista de dados|", "rodrigo@borges.net.br", sep = "")
)
```
