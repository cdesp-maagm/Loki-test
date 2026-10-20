
import json

modem_channel_config_properties = [
    "demod_phase_x",
    "demod_phase_y",
    "demod_pga_gain"
]

# L'ordre des noms de propriétés est important :
# les fréquences d'échantillonnage doivent être réglées en premier
# car elles conditionnent la résolution des fréquence des oscillateurs.
modem_config_properties = [
    "mod_sampling_frequency",
    "mod_osc1_wave_frequency",
    "mod_osc1_gain",
    "mod_osc2_wave_frequency",
    "mod_osc2_gain",
    "mod_offset",
    "mod_dc_value",
    "mod_pga_gain",
    "demod_bypass",
    "demod_sampling_frequency",
    "demod_osc_wave_frequency",
    "demod_xy_sampling_frequency"
]

def read_json(filename):
    try:
        with open(filename) as f:
            return json.load(f)
    except FileNotFoundError:
        print("Warning - File not found: '{}'. Using default settings.".format(filename))
    except json.JSONDecodeError:
        print("Warning - Invalid JSON file: '{}'. Using default settings.".format(filename))
    return None

def load_modem_config(modem, filename):
    cfgdict = read_json(filename)
    if cfgdict is None:
        return

    # Traiter les propriétés dans l'ordre fixé par modem_config_properties.
    for name in modem_config_properties:
        if name in cfgdict:
            getattr(modem, "set_" + name)(cfgdict[name])

    if "channels_config" in cfgdict:
        for c, channel_cfg in enumerate(cfgdict["channels_config"]):
            for name in modem_channel_config_properties:
                if name in channel_cfg:
                    getattr(modem, "set_" + name)(c, channel_cfg[name])


def save_modem_config(modem, filename):
    cfgdict = {
        "channels_config": []
    }

    for name in modem_config_properties:
        cfgdict[name] = getattr(modem, "get_" + name)()

    for c in range(modem.get_demod_channels()):
        channel_cfg = {}
        for name in modem_channel_config_properties:
            channel_cfg[name] = getattr(modem, "get_" + name)(c)
        cfgdict["channels_config"].append(channel_cfg)

    with open(filename, "w") as f:
        json.dump(cfgdict, f, sort_keys=True, indent=4)


system_config_properties = {
    "simulate",
    "skip",
    "wavelength",
    "reflections",
    "cavity_index",
    "distance_unit",
    "estimator_name",
    "estimator_throttle",
    "estimator_initial_radius",
    "filter_bandwidth",
    "filter_attenuation",
    "filter_length",
    "filter_decimation",
    # Managed separately:
    # "time_constants",
    # "estimator_params",
    # "sensors_scaling_factors"
}

def load_system_config(syscfg, reccfg, env_sensors, filename):
    cfgdict = read_json(filename)
    if cfgdict is None:
        return

    for name in reccfg.keys():
        if name in cfgdict:
            reccfg[name] = cfgdict[name]

    for name in system_config_properties:
        if name in cfgdict:
            getattr(syscfg, "set_" + name)(cfgdict[name])

    if "estimator_params" in cfgdict:
        for i, v in enumerate(cfgdict["estimator_params"]):
            syscfg.set_estimator_param(i, v)

    if "time_constants" in cfgdict:
        for i, v in enumerate(cfgdict["time_constants"]):
            syscfg.set_time_constant(i, v)

    if env_sensors is not None:
        c = env_sensors.get_channels()
        if "sensors_scaling_factors" in cfgdict:
            for i, v in enumerate(cfgdict["sensors_scaling_factors"]):
                if i < c:
                    env_sensors.set_scaling_factor(i, v)


def save_system_config(syscfg, reccfg, env_sensors, filename):
    cfgdict = {
        **reccfg,
        "estimator_params": [],
        "time_constants": [],
        "sensors_scaling_factors": []
    }

    for name in system_config_properties:
        cfgdict[name] = getattr(syscfg, "get_" + name)()

    for i in range(syscfg.get_estimator_params_length()):
        cfgdict["estimator_params"].append(syscfg.get_estimator_param(i))

    for i in range(syscfg.get_time_constants_length()):
        cfgdict["time_constants"].append(syscfg.get_time_constant(i))

    if env_sensors is not None:
        for i in range(env_sensors.get_channels()):
            cfgdict["sensors_scaling_factors"].append(env_sensors.get_scaling_factor(i))

    with open(filename, "w") as f:
        json.dump(cfgdict, f, sort_keys=True, indent=4)
