#!/usr/bin/env python3

import sys
from os.path import dirname, abspath, join
from pandas import read_csv
from matplotlib.pyplot import figure, plot, subplot, show,tight_layout

dir = dirname(abspath(__file__))
sys.path.append(join(dir, "..", ".."))

from scripts.common import read_config, cfg_get_value

cfg = read_config(join(dir, "LokiModulatorTestbench_cfg.json"))

datafile = join(dir, "..", "build", "tb", "LokiModulatorTestbench_out.csv")

data = read_csv(datafile, names=["phase", "P"])

figure()
data["phase"].plot()

figure()
data["P"].plot()

show()
