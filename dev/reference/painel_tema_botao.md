# Botão de alternância do núcleo do tema (marcação local)

Mesma marcação de
[`beep_tema_botao()`](https://distintivelab.github.io/beep/dev/reference/beep_tema_botao.md)
do pacote, definida aqui para o esqueleto copiado por
[`deploy_panel()`](https://distintivelab.github.io/beep/dev/reference/deploy_panel.md)
não depender do beep em execução — o comportamento (toggle, rótulo,
persistência) vive no beep-tema.js compartilhado, que enxerga a classe
`beep-tema-btn`.

## Usage

``` r
painel_tema_botao(id = "painel_paleta_btn")
```

## Arguments

- id:

  id do botão (o painel usa "painel_paleta_btn")
