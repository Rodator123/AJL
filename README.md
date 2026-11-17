# AJL OS

Système basé sur Arch Linux : bureau KDE Plasma, navigateur Tor, Wine pour les programmes Windows.

## Mettre l'ISO sur une clé USB (Windows)

Voir `Creer-Cle-Bootable.ps1` (PowerShell en administrateur), ou utiliser Rufus / Ventoy.

## Contenu du dépôt

- `creer-profil-ajl.sh` : génère le profil archiso (paquets, identité, utilisateur live, thème)
- `.github/workflows/build-iso.yml` : construction automatique de l'ISO

## Pour modifier AJL

Édite `creer-profil-ajl.sh` (liste de paquets, réglages), puis `git push` : une nouvelle ISO est construite.

## Remarques

- Utilisateur live : `ajl`, sans mot de passe, sudo sans mot de passe. À retirer avant toute distribution.
- L'installateur (Calamares, dans l'AUR) n'est pas encore intégré : l'ISO sert pour l'instant de système live.

!##! Ceci est un projet, il n'est actuellement pas fini, merci
