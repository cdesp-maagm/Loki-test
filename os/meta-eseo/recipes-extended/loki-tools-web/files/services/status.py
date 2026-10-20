
import os
import os.path
import errno
import json
import subprocess
import socket
import uuid
import re
from datetime import datetime, timezone
from shutil import disk_usage
from eseo.loki.web import modem, env_sensors
import eseo.loki.web.startstop as startstop
from eseo.loki.web import record_config, modem
from eseo.loki.defaults import env_sensors_config

def ntpstat():
    return subprocess.run(["ntpstat"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0

def uptime():
    with open("/proc/uptime") as f:
        return float(f.readline().split()[0])

def hex_to_signed(str):
    v = int(str, 16)
    if v > 2**31:
        v -= 2**32
    return v

def clkmon_ppm():
    with open("/sys/class/loki/loki-modem/clkmon_seconds") as f:
        sec = int(f.readline(), 16)
    if sec == 0:
        return "No PPS";
    with open("/sys/class/loki/loki-modem/clkmon_delta") as f:
        delta = hex_to_signed(f.readline()) / sec
    return round(delta * 1e6 / modem.get_clk_frequency(), 2)

def env_sensors_values():
    if env_sensors is None:
        env_sensors_channels = 0
    else:
        env_sensors_channels = env_sensors.get_channels()
    return [ env_sensors.get_last_data(c) for c in range(env_sensors_channels) ]

def xadc_temp():
    try:
        with open("/sys/bus/iio/devices/iio:device1/in_temp0_offset") as f:
            temp_offset = int(f.readline())
        with open("/sys/bus/iio/devices/iio:device1/in_temp0_raw") as f:
            temp_raw = int(f.readline())
        with open("/sys/bus/iio/devices/iio:device1/in_temp0_scale") as f:
            temp_scale = float(f.readline())
        return (temp_raw + temp_offset) * temp_scale / 1000
    except:
        return "-"

def xadc_v0():
    try:
        with open("/sys/bus/iio/devices/iio:device1/in_voltage8_vaux0_raw") as f:
            v0_raw = int(f.readline())
        with open("/sys/bus/iio/devices/iio:device1/in_voltage8_vaux0_scale") as f:
            v0_scale = float(f.readline())
        return v0_raw * v0_scale * env_sensors_config["xadc0_scale"]
    except:
        return "-"

def xadc_v1():
    try:
        with open("/sys/bus/iio/devices/iio:device1/in_voltage9_vaux1_raw") as f:
            v1_raw = int(f.readline())
        with open("/sys/bus/iio/devices/iio:device1/in_voltage9_vaux1_scale") as f:
            v1_scale = float(f.readline())
        return v1_raw * v1_scale * env_sensors_config["xadc1_scale"]
    except:
        return "-"

def hwmon0():
    try:
        with open("/sys/class/hwmon/hwmon0/temp1_input") as f:
            return int(f.readline()) / 1000
    except:
        return "-"

def hwmon1():
    try:
        with open("/sys/class/hwmon/hwmon1/temp1_input") as f:
            return int(f.readline()) / 1000
    except:
        return "-"

def is_running(pid_filename):
    if os.path.isfile(pid_filename):
        with open(pid_filename, "r") as f:
            try:
                pid = int(f.read())
            except:
                pass
            else:
                try:
                    os.kill(pid, 0)
                except OSError as err:
                    return err.errno != errno.ESRCH
                else:
                    return True
    return False

def get_ip_addresses():
    lines = subprocess.check_output(["ip", "addr", "show"]).decode().splitlines()
    nic_re  = re.compile(r"[0-9]+:\s+([^:]+)")
    inet_re = re.compile(r"\s*inet\s+([0-9.]+)")
    nic = None
    res = {}
    for l in lines:
        m_nic  = nic_re.match(l)
        m_inet = inet_re.match(l)
        if m_nic is not None:
            nic = m_nic.group(1)
        elif nic is not None and nic != "lo" and m_inet is not None:
            res[nic] = m_inet.group(1)
            nic = None
    return res

def get_status():
    channels = modem.get_demod_channels()

    try:
        du = disk_usage(record_config["path"])
    except:
        du = "Error: could not get disk usage for location '{}'".format(record_config["path"])

    return json.dumps({
        "hostname":                 socket.gethostname(),
        "datetime":                 datetime.now(timezone.utc).isoformat(),
        "mac_address":              ":".join("{:012X}".format(uuid.getnode())[i:i+2] for i in range(0, 12, 2)),
        "ip_addresses":             get_ip_addresses(),
        "modem_is_streaming":       modem.is_streaming(),
        "modem_is_recording":       is_running("/var/run/loki-record.pid"),
        "modem_dropped_packets":    modem.get_dropped_packets(),
        "demod_adc_min_ratio":      [ modem.get_demod_adc_min_ratio(c) for c in range(channels) ],
        "demod_adc_max_ratio":      [ modem.get_demod_adc_max_ratio(c) for c in range(channels) ],
        "env_sensors_is_streaming": env_sensors is not None and env_sensors.is_streaming(),
        "env_sensors_is_recording": is_running("/var/run/loki-env-sensors-record.pid"),
        "ntp_status":               ntpstat(),
        "uptime":                   uptime(),
        "disk_usage":               du,
        "clkmon_ppm":               clkmon_ppm(),
        "env_sensors_values":       env_sensors_values(),
        "xadc_values":              [xadc_temp(), xadc_v0(), xadc_v1()],
        "hwmon_temp":               [hwmon0(), hwmon1()]
    }, indent=2)

def run(args, form, start_response):
    start_response("200 Ok", [('Content-Type', 'application/json;charset=utf-8')])
    return [get_status().encode()]

if __name__ == "__main__":
    print(get_status())
