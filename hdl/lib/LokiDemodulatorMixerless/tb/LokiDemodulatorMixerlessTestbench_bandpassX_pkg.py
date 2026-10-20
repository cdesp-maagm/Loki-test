
from os.path import dirname, abspath, join
from FIRFilter.src.FIRFilter import generate_coefficients_package
from scripts.common import read_config

dir = dirname(abspath(__file__))
cfg = read_config(join(dir, "LokiDemodulatorMixerlessTestbench_cfg.json"))

generate_coefficients_package("LokiDemodulatorMixerlessTestbench_bandpassX_pkg", cfg, "TB_BANDPASS_X")
