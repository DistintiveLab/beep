# Registra o inicio de um ciclo de carga (modelo A: snapshot por ciclo)

Executa pg_dump do beepdb para

/beepdb_v\_.dump e cria a linha da versao. Ciclos SEM alteracao de dado
nao geram dump (a versao referencia o dump anterior). Dumps espelhados
em `espelho` (ex.: montagem sshfs extrainters) quando informado.

## Usage

``` r
versao_carga_inicio(
  dir_dump = "~/backups_beepdb",
  espelho = espelho_padrao(),
  codigo_versao = git_commit_beep(),
  projeto = "beep"
)
```

## Arguments

- dir_dump:

  diretorio dos dumps (default ~/backups_beepdb)

- espelho:

  diretorio espelho opcional (default: extrainters se montado)

- codigo_versao:

  identificador do codigo (default: commit git do beep)

- projeto:

  nome do projeto (raiz do lote) dono da versao de carga

## Details

Retencao (aplicada ao final do ciclo, ver
[`versao_carga_fim()`](https://distintivelab.github.io/beep/reference/versao_carga_fim.md)):
semanais completos + ultimos 3 dias uteis de dumps.
