# sonify 0.0-2

* Fixed a bug where `sonify()` failed to play audio on Linux systems where
  `/bin/sh` is not bash (e.g. Debian/Ubuntu, where `/bin/sh` is `dash`).
  The default player invocation used the bash-only `&>` redirection
  operator, which `dash` parses as backgrounding `mplayer` (with no
  arguments) followed by an attempt to *execute* the generated `.wav`
  file as a shell command, resulting in
  `sh: 1: .../tuneRtemp.wav: Permission denied`. The redirection is now
  written in POSIX form (`> /dev/null 2>&1`), which both `dash` and `bash`
  handle correctly.

# sonify 0.0-1

* Initial CRAN release.
