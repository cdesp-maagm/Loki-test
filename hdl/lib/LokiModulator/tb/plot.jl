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

cfg = JSON.parsefile(joinpath(thisdir, "LokiModulatorTestbench_cfg.json"))

function cfg_get_value(k)
    cste = cfg["declarations"][k]
    if cste["type"] == "real" && typeof(cste["value"]) == String
        parse(Float64, cste["value"])
    else
        cste["value"]
    end
end

F1        = cfg_get_value("TB_OSC1_WAVE_FREQUENCY")
F2        = cfg_get_value("TB_OSC2_WAVE_FREQUENCY")
Fm        = cfg_get_value("TB_DISPLACEMENT_FREQUENCY")
Am        = cfg_get_value("TB_DISPLACEMENT_AMPLIUDE")
Fsamp     = cfg_get_value("TB_SAMPLE_FREQUENCY")
λ0        = cfg_get_value("TB_WAVELENGTH")
use_mixer = false

csvmod   = joinpath(thisdir, "..", "build", "tb", "LokiModulatorTestbench_out.csv")
csvdemod = joinpath(thisdir, "..", "build", "tb", "LokiModulatorTestbench_xy.csv")

data = readdlm(csvmod, ',')

phase = data[:, 1]
P     = data[:, 2]

k = 0:length(P)-1
t = k / Fsamp

# oscx = sin.(2π * F2 * t)
# oscy = sin.(4π * F2 * t)
# mx = mod(findmax(abs.(xcorr(P, oscx)))[2] - length(t), Fsamp / F2)
# my = mod(findmax(abs.(xcorr(P, oscy)))[2] - length(t), Fsamp / 2F2)
# println("Delay x = $mx samples ($(2π*F2*mx/Fsamp) rad)")
# println("Delay y = $my samples ($(4π*F2*my/Fsamp) rad)")

δt = (cfg_get_value("TB_SENSOR_DELAY") + 1) / Fsamp

decimation = round(Int, Fsamp / F2)

oscx = sin.(2π * F2 * (t .- δt))
oscy = -cos.(4π * F2 * (t .- δt))

if use_mixer
    H = digitalfilter(Lowpass(F2 / 4, fs=Fsamp), Butterworth(4))
    x = filtfilt(H, P .* oscx)
    y = filtfilt(H, P .* oscy)
else
    Hx = digitalfilter(Bandpass(F2 * 0.5, F2 * 1.5, fs=Fsamp), Butterworth(4))
    Hy = digitalfilter(Bandpass(F2 * 1.5, F2 * 2.5, fs=Fsamp), Butterworth(4))
    x = filtfilt(Hx, P)
    y = filtfilt(Hy, P)
end

x  = x[1:decimation:end]
y  = y[1:decimation:end]

kmin = ceil(Int, F2 / F1)
kmax = length(x) - kmin

ts = t[1:decimation:end][kmin:kmax]
x = x[kmin:kmax]
y = y[kmin:kmax]

writedlm(csvdemod, [x y], ',')

z = x + 1im * y
u = periodogram(P, fs=F2)
e = Ellipse(LeastSquares(), z)
d = demod(e, z, 4 * Fm, F2)

figure()

subplot(211)
plot(t, phase)
title("Phase")

subplot(212)
plot(t, oscx)
plot(t, oscy)
plot(t, P)
title("Power")
tight_layout()

figure()

subplot(311)
plot(ts, x)

subplot(312)
plot(ts, y)

subplot(313)
plot(x, y)
plotellipse(e)

figure()

subplot(211)
plot(freq(u), power(u))

subplot(212)
plot(ts, (d .- π/2) * λ0 / 4π)
plot(ts, Am * cos.(2π * Fm .* ts))

show()
