
from os.path import dirname, abspath, join
from CORDIC.src.CORDIC import generate_package
from scripts.common import read_config

dir = dirname(abspath(__file__))
cfg = read_config(join(dir, "CORDICAngleTestbench_cfg.json"))

generate_package("CORDICAngle_pkg", cfg)
