
from os.path import dirname, abspath, join
from FIRFilter.src.FIRFilter import generate_coefficients_package
from scripts.common import read_config

dir = dirname(abspath(__file__))
cfg = read_config(join(dir, "LokiDemodulatorTestbench_cfg.json"))

generate_coefficients_package("LokiDemodulatorTestbench_lowpass1_pkg", cfg, "TB_LOWPASS1")
