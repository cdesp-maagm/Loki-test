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

cfg = JSON.parsefile(joinpath(jsondir, "LokiDemodulatorTestbench_cfg.json"))

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
d1                    = cfg_get_value("TB_LOWPASS1_DECIMATION")
d2                    = cfg_get_value("TB_LOWPASS2_DECIMATION")
Fsamp                 = cfg_get_value("TB_DEMOD_SAMPLE_FREQUENCY") / d1 / d2
λ0                    = cfg_get_value("TB_WAVELENGTH")

csv = joinpath(csvdir, "LokiDemodulatorTestbench_out.csv")
data = readdlm(csv, ',')

if length(displacement_filename) > 0
    displacement = readdlm(displacement_filename)
end

for c in 1:channels
    x = data[c:channels:end, 2]
    y = data[c:channels:end, 3]

    k = 0:length(x)-1
    t = k / Fsamp

    kmin = 2 * ceil(Int, Fsamp / F1)
    kmax = length(x)
    ks = kmin:kmax

    z = x[ks] + 1im * y[ks]
    u = periodogram(angle.(z), fs=Fsamp)
    e = Ellipse(LeastSquares(), z)
    d = demod(e, z, (channels + 1) * Fm, Fsamp)

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
    plot(t[ks], (d .+ π) * λ0 / 4π, label="tb")
    if length(displacement_filename) > 0
        plot(t[ks], displacement[ks .* d1 .* d2], label="ref")
    else
        plot(t[ks], Am * cos.(2π * c * Fm .* t[ks]), label="ref")
    end
    legend()
end

show()
