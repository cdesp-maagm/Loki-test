
using DSP

"""
    normalize(e, z)

Appliquer au point `z` la transformation de l'ellipse `e` vers le cercle unité.
"""
function normalize(e, z)
    # Translation et rotation.
    zn = (z .- e.zc) * cis(-e.α)
    # Égalisation.
    real(zn) / e.A + 1im * imag(zn) / e.B
end

"""
    demod(z, Fc, Fs)

Effectuer une démodulation de phase du vecteur `z`
puis appliquer un filtrage passe-bas avec une fréquence de coupure `Fc`, pour
une fréquence d'échantillonnage `Fs`.
"""
function demod(z, Fc, Fs)
    H = digitalfilter(Lowpass(Fc, fs=Fs), Butterworth(4))
    filtfilt(H, unwrap(angle.(z)))
end

"""
    demod(e, z, Fc, Fs)

Ramener les points du vecteur `z` au voisinage du cercle unité en utilisant
l'ellipse, ou le tableau d'ellipses, `e`.
Effectuer une démodulation de phase du vecteur `z`
puis appliquer un filtrage passe-bas avec une fréquence de coupure `Fc`, pour
une fréquence d'échantillonnage `Fs`.
"""
function demod(e, z, Fc, Fs)
    demod(normalize.(e, z), Fc, Fs)
end
