
obj-m := loki-env-sensors.o
loki-env-sensors-objs += loki-env-sensors-module.o loki-env-sensors-sysfs.o
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
