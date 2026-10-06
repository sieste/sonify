library(sonify)

y = seq(0, 1, length.out=11)

# returns a 2-channel WaveMC object of the requested length
w = sonify(y, duration=0.5, play=FALSE)
stopifnot(inherits(w, "WaveMC"), ncol(w@.Data) == 2, nrow(w@.Data) == 0.5 * 44100)

# fades bring the signal to exactly zero at both ends (no click)
stopifnot(all(w@.Data[1, ] == 0), all(w@.Data[nrow(w@.Data), ] == 0))

# without stereo, both channels are identical (equal-power centre)
w = sonify(y, duration=0.2, stereo=FALSE, play=FALSE)
stopifnot(identical(w@.Data[, 1], w@.Data[, 2]))

# logarithmic pitch mapping: data midpoint maps to the geometric mean of flim
f = sonify:::MapToFreq(c(0, 0.5, 1), y_ran=c(0, 1), flim=c(440, 880),
                       pitch_mapping="logarithmic")
stopifnot(isTRUE(all.equal(f, c(440, sqrt(440 * 880), 880))))
f = sonify:::MapToFreq(c(0, 0.5, 1), y_ran=c(0, 1), flim=c(440, 880),
                       pitch_mapping="linear")
stopifnot(isTRUE(all.equal(f, c(440, 660, 880))))
w = sonify(y, duration=0.2, pitch_mapping="logarithmic", play=FALSE)
stopifnot(inherits(w, "WaveMC"))

# input validation
stopifnot(inherits(try(sonify(y, flim=c(0, 880), pitch_mapping="logarithmic",
                              play=FALSE), silent=TRUE), "try-error"))
stopifnot(inherits(try(sonify(y, noise_interval=1, play=FALSE), silent=TRUE),
                   "try-error"))

# degenerate inputs do not fail
for (args in list(list(y=rep(2, 5)), list(y=3), list(y=c(1, NA, 3, 4)),
                  list(x=rep(1, 3), y=1:3, pulse_len=0.01),
                  list(y=y, interpolation="constant", ticks=0.5),
                  list(y=y, noise_interval=c(-Inf, 0.5), noise_amp=-0.5))) {
  w = suppressWarnings(do.call(sonify, c(args, duration=0.2, play=FALSE)))
  stopifnot(inherits(w, "WaveMC"))
}
