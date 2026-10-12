# Constroi o codigo completo de bairro a partir do atributo bruto dos setores: codigo ja completo (11-12 digitos) passa direto; sufixo curto (1-5 digitos) e zerado a esquerda para 4 e prefixado com o municipio (prefixo 7d do codigo do setor). Valores nao numericos/vazios viram NA (o setor fica fora do dissolve — nunca inferir bairro).

Constroi o codigo completo de bairro a partir do atributo bruto dos
setores: codigo ja completo (11-12 digitos) passa direto; sufixo curto
(1-5 digitos) e zerado a esquerda para 4 e prefixado com o municipio
(prefixo 7d do codigo do setor). Valores nao numericos/vazios viram NA
(o setor fica fora do dissolve — nunca inferir bairro).

## Usage

``` r
.resolver_codigo_bairro(bruto, mun7)
```
