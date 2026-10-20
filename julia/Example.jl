import Pkg; Pkg.add("PyPlot")
using PyPlot
plt[:style][:use]("ggplot")

include("Ellipse.jl")
include("EllipsePlotting.jl")
include("EllipseLeastSquares.jl")
include("EllipseLMS.jl")
include("EllipseRLS.jl")
include("EllipseKalman.jl")
include("Demodulation.jl")

# L'ellipse théorique
E = Ellipse(0.25, 0.5, 1.5, 1, 0.75)

# La longueur d'onde du laser.
λ0 = 1310e-9
# L'amplitude du déplacement mécanique, en m.
Am = 20e-9
# La fréquence du déplacement mécanique, en Hz.
Fm = 5
# L'amplitude du déplacement fictif, en m.
Af = 300e-9
# La fréquence du déplacement fictif, en Hz.
Ff = 250
# L'écart-type du bruit.
σ = 0.01
# La fréquence d'échantillonnage, en Hz.
Fsamp = 20e3
# La durée de simulation, multiple d'une période d'oscillation mécanique.
tmax = 30 / Fm
t = range(0, stop=tmax, step=1/Fsamp)

# Phase liée au déplacement mécanique.
ϕm = 4π * Am * cos.(2π * Fm * t) / λ0
# Phase liée au déplacement fictif.
ϕf = 4π * Af * cos.(2π * Ff * t) / λ0

# Synthèse des deux composantes en quadrature, rotation, translation et bruit.
z = pointat.(E, ϕm + ϕf) + σ * (randn(length(t)) + 1im * randn(length(t)))

figure()
plot(real.(z), imag.(z))
plotellipse(E)
title("Données d'entrée et ellipse théorique")

# ------------------------------------------------------------------------------
# Lissage au sens des moindres carrés
# ------------------------------------------------------------------------------

println("Lissage au sens des moindres carrés")

Els = Ellipse(LeastSquares(), z)
figure()
plot(real.(z), imag.(z))
plotellipse(Els)
title("Données d'entrée et ellipse estimée au sens des moindres carrés")

figure()
ylim(-0.3, 0.3)
plot(t, ϕm)
plot(t, demod(Els, z, 4 * Fm, Fsamp))
title("Démodulation de l'ellipse estimée au sens des moindres carrés")

function run(f, label)
    println(label)

    Ef = Ellipse.(f, z)

    figure()
    plot(real.(z), imag.(z))
    plotellipse(Ef[end])
    title("$label: Données d'entrée et ellipse estimée")

    figure()
    xscale("log")
    ylim(0, 3)
    plot(t, getfield.(Ef, :A))
    plot(t, getfield.(Ef, :B))
    plot(t, real.(getfield.(Ef, :zc)))
    plot(t, imag.(getfield.(Ef, :zc)))
    plot(t, getfield.(Ef, :α))
    title("$label: Convergence des paramètres de l'ellipse estimée")

    figure()
    ylim(-0.3, 0.3)
    plot(t, ϕm)
    plot(t, demod(Ef, z, 4 * Fm, Fsamp))
    title("$label: Phase liée au déplacement mécanique")
end

# run(LMS(0.02, 0.01), "Filtre LMS")
run(RLS(), "Filtre RLS")
run(Kalman(1e-6, 0), "Filtre de Kalman")

show()
