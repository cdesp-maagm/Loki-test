
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of_device.h>

#include "../loki-device/loki-device-regs.h"
#include "../loki-device/loki-device-dma.h"
#include "../loki-device/loki-device-ioctl.h"
#include "loki-env-sensors-regs.h"
#include "loki-env-sensors-sysfs.h"

MODULE_LICENSE("GPL");
MODULE_AUTHOR("ESEO");
MODULE_DESCRIPTION("loki-env-sensors");

#define DEVICE_NAME "loki-env-sensors"
#define DEVICE_COUNT 1

// Le timeout est exploité différemment de l'acquisition des voies optiques.
// Ici, il permet au client de ne pas rester bloqué dans un mmap trop longtemps.
#define LOKI_ENV_SENSORS_DMA_TIMEOUT_MS 500

/// Interface du pilote pour les opérations sur les fichiers.
static struct file_operations LokiEnvSensors_ops = {
    .open           = LokiDevice_open,
    .unlocked_ioctl = LokiDevice_ioctl,
    .read           = LokiDevice_dma_read,
    .mmap           = LokiDevice_dma_mmap
};

static int LokiEnvSensors_remove(struct platform_device *pdev);

static int LokiEnvSensors_create_char_device(LokiDevice *self) {
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

    cdev_init(&self->cdev, &LokiEnvSensors_ops);
    self->cdev.owner = THIS_MODULE;
    cdev_add(&self->cdev, self->dev_num, 1);

    return 0;
}

/** Initialisation du pilote de périphérique.
 *
 * @param dev Un pointeur sur la structure de données représentant le périphérique.
 * @return Un code d'erreur, 0 en cas de succès.
 */
static int LokiEnvSensors_probe(struct platform_device *pdev) {
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

    // Créer un périphérique caractère "loki-env-sensors"
    // pour la classe de périphériques "loki".
    err = LokiEnvSensors_create_char_device(self);
    if (err) {
        goto probe_error;
    }

    err = LokiDevice_regs_probe(self);
    if (err) {
        goto probe_error;
    }

    self->dma_packet_length_reg = LOKI_ENV_SENSORS_REG_PACKET_LENGTH;
    self->dma_timeout           = LOKI_ENV_SENSORS_DMA_TIMEOUT_MS > 0 ? msecs_to_jiffies(LOKI_ENV_SENSORS_DMA_TIMEOUT_MS) : MAX_SCHEDULE_TIMEOUT;
    self->reg_count             = LOKI_ENV_SENSORS_REG_LAST_DATA + LokiDevice_get_reg(self, LOKI_ENV_SENSORS_REG_CHANNELS);

    // Créer des fichiers dans /sys pour l'accès aux registres.
    if (LokiEnvSensors_sysfs_create(self)) {
        goto probe_error;
    }

    // Initialiser le DMA.
    if (LokiDevice_dma_probe(self)) {
        goto probe_error;
    }

    return 0;

probe_error:
    LokiEnvSensors_remove(pdev);
    return err;
}

/** Terminaison du pilote de périphérique.
 *
 * La plupart des ressources allouées dans LokiEnvSensors_probe sont
 * "device-managed" (cf les fonctions préfixées par "devm_").
 * Elles sont désallouées automatiquement si l'initialisation échoue ou
 * lorsque ce module se termine.
 *
 * @param dev Un pointeur sur la structure de données représentant le périphérique.
 * @return Un code d'erreur, 0 en cas de succès.
 */
static int LokiEnvSensors_remove(struct platform_device *pdev) {
    LokiDevice *self = dev_get_drvdata(&pdev->dev);

    LokiDevice_dma_remove(self);
    LokiEnvSensors_sysfs_remove(self);

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
static struct of_device_id LokiEnvSensors_of_match[] = {
	{ .compatible = "eseo,loki-env-sensors", },
	{ /* end of list */ },
};

MODULE_DEVICE_TABLE(of, LokiEnvSensors_of_match);

/// La structure de données permettant d'enregistrer ce pilote de périphérique auprès du noyau.
static struct platform_driver LokiEnvSensors_driver = {
	.driver = {
		.name = "loki-env-sensors-driver",
		.owner = THIS_MODULE,
		.of_match_table	= LokiEnvSensors_of_match,
	},
	.probe  = LokiEnvSensors_probe,
	.remove = LokiEnvSensors_remove,
};

/** Initialisation du module.
 *
 * @return Un code d'erreur, 0 en cas de succès.
 */
static int __init LokiEnvSensors_init(void) {
	return platform_driver_register(&LokiEnvSensors_driver);
}

/// Terminaison du module.
static void __exit LokiEnvSensors_exit(void) {
	platform_driver_unregister(&LokiEnvSensors_driver);
}

module_init(LokiEnvSensors_init);
module_exit(LokiEnvSensors_exit);
