# Predicting IPL first-innings totals

A reproducible R study with beginner explanations, a report and a course presentation.
The prediction is made after the toss and announced playing XIs, before the innings starts.

Run from this directory:

```sh
Rscript run_all.R
```

Dependencies are checked by `scripts/00_setup.R`. Install R and Pandoc first.
On Ubuntu with older system R, `Rscript scripts/bootstrap_ubuntu.R` prepares compatible
local binary dependencies without sudo. Raw data and the local runtime are excluded from Git.

Read the [learning guide](docs/01_learning_guide.md) first, then the
[HTML report](report/final_report.html) and [walkthrough](docs/02_walkthrough.md).
Use the [slides](presentation/slides.html) and [talk track](presentation/talk_track.md)
for presentation practice. The [glossary](docs/03_glossary.md) explains technical terms.

The [decision log](DECISIONS.md) records modelling choices; computed findings are in
[RESULTS.md](RESULTS.md) and `results/`. See [session information](results/session_info.txt),
[package versions](results/package_versions.csv), [verification](results/verification.csv),
and the [figure index](figures/INDEX.md).

Scripts run in numbered order; reusable functions live in `R/`. `data/raw/` preserves
source downloads; `data/interim/` contains clean histories; `data/processed/` contains
the modelling table; `data/reference/` contains name mappings. `results/` holds
computed evidence and model artifacts, `figures/` holds exported charts, and
`report/`, `presentation/` and `docs/` contain learning deliverables.

To verify a full rebuild while preserving raw downloads:

```sh
IPL_CLEAN=1 Rscript run_all.R
```

Troubleshooting: run from this project directory so `.Rprofile` activates local
dependencies. If an old Ubuntu R cannot install current CRAN packages, run
`Rscript scripts/bootstrap_ubuntu.R`, followed by `Rscript scripts/install_compat.R`.
The latter installs compatible source releases. If local web-asset links are broken,
run `Rscript scripts/repair_runtime.R`. On a standard system install Pandoc using
`sudo apt install pandoc`. Offline rebuilds work after both raw archives and dependencies
are present; initial downloads need network access.

Outcome plots before final evaluation use training data; earlier model comparisons
use validation. The latest completed season is scored only after the final choice is
frozen. A rerun reproduces that same procedure; it does not invite selection by test results.

Source archive hashes are locked in `data/reference/source_lock.csv`. Cricsheet's
live archives can change, so preserve this study's downloaded archives for exact
reproduction. A checksum mismatch stops the run rather than silently changing the
dataset. A deliberate data refresh should be treated as a new documented study.

Optional browser review: `Rscript scripts/preview_html.R` creates private slide and
report previews under `.runtime/visual_review/`. Chrome is needed for this review
only; the analysis and HTML rendering use R and Pandoc.
