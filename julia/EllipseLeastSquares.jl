
"Estimateur aux moindres carrés"
struct LeastSquares <: Estimator end

"""
    Ellipse(ls :: LeastSquares, z)

Construire une ellipse à partir d'un vecteur de points `z`
par lissage au sens des moindres carrés.
"""
function Ellipse(::LeastSquares, z)
    x = real.(z)
    y = imag.(z)
    M = [ x.^2-y.^ 2  x.*y  x  y  ones(size(z)) ]
    (a, b, d, e, f) = M \ -y.^2
    c = 1 - a
    Ellipse(a, b, c, d, e, f)
end
