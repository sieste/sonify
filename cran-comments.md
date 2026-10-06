## Summary

This is an update of an existing CRAN package (`sonify`, currently on CRAN
as version 0.0-1, published 2017-02-01).

Changes in 0.1-0 (see NEWS.md for details):

* Bug fix: on Linux systems where `/bin/sh` is `dash` (Debian, Ubuntu),
  `sonify()` played no sound because the default player call used the
  bash-only `&>` redirection. It now uses POSIX `> /dev/null 2>&1`.
* New argument `pitch_mapping` that allows logarithmic (perceptual) frequency
  mapping. The default keeps the previous behaviour.
* Equal-power stereo panning, click-free fades, `mpv` preferred over
  `mplayer` on Linux, and a warning when no player is found.
* `tuneR` moved from Depends to Imports. A small test suite was added.

Examples and tests never play audio (`play = FALSE`). The interactive
example is wrapped in `\dontrun{}` because it needs an external audio player.

## Test environments

* local: Ubuntu 23.10, R 4.3.1
* win-builder: R-devel (2026-10-05 r90641 ucrt), Status: OK

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Stefan Siegert <s.siegert@exeter.ac.uk>'

  (The local check also reported "unable to verify current time" and skipped
  HTML validation because `tidy` is not installed. Both are caused by the
  local environment, not the package.)

## Downstream dependencies

There are currently no reverse dependencies on CRAN.
