
#include <linux/device.h>

#include "../loki-device/loki-device-sysfs.h"
#include "loki-env-sensors-regs.h"

LokiDevice_sysfs_reg_show(clk_frequency, LOKI_ENV_SENSORS_REG_CLK_FREQUENCY)
static DEVICE_ATTR_RO(clk_frequency);

LokiDevice_sysfs_reg_show(channels, LOKI_ENV_SENSORS_REG_CHANNELS)
static DEVICE_ATTR_RO(channels);

LokiDevice_sysfs_reg_show(channel_output_width, LOKI_ENV_SENSORS_REG_CHANNEL_OUTPUT_WIDTH)
static DEVICE_ATTR_RO(channel_output_width);

LokiDevice_sysfs_reg_show(data_width, LOKI_ENV_SENSORS_REG_DATA_WIDTH)
static DEVICE_ATTR_RO(data_width);

LokiDevice_sysfs_reg_show(cycles_per_sample_max, LOKI_ENV_SENSORS_REG_CYCLES_PER_SAMPLE_MAX)
static DEVICE_ATTR_RO(cycles_per_sample_max);

LokiDevice_sysfs_reg_show(packet_length_max, LOKI_ENV_SENSORS_REG_PACKET_LENGTH_MAX)
static DEVICE_ATTR_RO(packet_length_max);

LokiDevice_sysfs_reg_show(cycles_per_sample, LOKI_ENV_SENSORS_REG_CYCLES_PER_SAMPLE)
LokiDevice_sysfs_reg_store(cycles_per_sample, LOKI_ENV_SENSORS_REG_CYCLES_PER_SAMPLE)
static DEVICE_ATTR_RW(cycles_per_sample);

LokiDevice_sysfs_reg_show(packet_length, LOKI_ENV_SENSORS_REG_PACKET_LENGTH)
LokiDevice_sysfs_reg_store(packet_length, LOKI_ENV_SENSORS_REG_PACKET_LENGTH)
static DEVICE_ATTR_RW(packet_length);

LokiDevice_sysfs_reg_store_field(restart, LOKI_ENV_SENSORS_REG_CONTROL, LOKI_ENV_SENSORS_REG_CONTROL_RESTART_SHIFT, LOKI_ENV_SENSORS_REG_CONTROL_RESTART_MASK)
static DEVICE_ATTR_WO(restart);

LokiDevice_sysfs_reg_show(status, LOKI_ENV_SENSORS_REG_STATUS)
static DEVICE_ATTR_RO(status);

static ssize_t last_data_show(struct device *dev, struct device_attribute *attr, char *buf) {
    LokiDevice *self = dev_get_drvdata(dev);
    int channels = LokiDevice_get_reg(self, LOKI_ENV_SENSORS_REG_CHANNELS);
    int count = 0;
    for (int i = 0; i < channels; i ++) {
        count += scnprintf(buf + count, PAGE_SIZE - count, "0x%08x ", LokiDevice_get_reg(self, LOKI_ENV_SENSORS_REG_LAST_DATA + i));
    }
    // Remplacer le dernier espace par un saut de ligne.
    buf[count - 1] = '\n';
    return count;
}

static DEVICE_ATTR_RO(last_data);

static ssize_t bmp390_nvm_data_show(struct device *dev, struct device_attribute *attr, char *buf) {
    LokiDevice *self = dev_get_drvdata(dev);
    int count = 0;
    for (int i = LOKI_ENV_SENSORS_REG_BMP390_NVM0; i <= LOKI_ENV_SENSORS_REG_BMP390_NVM5; i ++) {
        count += scnprintf(buf + count, PAGE_SIZE - count, "0x%08x ", LokiDevice_get_reg(self, i));
    }
    // Remplacer le dernier espace par un saut de ligne.
    buf[count - 1] = '\n';
    return count;
}

static DEVICE_ATTR_RO(bmp390_nvm_data);

int LokiEnvSensors_sysfs_create(LokiDevice *self) {
    LokiDevice_sysfs_create(self);

    LokiDevice_sysfs_create_file(clk_frequency);
    LokiDevice_sysfs_create_file(channels);
    LokiDevice_sysfs_create_file(channel_output_width);
    LokiDevice_sysfs_create_file(data_width);
    LokiDevice_sysfs_create_file(cycles_per_sample_max);
    LokiDevice_sysfs_create_file(packet_length_max);
    LokiDevice_sysfs_create_file(cycles_per_sample);
    LokiDevice_sysfs_create_file(packet_length);
    LokiDevice_sysfs_create_file(restart);
    LokiDevice_sysfs_create_file(status);
    LokiDevice_sysfs_create_file(last_data);
    LokiDevice_sysfs_create_file(bmp390_nvm_data);

    return 0;
}

void LokiEnvSensors_sysfs_remove(LokiDevice *self) {
    LokiDevice_sysfs_remove(self);

    LokiDevice_sysfs_remove_file(clk_frequency);
    LokiDevice_sysfs_remove_file(channels);
    LokiDevice_sysfs_remove_file(channel_output_width);
    LokiDevice_sysfs_remove_file(data_width);
    LokiDevice_sysfs_remove_file(cycles_per_sample_max);
    LokiDevice_sysfs_remove_file(packet_length_max);
    LokiDevice_sysfs_remove_file(cycles_per_sample);
    LokiDevice_sysfs_remove_file(packet_length);
    LokiDevice_sysfs_remove_file(restart);
    LokiDevice_sysfs_remove_file(status);
    LokiDevice_sysfs_remove_file(last_data);
    LokiDevice_sysfs_remove_file(bmp390_nvm_data);
}
