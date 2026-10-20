
#include <linux/module.h>
#include <linux/device.h>
#include <linux/fs.h>

#include "loki-device.h"

MODULE_LICENSE("GPL");
MODULE_AUTHOR("ESEO");
MODULE_DESCRIPTION("loki-device");

#define DEVICE_CLASS "loki"

struct class *LokiDevice_class;
EXPORT_SYMBOL(LokiDevice_class);

int LokiDevice_open(struct inode *n, struct file *f) {
    f->private_data = container_of(n->i_cdev, LokiDevice, cdev);
    return 0;
}

EXPORT_SYMBOL(LokiDevice_open);

static int __init LokiDevice_init(void) {
    LokiDevice_class = class_create(THIS_MODULE, DEVICE_CLASS);
    if (IS_ERR(LokiDevice_class)) {
        int err = PTR_ERR(LokiDevice_class);
        pr_err("Failed to create device class. Error: %d\n", err);
        return err;
    }

	return 0;
}

early_initcall(LokiDevice_init);
