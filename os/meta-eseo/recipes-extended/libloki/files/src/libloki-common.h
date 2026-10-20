/// @defgroup ggLokiCommon Définitions communes
/// @{

/// @defgroup gLokiCommon Macros utiles.
/// @{

#ifndef LIBLOKI_COMMON_H_
#define LIBLOKI_COMMON_H_

/** Retourner le nombre d'éléments d'un tableau.
 *
 * @param a Un tableau alloué statiquement.
 * @return Le nombre d'éléments dans a.
 */
#define LEN(a) (sizeof(a) / sizeof(a[0]))

/** Concaténer deux identifiants.
 *
 * @param a Le préfixe.
 * @param b Le suffixe.
 * @return Un identifiant construit à partir de a et b.
 */
#define CAT(a, b) a##b

/** Concaténer deux identifiants en insérant un séparateur.
 *
 * @param a Le préfixe.
 * @param b Le séparateur.
 * @param c Le suffixe.
 * @return Un identifiant construit à partir de a, b et c.
 */
#define CAT3(a, b, c) a##b##c

#endif

/// @}
/// @}

/// @ingroup gLokiCommon
/// @file libloki-common.h
/// @author Guillaume Savaton
/// @copyright ESEO
