
#ifndef LOKI_DEVICE_SYSFS_H_
#define LOKI_DEVICE_SYSFS_H_

#include "loki-device.h"
#include "loki-device-regs.h"

#define LokiDevice_sysfs_reg_show(name, addr)                                                  \
    static ssize_t name##_show(struct device *dev, struct device_attribute *attr, char *buf) { \
        LokiDevice *self = dev_get_drvdata(dev);                                               \
        return scnprintf(buf, PAGE_SIZE, "0x%08x\n", LokiDevice_get_reg(self, addr));          \
    }

#define LokiDevice_sysfs_reg_store(name, addr)                                                                      \
    static ssize_t name##_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t count) { \
        LokiDevice *self = dev_get_drvdata(dev);                                                                    \
        int arg;                                                                                                    \
        if (kstrtoint(buf, 0, &arg)) {                                                                              \
            dev_err(self->dev, "Expected integer value, found: %s.\n", buf);                                        \
        }                                                                                                           \
        else {                                                                                                      \
            LokiDevice_set_reg(self, addr, arg);                                                                    \
        }                                                                                                           \
        return count;                                                                                               \
    }

#define LokiDevice_sysfs_reg_show_field(name, addr, shift, mask)                                        \
    static ssize_t name##_show(struct device *dev, struct device_attribute *attr, char *buf) {          \
        LokiDevice *self = dev_get_drvdata(dev);                                                        \
        return scnprintf(buf, PAGE_SIZE, "0x%08x\n", (LokiDevice_get_reg(self, addr) >> shift) & mask); \
    }

#define LokiDevice_sysfs_reg_store_field(name, addr, shift, mask)                                                   \
    static ssize_t name##_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t count) { \
        LokiDevice *self = dev_get_drvdata(dev);                                                                    \
        int arg;                                                                                                    \
        if (kstrtoint(buf, 0, &arg)) {                                                                              \
            dev_err(self->dev, "Expected integer value, found: %s.\n", buf);                                        \
        }                                                                                                           \
        else {                                                                                                      \
            uint32_t val = LokiDevice_get_reg(self, addr);                                                          \
            val &= ~(((uint32_t)mask) << shift);                                                                    \
            val |= arg << shift;                                                                                    \
            LokiDevice_set_reg(self, addr, val);                                                                    \
        }                                                                                                           \
        return count;                                                                                               \
    }

#define LokiDevice_sysfs_create_file(name)                                                          \
    {                                                                                               \
        int err = device_create_file(self->dev_node, &dev_attr_##name);                             \
        if (err) {                                                                                  \
            dev_err(self->dev, "Failed to create sysfs endpoint for " #name ". Error: %d\n", err);  \
            return err;                                                                             \
        }                                                                                           \
    }

#define LokiDevice_sysfs_remove_file(name) \
    device_remove_file(self->dev_node, &dev_attr_##name);

int LokiDevice_sysfs_create(LokiDevice *self);
void LokiDevice_sysfs_remove(LokiDevice *self);

#endif
