
from sys import stderr
from scipy.signal import firwin
from math import ceil, log2, pi
from scripts.common import slv, cfg_get_value

package_tpl = """
use work.fixed_pkg.all;
use work.{with_pkg}.all;

package {package_name} is
    subtype Coefficient_t is sfixed(0 downto 1 - FIR_COEFF_WIDTH);
    type CoefficientArray_t is array(natural range <>) of Coefficient_t;
    type CoefficientMatrix_t is array(natural range <>, natural range<>) of Coefficient_t;
end {package_name};
"""

def generate_package(name, cfg):
    print(package_tpl.format(
        package_name=name,
        with_pkg=cfg["package_name"]
    ))

coeffs_package_tpl = """
library ieee;
use ieee.std_logic_1164.all;

use work.{with_pkg}.all;

package {package_name} is
    constant GAIN_BITS : natural := {gain_bits};
    constant COEFFICIENTS : CoefficientMatrix_t(0 to {coeffs_right1}, 0 to {coeffs_right2}) := (
{coeffs_slv}
    );
end {package_name};
"""

def generate_coefficients(cfg, prefix):
    fl   = cfg_get_value(cfg, "{}_CUTOFF_FREQUENCY_LOW".format(prefix))
    fh   = cfg_get_value(cfg, "{}_CUTOFF_FREQUENCY_HIGH".format(prefix))
    fs   = cfg_get_value(cfg, "{}_SAMPLE_FREQUENCY".format(prefix))
    taps = cfg_get_value(cfg, "{}_TAPS".format(prefix))
    win  = eval(cfg_get_value(cfg, "{}_WINDOW".format(prefix)))
    flen = cfg_get_value(cfg, "FIR_COEFF_WIDTH") - 1

    if fl <= 0:
        print("INFO: Generating low-pass filter", file=stderr)
        cutoff = fh
        resp = "lowpass"
    elif fh <= 0:
        print("INFO: Generating high-pass filter", file=stderr)
        cutoff = fl
        resp   = "highpass"
    else:
        print("INFO: Generating band-pass filter", file=stderr)
        cutoff = [fl, fh]
        resp   = "bandpass"

    flt = firwin(taps, cutoff, window=win, pass_zero=resp, fs=fs)
    return flt * (1 - 2.0 ** -flen) / abs(flt).max()

def generate_coefficients_package(name, cfg, prefix):
    decimation  = cfg_get_value(cfg, "{}_DECIMATION".format(prefix))
    parallelism = cfg_get_value(cfg, "{}_PARALLELISM".format(prefix))
    flen        = cfg_get_value(cfg, "FIR_COEFF_WIDTH") - 1

    coeffs = generate_coefficients(cfg, prefix)

    divisor = decimation * parallelism
    padding = divisor - len(coeffs) % divisor;
    if padding == divisor:
        padding = 0;

    coeffs.resize(len(coeffs) + padding)
    coeffs_tbl = coeffs.reshape((-1, decimation))

    def row_slv(ch, arr):
        rarr = reversed(arr)
        return "        -- " + str(list(rarr)) + \
               "\n        {} => (\n            ".format(ch) + \
               ",\n            ".join([slv(c, 1, flen) for c in reversed(arr)]) + "\n        )"

    coeffs_slv = ",\n".join([row_slv(r, coeffs_tbl[:,r]) for r in range(decimation)])

    print(coeffs_package_tpl.format(
        package_name = name,
        with_pkg = cfg["{}_use".format(prefix)],
        gain_bits = ceil(log2(sum(abs(coeffs)))),
        coeffs_right1 = coeffs_tbl.shape[1] - 1,
        coeffs_right2 = coeffs_tbl.shape[0] - 1,
        coeffs_slv = coeffs_slv
    ))
