#!/usr/bin/env bash
# creer-profil-ajl.sh
# Génère le profil archiso de l'OS "AJL" (base Arch Linux + KDE Plasma + Tor Browser).
#
# À lancer DANS une machine Arch Linux (VM), pas sous Windows :
#   bash creer-profil-ajl.sh
#   cd ajl && ./build.sh
#
# L'ISO produite se trouve dans ajl/out/

set -euo pipefail

NOM="ajl"
DOSSIER="$PWD/$NOM"

if ! command -v mkarchiso >/dev/null 2>&1; then
    echo "archiso n'est pas installé. Lance : sudo pacman -S archiso" >&2
    exit 1
fi

if [ -e "$DOSSIER" ]; then
    echo "Le dossier $DOSSIER existe déjà. Supprime-le ou renomme-le d'abord." >&2
    exit 1
fi

echo "==> Copie du profil de base (releng)"
cp -r /usr/share/archiso/configs/releng "$DOSSIER"
cd "$DOSSIER"

# ---------------------------------------------------------------------------
# 1. Identité de l'ISO
# ---------------------------------------------------------------------------
echo "==> Identité de l'ISO"
sed -i \
    -e 's|^iso_name=.*|iso_name="ajl"|' \
    -e 's|^iso_label=.*|iso_label="AJL_$(date +%Y%m)"|' \
    -e 's|^iso_publisher=.*|iso_publisher="AJL"|' \
    -e 's|^iso_application=.*|iso_application="AJL OS Live"|' \
    profiledef.sh

# ---------------------------------------------------------------------------
# 2. Paquets : bureau KDE Plasma, réseau, son, navigateur Tor
#    (Calamares est dans l'AUR : on l'ajoutera à l'étape installateur)
# ---------------------------------------------------------------------------
echo "==> Liste de paquets"
cat >> packages.x86_64 <<'EOF'

# --- AJL : bureau ---
xorg-server
plasma-desktop
sddm
konsole
dolphin
kate
plasma-nm
plasma-pa
networkmanager
pipewire-pulse
wireplumber
noto-fonts
sudo

# --- AJL : navigateur (Tor) ---
tor
torbrowser-launcher

# --- AJL : apparence ---
breeze
papirus-icon-theme
kvantum

# --- AJL : programmes Windows (Wine) ---
wine
wine-mono
wine-gecko
winetricks
EOF

# Thème par défaut pour tous les utilisateurs : sombre + icônes Papirus
mkdir -p airootfs/etc/xdg
cat > airootfs/etc/xdg/kdeglobals <<'EOF'
[General]
ColorScheme=BreezeDark

[Icons]
Theme=Papirus-Dark

[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
EOF

# ---------------------------------------------------------------------------
# 3. Nom de la machine et identité du système
# ---------------------------------------------------------------------------
echo "==> Identité du système"
echo "ajl" > airootfs/etc/hostname

cat > airootfs/etc/os-release <<'EOF'
NAME="AJL"
PRETTY_NAME="AJL OS"
ID=ajl
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;23;147;209"
EOF

# ---------------------------------------------------------------------------
# 4. Utilisateur live "ajl" (mot de passe vide) + sudo
# ---------------------------------------------------------------------------
echo "==> Utilisateur live"
echo 'ajl:x:1000:1000:AJL:/home/ajl:/bin/bash' >> airootfs/etc/passwd
echo 'ajl:x:1000:'                             >> airootfs/etc/group
echo 'ajl:!::'                                 >> airootfs/etc/gshadow
echo 'ajl::14871::::::'                        >> airootfs/etc/shadow

mkdir -p airootfs/home/ajl
mkdir -p airootfs/etc/sudoers.d
echo 'ajl ALL=(ALL:ALL) NOPASSWD: ALL' > airootfs/etc/sudoers.d/ajl

sed -i '/^file_permissions=(/a\
  ["/home/ajl"]="1000:1000:750"\
  ["/etc/sudoers.d/ajl"]="0:0:440"' profiledef.sh

# ---------------------------------------------------------------------------
# 5. Services : écran de connexion (SDDM) + réseau, démarrage en mode graphique
# ---------------------------------------------------------------------------
echo "==> Services au démarrage"
mkdir -p airootfs/etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/sddm.service \
       airootfs/etc/systemd/system/display-manager.service
ln -sf /usr/lib/systemd/system/NetworkManager.service \
       airootfs/etc/systemd/system/multi-user.target.wants/NetworkManager.service
ln -sf /usr/lib/systemd/system/graphical.target \
       airootfs/etc/systemd/system/default.target

# Connexion automatique de l'utilisateur live
mkdir -p airootfs/etc/sddm.conf.d
cat > airootfs/etc/sddm.conf.d/autologin.conf <<'EOF'
[Autologin]
User=ajl
Session=plasma
EOF

# ---------------------------------------------------------------------------
# 6. Script de construction
# ---------------------------------------------------------------------------
echo "==> Script de construction"
cat > build.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
sudo rm -rf /tmp/ajl-work
sudo mkarchiso -v -w /tmp/ajl-work -o ./out .
echo
echo "ISO générée dans : $(pwd)/out"
ls -lh ./out
EOF
chmod +x build.sh

echo
echo "Profil AJL créé dans : $DOSSIER"
echo "Étape suivante :  cd ajl && ./build.sh"
