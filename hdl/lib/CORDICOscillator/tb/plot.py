#!/usr/bin/env python3

from os.path import join, dirname
from matplotlib.pyplot import show
from pandas import read_csv

filename = join(dirname(__file__), "..", "build", "tb", "CORDICOscillatorTestbench_out.csv")
data = read_csv(filename, names=["osc:cos", "osc:sin", "th:cos", "th:sin"])

data.plot(legend=True)
show()
