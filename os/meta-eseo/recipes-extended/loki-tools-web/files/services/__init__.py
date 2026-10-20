
import os.path
from eseo.loki.native import *
from eseo.loki.util   import *
import eseo.loki.defaults

system_config_filename = "/media/data/config/loki-system-config.json"
modem_config_filename  = "/media/data/config/loki-modem-config.json"

class LokiSystemConfigWrapper(LokiSystemConfig):
    def set_estimator_params(self, params):
        l = self.get_estimator_params_length()
        for i, p in enumerate(params):
            if i < l:
                self.set_estimator_param(i, p)

    def get_estimator_params(self):
        return [self.get_estimator_param(i) for i in range(self.get_estimator_params_length())]

    def set_time_constants(self, params):
        l = self.get_time_constants_length()
        for i, p in enumerate(params):
            if i < l:
                self.set_time_constant(i, p)

    def get_time_constants(self):
        return [self.get_time_constant(i) for i in range(self.get_time_constants_length())]

modem = LokiModem()
if modem.this is None:
    modem = None

env_sensors = LokiEnvSensors()
if env_sensors.this is None:
    env_sensors = None

system_config = LokiSystemConfigWrapper()
record_config = dict(eseo.loki.defaults.record_config)

def has_configs():
    return os.path.isfile(modem_config_filename) and os.path.isfile(system_config_filename)

def load_configs():
    load_system_config(system_config, record_config, env_sensors, system_config_filename)

def save_configs():
    save_modem_config(modem, modem_config_filename)
    save_system_config(system_config, record_config, env_sensors, system_config_filename)

# Lecture de la configuration au démarrage, si elle existe.
load_configs()

