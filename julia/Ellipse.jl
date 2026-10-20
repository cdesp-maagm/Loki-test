
"""
    Ellipse(zc, A, B, α)

Représentation d'une ellipse par son centre `zc`, son demi-grand axe `A`,
son demi-petit axe `B` et son angle `α` entre l'axe horizontal et le grand axe.
"""
struct Ellipse
    "Le centre de l'ellipse, représenté par un nombre complexe."
    zc :: ComplexF64
    "Le demi-grand axe de l'ellipse."
    A :: Float64
    "Le demi-petit axe de l'ellipse."
    B :: Float64
    "L'angle entre l'axe horizontal et le grand axe de l'ellipse."
    α :: Float64
end

Base.broadcastable(e :: Ellipse) = Ref(e)

"""
    Ellipse(xc, xy, A, B, α)

Construire une ellipse avec pour centre le point de coordonnées `xc` et `yc`,
demi-grand axe `A`, demi-petit axe `B` et angle `α`.
"""
Ellipse(xc, yc, A, B, α) = Ellipse(xc + 1im * yc, A, B, α)

"""
    Ellipse(a, b, c, d, e, f)

Construire une ellipse dont l'équation est :
``a x^2 + b x y + c y^2 + d x + e y + f = 0``
"""
function Ellipse(a, b, c, d, e, f)
    α = atan(-b, c - a) / 2
    (xc, yc) = -[2a b ; b 2c] \ [d ; e]
    Δf = a * xc^2 + b * xc * yc + c * yc^2 - f
    (A0, B0) = [sin(α)^2 cos(α)^2 ; cos(α)^2 sin(α)^2] \ [a ; c]
    Ellipse(xc + 1im * yc, sqrt(abs(Δf / B0)), sqrt(abs(Δf / A0)), α)
end

"""
    coefficients(e)

Calculer les coefficients de l'équation de l'ellipse e:
``a x^2 + b x y + c y^2 + d x + e y + f = 0``
"""
function coefficients(el)
    A2    = 1/el.A/el.A;
    B2    = 1/el.B/el.B;
    cosα  = cos(el.α);
    sinα  = sin(el.α);
    cosα2 = cosα * cosα;
    sinα2 = sinα * sinα;
    xc    = real(el.zc)
    yc    = imag(el.zc)
    xc2   = xc * xc
    yc2   = yc * yc

    a = A2 * cosα2 + B2 * sinα2
    b = (A2 - B2) * 2sinα * cosα
    c = B2 * cosα2 + A2 * sinα2
    d = -2a * xc - b * yc
    e = -2c * yc - b * xc
    f = a * xc2 + b * xc * yc + c * yc2 - 1

    [a, b, c, d, e, f] ./ (a + c)
end

abstract type Estimator end

Base.broadcastable(e :: Estimator) = Ref(e)

"""
    Ellipse(::Estimator, z)

Construire une ellipse à partir d'un tableau de points `z`.
"""
Ellipse(::Estimator, z) = error("Not implemented")

"""
    pointat(e, θ)

Retourne un nombre complexe représentant le point de l'ellipse `e`
situé à l'angle `θ`.
"""
pointat(e, θ) = e.zc + cis(e.α) * (e.A * cos(θ) + 1im * e.B * sin(θ))

"""
    point(e, n)

Retourne un tableau de `n` points de l'ellipse `e`.
"""
points(e, n) = pointat.(e, range(0, stop=2π, length=n + 1))
