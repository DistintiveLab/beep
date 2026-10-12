# Um local_id pertence a zona de carga "municipal" do sanitize do [`db_datawrite()`](https://distintivelab.github.io/beep/dev/reference/db_datawrite.md)? Preserva a semantica historica (municipios + agregados convencionais + faixa PNAD 5572..5599 que sempre passou pelo filtro), excluindo apenas os blocos submunicipais novos. `bloco_fim` e a fronteira superior dinamica (linha "Brasil").

Um local_id pertence a zona de carga "municipal" do sanitize do
[`db_datawrite()`](https://distintivelab.github.io/beep/dev/reference/db_datawrite.md)?
Preserva a semantica historica (municipios + agregados convencionais +
faixa PNAD 5572..5599 que sempre passou pelo filtro), excluindo apenas
os blocos submunicipais novos. `bloco_fim` e a fronteira superior
dinamica (linha "Brasil").

## Usage

``` r
eh_zona_carga_municipal(local_id, bloco_fim = niveis_pnad_bloco_fim)
```
