# Do some checking, sanitizing and write to backend database `db_datawrite()` does some checking, sanitizing and writes new data to backend database

Do some checking, sanitizing and write to backend database
`db_datawrite()` does some checking, sanitizing and writes new data to
backend database

## Usage

``` r
db_datawrite(
  metadf,
  datadf,
  construct,
  grp = FALSE,
  engine = "postgresql",
  sanitize = TRUE,
  forceunique = T,
  replace = FALSE
)
```

## Arguments

- metadf:

  dataframe list with the following expected structure : \[1\] -\> df
  with orig_name data_name data_desc \[2\] -\> data.frame with at least
  data_class_id data_freq_id dataunit_num - TBI dataunit_den - TBI
  datasource_id data_url \<- construct ? call? @param datadf dataframe
  with the following expected structure: local \<-\> local_id or
  name/code pairable with local table periodo \<- date or string/number
  in yyyy,yyyy-mm, yyyy-mm-dd valor \<- numeric @param construct The
  call that extracted/obtained the data @param grp Should a datagroup be
  defined - for tables with subgroups (as sidra) @param engine Defaults
  to postgresql, sqlite TBI.
