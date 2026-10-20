
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of_device.h>

#include "../loki-device/loki-device-regs.h"
#include "../loki-device/loki-device-dma.h"
#include "../loki-device/loki-device-ioctl.h"
#include "loki-modem-regs.h"
#include "loki-modem-sysfs.h"

MODULE_LICENSE("GPL");
MODULE_AUTHOR("ESEO");
MODULE_DESCRIPTION("loki-modem");

#define DEVICE_NAME "loki-modem"
#define DEVICE_COUNT 1

#define LOKI_MODEM_DMA_TIMEOUT_MS 3000

/// Interface du pilote pour les opérations sur les fichiers.
static struct file_operations LokiModem_ops = {
    .open           = LokiDevice_open,
    .unlocked_ioctl = LokiDevice_ioctl,
    .read           = LokiDevice_dma_read,
    .mmap           = LokiDevice_dma_mmap
};

static int LokiModem_remove(struct platform_device *pdev);

int LokiModem_create_char_device(LokiDevice *self) {
    struct device *dev = self->dev;
    int err;

    err = alloc_chrdev_region(&self->dev_num, 0, DEVICE_COUNT, DEVICE_NAME);
    if (err) {
        dev_err(dev, "Failed to allocate region for character device. Error: %d\n", err);
        return err;
    }

    self->dev_node = device_create(LokiDevice_class, NULL, self->dev_num, NULL, DEVICE_NAME);
    if (IS_ERR(self->dev_node)) {
        err = PTR_ERR(self->dev_node);
        dev_err(dev, "Failed to create character device. Error: %d\n", err);
        return err;
    }
    dev_set_drvdata(self->dev_node, self);

    cdev_init(&self->cdev, &LokiModem_ops);
    self->cdev.owner = THIS_MODULE;
    cdev_add(&self->cdev, self->dev_num, 1);

    return 0;
}

/** Initialisation du pilote de périphérique.
 *
 * @param dev Un pointeur sur la structure de données représentant le périphérique.
 * @return Un code d'erreur, 0 en cas de succès.
 */
static int LokiModem_probe(struct platform_device *pdev) {
    int err = 0;
    struct device *dev = &pdev->dev;

    // Allouer et affecter les données du driver pour ce périphérique.
    LokiDevice *self = devm_kzalloc(dev, sizeof(LokiDevice), GFP_KERNEL);
    if (!self) {
        err = -ENOMEM;
        goto probe_error;
    }
    dev_set_drvdata(dev, self);
    self->dev = dev;

    // Créer un périphérique caractère "modem"
    // pour la classe de périphériques "loki".
    err = LokiModem_create_char_device(self);
    if (err) {
        goto probe_error;
    }

    err = LokiDevice_regs_probe(self);
    if (err) {
        goto probe_error;
    }

    self->dma_packet_length_reg = LOKI_MODEM_REG_DEMOD_PACKET_LENGTH;
    self->dma_timeout           = LOKI_MODEM_DMA_TIMEOUT_MS > 0 ? msecs_to_jiffies(LOKI_MODEM_DMA_TIMEOUT_MS) : MAX_SCHEDULE_TIMEOUT;
    self->reg_count             = LOKI_MODEM_REG_DEMOD_CHANNEL_CFG + LOKI_MODEM_REG_DEMOD_CHANNEL_CFG_COUNT * LokiDevice_get_reg(self, LOKI_MODEM_REG_DEMOD_CHANNELS);

    // Créer des fichiers dans /sys pour l'accès aux registres.
    if (LokiModem_sysfs_create(self)) {
        goto probe_error;
    }

    // Initialiser le DMA.
    if (LokiDevice_dma_probe(self)) {
        goto probe_error;
    }

    return 0;

probe_error:
    LokiModem_remove(pdev);
    return err;
}

/** Terminaison du pilote de périphérique.
 *
 * La plupart des ressources allouées dans LokiModem_probe sont
 * "device-managed" (cf les fonctions préfixées par "devm_").
 * Elles sont désallouées automatiquement si l'initialisation échoue ou
 * lorsque ce module se termine.
 *
 * @param dev Un pointeur sur la structure de données représentant le périphérique.
 * @return Un code d'erreur, 0 en cas de succès.
 */
static int LokiModem_remove(struct platform_device *pdev) {
    LokiDevice *self = dev_get_drvdata(&pdev->dev);

    LokiDevice_dma_remove(self);
    LokiModem_sysfs_remove(self);

    cdev_del(&self->cdev);

    if (!IS_ERR(self->dev_node)) {
        device_destroy(LokiDevice_class, self->dev_num);
    }

    if (self->dev_num) {
        unregister_chrdev_region(self->dev_num, DEVICE_COUNT);
    }

    return 0;
}

/// Table de critères pour la détection du périphérique.
static struct of_device_id LokiModem_of_match[] = {
	{ .compatible = "eseo,loki-modem", },
	{ /* end of list */ },
};

MODULE_DEVICE_TABLE(of, LokiModem_of_match);

/// La structure de données permettant d'enregistrer ce pilote de périphérique auprès du noyau.
static struct platform_driver LokiModem_driver = {
	.driver = {
		.name = "loki-modem-driver",
		.owner = THIS_MODULE,
		.of_match_table	= LokiModem_of_match,
	},
	.probe  = LokiModem_probe,
	.remove = LokiModem_remove,
};

/** Initialisation du module.
 *
 * @return Un code d'erreur, 0 en cas de succès.
 */
static int __init LokiModem_init(void) {
	return platform_driver_register(&LokiModem_driver);
}

/// Terminaison du module.
static void __exit LokiModem_exit(void) {
	platform_driver_unregister(&LokiModem_driver);
}

module_init(LokiModem_init);
module_exit(LokiModem_exit);
