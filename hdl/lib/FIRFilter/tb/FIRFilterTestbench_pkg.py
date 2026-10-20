
from os.path import dirname, abspath, join
from src.FIRFilter import generate_coefficients_package
from scripts.common import read_config

dir = dirname(abspath(__file__))
cfg = read_config(join(dir, "FIRFilterTestbench_cfg.json"))

generate_coefficients_package("FIRFilterTestbench_pkg", cfg, "TB")
