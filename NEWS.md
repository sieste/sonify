# sonify 0.1-0

* New argument `pitch_mapping` in `sonify()`. `pitch_mapping = "logarithmic"`
  maps the data linearly onto log-frequency, so equal steps in the data give
  equal steps in perceived pitch. The default (`"linear"`) keeps the previous
  behaviour.
* Stereo panning now uses an equal-power (sine/cosine) law, which removes the
  loudness dip in the middle of the left-to-right pan.
* Fixed an audible click at the start and end of each sound: the fade in/out
  now uses a raised-cosine ramp that reaches exactly zero.
* On Linux, `sonify()` now uses `mpv` when it is available, and falls back to
  `mplayer`. If neither is found, it issues a warning instead of failing
  silently.
* Fixed a bug where `sonify()` failed to play audio on Linux systems where
  `/bin/sh` is not bash (e.g. Debian/Ubuntu, where `/bin/sh` is `dash`).
  The default player invocation used the bash-only `&>` redirection
  operator, which `dash` parses as backgrounding the player followed by an
  attempt to *execute* the generated `.wav` file, resulting in
  `sh: 1: .../tuneRtemp.wav: Permission denied`. The redirection is now
  written in POSIX form (`> /dev/null 2>&1`).
* `noise_interval` must now have length at least 2. `pulse_len` is ignored
  (instead of failing) when all x-values are identical.
* `tuneR` moved from Depends to Imports.
* Added a basic test suite.

# sonify 0.0-1

* Initial CRAN release.
