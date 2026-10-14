# Save and restore an analysis session

A session file is JSON holding the genotype file contents, any traits
and the settings. Results are recomputed when the session is opened.

## Usage

``` r
save_session(d, settings, path)

load_session(path)
```

## Arguments

- d:

  The `lm_data` as read (with traits, if added).

- settings:

  The settings list.

- path:

  File to write or read.

## Value

`save_session()` returns `path` invisibly; `load_session()` returns a
list with `data` and `settings`.
