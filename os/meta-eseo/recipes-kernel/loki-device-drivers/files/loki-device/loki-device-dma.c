
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/dmaengine.h>
#include <linux/dma-mapping.h>
#include <linux/of.h>
#include <linux/time.h>

#include "loki-device-regs.h"

int LokiDevice_dma_probe(LokiDevice *self) {
    struct device *dev = self->dev;

    // Lire le champ "xlnx,sg-length-width" du DMA dans le device tree
    // pour connaître la taille maximale d'un buffer DMA.
    uint32_t dma_phandle;
    int err = of_property_read_u32_index(dev->of_node, "dmas", 0, &dma_phandle);
    if (err) {
        dev_err(dev, "Failed to find handle for DMA node. Error: %d\n", err);
        return err;
    }

    struct device_node *dma_node = of_find_node_by_phandle(dma_phandle);
    if (!dma_node) {
        dev_err(dev, "Failed to find device tree node for DMA.\n");
        return err;
    }

    uint32_t dma_length_width;
    err = of_property_read_u32(dma_node, "xlnx,sg-length-width", &dma_length_width);
    if (err) {
        dev_err(dev, "Failed to read property 'xlnx,sg-length-width' of DMA. Error: %d\n", err);
        return err;
    }

    uint32_t dma_max_buffer_size = (1 << dma_length_width) - 1;
    dev_info(dev, "Maximum DMA buffer size is %u bytes.\n", dma_max_buffer_size);

    // Lire le champ "xlnx,datawidth" du DMA dans le device tree.
    struct device_node *chan_node = of_get_compatible_child(dma_node, "xlnx,axi-dma-s2mm-channel");
    if (!chan_node) {
        dev_err(dev, "Failed to find device tree node for DMA S2MM channel.\n");
        return err;
    }

    uint32_t dma_datawidth;
    err = of_property_read_u32(chan_node, "xlnx,datawidth", &dma_datawidth);
    if (err) {
        dev_err(dev, "Failed to read property 'xlnx,datawidth' of DMA S2MM channel. Error: %d\n", err);
        return err;
    }
    self->dma_data_size = dma_datawidth / 8;
    dev_info(dev, "DMA sample size is %u bytes.\n", self->dma_data_size);

    // Réserver les canaux DMA.
    self->dma_channel = dma_request_slave_channel(dev, "s2mm");
    if (!self->dma_channel) {
		dev_err(dev, "S2MM DMA channel request error.\n");
		return EACCES;
	}

    sema_init(&self->dma_sema, 0);
    INIT_KFIFO(self->dma_fifo);

    return 0;
}

EXPORT_SYMBOL(LokiDevice_dma_probe);

void LokiDevice_dma_remove(LokiDevice *self) {
    if (self->dma_channel) {
        dmaengine_terminate_sync(self->dma_channel);
        dma_release_channel(self->dma_channel);
    }

    if (self->dma_buffer) {
        dma_free_coherent(self->dev, self->dma_buffer_size, self->dma_buffer, self->dma_alloc_handle);
    }
}

EXPORT_SYMBOL(LokiDevice_dma_remove);

/// Indiquer à un autre thread qu'un transfert DMA est terminé.
static void LokiDevice_dma_callback(void *arg) {
    LokiDevice *self = arg;

    // Préparer un élément à ajouter à la FIFO.
    LokiDMAFIFOItem item = {.offset = self->dma_offset};
    getnstimeofday(&item.ts);

    // Si l'élément a bien été inséré, signaler au client qu'un nouveau paquet est disponible.
    // Si la FIFO était pleine, compter un paquet perdu.
    if (kfifo_put(&self->dma_fifo, item)) {
        up(&self->dma_sema);
        self->dma_received_packets ++;
    }
    else {
        self->dma_dropped_packets ++;
    }

    // Mettre à jour l'offset du prochain paquet.
    self->dma_offset += self->dma_transfer_size;
    if (self->dma_offset >= self->dma_buffer_size) {
        self->dma_offset = 0;
    }
}

int LokiDevice_dma_read(struct file *fd, char *buf, size_t size, loff_t *pos) {
    LokiDevice *self = fd->private_data;

    if (down_timeout(&self->dma_sema, self->dma_timeout)) {
        return -ETIMEDOUT;
    }

    LokiDMAFIFOItem item;
    if (!kfifo_get(&self->dma_fifo, &item)) {
        return -ENODATA;
    }

    self->dma_packet_time = item.ts;

    dma_sync_single_for_cpu(self->dma_channel->device->dev, self->dma_map_handle + item.offset, self->dma_transfer_size, DMA_FROM_DEVICE);
    int err = copy_to_user(buf, self->dma_buffer + item.offset, size);
    dma_sync_single_for_device(self->dma_channel->device->dev, self->dma_map_handle + item.offset, self->dma_transfer_size, DMA_FROM_DEVICE);

    if (err) {
        return -EACCES;
    }

    return size;
}

EXPORT_SYMBOL(LokiDevice_dma_read);

int LokiDevice_dma_mmap(struct file *fd, struct vm_area_struct *vma) {
    LokiDevice *self = fd->private_data;

    if (down_timeout(&self->dma_sema, self->dma_timeout)) {
        return -ETIMEDOUT;
    }

    LokiDMAFIFOItem item;
    if (!kfifo_get(&self->dma_fifo, &item)) {
        return -ENODATA;
    }

    self->dma_packet_time = item.ts;

    unsigned long size = vma->vm_end - vma->vm_start;
    if (size > self->dma_transfer_size) {
        return -EINVAL;
    }

    return dma_mmap_coherent(self->dev, vma, self->dma_buffer + item.offset, self->dma_alloc_handle + item.offset, size);
}

EXPORT_SYMBOL(LokiDevice_dma_mmap);

int LokiDevice_dma_start(LokiDevice *self) {
    struct device *dev = self->dev;

    // Déterminer le nombre d'octets dans un transfert DMA.
    self->dma_transfer_size = self->dma_data_size * LokiDevice_get_reg(self, self->dma_packet_length_reg);

    // Allouer le buffer de réception pour un transfert DMA cyclique.
    self->dma_buffer_size = LOKI_DMA_PERIOD_COUNT * self->dma_transfer_size;
    dev_dbg(dev, "Allocating %u bytes.\n", self->dma_buffer_size);

    self->dma_buffer = dma_alloc_coherent(dev, self->dma_buffer_size, &self->dma_alloc_handle, GFP_KERNEL | GFP_DMA);
    if (!self->dma_buffer) {
        dev_err(dev, "S2MM DMA buffer allocation error.\n");
        return ENOMEM;
    }

    // Affecter le buffer au DMA.
    self->dma_map_handle = dma_map_single(self->dma_channel->device->dev, self->dma_buffer, self->dma_buffer_size, DMA_FROM_DEVICE);
    if (dma_mapping_error(self->dma_channel->device->dev, self->dma_map_handle)) {
        dev_err(dev, "Failed to map DMA buffer (dma_map_single).\n");
        return ENOMEM;
    }

    // Obtenir un descripteur pour une transaction DMA cyclique.
    // Cette fonction requiert un DMA avec scatter-gather.
	struct dma_async_tx_descriptor *desc = dmaengine_prep_dma_cyclic(self->dma_channel, self->dma_map_handle, self->dma_buffer_size, self->dma_transfer_size, DMA_DEV_TO_MEM, DMA_CTRL_ACK | DMA_PREP_INTERRUPT);
	if (!desc) {
		dev_err(dev, "Failed to get DMA transaction descriptor (dmaengine_prep_dma_cyclic).\n");
		return EBUSY;
	}

    // Affecter le callback de complétion.
	desc->callback = LokiDevice_dma_callback;
    desc->callback_param = self;

    // Réinitialiser l'état des transferts.
    self->dma_received_packets = 0;
    self->dma_dropped_packets = 0;
    self->dma_offset = 0;

    // Soumettre la transaction et retourner un cookie pour suivre son état.
	dma_cookie_t s2mm_cookie = dmaengine_submit(desc);
    if (dma_submit_error(s2mm_cookie)) {
        dev_err(dev, "Failed to submit DMA transaction.\n");
        return EBUSY;
    }

    // Mémoriser l'heure de démarrage des transferts DMA
    getnstimeofday(&self->dma_start_time);

    // Démarrer les transferts DMA.
    dev_dbg(dev, "Starting DMA transfers.\n");
    dma_async_issue_pending(self->dma_channel);
    enum dma_status status = dma_async_is_tx_complete(self->dma_channel, s2mm_cookie, NULL, NULL);
    if (status != DMA_IN_PROGRESS) {
        dev_err(dev, "Engine is not running.\n");
        return EIO;
    }

    return 0;
}

bool LokiDevice_dma_is_streaming(LokiDevice *self) {
    return self->dma_buffer != NULL;
}

void LokiDevice_dma_stop(LokiDevice *self) {
    dmaengine_terminate_sync(self->dma_channel);
    dma_unmap_single(self->dma_channel->device->dev, self->dma_map_handle, self->dma_buffer_size, DMA_FROM_DEVICE);

    if (self->dma_buffer) {
        dma_free_coherent(self->dev, self->dma_buffer_size, self->dma_buffer, self->dma_alloc_handle);
        self->dma_buffer = NULL;
    }
}
