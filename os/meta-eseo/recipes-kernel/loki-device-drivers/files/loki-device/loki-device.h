
#ifndef LOKI_DEVICE_H_
#define LOKI_DEVICE_H_

#include <linux/fs.h>
#include <linux/types.h>
#include <linux/device.h>
#include <linux/cdev.h>
#include <linux/dmaengine.h>
#include <linux/semaphore.h>
#include <linux/kfifo.h>
#include <linux/time.h>

/// Le nombre de transferts DMA mémorisés.
/// Pour une fréquence d'échantillonnage de 50 kHz,
/// et une taille de transfert de 512 échantillons par voie,
/// cela correspond à 1,31 secondes.
// TODO Différencier cette valeur selon le device.
#define LOKI_DMA_PERIOD_COUNT 128

typedef struct {
    uint32_t offset;
    struct timespec ts;
} LokiDMAFIFOItem;

/// Données utilisées par le driver.
typedef struct {
    /// Numéro du périphérique caractère.
    dev_t dev_num;
    /// Périphérique.
    struct device *dev;
    /// Périphérique caractère (fichier de périphérique).
    struct device *dev_node;
    /// Périphérique caractère.
    struct cdev cdev;
    /// Le nombre de registres.
    size_t reg_count;
    /// Les registres du périphérique.
    int32_t *regs;
    /// Le canal DMA stream-to-memory-map.
    struct dma_chan *dma_channel;
    /// Le numéro du registre qui contient la taille des paquets DMA.
    size_t dma_packet_length_reg;
    /// La taille d'une donnée dans un paquet DMA.
    size_t dma_data_size;
    /// La taille d'un transfert DMA, en octets.
    size_t dma_transfer_size;
    /// La taille du buffer alloué aux transferts DMA, en octets.
    size_t dma_buffer_size;
    /// Le buffer à utiliser lors des transferts DMA.
    char *dma_buffer;
    /// L'adresse retournée par dma_alloc_coherent.
    dma_addr_t dma_alloc_handle;
    /// L'adresse retournée par dma_map_single.
    dma_addr_t dma_map_handle;
    /// L'emplacement courant pour la lecture dans le buffer DMA.
    uint32_t dma_offset;
    /// L'heure de démarrage des transferts DMA.
    struct timespec dma_start_time;
    /// L'heure du paquet en cours de lecture (par read ou mmap).
    struct timespec dma_packet_time;
    /// Le nombre de paquets passés au consommateur.
    uint32_t dma_received_packets;
    /// Le nombre de paquets perdus entre producteur et consommateur.
    uint32_t dma_dropped_packets;
    /// La durée d'attente d'un buffer DMA, en jiffies.
    long dma_timeout;
    /// Le sémaphore qui gère la FIFO entre producteur et consommateur.
    struct semaphore dma_sema;
    /// La FIFO de données entre producteur et consommateur.
    DECLARE_KFIFO(dma_fifo, LokiDMAFIFOItem, LOKI_DMA_PERIOD_COUNT);

} LokiDevice;

int LokiDevice_open(struct inode *n, struct file *f);

extern struct class *LokiDevice_class;

#endif
