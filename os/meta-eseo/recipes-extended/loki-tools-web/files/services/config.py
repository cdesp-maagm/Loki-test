
import html
import re
import os
import subprocess
from datetime import datetime
from collections import OrderedDict
from collections.abc import Iterable
from threading import Lock
from time import time
from math import ceil

from eseo.loki.web import system_config, record_config, modem, env_sensors, has_configs, load_configs, save_configs

load_configs()

log_level_min = "info"

log_levels = ["debug", "info", "success", "warning", "error", "none"]

def str_list(s):
    return re.split("\s*[,;\s]\s*", s)

def float_list(s):
    def to_float(s):
        try:
            return float(s)
        except ValueError:
            return 0
    return map(to_float, str_list(s))

def mask(s):
    def to_shifted_int(s):
        try:
            return 1 << int(s)
        except ValueError:
            return 0
    return sum(map(to_shifted_int, str_list(s)))

class LokiProperty:
    def __init__(self, target, name, label, unit, type, *args, prefix="", signed=False, writable=True, max_len=0):
        self.target   = target
        self.name     = name
        self.label    = label
        self.unit     = unit
        self.type     = type
        self.signed   = signed
        self.writable = writable
        self.max_len  = max_len
        self.args     = args
        self.key      = prefix + name
        if len(args) > 0:
            self.key += "".join(["$" + str(a) for a in args])

        if isinstance(target, Iterable):
            self.getter     = lambda: target[name]
            self.setter     = lambda x: target.update([(name, x)])
            self.getter_res = None
            self.getter_max = None
        else:
            self.getter     = getattr(target, "get_" + name, getattr(target, name, None))
            self.setter     = getattr(target, "set_" + name,          None)
            self.getter_res = getattr(target, "get_" + name + "_res", None)
            self.getter_max = getattr(target, "get_" + name + "_max", None)

    def get_value(self):
        try:
            return self.getter(*self.args)
        except:
            if self.type is bool:
                return False
            elif self.type is int or self.type is float:
                return 0
            elif isinstance(self.type, dict):
                return self.type.keys()[0]
            else:
                return ""


    def get_res(self):
        return self.getter_res(*self.args)

    def get_max(self):
        return self.getter_max(*self.args)

    def set_value(self, value):
        try:
            type = self.type
            if isinstance(type, dict):
                type = str
            self.setter(*self.args, type(value))
        except:
            pass

    def to_checkbox(self):
        attrs = 'type="checkbox"'
        if self.get_value():
            attrs += " checked"
        if not self.writable:
            attrs += ' onclick="return false;"'

        return '''
            <div class="input-field">
                <input name="{name}" {attrs}>
                <label for="{name}">{label}</label>
            </div>
        '''.format(name=self.key, label=html.escape(self.label), attrs=attrs)

    def to_number_input(self):
        if self.type is float:
            value_str = "{:g}".format(self.get_value())
        else:
            value_str = str(self.get_value())

        meta = []
        if self.unit is not None:
            meta.append(self.unit)
        if self.getter_res is not None:
            meta.append("resolution: {:.3g}".format(self.get_res()))
        if self.getter_max is not None:
            meta.append("max: {:.3g}".format(self.get_max()))

        label = self.label
        if len(meta) > 0:
            label += " (" + ", ".join(meta) + ")"

        attrs = 'type="number" value="{}"'.format(html.escape(value_str))

        if self.getter_max is not None:
            step = self.get_max() / 10
            if self.getter_res is not None and self.get_res() > step:
                step = self.get_res()
            if self.type is int:
                step = ceil(step)
            attrs += ' step="{}"'.format(step)
        elif self.type is int:
            attrs += ' step="1"'
        else:
            attrs += ' step="any"'

        if not self.signed:
            attrs += 'min="0"'

        if self.getter_max is not None:
            attrs += ' max="{}"'.format(self.get_max())
            if self.signed:
                attrs += ' min="{}"'.format(-self.get_max())

        if not self.writable:
            attrs += " readonly"

        return '''
            <div class="input-field">
                <label for="{name}">{label}</label>
                <input name="{name}" {attrs}>
            </div>
        '''.format(name=self.key, label=html.escape(label), attrs=attrs)

    def to_text_input(self):
        if self.type is float_list:
            value_str = ", ".join("{:g}".format(v) for v in self.get_value())
        elif self.type is str_list:
            value_str = ", ".join(self.get_value())
        elif self.type is mask:
            value_str = ", ".join(str(n) for n in range(self.max_len) if self.get_value() & (1 << n))
        else:
            value_str = str(self.get_value())

        attrs = 'type="text" value="{}"'.format(html.escape(value_str))

        if not self.writable:
            attrs += " readonly"

        label = self.label
        if self.unit is not None:
            label += " (" + self.unit + ")"

        return '''
            <div class="input-field">
                <label for="{name}">{label}</label>
                <input name="{name}" {attrs}>
            </div>
        '''.format(name=self.key, label=html.escape(label), attrs=attrs)

    def to_dropdown(self):
        options = ""
        for key, label in self.type.items():
            attrs = 'value={}'.format(key)
            if self.get_value() == key:
                attrs += " selected"
            options += '<option {}>{}</option>'.format(attrs, html.escape(label))
        return '''
            <div class="input-field">
                <label for="{name}">{label}</label>
                <select name="{name}">
                    {options}
                </select>
            </div>
        '''.format(name=self.key, label=html.escape(self.label), options=options)

    def to_html(self):
        if self.type is bool:
            return self.to_checkbox()
        elif self.type is int or self.type is float:
            return self.to_number_input()
        elif isinstance(self.type, dict):
            return self.to_dropdown()
        else:
            return self.to_text_input()


class LokiHeading:
    def __init__(self, key, text, foldable=False):
        self.key      = key
        self.text     = text
        self.writable = False
        self.foldable = foldable

    def to_html(self):
        if self.foldable:
            attrs = 'class="fold-open"'
        else:
            attrs = ''
        return '<h3 {}>{}</h3>'.format(attrs, self.text)


def properties_to_dict(props):
    return dict([(p.key, p) for p in props])

# ------------------------------------------------------------------------------
# Affichage des capteurs.
# ------------------------------------------------------------------------------

if env_sensors is None:
    env_sensors_channels = 0
else:
    env_sensors_channels = env_sensors.get_channels()

env_sensors_props = [
    LokiProperty(env_sensors, "is_streaming", "Streaming", None, bool, prefix="env_sensors_", writable=False),
]

env_sensors_channels_props = [p for c in range(env_sensors_channels) for p in [
    LokiHeading("env_sensors_channel_heading_${}".format(c), "Environment sensor {}".format(c), True),
    LokiProperty(env_sensors, "last_data",      "Value", None, float, c, signed=True, writable=False),
    LokiProperty(env_sensors, "scaling_factor", "Scale", None, float, c)
]]

all_env_sensors_props = env_sensors_props + env_sensors_channels_props

# ------------------------------------------------------------------------------
# Définition du formulaire de configuration du modem.
# ------------------------------------------------------------------------------

modem_props = [
    LokiProperty(modem, "clk_frequency",   "Clock frequency", "Hz",      int,                   writable=False),
    LokiProperty(modem, "is_streaming",    "Streaming",       None,      bool, prefix="modem_", writable=False),
    LokiProperty(modem, "dropped_packets", "Dropped data",    "packets", int,                   writable=False),
    LokiProperty(modem, "test_mode",       "Test mode",       None,      bool),
]

mod_props = [
    LokiProperty(modem, "mod_sampling_frequency",  "Sample rate",            "Hz", float),
    LokiProperty(modem, "mod_osc1_wave_frequency", "Oscillator 1 frequency", "Hz", float),
    LokiProperty(modem, "mod_osc1_gain",           "Oscillator 1 amplitude", "mA", float),
    LokiProperty(modem, "mod_osc2_wave_frequency", "Oscillator 2 frequency", "Hz", float),
    LokiProperty(modem, "mod_osc2_gain",           "Oscillator 2 amplitude", "mA", float),
    LokiProperty(modem, "mod_offset",              "Offset",                 "mA", float, signed=True),
    LokiProperty(modem, "mod_dc_value",            "DC current",             "mA", float),
    LokiProperty(modem, "mod_pga_gain",            "PGA gain",               None, int),
]

demod_props = [
    LokiProperty(modem, "demod_bypass",                "Bypass",               None,           bool),
    LokiProperty(modem, "demod_mixerless",             "Mixerless",            None,           bool,  writable=False),
    LokiProperty(modem, "demod_channels",              "Channels",             None,           int,   writable=False),
    LokiProperty(modem, "demod_osc_wave_frequency",    "Oscillator frequency", "Hz",           float, writable=not modem.get_demod_mixerless()),
    LokiProperty(modem, "demod_sampling_frequency",    "Input Sample rate",    "Hz",           float),
    LokiProperty(modem, "demod_xy_sampling_frequency", "Output Sample rate",   "Hz",           float),
    LokiProperty(modem, "demod_bandwidth",             "Bandwidth",            "Hz",           float, writable=False),
]

demod_channels = modem.get_demod_channels()

demod_channel_cfg_props = [p for c in range(demod_channels) for p in [
    LokiHeading("demod_channel_heading_${}".format(c), "Channel {}".format(c), True),
    LokiProperty(modem, "demod_adc_min_ratio", "ADC min level",          None,  float, c, signed=True, writable=False),
    LokiProperty(modem, "demod_adc_max_ratio", "ADC max level",          None,  float, c, signed=True, writable=False),
    LokiProperty(modem, "demod_pga_gain",      "PGA gain",               None,  float, c),
    LokiProperty(modem, "demod_phase_x",       "Oscillator phase for X", "deg", float, c),
    LokiProperty(modem, "demod_phase_y",       "Oscillator phase for Y", "deg", float, c),
]]

all_modem_props = modem_props + mod_props + demod_props + demod_channel_cfg_props

modem_restart_props = [
    "mod_sampling_frequency",
    "mod_osc1_wave_frequency",
    "mod_osc2_wave_frequency",
    "demod_osc_wave_frequency",
    "demod_sampling_frequency",
    "demod_xy_sampling_frequency",
    "demod_phase_x",
    "demod_phase_y"
]

# ------------------------------------------------------------------------------
# Définition du formulaire de configuration du système et de l'enregistrement.
# ------------------------------------------------------------------------------

ellipse_props = [
    LokiProperty(system_config, "simulate",                 "Simulate sensors in software",           None,     bool),
    LokiProperty(system_config, "wavelength",               "Wavelength [λ0]",                        "nm",     float),
    LokiProperty(system_config, "reflections",              "Reflections",                            None,     int),
    LokiProperty(system_config, "cavity_index",             "Refractive index of the cavity",         None,     float),
    LokiProperty(system_config, "distance_unit",            "Distance unit",                          None,     OrderedDict([("p", "pm"), ("n", "nm"), ("u", "μm"), ("m", "mm")])),
    LokiProperty(system_config, "estimator_name",           "Estimator",                              None,     {"kalman": "Kalman [Rv, Rw, P0]", "rls": "Recursive Least Squares [λ, P0]", "nlms": "Normalized Least Mean Squares [μ, α]"}),
    LokiProperty(system_config, "estimator_params",         "Estimator parameters",                   "comma-separated list", float_list),
    LokiProperty(system_config, "estimator_initial_radius", "Ellipse initial radius",                 None,     float),
    LokiProperty(system_config, "estimator_throttle",       "Update ellipse every N samples",         None,     int),
    LokiProperty(system_config, "time_constants",           "Time constants [axes, center, angle]",   "sec, comma-separated list", float_list),
    LokiProperty(system_config, "skip",                     "Initial skip",                           "sec" ,   float),
]

filter_props = [
    LokiProperty(system_config, "filter_bandwidth",   "Bandwidth",   "Hz",     float),
    LokiProperty(system_config, "filter_attenuation", "Attenuation", "dB",     float),
    LokiProperty(system_config, "filter_length",      "Length",      None,     int),
    LokiProperty(system_config, "filter_decimation",  "Decimation",  None,     int),
]

rec_props = [
    LokiProperty(record_config, "autostart",         "Start recording automatically",        None,                       bool),
    LokiProperty(record_config, "force",             "Start recording immediately (without time synchronization)", None, bool),
    LokiProperty(record_config, "format",            "Displacement file format",             None,                       {"mseed": "MiniSEED", "raw": "Raw"}),
    LokiProperty(record_config, "filename",          "Base file name",                       None,                       str),
]

disp_rec_props = [
    LokiProperty(record_config, "record_enable",     "Enable",                           None,                        bool),
    LokiProperty(record_config, "xy",                "Also record raw demodulated data", None,                        bool),
    LokiProperty(record_config, "stream_channels",   "Channel numbers",                  "comma-separated list",      mask, max_len=demod_channels),
    LokiProperty(record_config, "duration",          "Duration",                         "sec, negative or zero means forever", float),
    LokiProperty(record_config, "duration_per_file", "Duration per file",                "sec, zero for single-file recording", float),
]

env_sensors_rec_props = [
    LokiProperty(record_config, "sensors_record_enable",      "Enable",             None,                                  bool, writable=env_sensors is not None),
    LokiProperty(record_config, "sensors_channels",           "Channel numbers",    "comma-separated list",                mask, max_len=env_sensors_channels),
    LokiProperty(record_config, "sensors_duration",           "Duration",           "sec, negative or zero means forever", float),
    LokiProperty(record_config, "sensors_duration_per_file",  "Duration per file",  "sec, zero for single-file recording", float),
    LokiProperty(record_config, "sensors_sampling_frequency", "Sample rate",        "Hz",                                  float),
]

mseed_props = [
    LokiProperty(record_config, "mseed_channel_names",     "Channel names",              "comma-separated list", str_list),
    LokiProperty(record_config, "mseed_aux_channel_names", "Aux channel names",          "comma-separated list", str_list),
    LokiProperty(record_config, "mseed_separate_channels", "Store one channel per file", None, bool),
    LokiProperty(record_config, "mseed_steim2",            "Steim2 encoding",            None, bool),
    LokiProperty(record_config, "mseed_network",           "Network",                    None, str),
    LokiProperty(record_config, "mseed_station",           "Station",                    None, str),
    LokiProperty(record_config, "mseed_location",          "Location",                   None, str),
]

# ------------------------------------------------------------------------------
# Définition du formulaire de configuration du stockage et de la synchronisation.
# ------------------------------------------------------------------------------

storage_props = [
    LokiProperty(record_config, "path",          "Path of the recordings", None,   str),
    LokiProperty(record_config, "keep_for_days", "Delete files after",     "days", int),
]

rsync_props = [
    LokiProperty(record_config, "rsync_enable", "Enable",           None, bool),
    LokiProperty(record_config, "rsync_host",   "Host",             None, str),
    LokiProperty(record_config, "rsync_user",   "User name",        None, str),
    LokiProperty(record_config, "rsync_dest",   "Destination path", None, str),
]

status_props = [
    LokiProperty(record_config, "status_enable", "Enable",           None, bool),
    LokiProperty(record_config, "status_host",   "Host",             None, str),
    LokiProperty(record_config, "status_user",   "User name",        None, str),
    LokiProperty(record_config, "status_dest",   "Destination path", None, str),
]

# ------------------------------------------------------------------------------
# Template de la page web à afficher.
# ------------------------------------------------------------------------------

tpl_dir = os.path.dirname(os.path.abspath(__file__))
tpl_filename = os.path.join(tpl_dir, "config.tpl.html")

with open(tpl_filename) as tpl_file:
    tpl = tpl_file.read()

def append_message(messages, msg, level="info"):
    if log_levels.index(level) >= log_levels.index(log_level_min):
        messages.append('<div class="message {}">{}</div>'.format(level, msg))

def properties_to_html(props):
    return "".join([p.to_html() for p in props])

# ------------------------------------------------------------------------------
# Fonction appelée par le serveur web.
# ------------------------------------------------------------------------------

all_system_props = properties_to_dict(
    all_env_sensors_props + ellipse_props + filter_props +
    rec_props + disp_rec_props + env_sensors_rec_props +
    mseed_props + storage_props
)

all_other_props = properties_to_dict(all_modem_props + status_props + rsync_props)

all_props = {
    **all_system_props,
    **all_other_props
}

lock = Lock()

# Le timestamp de la dernière modification de la configuration.
last_update = -1

def run(args, form, start_response):
    global last_update

    lock.acquire()

    modified             = False
    modem_needs_restart  = False
    system_needs_restart = False
    timestamp            = time()
    conflict             = False

    # Application de la configuration passée par la requête HTTP.
    try:
        if len(form.keys()) > 0:
            # Si la configuration a été modifiée après l'affichage du formulaire
            # par ce client, ne pas effectuer la mise à jour.
            if float(form["timestamp"][0]) < last_update:
                conflict = True
            else:
                for key in form["dirty"][0].split():
                    if key in all_props and all_props[key].writable:
                        value = None

                        # Un champ de type "checkbox" n'est inclus dans les données POST
                        # que si la case est cochée.
                        if all_props[key].type is bool:
                            value = key in form
                        elif key in form and len(form[key]) > 0:
                            value = form[key][0]

                        if value is not None:
                            all_props[key].set_value(value)
                            modified = True
                            if key.split("$")[0] in modem_restart_props:
                                modem_needs_restart = True
                            if key in all_system_props:
                                system_needs_restart = True
                    elif key == "datetime":
                        set_datetime(form[key][0])
        if modified or not has_configs():
            last_update = timestamp
            save_configs()

        if modem_needs_restart:
            modem.restart()

    except Exception as e:
        print(str(e))

    lock.release()

    if len(form.keys()) > 0:
        # Si le formulaire a été soumis, rediriger vers la même page en effaçant les données POST.
        # La liste des sections repliables ouvertes (foldables) est obtenue dans les données POST et renvoyée dans l'URL.
        start_response("303 See Other", [("Location", "config?modified={}&conflict={}&modem-restarted={}&system-needs-restart={}&foldables={}".format(modified, conflict, modem_needs_restart, system_needs_restart, form["foldables"][0]))])
        return []
    else:
        # Préparation des messages à afficher après une requête POST.
        def check_arg(key):
            return key in args and args[key][-1] == "True"

        messages = []
        if check_arg("modified"):
            append_message(messages, "New configuration was applied.", "success")
        if check_arg("conflict"):
            append_message(messages, "Concurrent modification detected. Configuration was not applied.", "warning")
        if check_arg("modem-restarted"):
            append_message(messages, "Modem restarted.", "success")
        if check_arg("system-needs-restart"):
            append_message(messages, "Please stop and restart to apply the changes from the Measurement, Recording, and Storage categories.", "warning")

        # Affichage du formulaire de configuration.
        # La liste des sections repliables ouvertes (foldables) est obtenue dans l'URL et renvoyée dans un champ du formulaire.
        start_response("200 Ok", [('Content-Type', 'text/html;charset=utf-8')])
        return [tpl.format(
            messages="".join(messages),
            env_sensors_table=properties_to_html(all_env_sensors_props),
            modem_table=properties_to_html(modem_props),
            mod_table=properties_to_html(mod_props),
            demod_table=properties_to_html(demod_props),
            demod_channel_cfg_table=properties_to_html(demod_channel_cfg_props),
            ellipse_table=properties_to_html(ellipse_props),
            filter_table=properties_to_html(filter_props),
            rec_table=properties_to_html(rec_props),
            disp_rec_table=properties_to_html(disp_rec_props),
            env_sensors_rec_table=properties_to_html(env_sensors_rec_props),
            mseed_table=properties_to_html(mseed_props),
            storage_table=properties_to_html(storage_props),
            status_table=properties_to_html(status_props),
            rsync_table=properties_to_html(rsync_props),
            demod_mixerless= "true" if modem.get_demod_mixerless() else "false",
            demod_decimation=modem.get_demod_decimation(),
            timestamp=timestamp,
            foldables=args["foldables"][0] if "foldables" in args else []
        ).encode()]

def set_datetime(s):
    now = datetime.today()
    # Split s into an array of numbers.
    date_elts = list(map(int, re.split(r"[^0-9]+", s)))
    # Pad the array with zeros if it is two short.
    if len(date_elts) < 6:
        date_elts.extend([0] * (6 - len(date_elts)))
    # Extract the components of the date and time.
    year, month, day, hour, minute, second, *rest = date_elts
    # Fix invalid date elements.
    if year not in range(1970, 10000):
        year = now.year
    if month not in range(1, 13):
        month = now.month
    if day not in range(1, 32):
        day = now.day
    # Fix the year, month, and day
    subprocess.call(["sudo", "date", "-u", "-s", "{:04}/{:02}/{:02} {:02}:{:02}:{:02}".format(year, month, day, hour, minute, second)])
