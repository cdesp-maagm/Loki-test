
#ifndef LOKI_DEVICE_REGS_H_
#define LOKI_DEVICE_REGS_H_

#include "loki-device.h"

int LokiDevice_regs_probe(LokiDevice *self);

/** Affecter la valeur d'un registre.
 *
 * Cette fonction ne vérifie pas que le registre demandé existe.
 *
 * @param index Le numéro du registre.
 * @param value La valeur à affecter.
 * @pre index < self->reg_count
 */
void LokiDevice_set_reg(LokiDevice *self, int index, uint32_t value);

/** Lire la valeur d'un registre.
 *
 * @param index Le numéro du registre.
 * @pre index < self->reg_count
 * @return La valeur du registre.
 */
uint32_t LokiDevice_get_reg(LokiDevice *self, int index);

#endif
