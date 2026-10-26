# AJL OS

Système basé sur Arch Linux : bureau KDE Plasma, navigateur Tor, Wine pour les programmes Windows.

## Construire l'ISO (sans VM)

1. Crée un dépôt GitHub et envoie-y le contenu de ce dossier :
   ```
   git init
   git add .
   git commit -m "AJL: premier profil"
   git branch -M main
   git remote add origin https://github.com/TON-COMPTE/ajl.git
   git push -u origin main
   ```
2. Sur GitHub, onglet **Actions** : le workflow « Construire l'ISO AJL » se lance tout seul.
3. Une fois terminé, télécharge l'ISO dans les **artefacts** du run.
4. Pour publier une version téléchargeable : `git tag v0.1 && git push --tags`
   (l'ISO est alors attachée à une Release).

## Mettre l'ISO sur une clé USB (Windows)

Voir `Creer-Cle-Bootable.ps1` (PowerShell en administrateur), ou utilise Rufus / Ventoy.

## Contenu du dépôt

- `creer-profil-ajl.sh` : génère le profil archiso (paquets, identité, utilisateur live, thème)
- `.github/workflows/build-iso.yml` : construction automatique de l'ISO

## Pour modifier AJL

Édite `creer-profil-ajl.sh` (liste de paquets, réglages), puis `git push` : une nouvelle ISO est construite.

## Remarques

- Utilisateur live : `ajl`, sans mot de passe, sudo sans mot de passe. À retirer avant toute distribution.
- L'installateur (Calamares, dans l'AUR) n'est pas encore intégré : l'ISO sert pour l'instant de système live.
