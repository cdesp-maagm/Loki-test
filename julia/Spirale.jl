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
# Facteur de pondération
ϵ = 5e-2

# Phase liée au déplacement mécanique.
ϕm = 4π * Am * cos.(2π * Fm * t) / λ0
# Phase liée au déplacement fictif.
ϕf = 4π * Af * cos.(2π * Ff * t) / λ0

z = E.zc .+ cis(E.α) * (E.A * (1 .+ ϵ * ϕf) .* cos.(ϕm + ϕf) + 1im * E.B * (1 .+ ϵ * ϕf) .* sin.(ϕm + ϕf))

figure()
plot(real.(z), imag.(z))
plotellipse(E)
title("Données d'entrée et ellipse théorique")

function run(f, label, filename)
    println(label)

    Ef = Ellipse.(f, z)

    figure()
    plot(real.(z), imag.(z))
    plotellipse(Ef[end])
    title("$label: Données d'entrée et ellipse estimée")

    figure()
    # xscale("log")
    ylim(0, 3)
    plot(t, getfield.(Ef, :A))
    plot(t, getfield.(Ef, :B))
    plot(t, real.(getfield.(Ef, :zc)))
    plot(t, imag.(getfield.(Ef, :zc)))
    plot(t, getfield.(Ef, :α))
    title("$label: Convergence des paramètres de l'ellipse estimée")

    figure()
    # ylim(-0.3, 0.3)
    plot(t, ϕm)
    plot(t, demod(Ef, z, 4 * Fm, Fsamp))
    title("$label: Phase liée au déplacement mécanique")

    open(filename, "w") do f
        write(f, "# Ellipse: A=$(E.A) B=$(E.B) xc=$(real(E.zc)) yc=$(imag(E.zc)) angle=$(E.α)\r\n")
        write(f, "# $label\r\n")
        write(f, "#\r\n")
        write(f, "# t x y A B xc yc angle\r\n")
        for (it, iz, ie) in zip(t, z, Ef)
            write(f, "$it $(real(iz)) $(imag(iz)) $(ie.A) $(ie.B) $(real(ie.zc)) $(imag(ie.zc)) $(ie.α)\r\n")
        end
    end
end

outdir = "data/2018-06-06-Spirale"
mkpath(outdir)

run(LMS(0.02, 0.01), "Filtre LMS", "$outdir/Spirale-LMS-20k.txt")
run(RLS(), "Filtre RLS", "$outdir/Spirale-RLS-20k.txt")
run(Kalman(1e-4, 0), "Filtre de Kalman", "$outdir/Spirale-Kalman-20k.txt")

show()
