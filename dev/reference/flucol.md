# Fluid Column - Shiny fluidRow + Column

Fluid Column - Shiny fluidRow + Column

## Usage

``` r
flucol(..., width = 12, offset = 0)
```

## Arguments

- ...:

  elements to include within the flucol

- width:

  width

- offset:

  offset

## Value

A column wrapped in fluidRow

## Examples

``` r
beep::flucol(12, 0, shiny::h5("HEY"))
#> <div class="row">
#>   <div class="col-sm-12">
#>     12
#>     0
#>     <h5>HEY</h5>
#>   </div>
#> </div>
```
