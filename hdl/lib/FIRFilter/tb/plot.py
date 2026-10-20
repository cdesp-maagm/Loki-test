#!/usr/bin/env python3

import sys
from os.path import dirname, abspath, join
from matplotlib.pyplot import plot, subplot, show,tight_layout
from pandas import read_csv
import numpy as np

dir = dirname(abspath(__file__))
sys.path.append(join(dir, "..", ".."))

from scripts.common import read_config, cfg_get_value

cfg = read_config(join(dir, "FIRFilterTestbench_cfg.json"))

decimation = cfg_get_value(cfg, "TB_DECIMATION")
channels   = cfg_get_value(cfg, "TB_CHANNELS")

csv_in  = join(dirname(__file__), "..", "build", "tb", "FIRFilterTestbench_in.csv")
csv_out = join(dirname(__file__), "..", "build", "tb", "FIRFilterTestbench_out.csv")

data_in  = read_csv(csv_in, names=["ch", "x", "y_ref"], sep="\s+")
data_out = read_csv(csv_out, names=["ch", "y"], sep="\s+")

for c in range(channels):
    di = data_in.query("ch=={}".format(c))
    do = data_out.query("ch=={}".format(c))
    x    = di["x"]
    yref = di["y_ref"]
    y    = do["y"]
    ti   = np.linspace(0, len(x) - 1, num=len(x))
    to   = np.linspace(decimation-1, len(x) - 1, num=len(y))
    subplot(channels, 1, c + 1)
    plot(ti, x)
    plot(ti, yref)
    plot(to, y)

tight_layout()
show()
