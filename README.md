# sonify

Data sonification in R: turn data into sound.

`sonify()` maps a series of data values onto a continuous tone whose pitch
rises and falls with the data. It works as an audio substitute for `plot()`
and makes data analysis easier for visually impaired users.

## Installation

From CRAN:

```r
install.packages("sonify")
```

Development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("sieste/sonify")
```

## Usage

```r
library(sonify)

# A bell curve: the pitch rises, then falls
sonify(dnorm(seq(-3, 3, 0.1)), duration = 1)

# Unevenly spaced x-values, with pitch mapped perceptually (log-frequency)
x <- sort(runif(50, 0, 10))
sonify(x, sin(x), pitch_mapping = "logarithmic")

# Mark negative values with white noise and add x-axis ticks
y <- cumsum(rnorm(100))
sonify(y, noise_interval = c(-Inf, 0), ticks = seq(-50, 50, 10))

# Generate the sound without playing it, and save it as a wav file
w <- sonify(y, play = FALSE)
tuneR::writeWave(w, "series.wav")
```

`sonify()` returns the sound as a `tuneR::WaveMC` object. Useful arguments:

| Argument | Purpose |
|---|---|
| `duration` | Length of the sound in seconds (default 5) |
| `flim` | Frequency range in Hz that the data is mapped to (default `c(440, 880)`) |
| `pitch_mapping` | `"linear"` (in Hz) or `"logarithmic"` (equal steps in perceived pitch) |
| `waveform` | `"sine"`, `"square"`, `"triangle"` or `"sawtooth"` |
| `interpolation` | `"spline"`, `"linear"` or `"constant"` between data points |
| `ticks` | x-axis tick positions, played as short clicks |
| `noise_interval`, `noise_amp` | Overlay white noise when the data is inside (or outside) an interval |
| `stereo` | Pan from left to right over the course of the sound (default `TRUE`) |

See `?sonify` for the full list.

## Audio playback

Playback uses an external command-line player via `tuneR::play()`:

- **Linux:** `mpv` if installed, otherwise `mplayer`
- **macOS:** `afplay`
- **Windows:** the default player from `?tuneR::play`

Use the `player` and `player_args` arguments to choose a different player.

## License

GPL (>= 2)
