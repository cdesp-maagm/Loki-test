/**
 * @ingroup ggLokiCommon
 * @defgroup gLokiClass Support de structures de données avec polymorphisme.
 *
 * Ce module fournit des macros facilitant la définition d'interfaces et de classes.
 * - Une interface est un type `struct` qui déclare des attributs (des champs de données) et des méthodes (des pointeurs sur des fonctions).
 * - Une implémentation est une variable de ce type `struct`, dans laquelle on a affecté des valeurs aux attributs, et des fonctions aux méthodes.
 *
 * On ne fournit pas de support particulier pour créer des instances de ces classes.
 *
 * Exemple :
 *
 * ```
 * // Déclarer une interface Config.
 * LokiClass_interface(Config,
 *     LokiClass_attribute(char *category)
 *     LokiClass_method(Config, new)
 * );
 *
 * // Le type des instances de Config.
 * typedef struct {
 *     void *instance;
 *     // Les pointeurs vers les méthodes seront copiés ici pour éviter un niveau
 *     // d'indirection supplémentaire et réduire la durée d'un appel de méthode.
 *     ConfigInterface impl;
 * } Config;
 *
 * // Un constructeur de Config, qui délègue à une implémentation.
 * Config *Config_new(const ConfigInterface *impl) {
 *     printf("Création d'une configuration dans la catégorie : %s.\n", impl->category);
 *     Config *self = calloc(1, sizeof(Config));
 *     self->instance = impl->new();
 *     memcpy(&self->impl, impl, sizeof(ConfigInterface));
 *     return self;
 * }
 *
 * // Déclarer une classe UserConfig qui implémente Config.
 * // Cette ligne se place généralement dans un fichier .h
 * LokiClass_declare_implementation(Config, UserConfig)
 *
 * // Le type des instances de UserConfig.
 * typedef struct {
 *     ...
 * } UserConfig;
 *
 * // Le constructeur de UserConfig, associé à la méthode Config.new.
 * UserConfig *UserConfig_new() {
 *     UserConfig *self = calloc(1, sizeof(UserConfig));
 *     ...
 *     return self;
 * }
 *
 * // Définir l'implémentation de UserConfig.
 * LokiClass_implementation(Config, UserConfig,
 *     LokiClass_set_attribute(category, "User")
 *     LokiClass_define_method(UserConfig, new)
 * );
 *
 * int main(void) {
 *     Config *cfg = Config_new(UserConfig);
 *     ...
 * }
 * ```
 */

/// @{

#ifndef LIBLOKI_CLASS_H_
#define LIBLOKI_CLASS_H_

#include "libloki-common.h"

/** Construit un nom d'interface pour le préfixe donné.
 *
 * @param prefix Le nom de base de l'interface.
 *
 * Exemple :
 * ```
 * LokiClass_interface_name(Config) // --> ConfigInterface
 * ```
 */
#define LokiClass_interface_name(prefix) CAT(prefix, Interface)

/** Construit un nom de classe pour le préfixe donné.
 *
 * @param prefix Le nom de base de la classe.

 * Exemple :
 * ```
 * LokiClass_class_name(UserConfig) // --> UserConfigClass
 * ```
 */
#define LokiClass_class_name(prefix) CAT(prefix, Class)

/** Construit un nom de fonction pour une méthode d'une classe.
 *
 * @param prefix Le nom de base de l'interface ou de la classe.
 * @param name Le nom de la méthode.
 *
 * Exemple :
 * ```
 * LokiClass_function_name(Config, new) // --> Config_new
 * ```
 */
#define LokiClass_function_name(prefix, name) CAT3(prefix, _, name)

/** Déclare une interface.
 *
 * @param prefix Le nom de base de l'interface.
 * @param methods Les attributs ou méthodes déclarées dans cette interface.
 */
#define LokiClass_interface(prefix, methods) \
    typedef struct {                         \
        methods                              \
    } LokiClass_interface_name(prefix)

/** Dans une interface, déclare un attribut.
 *
 * Un attribut est un champ qui sera affecté dans la structure qui décrit
 * une classe (voir #LokiClass_implementation).
 *
 * @param decl Une déclaration de champ, sans `;` terminal.
 */
#define LokiClass_attribute(decl) \
    decl;

/** Dans une interface, déclare une méthode.
 *
 * @param prefix Le nom de base de l'interface.
 * @param name Le nom de la méthode.
 */
#define LokiClass_method(prefix, name) \
    typeof(LokiClass_function_name(prefix, name)) *name;

/** Déclare une classe qui implémente une interface donnée.
 *
 * @param superclass Le nom de base de l'interface.
 * @param prefix Le nom de base de la classe.
 */
#define LokiClass_declare_implementation(superclass, prefix) \
    extern LokiClass_interface_name(superclass) LokiClass_class_name(prefix)

/** Définit le contenu d'une classe qui implémente une interface donnée.
 *
 * @param superclass Le nom de base de l'interface.
 * @param prefix Le nom de base de la classe.
 * @param impls Les affectations d'attributs et de méthodes qui implémentent l'interface.
 */
#define LokiClass_implementation(superclass, prefix, impls)               \
    LokiClass_interface_name(superclass) LokiClass_class_name(prefix) = { \
        impls                                                             \
    }

/** Dans une implémentation, affecte une valeur à un attribut.
 *
 * @param name Le nom de l'attribut.
 * @param value La valeur de l'attribut.
 */
#define LokiClass_set_attribute(name, value) \
    .name = value,

/** Dans une implémentation, associe une fonction à une méthode.
 *
 * @param prefix Le nom de base de la classe.
 * @param name Le nom de la méthode.
 */
#define LokiClass_define_method(prefix, name) \
    .name = (typeof(LokiClass_class_name(prefix).name))LokiClass_function_name(prefix, name),

#endif

/// @file libloki-class.h
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
