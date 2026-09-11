#!/bin/bash

# Messages en couleur
error() { echo -e "\033[0;31m❯ $*\033[0m"; }
message() { echo -e "\033[0;36m──────────\033[0m\n\033[0;32m❱ $*\033[0m"; }
warning() { echo -e "\033[0;33m❱ $*\033[0m\n\033[0;36m──────────\033[0m"; }

# Vérification de l'OS :
if ! command -v dnf >/dev/null; then
  error "Ce script nécessite dnf (Fedora)"
  exit 1
fi

# Vérification des droits root
if [[ "$EUID" -ne 0 ]]; then
  error "Droits root nécessaires"
  exit 1
fi

# Fonctions
install_packages() {
  warning "Mise à jour des paquets"
  dnf -y upgrade || { error "Problème lors de la mise à jour des paquets"; }
  if [[ -f "$list" ]]; then
    warning "Installation des paquets"
    grep -v -e '#' -e '^$' "$list" | xargs dnf -y install || {
      error "Problème lors de l'installation des paquets"
    }
    message "Installation des paquets terminée"
    echo
  fi
}

enable_flathub() {
  warning "Activation de Flathub..."
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || {
    error "Problème lors de l'activation de Flathub"
  }
  message "Flathub activé"
  echo
}

disable_tty1() {
  warning "Désactivation du tty1..."
  systemctl disable getty@tty1 || {
    error "Problème lors de la désactivation du tty1"
  }
  message "tty1 désactivé"
  echo
}

disable_sudopasswd() {
  warning "Désactivation du mot de passe pour les utilisateurs sudo..."
  echo "%wheel ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/010_nopasswd || {
    error "Problème lors de la configuration de sudo"
  }
  chmod 440 /etc/sudoers.d/010_nopasswd || {
    error "Problème lors de la configuration des permissions sudo"
  }
  message "Mot de passe sudo désactivé"
  echo
}

configure_sshd() {
  if [[ ! -d /etc/ssh/sshd_config.d ]]; then
    error "SSH n'est pas installé"
    return 1
  fi
  warning "Sécurisation de SSH"
  user=$(id -un 1000)
  tee "/etc/ssh/sshd_config.d/$user.conf" <<EOF
# Secure Config
X11Forwarding no
AllowUsers $user
HostKey /etc/ssh/ssh_host_ed25519_key
PasswordAuthentication yes
KbdInteractiveAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
Ciphers aes256-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-gcm@openssh.com,aes128-ctr
EOF
  systemctl restart sshd || {
    error "Problème lors du redémarrage de SSH"
    exit 1
  }
  message "SSH sécurisé. Modifiez le fichier /etc/ssh/sshd_config.d/$user.conf pour désactiver la connexion par mot de passe après avoir importé votre clé ed25519"
  echo
}

# Exécution
dir="$(dirname "$0")/config"
cfg="$dir/config.cfg"
list="$dir/packages.cfg"
if [[ ! -f "$cfg" ]] || [[ ! -f "$list" ]]; then
  error "Fichier $cfg ou $list introuvable"
  exit 1
fi
echo
while read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  if declare -f "$line" >/dev/null; then
    "$line"
  else
    error "Aucune fonction ne correspond au paramètre $line"
    exit 1
  fi
done <"$cfg"
