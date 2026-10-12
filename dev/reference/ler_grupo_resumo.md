# Lê os membros atuais do grupo Resumo no DW

Lê os membros atuais do grupo Resumo no DW

## Usage

``` r
ler_grupo_resumo(con = NULL)
```

## Arguments

- con:

  conexão aberta com o DW; por padrão abre uma com as variáveis de
  ambiente `user`, `password`, `host` e `dbname` (mesmos defaults de
  [`atualizar_grupos_indicadores()`](https://distintivelab.github.io/beep/dev/reference/atualizar_grupos_indicadores.md))

## Value

data.frame com `mdata_id` e `orig_name` (ordem do `mdata_id`); zero
linhas quando o grupo não existe ou não tem vínculos
