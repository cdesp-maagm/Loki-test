
from sys import stderr
from math import ceil, sin, pi
from scripts.common import slv, cfg_get_value

package_tpl = """
use work.fixed_pkg.all;
use work.{with_pkg}.all;

package {package_name} is

    subtype SinCos_t is sfixed(1 downto -OSC_SIN_COS_FRACTIONAL_WIDTH);
    type SinCosArray_t is array(natural range<>) of SinCos_t;

end {package_name};
"""

def generate_package(name, cfg):
    print(package_tpl.format(
        package_name=name,
        with_pkg=cfg["package_name"]
    ))

lookup_package_tpl = """
library ieee;
use ieee.std_logic_1164.all;

use work.{with_pkg}.all;

package {package_name} is
    constant LOOKUP_TABLE : SinCosArray_t(0 to {table_right}) := ({table_slv});
end {package_name};
"""

def generate_lookup_package(name, cfg, prefix):
    fmin = cfg_get_value(cfg, "{}_WAVE_FREQUENCY_MIN".format(prefix))
    fs   = cfg_get_value(cfg, "{}_SAMPLE_FREQUENCY".format(prefix))
    flen = cfg_get_value(cfg, "OSC_SIN_COS_FRACTIONAL_WIDTH")

    if fs % (4 * fmin) != 0:
        print("WARNING: fs={} is not a multiple of 4 * {}".format(fs, fmin), file=stderr)

    table_len = ceil(fs / fmin / 4 + 1)

    table_slv = [slv(sin(k * pi / 2 / (table_len - 1)), 2, flen) for k in range(table_len)]

    print(lookup_package_tpl.format(
        package_name = name,
        with_pkg = cfg["{}_use".format(prefix)],
        table_right = table_len - 1,
        table_slv = ", ".join(table_slv)
    ))
