
Préparation
===========

Cloner ce dépôt et ses sous-modules :

```
git clone --recurse-submodules <URL de ce dépôt> Loki-firmware
```

Installer les outils nécessaires à la construction sous Debian ou Ubuntu :

```
sudo apt install wget git-core unzip \
     gcc-multilib build-essential socat cpio \
     python3 python3-pip python3-pexpect \
     python3-scipy python3-pandas python3-matplotlib \
     xz-utils debianutils iputils-ping libsdl1.2-dev xterm \
     ghdl distrobox
```

Installer Xilinx Vivado et SDK 2018.1 avec la prise en charge des cibles Zynq-7000.
Par la suite, on supposera que ces outils sont installés dans `/opt/Xilinx`.

Une partie de la chaîne de compilation est incompatible avec les versions récentes des distributions Linux.
La construction du logiciel embarqué s'effectuera sous Ubuntu 20.04 dans un conteneur en utilisant l'outil Distrobox.
La création du conteneur s'effectue à l'aide de la commande suivante :

```
distrobox create --image quay.io/toolbx/ubuntu-toolbox:20.04 ubuntu-20.04-eseo-loki
```

Entrer dans le conteneur et installer les paquets nécessaires à la construction du firmware :

```
distrobox enter ubuntu-20.04-eseo-loki
sudo apt install install wget git-core unzip \
     gcc-multilib build-essential socat cpio \
     python3 python3-pip python3-pexpect \
     python3-scipy python3-pandas python3-matplotlib \
     xz-utils debianutils iputils-ping libsdl1.2-dev xterm \
     python2 build-essential chrpath diffstat gawk texinfo
exit
```

**Attention : le support d'Ubuntu 20.04 se termine en avril 2025.**
Au-delà de cette date :

- Un conteneur existant pourra continuer à fonctionner mais ne bénéficiera pas de mises à jour.
- La possibilité de créer un nouveau conteneur avec cette version n'est pas garantie.

Construction du système d'exploitation
======================================

Entrer dans le conteneur et définir les variables d'environnement :

```
cd Loki-firmware/os/poky
distrobox enter ubuntu-20.04-eseo-loki
. oe-init-build-env ../build/{carte}
```

Construire l'image :

```
bitbake core-image-loki-dev
```

Quitter le conteneur :

```
exit
```

Construction de la plate-forme matérielle
=========================================

Définir les variables d'environnement pour les outils Xilinx :

```
. /opt/Xilinx/Vivado/{version}/settings64.sh
. /opt/Xilinx/SDK/{version}/settings64.sh
```

Générer le bitstream et le first-stage bootloader (FSBL) pour un projet :

```
cd Loki/hdl/projects/{nom-du-projet}
make
```

La construction du FSBL utilise Eclipse. Bien qu'aucune fenêtre ne s'ouvre,
Eclipse teste la configuration d'affichage de la machine hôte et retourne une
erreur en cas de non-détection d'un serveur graphique.
Pour construire Loki sur une machine distante (à travers SSH) ou sans serveur
graphique, installer Xvfb et lancer `make` de la manière suivante :

```
xvfb-run make
```

Fichiers de démarrage sur carte SD
==================================

Formater une carte micro-SD avec au moins deux partitions :

* La première partition, au format FAT32, recevra l'image du système d'exploitation.
* La seconde, au format EXT4, servira au stockage des données d'acquisition.

La partition FAT contiendra les fichiers suivants :

| Lien                   | Description                                                               |
|:-----------------------|:--------------------------------------------------------------------------|
| `uEnv.txt`             | Le script de configuration du bootloader U-Boot                           |
| `uImage`               | Le noyau Linux                                                            |
| `uImage-{machine}.dtb` | Le fichier *device tree* binaire pour Linux                               |
| `rootfs.cpio.gz`       | Le système de fichiers à charger en RAM                                   |
| `boot.bin`             | Le First-Stage Bootloader Xilinx avec le bitstream pour le FPGA et U-Boot |

Ces fichiers sont disponibles dans le dossier `boot/{projet-carte}` à la racine de ce dépôt.
La plupart sont des liens symboliques vers les fichiers obtenus lors de la construction du
bitstream et du système d'exploitation.
