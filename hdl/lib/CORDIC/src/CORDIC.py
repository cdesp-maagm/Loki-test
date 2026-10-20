
from math import atan, sqrt, pow, prod, pi
from scripts.common import fixed, slv, cfg_get_value

package_tpl = """
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.{with_pkg}.all;

package {package_name} is
    subtype Angle_t      is sfixed(2 downto -CORDIC_ANGLE_FRACTIONAL_WIDTH);
    subtype FullAngle_t  is sfixed(3 downto -CORDIC_ANGLE_FRACTIONAL_WIDTH);
    subtype RefAngle_t   is sfixed(0 downto -CORDIC_ANGLE_FRACTIONAL_WIDTH);
    type RefAngleArray_t is array(0 to CORDIC_ANGLE_FRACTIONAL_WIDTH) of RefAngle_t;

    constant CORDIC_PI        : Angle_t     := "{pi_bin}";
    constant CORDIC_2PI       : FullAngle_t := "{twopi_bin}";
    constant CORDIC_PI_OVER_2 : Angle_t     := "{pi2_bin}";

    constant CORDIC_ANGLES : RefAngleArray_t := ({angles_slv});

    constant CORDIC_SCALING : sfixed(1 downto -{scaling_flen}) := "{scaling_bin}";
end {package_name};
"""

def generate_package(name, cfg):
    angle_flen = cfg_get_value(cfg, "CORDIC_ANGLE_FRACTIONAL_WIDTH")

    # Les angles de référence, en binaire en virgule fixe.
    angles     = [atan(pow(2.0, -n))    for n in range(angle_flen + 1)]
    angles_slv = [slv(a, 1, angle_flen) for a in angles]

    # Précalcul du facteur de multiplication K.
    # Sa valeur est stable à partir de 51 bits après la virgule.
    scaling = 1.0 / sqrt(prod([1.0 + pow(2.0, -2 * n) for n in range(angle_flen + 1)]))
    scaling_flen = 51
    scaling_bin = fixed(scaling, 2, scaling_flen)

    print(package_tpl.format(
        package_name=name,
        with_pkg=cfg["package_name"],
        # La valeur des angles π, 2π et π/2 en radians, codés en binaire en virgule fixe.
        pi_bin=fixed(pi, 3, angle_flen),
        twopi_bin=fixed(pi * 2, 4, angle_flen),
        pi2_bin=fixed(pi / 2, 3, angle_flen),
        angles_slv=", ".join(angles_slv),
        scaling_flen=scaling_flen,
        scaling_bin=scaling_bin
    ))
