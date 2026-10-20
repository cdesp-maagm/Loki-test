
#include <linux/of_address.h>
#include "loki-device-regs.h"
#include "loki-device-dma.h"

int LokiDevice_regs_probe(LokiDevice *self) {
    struct device *dev = self->dev;

    // Lire le champ "reg" du périphérique dans le device tree
    // pour connaître la région du plan d'adressage associée aux registres.
    struct resource regs_res;
    int err = of_address_to_resource(dev->of_node, 0, &regs_res);
    if (err) {
        dev_err(dev, "Failed to read memory segment for registers. Error: %d\n", err);
        return err;
    }
    dev_info(dev, "Found registers at address: 0x%08x\n", regs_res.start);

    // Réserver la région du plan d'adressage associées au registres.
    // Associer les adresses physiques aux adresses virtuelles du noyau
    // et obtenir un pointeur sur cette région.
    self->regs = devm_ioremap_resource(dev, &regs_res);
    if (IS_ERR(self->regs)) {
        err = PTR_ERR(self->regs);
        dev_err(dev, "Failed to map memory segment for registers. Error: %d\n", err);
        return err;
    }

    return 0;
}

EXPORT_SYMBOL(LokiDevice_regs_probe);

// Voir loki-modem.h
void LokiDevice_set_reg(LokiDevice *self, int index, uint32_t value) {
    if (index == self->dma_packet_length_reg && LokiDevice_dma_is_streaming(self)) {
        dev_err(self->dev, "Cannot change packet length while a DMA transfer is in progress.\n");
        return;
    }
    iowrite32(value, self->regs + index);
}

EXPORT_SYMBOL(LokiDevice_set_reg);

// Voir loki-modem.h
uint32_t LokiDevice_get_reg(LokiDevice *self, int index) {
    return ioread32(self->regs + index);
}

EXPORT_SYMBOL(LokiDevice_get_reg);
