
obj-m := loki-device.o
loki-device-objs += loki-device-module.o loki-device-regs.o loki-device-dma.o loki-device-ioctl.o loki-device-sysfs.o
ccflags-y := -std=gnu99 -Wno-declaration-after-statement

SRC := $(shell pwd)

all:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC)

modules_install:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules_install

clean:
	rm -f *.o *~ core .depend .*.cmd *.ko *.mod.c
	rm -f Module.markers Module.symvers modules.order
	rm -rf .tmp_versions Modules.symvers
