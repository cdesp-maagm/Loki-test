
#include "loki-device-sysfs.h"
#include "loki-device-dma.h"

static ssize_t dma_is_streaming_show(struct device *dev, struct device_attribute *attr, char *buf) {
    LokiDevice *self = dev_get_drvdata(dev);
    return scnprintf(buf, PAGE_SIZE, "%u\n", LokiDevice_dma_is_streaming(self));
}

static DEVICE_ATTR_RO(dma_is_streaming);

static ssize_t dma_received_packets_show(struct device *dev, struct device_attribute *attr, char *buf) {
    LokiDevice *self = dev_get_drvdata(dev);
    return scnprintf(buf, PAGE_SIZE, "%u\n", self->dma_received_packets);
}

static DEVICE_ATTR_RO(dma_received_packets);

static ssize_t dma_dropped_packets_show(struct device *dev, struct device_attribute *attr, char *buf) {
    LokiDevice *self = dev_get_drvdata(dev);
    return scnprintf(buf, PAGE_SIZE, "%u\n", self->dma_dropped_packets);
}

static DEVICE_ATTR_RO(dma_dropped_packets);

static ssize_t dma_start_time_sec_show(struct device *dev, struct device_attribute *attr, char *buf) {
    LokiDevice *self = dev_get_drvdata(dev);
    return scnprintf(buf, PAGE_SIZE, "%ld\n", self->dma_start_time.tv_sec);
}

static DEVICE_ATTR_RO(dma_start_time_sec);

static ssize_t dma_start_time_nsec_show(struct device *dev, struct device_attribute *attr, char *buf) {
    LokiDevice *self = dev_get_drvdata(dev);
    return scnprintf(buf, PAGE_SIZE, "%ld\n", self->dma_start_time.tv_nsec);
}

static DEVICE_ATTR_RO(dma_start_time_nsec);

int LokiDevice_sysfs_create(LokiDevice *self) {
    LokiDevice_sysfs_create_file(dma_is_streaming);
    LokiDevice_sysfs_create_file(dma_received_packets);
    LokiDevice_sysfs_create_file(dma_dropped_packets);
    LokiDevice_sysfs_create_file(dma_start_time_sec);
    LokiDevice_sysfs_create_file(dma_start_time_nsec);

    return 0;
}

EXPORT_SYMBOL(LokiDevice_sysfs_create);

void LokiDevice_sysfs_remove(LokiDevice *self) {
    LokiDevice_sysfs_remove_file(dma_is_streaming);
    LokiDevice_sysfs_remove_file(dma_received_packets);
    LokiDevice_sysfs_remove_file(dma_dropped_packets);
    LokiDevice_sysfs_remove_file(dma_start_time_sec);
    LokiDevice_sysfs_remove_file(dma_start_time_nsec);
}

EXPORT_SYMBOL(LokiDevice_sysfs_remove);
