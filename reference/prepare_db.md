# Prepare app_db

Writes sqlite database on current dir or pgsql tables to beep_db if
'pgsql' , user , password and database should be set up separately on
the corresponding PostgreSQL Server

## Usage

``` r
prepare_db(
  tdbname = "beepdb",
  type = "sqlite",
  userdb = "beep",
  passwddb = "aEd1#man@gR",
  hostdb = "127.0.0.1",
  postgis = TRUE,
  geo = TRUE
)
```

## Arguments

- tdbname:

  Name of the database that will be created, defaults to beepdb

- type:

  type of db backend - defaults to sqlite, alternative pgsql

- userdb:

  Name of the user with connection permissions

- passwddb:

  userdb password for connecting to tdbname

- hostdb:

  host resolvable domain or address

- postgis:

  is postgis extension enabled on pgsql database? defaults to TRUE
  @importFrom RSQLite SQLite @importFrom DBI dbExecute dbGetQuery
  dbSendQuery
