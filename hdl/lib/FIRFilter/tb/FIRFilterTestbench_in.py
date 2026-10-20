
from os.path import dirname, abspath, join
import numpy as np
from scipy.signal import lfilter
from math import ceil, sin, log2, pi
from src.FIRFilter import generate_coefficients
from scripts.common import binround, binfloor, read_config, cfg_get_value

dir = dirname(abspath(__file__))
cfg = read_config(join(dir, "FIRFilterTestbench_cfg.json"))

channels         = cfg_get_value(cfg, "TB_CHANNELS")
coeffs_flen      = cfg_get_value(cfg, "FIR_COEFF_WIDTH") - 1
data_flen        = cfg_get_value(cfg, "TB_DATA_FRACTIONAL_WIDTH")
duration_samples = cfg_get_value(cfg, "TB_DURATION_SAMPLES")
fl               = cfg_get_value(cfg, "TB_CUTOFF_FREQUENCY_LOW")
fh               = cfg_get_value(cfg, "TB_CUTOFF_FREQUENCY_HIGH")
fs               = cfg_get_value(cfg, "TB_SAMPLE_FREQUENCY")

coeffs = generate_coefficients(cfg, "TB")
coeffs = np.array([binround(c, coeffs_flen) for c in coeffs])
gain_bits = ceil(log2(sum(abs(coeffs))))

freqs = np.linspace(fl/fs, fh/fs, 4)
gain = 1 / len(freqs)

t = np.linspace(0, duration_samples - 1, num=duration_samples)
out = []
for ch in range(channels):
    data_i = np.zeros(duration_samples)
    phase = 2 * pi * (ch + 1) / (channels + 1)
    for f in freqs:
        if f > 0:
            data_i += gain * np.cos(2 * pi * f * t + phase)
    data_o = lfilter(coeffs, 2 ** gain_bits, data_i)
    out.append((data_i, [binfloor(d, data_flen) for d in data_o]))

for k in range(duration_samples):
    for ch in range(channels):
        print("{} {} {}".format(ch, out[ch][0][k], out[ch][1][k]))
