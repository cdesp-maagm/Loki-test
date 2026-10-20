
import sys
from common import dict_to_package, read_config

dict_to_package(read_config(sys.argv[1]))
