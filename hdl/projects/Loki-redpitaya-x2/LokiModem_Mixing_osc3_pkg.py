
from os.path import dirname, abspath, join
from Oscillator.src.Oscillator import generate_lookup_package
from scripts.common import read_config

dir = dirname(abspath(__file__))
cfg = read_config(join(dir, "LokiModem_cfg.json"))

generate_lookup_package("LokiModem_Mixing_osc3_pkg", cfg, "DEMOD_MIXING_OSC")
