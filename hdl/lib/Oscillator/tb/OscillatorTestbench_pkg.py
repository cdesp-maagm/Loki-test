
from os.path import dirname, abspath, join
from src.Oscillator import generate_lookup_package
from scripts.common import read_config

dir = dirname(abspath(__file__))
cfg = read_config(join(dir, "OscillatorTestbench_cfg.json"))

generate_lookup_package("OscillatorTestbench_pkg", cfg, "TB")
