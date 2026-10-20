
"""
    LMS(μ, ν=1e-6)

Construire un filtre LMS normalisé avec pour pas d'apprentissage `μ`.
Le paramètre `ν` est une petite valeur évitant les divisions par zéro
lors de la normalisation.
"""
struct LMS <: Estimator
    "Le pas d'apprentissage du filtre"
    μ :: Float64
    "Le cœfficient du filtre passe-bas pour le calcul des facteurs de normalisation"
    α :: Float64
    "Une petite valeur évitant les divisions par zéro lors de la normalisation"
    ν :: Float64
    "L'estimation courante des cœfficients de l'équation de l'ellipse"
    K :: Array{Float64, 1}
    "La puissance courante des cœefficients"
    P :: Array{Float64, 1}

    LMS(μ, α, ν=1e-30) = new(μ, α, ν, [0.5 ; 0 ; 0 ; 0 ; -1e-4], zeros(5))
end

"""
    Ellipse(f :: LMS, z)

Construire une ellipse à partir d'un ensemble de points en utilisant un filtre LMS.
À chaque appel, cette fonction traite un point `z`, met à jour l'état du filtre `f`
et retourne une nouvelle ellipse.
"""
function Ellipse(f :: LMS, z)
    x = real(z)
    y = imag(z)
    Y = -y^2
    X = [x^2-y^2 x*y x y 1]

    ϵ = Y - first(X * f.K)
    f.P[:] += f.α * (X' .^ 2 - f.P)
    μn = f.μ ./ (f.ν .+ f.P)
    f.K[:] += μn * ϵ .* X'

    (a, b, d, e, f) = f.K
    c = 1 - a

    Ellipse(a, b, c, d, e, f)
end
