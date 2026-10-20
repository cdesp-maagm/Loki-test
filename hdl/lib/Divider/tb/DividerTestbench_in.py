
from os.path import dirname, abspath, join
from math import ceil, sqrt, floor
from scripts.common import binfloor, sign, read_config, cfg_get_value

dir = dirname(abspath(__file__))
cfg = read_config(join(dir, "DividerTestbench_cfg.json"))

dividend_ilen = cfg_get_value(cfg, "TB_DIVIDEND_INTEGER_WIDTH")
dividend_flen = cfg_get_value(cfg, "TB_DIVIDEND_FRACTIONAL_WIDTH")
divisor_ilen  = cfg_get_value(cfg, "TB_DIVISOR_INTEGER_WIDTH")
divisor_flen  = cfg_get_value(cfg, "TB_DIVISOR_FRACTIONAL_WIDTH")
test_data_len = cfg_get_value(cfg, "TB_TEST_DATA_LENGTH")

quotient_flen = dividend_flen + divisor_ilen - 1

dividend_max = 2.0 ** (dividend_ilen-1) - 1
dividend_min = 2.0 ** -dividend_flen
divisor_max  = 2.0 ** (divisor_ilen-1) - 1
divisor_min  = 2.0 ** -divisor_flen

L = ceil(sqrt(test_data_len) / 2)

for j in range(L):
    n = (dividend_min * (L - 1 - j) + dividend_max * j) / (L - 1)
    nr = binfloor(n, dividend_flen)
    for k in range(L):
        d = (divisor_min * (L - 1 - j) + divisor_max * j) / (L - 1)
        dr = binfloor(d, divisor_flen)
        qr = binfloor(nr / dr, quotient_flen)
        rr = nr - qr * dr
        for sn in [-1, 1]:
            for sd in [-1, 1]:
                print("{} {} {} {}".format(sn * nr, sd * dr, sn * sd * qr, sn * rr))
