
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s addr\n", argv[0]);
        return -1;
    }

    int devmem = open("/dev/mem", O_RDWR);
    if (devmem < 0) {
        fprintf(stderr, "Couldn't open /dev/mem. Are you root?\n");
        return -1;
    }

    unsigned addr = 0;
    sscanf(argv[1], "%x", &addr);

    unsigned page   = addr & 0xFFFF0000;
    unsigned offset = addr & 0x0000FFFF;

    char *buffer = mmap(0, 65536, PROT_READ, MAP_SHARED, devmem, page);
    if (!buffer) {
        fprintf(stderr, "Couldn't mmap /dev/mem.\n");
        close(devmem);
        return -1;
    }

    unsigned val = *(unsigned*)(buffer + offset);

    printf("%x\n", val);

    munmap(buffer, 1);
    close(devmem);

    return 0;
}
