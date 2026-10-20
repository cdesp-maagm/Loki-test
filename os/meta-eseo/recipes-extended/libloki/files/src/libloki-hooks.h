/**
 * @ingroup ggLokiCommon
 * @defgroup gLokiHooks Instrumentation des fonctions malloc et free
 *
 * Ce module peut être utilisées en phase de mise au point pour identifier
 * l'origine de fuites mémoire ou de double désallocation.
 */

/// @{

#ifndef LOKI_HOOKS_H_
#define LOKI_HOOKS_H_

/// Initialiser l'utilisation des hooks instrumentés pour l'allocation/désallocation de mémoire.
void LokiHooks_init(void);

/// Restaurer les hooks d'origine pour l'allocation/désallocation de mémoire.
void LokiHooks_restore(void);

#endif

/// @file libloki-hooks.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
