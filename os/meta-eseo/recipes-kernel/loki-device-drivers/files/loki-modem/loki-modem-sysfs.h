
#ifndef LOKI_MODEM_SYSFS_H_
#define LOKI_MODEM_SYSFS_H_

#include "../loki-device/loki-device.h"

int LokiModem_sysfs_create(LokiDevice *self);
void LokiModem_sysfs_remove(LokiDevice *self);

#endif
