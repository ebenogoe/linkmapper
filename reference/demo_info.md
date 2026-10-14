# Demo datasets

The F2 and backcross demos are the simulated example data shipped with
onemap (200 and 150 individuals, one trait each). The RIL demo is
onemap's selfed RIL example (100 lines, no traits). `small` is the
20-individual F2 file from the 2022 Linkmapper.

## Usage

``` r
demo_info()

linkmapper_demo(name = c("f2", "bc", "ril", "small"))
```

## Arguments

- name:

  One of `demo_info()$name`.

## Value

`demo_info()` returns a data frame describing each dataset.

`linkmapper_demo()` returns an `lm_data` object.
