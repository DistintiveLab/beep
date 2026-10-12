# Constroi o codigo completo de subdistrito a partir do atributo bruto dos setores: codigo ja completo (11 digitos) passa direto; sufixo curto (1-4 digitos) e zerado a esquerda para 4 e prefixado com o municipio (prefixo 7d do codigo do setor). Valores nao numericos/vazios viram NA (o setor fica fora do dissolve — nunca inferir subdistrito).

Constroi o codigo completo de subdistrito a partir do atributo bruto dos
setores: codigo ja completo (11 digitos) passa direto; sufixo curto (1-4
digitos) e zerado a esquerda para 4 e prefixado com o municipio (prefixo
7d do codigo do setor). Valores nao numericos/vazios viram NA (o setor
fica fora do dissolve — nunca inferir subdistrito).

## Usage

``` r
.resolver_codigo_subdistrito(bruto, mun7)
```
