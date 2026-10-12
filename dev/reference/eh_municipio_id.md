# Um local_id e municipio? (bloco malha 2024 + incorporados apos a linha "Brasil", excluindo os blocos submunicipais). `bloco_fim` recebe a fronteira superior dinamica (local_id da linha "Brasil") quando disponivel; o default e o fallback estatico.

Um local_id e municipio? (bloco malha 2024 + incorporados apos a linha
"Brasil", excluindo os blocos submunicipais). `bloco_fim` recebe a
fronteira superior dinamica (local_id da linha "Brasil") quando
disponivel; o default e o fallback estatico.

## Usage

``` r
eh_municipio_id(local_id, bloco_fim = niveis_pnad_bloco_fim)
```
