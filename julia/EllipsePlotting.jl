
using PyPlot

"""
    plotellipse(e)

Trace une ellipse en utilisant la fonction `plot` de PyPlot.
"""
function plotellipse(e, n=360)
    z = points(e, n)
    plot(real.(z), imag.(z))
end
