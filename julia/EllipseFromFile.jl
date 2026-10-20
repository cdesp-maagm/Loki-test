#!/usr/bin/env julia

# 7 bits --> [-64 ; +64[ --> [-1 V ; +1 V[

# Conditions d'enregistrement :
# Fm1 = 1000 Hz
# Am1 = 5 mV (gain 0.32)
# Fm2 = 50 kHz
# Am2 = 100 mV (gain 6.4)

# Régler le gain de la photodiode à 20 dB

using Statistics
using DSP
using PyPlot
plt[:style][:use]("ggplot")

include("Ellipse.jl")
include("EllipsePlotting.jl")
include("EllipseLeastSquares.jl")
include("EllipseLMS.jl")
include("EllipseRLS.jl")
include("EllipseKalman.jl")
include("Demodulation.jl")

filename = ARGS[1] #"/home/gsavaton/tmp/test-5.bin"
channels = 1
channel = 0
Fsamp = 50e3
Fc = 400
duration = 4
nellipses = 10

# La longueur d'onde du laser.
λ0 = 1310e-9
K = λ0 / 4π

data = reinterpret(Float32, read(filename))
x = data[channel * 4 + 3:channels * 4:end]
y = data[channel * 4 + 4:channels * 4:end]
start = max(513, length(x) - round(Int, duration * Fsamp))
z = (x + 1im * y)[start:end]

data = nothing
x = nothing
y = nothing
GC.gc()

t = (0:length(z)-1) / Fsamp

# Optionnellement, centrer l'ellipse en (0, 0) pour faciliter la convergence.
# z .-= mean(z)

function run(f, Eref, label)
    println(label)

    Ef = Ellipse.(f, z)

    # Afficher le diagramme de Lissajous et quelques ellipses estimées.
    figure()
    suptitle("$label: Données d'entrée et ellipses estimées")
    plot(real.(z), imag.(z))
    plotellipse.(Ef[1:round(Int, length(Ef)/nellipses):end])

    # Afficher les coefficients de l'équation, et les paramètres de l'ellipse,
    # pour l'estimateur f.
    figure()
    suptitle("$label: Convergence des paramètres de l'ellipse estimée")
    subplot(211)
    # xscale("log")
    # ylim(0, 3)
    plot(t, getfield.(Ef, :A),         label="A")
    plot(t, getfield.(Ef, :B),         label="B")
    plot(t, real.(getfield.(Ef, :zc)), label="xc")
    plot(t, imag.(getfield.(Ef, :zc)), label="yc")
    plot(t, getfield.(Ef, :α),         label="alpha")
    legend()

    subplot(212)
    c = coefficients.(Ef)
    for n in 1:6
        plot(t, getindex.(c, n), label = "abcdef"[n:n])
    end
    legend()

    # Afficher les erreurs.
    figure()
    suptitle("$label: Erreur sur les paramètres de l'ellipse estimée")
    subplot(211)
    plot(t, abs.(getfield.(Ef, :A)         .- Eref.A),        label="A")
    plot(t, abs.(getfield.(Ef, :B)         .- Eref.B),        label="B")
    plot(t, abs.(real.(getfield.(Ef, :zc)) .- real(Eref.zc)), label="xc")
    plot(t, abs.(imag.(getfield.(Ef, :zc)) .- imag(Eref.zc)), label="yc")
    plot(t, abs.(getfield.(Ef, :α)         .- Eref.α),        label="alpha")
    legend()

    subplot(212)
    c = coefficients.(Ef)
    cref = coefficients.(Eref)
    for n in 1:6
        plot(t, abs.(getindex.(c, n) .- cref[n]), label = "abcdef"[n:n])
    end
    legend()

    figure()
    suptitle("$label: Phase liée au déplacement mécanique")
    # ylim(-0.3, 0.3)
    plot(t, K * demod(Ef, z, Fc, Fsamp))
end

println("Lissage au sens des moindres carrés")

Els = Ellipse(LeastSquares(), z)
figure()
suptitle("Données d'entrée et ellipse estimée au sens des moindres carrés")
plot(real.(z), imag.(z))
plotellipse(Els)

println("Ellipse de référence : A=$(Els.A) B=$(Els.B) xc=$(real(Els.zc)) yc=$(imag(Els.zc)) α=$(Els.α)")
println("Équation : $(coefficients(Els))")

# show()
# exit()

# figure()
# plot(t, real.(z))
# plot(t, imag.(z))

figure()
suptitle("Démodulation de l'ellipse estimée au sens des moindres carrés")
# ylim(-0.3, 0.3)
plot(t, K * demod(Els, z, Fc, Fsamp))

# run(LMS(0.02, 0.01), Els, "Filtre LMS")
# run(RLS(0.999), Els, "Filtre RLS")
run(Kalman(1e-4, 0), Els, "Filtre de Kalman")

show()
