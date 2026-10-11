# These pure-R releases support the installed R and Ubuntu dependencies.
set.seed(42)
lib <- file.path(getwd(), ".runtime", "usr", "lib", "R", "site-library")
.libPaths(c(lib, .libPaths()))
sources <- c(snakecase = "https://cran.r-project.org/src/contrib/Archive/snakecase/snakecase_0.11.0.tar.gz",
 janitor = "https://cran.r-project.org/src/contrib/Archive/janitor/janitor_2.2.0.tar.gz",
 nortest = "https://cran.r-project.org/src/contrib/nortest_1.0-4.tar.gz",
 goftest = "https://cran.r-project.org/src/contrib/goftest_1.2-3.tar.gz",
 olsrr = "https://cran.r-project.org/src/contrib/Archive/olsrr/olsrr_0.5.3.tar.gz",
 rmarkdown = "https://cran.r-project.org/src/contrib/Archive/rmarkdown/rmarkdown_2.6.tar.gz")
for(p in names(sources)) if(!requireNamespace(p, quietly = TRUE) ||
 (p=="rmarkdown" && !nzchar(system.file("rmd/ioslides/default.html",package="rmarkdown"))))
  install.packages(sources[[p]], lib = lib, repos = NULL, type = "source", dependencies = FALSE)
stopifnot(all(vapply(names(sources), requireNamespace, logical(1), quietly = TRUE)))
