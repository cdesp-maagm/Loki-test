SUMMARY = "Signal acquisition and processing for optical displacement sensors. Development image."

LOKI_PYTHON3_INSTALL = "\
    python3-core \
    python3-runpy \
    python3-misc \
    python3-netserver \
    python3-json \
    python3-threading \
    python3-asyncio \
    "

LOKI_NET_INSTALL = "\
    packagegroup-base-zeroconf \
    packagegroup-base-bluetooth \
    packagegroup-base-wifi \
    iptables \
    dropbear \
    ntp ntp-utils ntpstat \
    lighttpd \
    lighttpd-module-proxy \
    lighttpd-module-wstunnel \
    rsync \
    openvpn \
    linux-firmware-extra \
    rtl8821cu \
    mtr \
    "

LOKI_GPS_INSTALL = "\
    gpsd \
    gps-utils \
    pps-tools \
    "

LOKI_UTIL_INSTALL = "\
    util-linux-agetty \
    watchdog \
    molly-guard \
    util-linux \
    coreutils \
    usbutils \
    cronie \
    logrotate \
    socat \
    htop \
    procps \
    nfs-utils-client \
    digitemp \
    nano \
    "

LOKI_DEBUG_INSTALL = "\
    gdb \
    valgrind \
    peekpoke \
    "

LOKI_MSEED_INSTALL = "\
    libmseed \
    ringserver \
    "

LOKI_INSTALL = "\
    loki-device-drivers \
    libloki \
    libloki-benchmarks \
    loki-users \
    loki-power \
    loki-init-macaddr \
    loki-init-ntpdate \
    loki-init-fix-filesystem \
    loki-init-modem-config \
    loki-init-indicators \
    loki-init-record \
    loki-init-env-sensors-record \
    loki-init-web-server \
    loki-init-ringserver \
    loki-tools \
    loki-tools-web \
    loki-sync \
    "

IMAGE_INSTALL = "\
    packagegroup-core-boot \
    ${LOKI_PYTHON3_INSTALL} \
    ${LOKI_NET_INSTALL} \
    ${LOKI_GPS_INSTALL} \
    ${LOKI_DEBUG_INSTALL} \
    ${LOKI_UTIL_INSTALL} \
    ${LOKI_MSEED_INSTALL} \
    ${LOKI_INSTALL} \
    ${CORE_IMAGE_EXTRA_INSTALL} \
    "

IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image

IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE_append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "" ,d)}"
