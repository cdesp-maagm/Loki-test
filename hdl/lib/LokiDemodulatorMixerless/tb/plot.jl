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

thisdir = dirname(@__FILE__)

cfg = JSON.parsefile(joinpath(thisdir, "LokiDemodulatorMixerlessTestbench_cfg.json"))

function cfg_get_value(k)
    cste = cfg["declarations"][k]
    if cste["type"] == "real" && typeof(cste["value"]) == String
        parse(Float64, cste["value"])
    else
        cste["value"]
    end
end

displacement_filename = cfg_get_value("TB_DISPLACEMENT_FILENAME")
channels              = cfg_get_value("TB_CHANNELS")
F1                    = cfg_get_value("TB_OSC1_WAVE_FREQUENCY")
Fm                    = cfg_get_value("TB_DISPLACEMENT_FREQUENCY")
Am                    = cfg_get_value("TB_DISPLACEMENT_AMPLIUDE")
d1                    = cfg_get_value("TB_LOWPASS_DECIMATION")
d2                    = cfg_get_value("TB_BANDPASS_DECIMATION")
Fsamp                 = cfg_get_value("TB_DEMOD_SAMPLE_FREQUENCY") / d1 / d2
λ0                    = cfg_get_value("TB_WAVELENGTH")

csv = joinpath(thisdir, "..", "build", "tb", "LokiDemodulatorMixerlessTestbench_out.csv")
data = readdlm(csv, ',')

if length(displacement_filename) > 0
    displacement = readdlm(displacement_filename)
end

for c in 1:channels
    x = data[c:channels:end, 2]
    y = data[c:channels:end, 3]

    k = 0:length(x)-1
    t = k / Fsamp

    kmin = ceil(Int, Fsamp / F1)
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
