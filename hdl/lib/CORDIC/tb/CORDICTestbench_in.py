
from os.path import dirname, abspath, join
from math import pi, cos, sin
from scripts.common import binround, sign, read_config, cfg_get_value

dir = dirname(abspath(__file__))
cfg = read_config(join(dir, "CORDICTestbench_cfg.json"))

angle_flen    = cfg_get_value(cfg, "CORDIC_ANGLE_FRACTIONAL_WIDTH")
coord_ilen    = cfg_get_value(cfg, "TB_COORD_INTEGER_WIDTH")
coord_flen    = cfg_get_value(cfg, "TB_COORD_FRACTIONAL_WIDTH")
test_data_len = cfg_get_value(cfg, "TB_TEST_DATA_LENGTH")
unit          = cfg_get_value(cfg, "TB_UNIT_CIRCLE")

K = 2.0 ** (coord_ilen-1) - 2.0 ** -coord_flen

for i in range(test_data_len):
    # Les coordonnées sont calculées de manière à couvrir des angles
    # régulièrement espacés. La plus grande des coordonnées est saturée
    # à l'amplitude maximum permise par leur format.
    th = -pi + 2.0 * i * pi / (test_data_len - 1)
    thr = binround(th, angle_flen)
    x = cos(thr)
    y = sin(thr)

    if not unit:
        if abs(x) > abs(y):
            y *= K / abs(x)
            x = K * sign(x)
        elif abs(x) < abs(y):
            x *= K / abs(y)
            y = K * sign(y)
        else:
            x = K * sign(x)
            y = K * sign(y)

    xr = binround(x, coord_flen)
    yr = binround(y, coord_flen)
    print("{} {} {}".format(xr, yr, thr))
