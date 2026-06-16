## Summary

This is a resubmission of an existing CRAN package (`sonify`, last on
CRAN as version 0.0-1, published 2017-02-01).

This release (0.0-2) fixes a bug reported by a user: `sonify()` failed
to play any sound on Linux systems where `/bin/sh` is `dash` rather than
`bash` (e.g. Debian, Ubuntu). The default Linux playback call relied on
the bash-only `&>` redirection operator, which `dash` parses
differently, causing `mplayer` to be invoked with no arguments and the
temporary wav file to be treated as a shell command, producing
`Permission denied` and no audio. The fix uses POSIX-compatible
redirection (`> /dev/null 2>&1`) that works under both shells. See
NEWS.md for details.

No new dependencies, no API changes, no deprecated/defunct functions.

## Test environments

* local: Ubuntu 23.10, R 4.3.1

## R CMD check results

0 errors | 0 warnings | 2 notes

* `checking for future file timestamps ... NOTE` — environment could not
  reach an NTP time server in this sandbox; not expected on CRAN's
  check machines.
* `checking HTML version of manual ... NOTE` — `tidy` is not installed
  in this sandbox; unrelated to the package.

## Downstream dependencies

None (checked via CRAN package search; no reverse dependencies).
