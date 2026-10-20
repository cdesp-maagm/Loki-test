
#include <linux/fs.h>
#include <linux/io.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/of_address.h>
#include <linux/of_platform.h>
#include <linux/uaccess.h>
#include <linux/dmaengine.h>
#include <linux/dma-mapping.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("ESEO");
MODULE_DESCRIPTION("loki-stub-driver");

#define DEVICE_CLASS "loki"
#define DEVICE_NAME "loki-stub"

#define LOKI_STUB_IOCTL_REG_WRITE_MASK 0x80
#define LOKI_STUB_IOCTL_REG_INDEX_MASK 0x03

#define LOKI_STUB_DMA_TIMEOUT_MS 3000

/// Données utilisées par le driver.
static struct {
    /// Numéro majeur du périphérique caractère.
    int major;
    /// Classe du périphérique.
    struct class *class;
    /// Périphérique caractère.
    struct device *chrdev;
    /// Les registres du périphérique.
    int32_t *regs;
    /// La longueur maximale d'un buffer DMA.
    uint32_t dma_max_buffer_length;
    /// Le canal DMA stream-to-memory-map.
    struct dma_chan *s2mm;
    /// Le canal DMA memory-map-to-stream.
    struct dma_chan *mm2s;
} LokiStub_data;

/** Affecter la valeur d'un registre.
 *
 * @param index Le numéro du registre.
 * @param value La valeur à affecter.
 */
static void LokiStub_set_reg(int index, int value) {
    iowrite32(value, LokiStub_data.regs + index);
}

/** Lire la valeur d'un registre.
 *
 * @param index Le numéro du registre.
 * @return La valeur du registre.
 */
static int LokiStub_get_reg(int index) {
    return ioread32(LokiStub_data.regs + index);
}

/** Lire le numéro du registre correspondant à un attribut.
 *
 * Le nom de l'attribut doit être de la forme "regN" avec N entier
 * représenté en base 10.
 *
 * @param attr L'attribut à analyser.
 * @return Le numéro du registre.
 */
static int LokiStub_get_reg_index(struct device_attribute *attr) {
    int index = 0;
    if (kstrtoint(attr->attr.name + 3, 10, &index)) {
        pr_err("Le nom de l'attribut ne contient pas un numéro de registre valide.\n");
    }
    return index;
}

/** Affecter la valeur d'un registre à partir d'un attribut du périphérique dans /sys
 *
 * Écrire la valeur sous forme de chaîne de caractères dans
 * /sys/class/loki/loki-stub/regN.
 * Le préfixe 0x permet d'entrer une valeur en hexadécimal.
 *
 * @param dev Un pointeur sur la structure de données représentant le périphérique.
 * @param attr Un pointeur sur la structure de données de l'attribut du périphérique à affecter.
 * @param buf La chaîne de caractère qui contient la valeur à affecter.
 * @param count La longueur de la chaîne de caractères.
 * @return Le nombre d'octets traités.
 */
static ssize_t reg_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t count) {
    int arg;
    if (kstrtoint(buf, 0, &arg)) {
        dev_err(dev, "Valeur incorrecte.\n");
    }
    else {
        LokiStub_set_reg(LokiStub_get_reg_index(attr), arg);
    }
    return count;
}

/** Lire la valeur d'un registre à partir d'un attribut du périphérique dans /sys
 *
 * La lecture du fichier /sys/class/loki/loki-stub/regN
 * retourne une chaîne de caractères représentant une valeur entière en
 * hexadécimal avec le préfixe 0x.
 *
 * @param dev Un pointeur sur la structure de données représentant le périphérique.
 * @param attr Un pointeur sur la structure de données de l'attribut du périphérique à affecter.
 * @param buf La chaîne de caractère qui recevra la valeur de l'attribut.
 * @return Le nombre d'octets écrits dans buf.
 */
static ssize_t reg_show(struct device *dev, struct device_attribute *attr, char *buf) {
    return scnprintf(buf, PAGE_SIZE, "0x%x\n", LokiStub_get_reg(LokiStub_get_reg_index(attr)));
}

/// Attribut permettant l'accès aux registre 0, en lecture/écriture.
static DEVICE_ATTR(reg0, S_IWUSR | S_IRUGO, reg_show, reg_store);

/// Attribut permettant l'accès aux registre 1, en lecture/écriture.
static DEVICE_ATTR(reg1, S_IWUSR | S_IRUGO, reg_show, reg_store);

/// Attribut permettant l'accès aux registre 2, en lecture/écriture.
static DEVICE_ATTR(reg2, S_IWUSR | S_IRUGO, reg_show, reg_store);

/// Attribut permettant l'accès aux registre 3, en lecture/écriture.
static DEVICE_ATTR(reg3, S_IWUSR | S_IRUGO, reg_show, reg_store);

/** Interface ioctl
 *
 * @param f Un descripteur du fichier sur lequel la fonction ioctl est appelée.
 * @param cmd La commande à exécuter.
 * @param arg L'argument de la commande (ici un pointeur).
 * @return Un code d'erreur.
 */
static long LokiStub_ioctl(struct file *f, unsigned cmd, unsigned long arg) {
    int index = cmd & LOKI_STUB_IOCTL_REG_INDEX_MASK;
    int value;
    if (cmd & LOKI_STUB_IOCTL_REG_WRITE_MASK) {
        if (copy_from_user(&value, (int*)arg, sizeof(int))) {
            pr_err("Echec de copy_from_user");
        }
        LokiStub_set_reg(index, value);
    }
    else {
        value = LokiStub_get_reg(index);
        if (copy_to_user((int*)arg, &value, sizeof(int))) {
            pr_err("Echec de copy_to_user");
        }
    }

    return 0;
}

/// Interface du pilote pour les opérations sur les fichiers.
static struct file_operations LokiStub_ops = {
    .unlocked_ioctl = LokiStub_ioctl
};

/// Indiquer à un autre thread qu'un transfert DMA est terminé.
static void LokiStub_sync_callback(void *completion) {
    complete(completion);
}

/// Péparer un buffer pour une transaction DMA.
static dma_cookie_t LokiStub_prepare_dma_transfer(struct dma_chan *chan, dma_addr_t buf, size_t len, enum dma_transfer_direction dir, struct completion *cmp) {
    // Obtenir un descripteur pour la transaction DMA.
	struct dma_async_tx_descriptor *desc = dmaengine_prep_slave_single(chan, buf, len, dir, DMA_CTRL_ACK | DMA_PREP_INTERRUPT);
	if (!desc) {
		pr_err("Failed to get DMA transaction descriptor (dmaengine_prep_slave_single).\n");
		return -EBUSY;
	}

    // Affecter le callback de complétion
	desc->callback = LokiStub_sync_callback;
	desc->callback_param = cmp;

    // Soumettre la transaction et retourner un cookie pour suivre son état.
	return dmaengine_submit(desc);
}

/** Démarrer un transfert DMA préparé précédemment.
 *
 * Cette fonction démarre un transfert, attend sa complétion, un timeout ou une erreur.
 */
static void LokiStub_start_dma_transfer(struct dma_chan *chan, struct completion *cmp, dma_cookie_t cookie, bool wait) {
    // Initialiser la complétion et démarrer la transaction en attente.
    init_completion(cmp);
    dma_async_issue_pending(chan);

    if (!wait) {
        return;
    }

    pr_info("Waiting for DMA transfer to complete.\n");

    unsigned long timeout = wait_for_completion_timeout(cmp, msecs_to_jiffies(LOKI_STUB_DMA_TIMEOUT_MS));
    enum dma_status status = dma_async_is_tx_complete(chan, cookie, NULL, NULL);

    if (!timeout)  {
        pr_err("DMA transfer timed out.\n");
    }
    else if (status != DMA_COMPLETE) {
        pr_err("DMA transfer completion status: %s\n", status == DMA_ERROR ? "error" : "in progress");
    }
}

/** Démarrer un test du DMA.
 *
 * Cette fonction prépare un transfert vers le périphérique et un en provenance
 * du périphérique. Elle démarre les deux transferts, attend leur complétion,
 * et vérifie que les données reçues sont correcte.
 *
 * On suppose que le périphérique réémet les donées qu'il a reçues.
 */
static void LokiStub_test_dma_transfer(struct device *dev) {
    // Choisir une taille de buffer multiple de 4.
    uint32_t dma_buffer_length = LokiStub_data.dma_max_buffer_length;
    dma_buffer_length -= dma_buffer_length % sizeof(uint32_t);

    // Allouer les buffers d'envoi et de réception.
    char *s2mm_buffer = kzalloc(dma_buffer_length, GFP_KERNEL);
    char *mm2s_buffer = kmalloc(dma_buffer_length, GFP_KERNEL);

    if (!mm2s_buffer || !s2mm_buffer) {
        pr_err("Failed to allocate DMA buffers.\n");
        return;
    }

    // Initialiser le buffer source avec des données de test.
    for (int i = 0; i < dma_buffer_length; i ++) {
        mm2s_buffer[i] = i;
    }

    // Affecter les buffers du CPU au DMA.
    dma_addr_t s2mm_addr = dma_map_single(LokiStub_data.s2mm->device->dev, s2mm_buffer, dma_buffer_length, DMA_FROM_DEVICE);
    dma_addr_t mm2s_addr = dma_map_single(LokiStub_data.mm2s->device->dev, mm2s_buffer, dma_buffer_length, DMA_TO_DEVICE);

    // Préparer les transactions.
    struct completion s2mm_cmp, mm2s_cmp;
    dma_cookie_t s2mm_cookie = LokiStub_prepare_dma_transfer(LokiStub_data.s2mm, s2mm_addr, dma_buffer_length, DMA_DEV_TO_MEM, &s2mm_cmp);
    dma_cookie_t mm2s_cookie = LokiStub_prepare_dma_transfer(LokiStub_data.mm2s, mm2s_addr, dma_buffer_length, DMA_MEM_TO_DEV, &mm2s_cmp);

    if (dma_submit_error(mm2s_cookie) || dma_submit_error(s2mm_cookie)) {
        pr_err("Failed to prepare DMA transfers.\n");
        return;
    }

    pr_info("Starting DMA transfers (%d bytes).\n", dma_buffer_length);
    LokiStub_start_dma_transfer(LokiStub_data.s2mm, &s2mm_cmp, s2mm_cookie, false);
    LokiStub_start_dma_transfer(LokiStub_data.mm2s, &mm2s_cmp, mm2s_cookie, true);

    // Affecter les buffers du DMA au CPU.
    dma_unmap_single(LokiStub_data.s2mm->device->dev, s2mm_addr, dma_buffer_length, DMA_FROM_DEVICE);
    dma_unmap_single(LokiStub_data.mm2s->device->dev, mm2s_addr, dma_buffer_length, DMA_TO_DEVICE);

    // Vérifier les données reçues.
    for (int i = 0; i < dma_buffer_length; i ++) {
        if (s2mm_buffer[i] != mm2s_buffer[i]) {
            pr_err("DMA data error after %d bytes. Expected %d, received %d", i, (int)mm2s_buffer[i], (int)s2mm_buffer[i]);
            break;
        }
    }

    kfree(mm2s_buffer);
    kfree(s2mm_buffer);
}

static ssize_t dma_test_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t count) {
    LokiStub_test_dma_transfer(dev);
    return count;
}

static DEVICE_ATTR_WO(dma_test);

static int LokiStub_remove(struct platform_device *pdev);

/** Initialisation du pilote de périphérique.
 *
 * @param dev Un pointeur sur la structure de données représentant le périphérique.
 * @return Un code d'erreur, 0 en cas de succès.
 */
static int LokiStub_probe(struct platform_device *pdev) {
    int err = 0;
    struct device *dev = &pdev->dev;
    struct resource regs_res;

    // Créer un périphérique caractère "loki-stub"
    // pour la classe de périphériques "loki".
    LokiStub_data.major = register_chrdev(0, DEVICE_NAME, &LokiStub_ops);
    if (LokiStub_data.major < 0) {
        err = LokiStub_data.major;
        dev_err(dev, "Failed to register character device. Error: %d\n", err);
        goto probe_error;
    }

    LokiStub_data.class = class_create(THIS_MODULE, DEVICE_CLASS);
    if (IS_ERR(LokiStub_data.class)) {
        err = PTR_ERR(LokiStub_data.class);
        dev_err(dev, "Failed to create device class. Error: %d\n", err);
        goto probe_error;
    }

    LokiStub_data.chrdev = device_create(LokiStub_data.class, NULL, MKDEV(LokiStub_data.major, 0), NULL, DEVICE_NAME);
    if (IS_ERR(LokiStub_data.chrdev)) {
        err = PTR_ERR(LokiStub_data.class);
        dev_err(dev, "Failed to create character device. Error: %d\n", err);
        goto probe_error;
    }

    // Lire le champ "reg" du périphérique dans le device tree
    // pour connaître la région du plan d'adressage associée aux registres.
    err = of_address_to_resource(dev->of_node, 0, &regs_res);
    if (err) {
        dev_err(dev, "Failed to read memory segment for registers. Error: %d\n", err);
        goto probe_error;
    }
    dev_info(dev, "Found registers at address: 0x%08x\n", regs_res.start);

    // Réserver la région du plan d'adressage associées au registres.
    // Associer les adresses physiques aux adresses virtuelles du noyau
    // et obtenir un pointeur sur cette région.
    LokiStub_data.regs = devm_ioremap_resource(dev, &regs_res);
    if (IS_ERR(LokiStub_data.regs)) {
        err = PTR_ERR(LokiStub_data.regs);
        dev_err(dev, "Failed to map memory segment for registers. Error: %d\n", err);
        goto probe_error;
    }

    // Créer des fichiers dans /sys pour les attributs "regN".
    err = device_create_file(LokiStub_data.chrdev, &dev_attr_reg0);
    if (err) {
        dev_err(dev, "Failed to create /sys endpoint for reg0. Error: %d\n", err);
        goto probe_error;
    }

    err = device_create_file(LokiStub_data.chrdev, &dev_attr_reg1);
    if (err) {
        dev_err(dev, "Failed to create /sys endpoint for reg1. Error: %d\n", err);
        goto probe_error;
    }

    err = device_create_file(LokiStub_data.chrdev, &dev_attr_reg2);
    if (err) {
        dev_err(dev, "Failed to create /sys endpoint for reg2. Error: %d\n", err);
        goto probe_error;
    }

    err = device_create_file(LokiStub_data.chrdev, &dev_attr_reg3);
    if (err) {
        dev_err(dev, "Failed to create /sys endpoint for reg3. Error: %d\n", err);
        goto probe_error;
    }

    // Lire le champ "xlnx,sg-length-width" du DMA dans le device tree
    // pour connaître la taille maximale d'un buffer DMA.
    uint32_t dma_phandle;
    err = of_property_read_u32_index(dev->of_node, "dmas", 0, &dma_phandle);
    if (err) {
        dev_err(dev, "Failed to find handle for DMA node. Error: %d\n", err);
        goto probe_error;
    }

    struct device_node *dma_node = of_find_node_by_phandle(dma_phandle);
    if (!dma_node) {
        dev_err(dev, "Failed to find device tree node for DMA.\n");
        goto probe_error;
    }

    uint32_t dma_length_width;
    err = of_property_read_u32(dma_node, "xlnx,sg-length-width", &dma_length_width);
    if (err) {
        dev_err(dev, "Failed to read property 'xlnx,sg-length-width' of DMA. Error: %d\n", err);
        goto probe_error;
    }
    LokiStub_data.dma_max_buffer_length = (1 << dma_length_width) - 1;
    dev_info(dev, "Maximum DMA buffer length is %u bytes.\n", LokiStub_data.dma_max_buffer_length);

    // Réserver les canaux DMA.
    LokiStub_data.s2mm = dma_request_slave_channel(dev, "s2mm");
    if (!LokiStub_data.s2mm) {
		dev_err(dev, "S2MM DMA channel request error.\n");
		goto probe_error;
	}

	LokiStub_data.mm2s = dma_request_slave_channel(dev, "mm2s");
    if (!LokiStub_data.mm2s) {
		dev_err(dev, "MM2S DMA channel request error.\n");
		goto probe_error;
	}

    err = device_create_file(LokiStub_data.chrdev, &dev_attr_dma_test);
    if (err) {
        dev_err(dev, "Failed to create /sys endpoint for dma_test. Error: %d\n", err);
        goto probe_error;
    }

    return 0;

probe_error:
    LokiStub_remove(pdev);
    return err;
}

/** Terminaison du pilote de périphérique.
 *
 * La plupart des ressources allouées dans LokiStub_probe sont
 * "device-managed" (cf les fonctions préfixées par "devm_").
 * Elles sont désallouées automatiquement si l'initialisation échoue ou
 * lorsque ce module se termine.
 *
 * @param dev Un pointeur sur la structure de données représentant le périphérique.
 * @return Un code d'erreur, 0 en cas de succès.
 */
static int LokiStub_remove(struct platform_device *pdev) {
    struct device *dev = &pdev->dev;

    device_remove_file(dev, &dev_attr_reg0);
    device_remove_file(dev, &dev_attr_reg1);
    device_remove_file(dev, &dev_attr_reg2);
    device_remove_file(dev, &dev_attr_reg3);
    device_remove_file(dev, &dev_attr_dma_test);

    if (!IS_ERR(LokiStub_data.chrdev)) {
        device_destroy(LokiStub_data.class, MKDEV(LokiStub_data.major, 0));
    }

    if (!IS_ERR(LokiStub_data.class)) {
        class_destroy(LokiStub_data.class);
    }

    if (LokiStub_data.major >= 0) {
        unregister_chrdev(LokiStub_data.major, DEVICE_NAME);
    }

    if (LokiStub_data.s2mm) {
        dma_release_channel(LokiStub_data.s2mm);
    }

    if (LokiStub_data.mm2s) {
        dma_release_channel(LokiStub_data.mm2s);
    }

    return 0;
}

/// Table de critères pour la détection du périphérique.
static struct of_device_id LokiStub_of_match[] = {
	{ .compatible = "eseo,loki-stub", },
	{ /* end of list */ },
};

MODULE_DEVICE_TABLE(of, LokiStub_of_match);

/// La structure de données permettant d'enregistrer ce pilote de périphérique auprès du noyau.
static struct platform_driver LokiStub_driver = {
	.driver = {
		.name = "loki-stub-driver",
		.owner = THIS_MODULE,
		.of_match_table	= LokiStub_of_match,
	},
	.probe  = LokiStub_probe,
	.remove = LokiStub_remove,
};

/** Initialisation du module.
 *
 * @return Un code d'erreur, 0 en cas de succès.
 */
static int __init LokiStub_init(void) {
	return platform_driver_register(&LokiStub_driver);
}

/// Terminaison du module.
static void __exit LokiStub_exit(void) {
	platform_driver_unregister(&LokiStub_driver);
}

module_init(LokiStub_init);
module_exit(LokiStub_exit);
