
#ifndef LOKI_ENV_SENSORS_SYSFS_H_
#define LOKI_ENV_SENSORS_SYSFS_H_

#include "../loki-device/loki-device.h"

int LokiEnvSensors_sysfs_create(LokiDevice *self);
void LokiEnvSensors_sysfs_remove(LokiDevice *self);

#endif
