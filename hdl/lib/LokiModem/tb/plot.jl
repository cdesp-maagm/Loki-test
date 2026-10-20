#!/usr/bin/env julia

using PyPlot
plt[:style][:use]("ggplot")

using DelimitedFiles
using DSP
import JSON

D="../../../../julia"
include("$D/Ellipse.jl")
include("$D/EllipseLeastSquares.jl")
include("$D/EllipsePlotting.jl")
include("$D/Demodulation.jl")

jsondir = "."
csvdir = joinpath("build", "tb")

cfg = merge(
    JSON.parsefile(joinpath(jsondir, "LokiModem_cfg.json"))["declarations"],
    JSON.parsefile(joinpath(jsondir, "LokiModemTestbench_cfg.json"))["declarations"]
)

function cfg_get_value(k)
    cste = cfg[k]
    if cste["type"] == "real" && typeof(cste["value"]) == String
        parse(Float64, cste["value"])
    else
        cste["value"]
    end
end

if cfg_get_value("TB_DEMOD_MIXERLESS")
    d1 = cfg_get_value("DEMOD_MIXERLESS_LOWPASS_DECIMATION")
    d2 = cfg_get_value("DEMOD_MIXERLESS_BANDPASS_DECIMATION")
else
    d1 = cfg_get_value("DEMOD_MIXING_LOWPASS1_DECIMATION")
    d2 = cfg_get_value("DEMOD_MIXING_LOWPASS2_DECIMATION")
end

displacement_filename = cfg_get_value("TB_DISPLACEMENT_FILENAME")
channels              = cfg_get_value("TB_DEMOD_CHANNELS")
F1                    = cfg_get_value("TB_OSC1_WAVE_FREQUENCY")
Fm                    = cfg_get_value("TB_DISPLACEMENT_FREQUENCY")
Am                    = cfg_get_value("TB_DISPLACEMENT_AMPLIUDE")
Fsamp                 = cfg_get_value("DEMOD_SAMPLE_FREQUENCY_REF") / d1 / d2
λ0                    = cfg_get_value("TB_WAVELENGTH")

csv = joinpath(csvdir, "LokiModemTestbench_out.csv")
data = readdlm(csv, ',')

if length(displacement_filename) > 0
    displacement = readdlm(displacement_filename)
end

for c in 1:channels
    x = data[c:channels:end, 3]
    y = data[c:channels:end, 4]

    k = 0:length(x)-1
    t = k / Fsamp

    kmin = 2 * ceil(Int, Fsamp / F1)
    kmax = length(x)
    ks = kmin:kmax

    z = x[ks] + 1im * y[ks]
    u = periodogram(angle.(z), fs=Fsamp)
    e = Ellipse(LeastSquares(), z)
    d = demod(e, z, F1 / 4, Fsamp)

    figure()
    suptitle("Voie $c")

    subplot(411)
    plot(t[ks], x[ks])

    subplot(412)
    plot(t[ks], y[ks])

    subplot(413)
    plot(x[ks], y[ks])
    plotellipse(e)

    figure()
    suptitle("Voie $c")

    subplot(211)
    plot(freq(u), power(u))

    subplot(212)
    plot(t[ks], (d .+ π) * λ0 / 4π)
    if length(displacement_filename) > 0
        plot(t[ks], displacement[ks .* d1 .* d2])
    else
        plot(t[ks], Am * cos.(2π * c * Fm .* t[ks]))
    end
end

show()
