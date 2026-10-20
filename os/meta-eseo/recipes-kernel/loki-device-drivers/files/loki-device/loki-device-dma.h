
#ifndef LOKI_DEVICE_DMA_H_
#define LOKI_DEVICE_DMA_H_

#include <stdbool.h>
#include "loki-device.h"

int LokiDevice_dma_probe(LokiDevice *self);
void LokiDevice_dma_remove(LokiDevice *self);
int LokiDevice_dma_start(LokiDevice *self);
bool LokiDevice_dma_is_streaming(LokiDevice *self);
void LokiDevice_dma_stop(LokiDevice *self);
int LokiDevice_dma_read(struct file *fd, char *buf, size_t size, loff_t *pos);
int LokiDevice_dma_mmap(struct file *fd, struct vm_area_struct *vma);

#endif
