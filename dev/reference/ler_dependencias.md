# Le a semente de dependencias versionada no projeto

Colunas do CSV: `script` (nome sem .R), `dep_orig_name` (serie no
mdata), `regua` ("proprio" ou "fonte"), `acao` ("pular" ou "avisar") e
`serie_propria` (opcional: series gravadas pelo script quando o parse do
arquivo nao as encontra, ex. gravacao via variavel; varios nomes
separados por ";". Vale a uniao das linhas do script - basta declarar em
uma unica linha). Retorna NULL quando o projeto nao tem manifesto.

## Usage

``` r
ler_dependencias(raiz = .beep_raiz())
```

## Arguments

- raiz:

  raiz do projeto dono do lote (diretorio com coleta/)

## Value

data.frame do manifesto ou NULL
