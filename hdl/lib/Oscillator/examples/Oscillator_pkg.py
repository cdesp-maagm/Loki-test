
from os.path import dirname, abspath, join
from src.Oscillator import generate_package
from scripts.common import read_config

dir = dirname(abspath(__file__))
cfg = read_config(join(dir, "OscillatorExample_cfg.json"))

generate_package("Oscillator_pkg", cfg)
