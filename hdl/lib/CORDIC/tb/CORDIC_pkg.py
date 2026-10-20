
from os.path import dirname, abspath, join
from src.CORDIC import generate_package
from scripts.common import read_config

dir = dirname(abspath(__file__))
cfg = read_config(join(dir, "CORDICTestbench_cfg.json"))

generate_package("CORDIC_pkg", cfg)
