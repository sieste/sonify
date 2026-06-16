#' Data sonification
#'
#' Sonification (or audification) is the process of representing data by sounds in the audible range. This package provides the R function `sonify` that transforms univariate data, sampled at regular or irregular intervals, into a continuous sound with time-varying frequency. The ups and downs in frequency represent the ups and downs in the data. Sonify provides a substitute for R's plot function to simplify data analysis for the visually impaired.
#'
#' @param x The x values. Can be used when y values are unevenly spaced. Default is -length(y)/2:length(y)/2
#' @param y The data values used to modulate the frequency.
#' @param waveform The waveform used for the sound. One of `sine`, `square`, `triangle`, `sawtooth`. Default is `sine`.
#' @param ticks The location of x-axis ticks. The ticks are indicated by short bursts of a sawtooth wave (duration set by `tick_len`). The default is NULL (no ticks).
#' @param tick_len The duration of each tick sound.
#' @param pulse_len Length of white-noise pulses (in seconds) to mark the individual x-values. Ignored if all (non-`NA`) x-values are identical. Default is 0.
#' @param pulse_amp Amplitude of pulses between 0 and 1. Default is 0.2.
#' @param interpolation The interpolation method to connect the y-values before generating the sound. One of `spline`, `linear`, `constant`. `spline` and `linear` generate continous transitions between frequencies, `constant` changes frequencies abruptly. Note: If `interpolation=constant`, y[1] is played from x[1] to x[2], y[2] is played from x[2] to x[3], etc, and the last y-value y[n] is played for the duration x[n] - x[n-1]. Default is `spline`.
#' @param duration Total duration of the generated sound in seconds. Default is 5.
#' @param noise_interval A numeric vector of length (at least) 2; only the first two elements are used. White noise is overlayed whenever y is inside this interval (if noise_amp > 0) or outside this interval (if noise_amp < 0). For example, set to c(-Inf, 0) to indicate data in the negative range. Default is c(0,0) (no noise).
#' @param noise_amp Amplitude (between 0 and 1) of the noise used for noise_interval. Negative values (between 0 and -1) invert noise_interval, i.e. noise is overlaid whenever y falls outside `noise_interval`. Default is 0.5.
#' @param amp_level Amplitude level between 0 and 1 to adjust the volume. Default is 1.
#' @param stereo If TRUE a left-to-right transition is simulated, using equal power panning. Default is TRUE.
#' @param smp_rate The sampling rate of the wav file. Default is 44100 (CD quality)
#' @param flim The frequency range in Hz to which the data is mapped. Default is c(440, 880).
#' @param pitch_mapping How `y` is mapped onto `flim`. `"linear"` maps linearly in Hz, so equal steps in the data give equal steps in Hz. `"logarithmic"` maps linearly in log-frequency, so equal steps in the data give equal steps in perceived pitch. Default is `"linear"`.
#' @param na_freq Frequency in Hz that is used for NA data. Default is 300.
#' @param play If TRUE, the sound is played. Default is TRUE. 
#' @param player (Path to) a program capable of playing a wave file from the command line. Under windows, the default is "mplay32.exe" or "wmplayer.exe" (as specified in `?tuneR::play`). Under Linux, the default is "mplayer"; if `mplayer` is not found on the PATH, a warning is issued and no sound is played. Under OS X, the default is "afplay". See `?tuneR::play` for details.
#' @param player_args Further arguments passed to the wav player, as a single string (e.g. `"-novideo -really-quiet"`). Ignored when `player` is unspecified. Under Windows the default is `"/play /close"`. Under Linux the default is `"> /dev/null 2>&1"`. Under OS X the default is "". See `?tuneR::play` for details.
#'
#' @return The synthesized sound saved as a `tuneR::WaveMC` object.
#' 
#' @examples
#' obj = sonify(dnorm(seq(-3,3,.1)), duration=1, play=FALSE)
#' \dontrun{sonify(dnorm(seq(-3,3,.1)), duration=1)}
#'
#' @seealso tuneR::play, tuneR::WaveMC
#'
#' @author Stefan Siegert \email{s.siegert@@exeter.ac.uk} (please report bugs!)
#'
#' @section Licence:
#' GPL (>=2)
#'
#' 
#' @importFrom stats approx pnorm runif spline
#' @importFrom utils tail
#' @importFrom tuneR WaveMC normalize play
#'
#' @export 


sonify = 
function(x=NULL, y=NULL,
         waveform=c('sine', 'square', 'triangle', 'sawtooth'),
         interpolation=c('spline', 'linear', 'constant'),
         duration=5, flim=c(440, 880),
         pitch_mapping=c('linear', 'logarithmic'),
         ticks=NULL, tick_len=0.05,
         pulse_len=0, pulse_amp=0.2,
         noise_interval=c(0, 0), noise_amp=0.5,
         amp_level=1, na_freq=300,
         stereo=TRUE, smp_rate=44100,
         play=TRUE, player=NULL, player_args=NULL)
{

  # error checking
  ################

  # sonify() throws an error
  stopifnot(!is.null(x) | !is.null(y))

  # sonify(rnorm(10)) is interpreted as sonify(x=NULL, y=rnorm(10))
  if (is.null(y)) {
    y = x
    x = NULL
  }
  if(is.null(x)) {
    x = seq_along(y) - round(length(y) / 2)
  } 
  stopifnot(length(x) == length(y))
  stopifnot(is.numeric(flim), length(flim)>1)
  stopifnot(is.numeric(noise_interval), length(noise_interval)>1)

  flim = sort(flim[1:2])
  if (!is.null(ticks)) ticks = sort(ticks)
  noise_interval = sort(noise_interval[1:2])
  noise_amp = min(max(noise_amp, -1), 1)
  waveform = match.arg(waveform)
  interpolation = match.arg(interpolation)
  pitch_mapping = match.arg(pitch_mapping)
  if (pitch_mapping == 'logarithmic') {
    stopifnot(all(flim > 0))
  }

  # if only one y-value is given, set interpolation = spline; only spline
  # interpolation will not throw an error; also spline will return a constant,
  # which is what would be expected from the other interpolation methods
  if (length(x) < 2) {
    interpolation = 'spline'
  }

  # for constant interpolation, append the last y value and the last
  # x-interval; only then will the last y-value be played
  if (interpolation == 'constant') {
    y = c(y, tail(y,1))
    x = c(x, tail(x,1) + diff(tail(x,2))) 
  }

  ################

  # auxiliary quantities
  n = duration * smp_rate
  x_ran = range(x, na.rm=TRUE)
  y_ran = range(y, na.rm=TRUE)
  if (y_ran[1] == y_ran[2]) {
    y_ran = y_ran + c(-1, 1)
  }


  # rescale y values to desired frequency range
  yy = MapToFreq(y, y_ran=y_ran, flim=flim, pitch_mapping=pitch_mapping)

  # replace NA's by na_freq
  yy[is.na(yy)] = na_freq
  
  # interpolate to length n
  interp = switch(interpolation,
    spline = spline(x=x, y=yy, n=n),
    linear = approx(x=x, y=yy, n=n),
    constant = approx(x=x, y=yy, n=n, method='constant')
  )
  xx = interp$x
  yy = interp$y
  
  # make signal for range of x and yy
  signal = MakeSignal(yy, waveform=waveform, smp_rate=smp_rate)

  # indicate ticks by a sawtooth burst
  n_tick_half = round(tick_len * smp_rate / 2)    
  for (i in seq_along(ticks)) {
    tick_ = ticks[i]
    if(tick_ > x_ran[1] & tick_ < x_ran[2]) {
      # ind is largest index smaller than tick index
      ind = which.max(xx[xx < tick_])
      xinds = (ind - n_tick_half):(ind + 1 + n_tick_half)
      xinds = xinds[xinds > 0 & xinds <= n]
      signal[xinds] = signal[xinds] + MakeSignal(yy[xinds], waveform='sawtooth', 
                                                 smp_rate=smp_rate)
    }
  }
    
  # add pulses of white noise to mark x values
  # (skipped if all non-NA x are identical, since x-locations would be undefined)
  if (pulse_len > 0 && diff(range(x, na.rm=TRUE)) > 0) {
    n_pulse_half = round(pulse_len * smp_rate / 2)
    i_pulses = round((x - min(x, na.rm=TRUE)) / diff(range(x, na.rm=TRUE)) * (n-1)) + 1
    i_pulses = i_pulses[!is.na(i_pulses)]
    for (i in seq(-n_pulse_half, n_pulse_half)) {
      j = i_pulses + i
      j = j[j > 0 & j <= n]
      signal[j] = signal[j] + pulse_amp * runif(1)
    }
  }

  # add white noise whenever y is within (or outside) `noise_interval`
  # rescale noise_interval to frequency range (use same transformation as for y)
  noise_interval = MapToFreq(noise_interval, y_ran=y_ran, flim=flim, pitch_mapping=pitch_mapping)
  inds = (yy > noise_interval[1] & yy <= noise_interval[2])
  if (noise_amp < 0) {
    inds = !inds
  }
  signal[inds] = signal[inds] + abs(noise_amp) * runif(sum(inds))
    
  # pan left-to-right using an equal-power (sin/cos) law, so that the
  # combined acoustic power stays constant; a simple linear amplitude
  # crossfade would create a ~3dB loudness dip in the middle of the pan
  if (stereo) {
    ramp = seq(0, pi/2, length.out=n)
  } else {
    ramp = rep(pi/4, times=n)
  }

  Rchannel = round(32000 * signal * sin(ramp))
  Lchannel = round(32000 * signal * cos(ramp))
  
  # construct tuneR wave object
  final = tuneR::WaveMC(data = data.frame(FR=Rchannel, FL=Lchannel), samp.rate=smp_rate, bit=16)
  final = tuneR::normalize(final, unit='16', level=amp_level)
  
  # synthesize
  if (play) {
    if (is.null(player)) { # try to find a wav player
      if (Sys.info()[['sysname']] == 'Linux') {
        if (nzchar(Sys.which('mplayer'))) {
          tuneR::play(final, 'mplayer', '> /dev/null 2>&1')
        } else {
          warning("'mplayer' was not found on the PATH; no sound was played. ",
                  "Install mplayer, or pass the `player` argument to use a ",
                  "different command-line wav player (e.g. player='mpv').",
                  call.=FALSE)
        }
      } else if (Sys.info()[['sysname']] == 'Darwin') {
        tuneR::play(final, 'afplay', '')
      } else {
        tuneR::play(final) # use tuneR defaults
      }
    } else {
      tuneR::play(final, player=player, player_args)
    }
  }

  # return the synthesized WaveMC object
  invisible(final)

}


# map data values v onto the frequency range flim, either linearly in Hz
# or linearly in log-frequency (so that equal steps in v give equal
# perceived pitch steps, rather than equal Hz steps)
MapToFreq = function(v, y_ran, flim, pitch_mapping) {
  if (pitch_mapping == 'logarithmic') {
    log_flim = log(flim)
    exp((v - y_ran[1]) / diff(y_ran) * diff(log_flim) + log_flim[1])
  } else {
    (v - y_ran[1]) / diff(y_ran) * diff(flim) + flim[1]
  }
}


# function to make signal
MakeSignal = function(yy, waveform, smp_rate) {
  # fourier coefficients for different waveform
  a = switch(waveform,
    sine = 1,
    square = c(1, 0, 1/3, 0, 1/5, 0, 1/7, 0, 1/9),
    triangle = c(1, 0, -1/9, 0, 1/25, 0, -1/49, 0, 1/81),
    sawtooth = 1/(1:9)
  )
  # create waveform with instantaneous frequency yy
  sig = rowSums(
  sapply(seq_along(a), function(i) {
      a[i] * sin(i * 2 * pi * cumsum(yy) / smp_rate)
    })
  )
  # fade in and out to avoid clicking
  n = length(yy)
  n_fade = min(1000, n)
  sig[1:n_fade] = sig[1:n_fade] * pnorm(seq(-3,3,len=n_fade))
  sig[(n-n_fade+1):n] = sig[(n-n_fade+1):n] * (1-pnorm(seq(-3,3,len=n_fade)))

  return(sig)
}

