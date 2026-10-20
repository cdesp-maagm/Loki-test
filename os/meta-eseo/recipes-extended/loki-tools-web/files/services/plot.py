
import os
from eseo.loki.web import record_config, modem, load_configs

load_configs()

tpl_dir = os.path.dirname(os.path.abspath(__file__))
tpl_filename = os.path.join(tpl_dir, "plot.tpl.html")

with open(tpl_filename) as tpl_file:
    tpl = tpl_file.read()

def make_checkbox(channel):
    return '''
        <input type="checkbox" name="enable-{c}">
        <label for="enable-{c}">Channel {c} <span id="legend-{c}" class="legend">&nbsp;</span></label>
    '''.format(c=channel)

def make_canvas(prefix, channel):
    return '''
        <canvas id="{p}-canvas-{c}" height="500px"></canvas>
        <canvas id="{p}-axis-canvas-{c}" height="500px"></canvas>
    '''.format(c=channel, p=prefix)

def run(args, form, start_response):
    demod_channels  = modem.get_demod_channels()
    record_channels = []
    for c in range(demod_channels):
        if record_config["stream_channels"] & (1 << c):
            record_channels.append(c)

    channel_enables = "".join([make_checkbox(c) for c in record_channels])

    disp_cvs = "".join([make_canvas("disp", c) for c in record_channels])

    start_response("200 Ok", [('Content-Type', 'text/html;charset=utf-8')])
    return [tpl.format(
        demod_channels=demod_channels,
        record_channels=list(record_channels),
        channel_enables=channel_enables,
        disp_cvs=disp_cvs
    ).encode()]
