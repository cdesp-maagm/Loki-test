
/// Permettre l'utilisation de la fonction `dladdr` pour connaître le nom de la fonction référencée par un pointeur.
#define _GNU_SOURCE

#include <dlfcn.h>
#include <malloc.h>
#include <stdio.h>

/// @addtogroup gLokiHooks
/// @{

/// Pointeur vers le hook qui exécute la fonction `malloc` d'origine.
static void* (*LokiHooks_saved_malloc)(size_t, const void*);

/// Pointeur vers le hook qui exécute la fonction `free` d'origine.
static void (*LokiHooks_saved_free)(void*, const void*);

static void *LokiHooks_malloc(size_t, const void*);

static void LokiHooks_free(void*, const void*);

/// Affecter les hooks des fonctions `malloc` et `free`.
static void LokiHooks_setup(void) {
    __malloc_hook = LokiHooks_malloc;
    __free_hook   = LokiHooks_free;
}

/// Sauvegarder les hooks des fonctions `malloc` et `free`.
static void LokiHooks_save(void) {
    LokiHooks_saved_malloc = __malloc_hook;
    LokiHooks_saved_free   = __free_hook;
}

void LokiHooks_restore(void) {
    __malloc_hook = LokiHooks_saved_malloc;
    __free_hook   = LokiHooks_saved_free;
}

void LokiHooks_init(void) {
    if (__malloc_hook == LokiHooks_malloc) {
        return;
    }
    LokiHooks_save();
    LokiHooks_setup();
}

/** Une version instrumentée du hook de la fonction `malloc`.
 *
 * Cette fonction alloue une région de la mémoire en utilisant la fonction `malloc`
 * d'origine, puis elle affiche des informations sur la sortie d'erreur.
 *
 * @param size La taille de la région de mémoire à allouer.
 * @param caller Un pointeur vers la fonction appelante.
 * @return Un pointeur vers la région de mémoire allouée.
 */
static void *LokiHooks_malloc(size_t size, const void *caller) {
    LokiHooks_restore();
    void *result = malloc(size);
    LokiHooks_save();

    Dl_info info;
    dladdr(caller, &info);

    // fprintf utilise peut-être malloc.
    // Ne pas restaurer les hooks avant cet appel.
    fprintf(stderr, "LokiHooks_malloc: %p (allocated %zu bytes), called by %s\n", result, size, info.dli_sname);

    LokiHooks_setup();
    return result;
}

/** Une version instrumentée du hook de la fonction `free`.
 *
 * Cette fonction libère une région de la mémoire en utilisant la fonction `free`
 * d'origine, puis elle affiche des informations sur la sortie d'erreur.
 *
 * @param ptr Un pointeur vers la région de mémoire à libérer.
 * @param caller Un pointeur vers la fonction appelante.
 */
static void LokiHooks_free(void *ptr, const void *caller) {
    LokiHooks_restore();
    free(ptr);
    LokiHooks_save();

    Dl_info info;
    dladdr(caller, &info);

    // fprintf utilise peut-être malloc.
    // Ne pas restaurer les hooks avant cet appel.
    fprintf (stderr, "LokiHooks_free: %p, called by %s\n", ptr, info.dli_sname);

    LokiHooks_setup();
}

/// @file libloki-hooks.c
/// @author Guillaume Savaton
/// @copyright ESEO
/// @}
