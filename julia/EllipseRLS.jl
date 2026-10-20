
using LinearAlgebra

"""
    RLS(λ=0.99, δ=0.1)

Construire un filtre RLS avec pour facteur d'oubli `λ`.
Le paramètre `δ` sert à initialiser la matrice `P` du filtre.
"""
struct RLS <: Estimator
    "Le facteur d'oubli du filtre"
    λ :: Float64
    "L'inverse de la matrice de covariance du signal d'entrée"
    P :: Array{Float64, 2}
    "L'estimation courante des cœfficients de l'équation de l'ellipse"
    K :: Array{Float64, 1}

    RLS(λ=0.99, δ=0.1) = new(λ, Matrix(δ * I, 5, 5), [0.5 ; 0 ; 0 ; 0 ; -1e-4])
end

"""
    Ellipse(f :: RLS, z)

Construire une ellipse à partir d'un ensemble de points en utilisant un filtre RLS.
À chaque appel, cette fonction traite un point `z`, met à jour l'état du filtre `f`
et retourne une nouvelle ellipse.
"""
function Ellipse(f :: RLS, z)
    J = Matrix(1.0I, 5, 5)

    x = real(z)
    y = imag(z)
    Y = -y^2
    X = [x^2-y^2 x*y x y 1]

    ϵ = Y - first(X * f.K)
    G = f.P * X' / (first(X * f.P * X') + f.λ)
    f.P[:, :] = (J - G * X) * f.P / f.λ
    f.K[:] += ϵ * G

    (a, b, d, e, f) = f.K
    c = 1 - a

    Ellipse(a, b, c, d, e, f)
end
