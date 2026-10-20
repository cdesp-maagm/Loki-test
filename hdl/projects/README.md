
Liste des projets présents dans ce dossier
==========================================

Ce dossier contient plusieurs variantes du firmware du FPGA de Loki.
Ces variantes correspondent généralement à des configurations du matériel.

Type de firmware
----------------

Nom        | Description
-----------|------------
`Loki`     | Le firmware complet de l'interrogateur
`LokiStub` | Un firmware minimal de démonstration


Module ou carte Zynq-7000
-------------------------

Nom             | Description
----------------|------------
`microzed-7010` | Carte Loki avec module Microzed 7010
`microzed-7020` | Carte Loki avec module Microzed 7020
`redpitaya`     | Carte Redpitaya STEM-125-14
`zedboard`      | Carte ZedBoard

Nombre de voies
--------------------

Nom  | Description
-----|------------
`x2` | 2 voies optiques
`x4` | 4 voies optiques
`x8` | 8 voies optiques

Interface des capteurs d'environnement
--------------------------------------

Nom        | Description
-----------|------------
`+ltc2325` | Convertisseur analogique/numérique LTC2325
`+ds1820`  | Capteurs de température DS1820 (One-Wire)
`+ltc2984` | Interface pour capteurs de températures (SPI)


Version du prototype
--------------------

Nom  | Description
-----|------------
`v1` | Les affectations des broches du DAC AD9767 tiennent compte d'une erreur d'empreinte sous Altium
`v2` | Rétablissement des affectations de broches du DAC AD9767 après correction du routage
`v3` | Version à 8 voies avec capteur de pression BMP390 (SPI)

