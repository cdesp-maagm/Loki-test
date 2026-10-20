
#include <linux/fs.h>
#include <linux/uaccess.h>

#include "loki-device.h"
#include "loki-device-regs.h"
#include "loki-device-ioctl.h"
#include "loki-device-dma.h"

/** Interface ioctl
 *
 * @param f Un descripteur du fichier sur lequel la fonction ioctl est appelée.
 * @param cmd La commande à exécuter.
 * @param arg L'argument de la commande (ici un pointeur).
 * @return Un code d'erreur.
 */
long LokiDevice_ioctl(struct file *f, unsigned cmd, unsigned long arg) {
    LokiDevice *self = f->private_data;
    LokiRegisterQuery reg_query;
    bool status;
    void *arg_ptr = (void*)arg;

    switch (cmd) {
        case LOKI_IOCTL_REG_READ:
            if (copy_from_user(&reg_query, arg_ptr, sizeof(LokiRegisterQuery))) {
                return -EFAULT;
            }
            if (reg_query.reg >= self->reg_count) {
                return -EINVAL;
            }
            reg_query.value = LokiDevice_get_reg(self, reg_query.reg);
            dev_dbg(self->dev, "ioctl register read: %x -> %x\n", reg_query.reg, reg_query.value);
            if (copy_to_user(arg_ptr, &reg_query, sizeof(LokiRegisterQuery))) {
                return -EFAULT;
            }
            return 0;

        case LOKI_IOCTL_REG_WRITE:
            if (copy_from_user(&reg_query, arg_ptr, sizeof(LokiRegisterQuery))) {
                return -EFAULT;
            }
            if (reg_query.reg >= self->reg_count) {
                return -EINVAL;
            }
            LokiDevice_set_reg(self, reg_query.reg, reg_query.value);
            dev_dbg(self->dev, "ioctl register write: %x <- %x\n", reg_query.reg, reg_query.value);
            return 0;

        case LOKI_IOCTL_DMA_START:
            LokiDevice_dma_start(self);
            return 0;

        case LOKI_IOCTL_DMA_STOP:
            LokiDevice_dma_stop(self);
            return 0;

        case LOKI_IOCTL_DMA_IS_STREAMING:
            status = LokiDevice_dma_is_streaming(self);
            if (copy_to_user(arg_ptr, &status, sizeof(bool))) {
                return -EFAULT;
            }
            return 0;

        case LOKI_IOCTL_DMA_START_TIME:
            if (copy_to_user(arg_ptr, &self->dma_start_time, sizeof(struct timespec))) {
                return -EFAULT;
            }
            return 0;

        case LOKI_IOCTL_DMA_PACKET_TIME:
            if (copy_to_user(arg_ptr, &self->dma_packet_time, sizeof(struct timespec))) {
                return -EFAULT;
            }
            return 0;

        case LOKI_IOCTL_DMA_DROPPED_PACKETS:
            if (copy_to_user(arg_ptr, &self->dma_dropped_packets, sizeof(unsigned))) {
                return -EFAULT;
            }
            return 0;

        default:
            return -EINVAL;
    }

    return 0;
}

EXPORT_SYMBOL(LokiDevice_ioctl);
