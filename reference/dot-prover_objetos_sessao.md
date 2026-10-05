# Prove, best-effort, no ambiente do script os objetos de sessao que os scripts de coleta costumam esperar (padrao A5b): con/mdr no DW, rais quando as env vars do banco RAIS estao definidas (dbname em dbrais ou, na convencao dos scripts de coleta, em mte_rais) e locgeoloc do cadastro de locais. Scripts que criam os proprios objetos (if (!exists(...))) reutilizam os fornecidos aqui. Retorna list(abertas, pendentes): conexoes abertas aqui (para desconectar ao final) e objetos NAO fornecidos com o motivo, para anexar ao erro do script em vez de um generico "object not found".

Prove, best-effort, no ambiente do script os objetos de sessao que os
scripts de coleta costumam esperar (padrao A5b): con/mdr no DW, rais
quando as env vars do banco RAIS estao definidas (dbname em dbrais ou,
na convencao dos scripts de coleta, em mte_rais) e locgeoloc do cadastro
de locais. Scripts que criam os proprios objetos (if (!exists(...)))
reutilizam os fornecidos aqui. Retorna list(abertas, pendentes):
conexoes abertas aqui (para desconectar ao final) e objetos NAO
fornecidos com o motivo, para anexar ao erro do script em vez de um
generico "object not found".

## Usage

``` r
.prover_objetos_sessao(env)
```
