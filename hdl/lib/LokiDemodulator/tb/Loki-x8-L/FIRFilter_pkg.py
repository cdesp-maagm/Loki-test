
from os.path import dirname, abspath, join
from FIRFilter.src.FIRFilter import generate_package
from scripts.common import read_config

dir = dirname(abspath(__file__))
cfg = read_config(join(dir, "LokiDemodulatorTestbench_cfg.json"))

generate_package("FIRFilter_pkg", cfg)
