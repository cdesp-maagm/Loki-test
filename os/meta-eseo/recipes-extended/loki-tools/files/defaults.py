
record_config = {
    "force"                      : False,
    "autostart"                  : False,

    "record_enable"              : True,
    "stream_channels"            : -1,
    "duration"                   : 0.0,
    "duration_per_file"          : 0.0,
    "fifo_packet_length"         : 2048, # Nombre d'échantillons par voie dans un paquet géré par une FIFO
    "fifo_length"                : 32,
    "format"                     : "raw",
    "xy"                         : False,
    "path"                       : "/media/data/record",
    "filename"                   : "rec",

    "sensors_record_enable"      : False,
    "sensors_channels"           : -1,
    "sensors_duration"           : 0.0,
    "sensors_duration_per_file"  : 0.0,
    "sensors_fifo_packet_length" : 128, # Nombre d'échantillons par voie dans un paquet géré par une FIFO
    "sensors_fifo_length"        : 4,
    # TODO À placer dans un outil de configuration séparé comme loki-modem-config
    "sensors_sampling_frequency" : 1,

    "mseed_separate_channels"    : True,
    "mseed_station"              : "eseo",
    "mseed_network"              : "xx",
    "mseed_location"             : "fr",
    "mseed_steim2"               : True,
    "mseed_channel_names"        : ["a", "b", "c", "d", "e", "f", "g", "h"],
    "mseed_aux_channel_names"    : ["xa", "xb", "xc", "xd", "xe", "xf", "xg", "xh"],

    "keep_for_days"              : 21,

    "rsync_enable"               : False,
    "rsync_host"                 : "your-server.tld",
    "rsync_user"                 : "username",
    "rsync_dest"                 : "/path/to/recordings",

    "status_enable"              : False,
    "status_host"                : "your-server.tld",
    "status_user"                : "username",
    "status_dest"                : "/path/to/logs"
}

env_sensors_config = {
    "xadc0_scale": 0.02,
    "xadc1_scale": 0.002
}
