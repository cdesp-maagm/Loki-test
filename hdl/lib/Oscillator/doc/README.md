
Le module `Oscillator` est un générateur de sinusoïdes en quadratures.
Il fonctionne au moyen d'une table de correspondance qui contient des valeurs
échantillonées de la fonction sinus sur l'intervalle de 0 à π/2 inclus.

Construction de la table de correspondance
==========================================

La table de correspondance est statique. Pour une fréquence d'échantillonnage
$F_s$ et une longueur de table $L$, elle est constituée des valeurs suivantes :

$$
\sin\left(\frac{\pi}{2} \times \frac{n}{L - 1}\right) \text{ pour } 0 \le n < L
$$

La fréquence minimale des oscillations est :

$$
F_{min} = \frac{F_s}{4 (L - 1)}
$$

Pour augmenter la fréquence des oscillations, il suffit de parcourir la table
par pas de $s$, avec $s < L$.
La fréquence des oscillations est proportionnelle à $F_{min}$ :

$$
F(s) = s \times F_{min}
$$

La fréquence maximale des oscillations est :

$$
F_{max} = (L-1) \times F_{min} = \frac{F_s}{4}
$$

Relation entre la taille de la table de correspondance, la précision et le bruit
================================================================================

La table de correspondance stocke les valeurs des échantillons en virgule fixe.
La taille maximale utile de la table correspond au cas où la différence maximale entre
deux échantillons consécutifs est égale à la précision du format des échantillons.

Pour $P$ bits après la virgule et avec une table de correspondance de taille $L_{max}$,
on cherche à avoir la plus petite variation là où la sinusoïde a la plus grande pente :

$$
0,5 < 2^P \times \sin\left(\frac{\pi}{2} \times \frac{1}{L_{max} - 1}\right) \le 1
$$

On peut au contraire souhaiter que la table ne contienne pas de doublon.
Avec une table de taille $L_{min}$, on cherche à avoir la plus petite variation
là où la sinusoïde a la plus petite pente :

$$
0,5 < 2^P \times \Big(1 - \cos\left(\frac{\pi}{2} \times \frac{1}{L_{min} - 1}\right)\Big) \le 1
$$

Le tableau ci-dessous donne les tailles de tables pour différentes précisions
allant de 8 à 24 bits après la virgule :

| $P$ | $L_{min}$ | L_{max}  |
|:----|:----------|:---------|
| 8   | 18        | 404      |
| 9   | 26        | 806      |
| 10  | 36        | 1610     |
| 11  | 51        | 3218     |
| 12  | 72        | 6435     |
| 13  | 101       | 12869    |
| 14  | 143       | 25737    |
| 15  | 202       | 51473    |
| 16  | 285       | 102945   |
| 17  | 403       | 205889   |
| 18  | 569       | 411776   |
| 19  | 805       | 823551   |
| 20  | 1138      | 1647101  |
| 21  | 1609      | 3294200  |
| 22  | 2275      | 6588399  |
| 23  | 3217      | 13176796 |
| 24  | 4550      | 26353591 |

Lorsque la table de correspondance est grande, le circuit produit pourra être
volumineux. Si la fréquence d'échantillonnage est suffisamment petite par
rapport à la fréquence d'horloge, il peut être plus efficace d'utiliser
un oscillateur basé sur le module CORDIC.
