#!/usr/bin/env python3

from os.path import join, dirname
from matplotlib.pyplot import show
from pandas import read_csv

filename = join(dirname(__file__), "..", "build", "tb", "OscillatorTestbench_out.csv")
data = read_csv(filename, header=None)

data.plot()
show()
