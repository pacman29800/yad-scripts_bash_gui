# 🧰 YAD Scripts Bash GUI

**Auteur :** DPMW (pacman29800)  
**Licence :** MIT  
**Date :** 2025  

---

## 📦 Contenu du dépôt

Ce dépôt regroupe plusieurs **scripts Bash avec interface graphique YAD** pour Linux.

### 🔹 1. BD Converter (`bd_converter.sh`)
Convertit des fichiers **PDF** en **archives CBZ ou CBR** avec interface graphique.

- Conversion page par page via `pdftoppm`
- Création automatique d’archives CBZ/CBR
- Barre de progression et annulation via YAD
- Options : résolution, format image, logs, suppression du PDF original

👉 [Voir le script](./bd_converter.sh)

---

### 🔹 2. DEB Empacktor (`deb_empacktor.sh`)
Permet de créer facilement un **package Debian (.deb)** avec interface graphique YAD.

- Formulaire pour saisir les informations du package (nom, version, mainteneur, architecture)
- Sélection des binaires et création des liens symboliques
- Choix de l’icône et de la catégorie pour `.desktop`
- Option d’inclure README et LICENSE MIT automatiquement
- Génère les fichiers nécessaires dans `DEBIAN/` : `control`, `postinst`, `postrm`, quelques ajustements a faire dans les fichiers en fonction des besoins
- Création finale du `.deb` directement depuis l’interface

👉 [Voir le script](./deb_empacktor.sh)

---

## ⚙️ Dépendances communes

| Paquet | Rôle |
|:--|:--|
| `yad` | Interface graphique |
| `bash` | Interpréteur de scripts |
| `dpkg-deb` | Construction du package `.deb` |
| `zip`, `rar`, `pdftoppm` | Pour BD Converter |
| `sensors` *(optionnel)* | Pour BD Converter (lecture température CPU) |

### 🔸 Installation (Ubuntu / Debian)
```bash
sudo apt install yad bash dpkg-dev zip rar poppler-utils lm-sensors

