# 📘 BD Converter – PDF → CBZ/CBR

**Auteur :** DPMW (pacman29800)  
**Version :** 1.0.0  
**Licence :** MIT  
**Date :** 2025  

---

## 🧩 Description

**BD Converter** est un script **Bash graphique** utilisant **YAD** (Yet Another Dialog) pour convertir des fichiers **PDF** en **archives CBZ ou CBR**, formats utilisés pour les bandes dessinées numériques.

L’application gère la conversion page par page, le renommage automatique, la création d’archives, et affiche une **barre de progression graphique** avec possibilité d’annulation.

---

## ⚙️ Dépendances

Avant utilisation, installe les paquets suivants :

| Paquet | Rôle |
|:--|:--|
| `yad` | Interface graphique |
| `pdftoppm`, `pdfinfo` | Conversion et info sur les PDF |
| `zip` | Création d’archives CBZ |
| `rar` | Création d’archives CBR |
| `sensors` | Contrôle de la température CPU |

### 🔸 Installation (Ubuntu / Debian)
```bash
sudo apt install yad poppler-utils zip rar lm-sensors
