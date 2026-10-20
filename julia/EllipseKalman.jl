
using LinearAlgebra

"""
    Kalman(Rv, Rw, δ=0.1)

Construire un filtre de Kalman avec `Rv` et `Rw` la puissance des bruits
de sortie et d'état.
Le paramètre `δ` sert à initialiser la matrice `P` du filtre.
"""
struct Kalman <: Estimator
    "La puissance du bruit de sortie du filtre"
    Rv :: Float64
    "La puissance du bruit d'état du filtre"
    Rw :: Float64
    "La matrice de covariance de l'erreur d'estimation"
    P :: Array{Float64, 2}
    "L'estimation courante des cœfficients de l'équation de l'ellipse"
    X :: Array{Float64, 1}

    Kalman(Rv, Rw, δ=0.1) = new(Rv, Rw, Matrix(δ * I, 5, 5), [0.5 ; 0 ; 0 ; 0 ; -0.5])
end

"""
    Ellipse(f :: Kalman, z)

Construire une ellipse à partir d'un ensemble de points en utilisant un filtre Kalman.
À chaque appel, cette fonction traite un point `z`, met à jour l'état du filtre `f`
et retourne une nouvelle ellipse.
"""
function Ellipse(f :: Kalman, z)
    J = Matrix(1.0I, 5, 5)

    x = real(z)
    y = imag(z)
    Y = -y^2
    C = [ x^2-y^2 x*y  x  y  1]

    ϵ = Y - first(C * f.X)
    L = f.P * C' / (first(C * f.P * C') + f.Rv)
    f.P[:, :] = (J - L * C) * f.P + f.Rw * J
    f.X[:] += ϵ * L

    (a, b, d, e, f) = f.X
    c = 1 - a

    Ellipse(a, b, c, d, e, f)
end
