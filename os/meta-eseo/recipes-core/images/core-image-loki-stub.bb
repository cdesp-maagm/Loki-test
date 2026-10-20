SUMMARY = "Signal acquisition and processing for optical displacement sensors. Stub image."

LOKI_PYTHON3_INSTALL = "\
    "

LOKI_NET_INSTALL = "\
    packagegroup-base-zeroconf \
    iptables \
    dropbear \
    ntp ntp-utils ntpstat \
    rsync \
    openvpn \
    "

LOKI_GPS_INSTALL = "\
    gpsd \
    gps-utils \
    pps-tools \
    "

LOKI_UTIL_INSTALL = "\
    util-linux-agetty \
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
    peekpoke \
    "

LOKI_MSEED_INSTALL = "\
    "

LOKI_INSTALL = "\
    loki-stub-driver \
    loki-users \
    loki-init-ntpdate \
    loki-init-fix-filesystem \
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
