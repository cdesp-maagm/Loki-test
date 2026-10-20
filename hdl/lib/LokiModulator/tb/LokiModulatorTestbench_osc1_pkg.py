
from os.path import dirname, abspath, join
from Oscillator.src.Oscillator import generate_lookup_package
from scripts.common import read_config

dir = dirname(abspath(__file__))
cfg = read_config(join(dir, "LokiModulatorTestbench_cfg.json"))

generate_lookup_package("LokiModulatorTestbench_osc1_pkg", cfg, "TB_OSC1")
