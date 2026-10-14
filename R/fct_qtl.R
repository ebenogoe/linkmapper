#' Build an R/qtl cross from a Linkmapper map
#'
#' Writes the mapped markers and the traits in MAPMAKER format, writes the
#' map with [onemap::write_map()], and reads both with
#' [qtl::read.cross()]. Chromosomes are the linkage groups in map order.
#'
#' @param d The `lm_data` the map was built from.
#' @param m An `lm_map` from [order_groups()].
#' @return An R/qtl `cross` object.
#' @export
build_cross <- function(d, m) {
  if (is.null(d$onemap$pheno)) lm_abort("The data has no traits. Add a trait file in step 1.")
  mapped <- match(m$positions$marker, colnames(d$onemap$geno))
  dm <- d
  dm$onemap <- quiet(onemap::split_onemap(d$onemap, mks = sort(unique(mapped))))
  genfile <- tempfile(fileext = ".raw")
  mapfile <- tempfile(fileext = ".map")
  on.exit(unlink(c(genfile, mapfile)))
  write_mapmaker(dm, genfile)
  onemap::set_map_fun(type = m$map_fun)
  quiet(onemap::write_map(unname(m$maps), mapfile))
  cr <- tryCatch(
    quiet(qtl::read.cross("mm", file = genfile, mapfile = mapfile, estimate.map = FALSE)),
    error = function(e) lm_abort("Could not prepare the data for QTL mapping: ", conditionMessage(e))
  )
  names(cr$geno) <- names(m$maps)[seq_along(cr$geno)]
  cr
}

#' QTL mapping methods
#' @return A named character vector (labels as names).
#' @export
qtl_methods <- function() {
  c("Haley-Knott regression" = "hk", "Maximum likelihood (EM)" = "em", "Multiple imputation" = "imp")
}

#' Scan for QTL
#'
#' Interval mapping ([qtl::scanone()]) or composite interval mapping
#' ([qtl::cim()]) for one trait, with a genome-wide LOD threshold from
#' permutations (Churchill and Doerge 1994). For each linkage group whose
#' highest LOD passes the threshold, the peak is reported with its
#' 1.5-LOD support interval, nearest marker, genome-wide p-value, percentage
#' of phenotypic variance explained and estimated effects.
#'
#' @param cross A cross from [build_cross()].
#' @param trait Trait name.
#' @param method One of [qtl_methods()].
#' @param cim Use composite interval mapping.
#' @param n_marcovar,window Marker covariates and window (cM) for CIM.
#' @param n_perm Number of permutations.
#' @param alpha Genome-wide significance level.
#' @param step Spacing (cM) of the scan.
#' @param seed Random seed.
#' @param progress Optional function called with the share done (0 to 1).
#' @return An `lm_qtl` list.
#' @export
scan_qtl <- function(cross, trait = NULL, method = "hk", cim = FALSE, n_marcovar = 3,
                     window = 10, n_perm = 1000, alpha = 0.05, step = 1, seed = 1,
                     progress = NULL) {
  traits <- names(cross$pheno)
  trait <- trait %||% traits[1]
  pc <- match(trait, traits)
  if (is.na(pc)) lm_abort("Unknown trait: ", trait)
  if (!method %in% qtl_methods()) lm_abort("Unknown method: ", method)
  tick <- function(p) if (!is.null(progress)) progress(p)
  cross <- with_seed(seed, {
    cr <- qtl::calc.genoprob(cross, step = step, error.prob = 0.001)
    if (method == "imp") cr <- qtl::sim.geno(cr, step = step, n.draws = 64, error.prob = 0.001)
    cr
  })
  one <- function(n.perm = 0) {
    if (cim) {
      qtl::cim(cross,
        pheno.col = pc, n.marcovar = n_marcovar, window = window,
        method = method, n.perm = n.perm
      )
    } else {
      qtl::scanone(cross, pheno.col = pc, method = method, n.perm = n.perm, verbose = FALSE)
    }
  }
  scan <- with_seed(seed, quiet(one()))
  tick(0.05)
  chunk <- if (cim) 10 else 100
  done <- 0
  perms <- numeric()
  with_seed(seed, {
    while (done < n_perm) {
      k <- min(chunk, n_perm - done)
      p <- quiet(one(k))
      perms <- c(perms, as.numeric(p[, 1]))
      done <- done + k
      tick(0.05 + 0.9 * done / n_perm)
    }
  })
  thr <- as.numeric(stats::quantile(perms, 1 - alpha))
  peaks <- qtl_peaks(cross, scan, pc, thr, perms, method)
  tick(1)
  sc <- data.frame(
    lg = as.character(scan$chr), position = scan$pos, lod = scan$lod,
    locus = rownames(scan), stringsAsFactors = FALSE
  )
  sc$lg <- factor(sc$lg, levels = names(cross$geno))
  structure(
    list(
      scan = sc, threshold = thr, perms = perms, peaks = peaks, trait = trait,
      method = method, cim = cim, n_perm = n_perm, alpha = alpha, seed = seed,
      cross_type = class(cross)[1], cross = cross, pheno_col = pc
    ),
    class = "lm_qtl"
  )
}

qtl_peaks <- function(cross, scan, pc, thr, perms, method) {
  rows <- lapply(unique(as.character(scan$chr)), function(ch) {
    s <- scan[scan$chr == ch, ]
    i <- which.max(s$lod)
    if (!length(i) || s$lod[i] < thr) {
      return(NULL)
    }
    pos <- s$pos[i]
    li <- tryCatch(qtl::lodint(scan, chr = ch, drop = 1.5), error = function(e) NULL)
    mk <- qtl::find.marker(cross, chr = ch, pos = pos)
    fit_method <- if (method == "imp") "imp" else "hk"
    q <- qtl::makeqtl(cross, chr = ch, pos = pos, what = if (fit_method == "imp") "draws" else "prob")
    f <- tryCatch(
      quiet(summary(qtl::fitqtl(cross,
        pheno.col = pc, qtl = q, method = fit_method,
        get.ests = TRUE, dropone = FALSE
      ))),
      error = function(e) NULL
    )
    pve <- if (!is.null(f)) f$result.full["Model", "%var"] else NA
    est <- if (!is.null(f)) f$ests[, "est"] else numeric()
    a <- est[grepl("a$", names(est))]
    dd <- est[grepl("d$", names(est))]
    # Backcross and RIL models have one effect, named without the a/d suffix
    if (!length(a) && length(est) > 1) a <- est[-1][1]
    data.frame(
      lg = ch, position = round(pos, 1), lod = round(s$lod[i], 2),
      p_value = mean(perms >= s$lod[i]),
      interval_low = if (!is.null(li)) round(li$pos[1], 1) else NA,
      interval_high = if (!is.null(li)) round(li$pos[nrow(li)], 1) else NA,
      nearest_marker = mk,
      pve = round(pve, 2),
      additive = if (length(a)) round(unname(a[1]), 3) else NA,
      dominance = if (length(dd)) round(unname(dd[1]), 3) else NA,
      stringsAsFactors = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) {
    return(data.frame(
      lg = character(), position = numeric(), lod = numeric(), p_value = numeric(),
      interval_low = numeric(), interval_high = numeric(), nearest_marker = character(),
      pve = numeric(), additive = numeric(), dominance = numeric()
    ))
  }
  out <- do.call(rbind, rows)
  if (all(is.na(out$dominance))) out$dominance <- NULL
  out
}

#' Trait values by genotype at a marker
#' @param res An `lm_qtl` from [scan_qtl()].
#' @param marker Marker name.
#' @return A data frame with `genotype` and `value`.
#' @export
genotype_effect <- function(res, marker) {
  cr <- res$cross
  g <- qtl::pull.geno(cr)
  if (!marker %in% colnames(g)) lm_abort("Marker not on the map: ", marker)
  labels <- switch(res$cross_type,
    f2 = c("AA", "AB", "BB", "not BB", "not AA"),
    bc = c("AA", "AB"),
    riself = ,
    risib = c("AA", "BB"),
    as.character(1:5)
  )
  v <- g[, marker]
  data.frame(genotype = factor(labels[v], levels = labels), value = cr$pheno[[res$pheno_col]])[!is.na(v), ]
}

# Run code with a fixed seed and put the caller's random number state back
with_seed <- function(seed, code) {
  if (is.null(seed)) {
    return(code)
  }
  env <- globalenv()
  had <- exists(".Random.seed", envir = env, inherits = FALSE)
  old <- if (had) get(".Random.seed", envir = env, inherits = FALSE)
  on.exit(if (had) assign(".Random.seed", old, envir = env) else rm(".Random.seed", envir = env))
  set.seed(seed)
  code
}
