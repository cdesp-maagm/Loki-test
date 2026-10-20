
#ifndef LOKI_DEVICE_IOCTL_H_
#define LOKI_DEVICE_IOCTL_H_

#ifndef __KERNEL__
    #include <stdint.h>
#else
    #include <linux/types.h>
    extern long LokiDevice_ioctl(struct file *f, unsigned cmd, unsigned long arg);
#endif

#include <linux/ioctl.h>

typedef struct {
    uint32_t reg;
    uint32_t value;
} LokiRegisterQuery;

#define LOKI_IOCTL_REG_READ            _IOR('s',  1, LokiRegisterQuery*)
#define LOKI_IOCTL_REG_WRITE           _IOWR('s', 2, LokiRegisterQuery*)
#define LOKI_IOCTL_DMA_START           _IO('s',   3)
#define LOKI_IOCTL_DMA_STOP            _IO('s',   4)
#define LOKI_IOCTL_DMA_IS_STREAMING    _IOR('s',  5, bool*)
#define LOKI_IOCTL_DMA_START_TIME      _IOR('s',  6, struct timespec*)
#define LOKI_IOCTL_DMA_PACKET_TIME     _IOR('s',  7, struct timespec*)
#define LOKI_IOCTL_DMA_DROPPED_PACKETS _IOR('s',  8, unsigned*)

#endif
