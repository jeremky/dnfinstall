# dnfinstall

Script automatisant l'installation et le paramétrage de Fedora.

## Fonctionnalités

- `install_packages` : met à jour le système et installe les applications présentes dans le fichier `config/<mode>/packages.cfg`

- `disable_tty1` : désactive le tty1 si c'est pour une utilisation uniquement par SSH

- `disable_sudopasswd` : désactive la demande du mot de passe pour les commandes sudo. **A NE PAS UTILISER EN PROD !**

- `configure_sshd` : crée un fichier pour `sshd` (`/etc/ssh/sshd_config.d/<user>.conf`) avec les éléments suivants :
  - Restreint l'accès à l'utilisateur principal (UID 1000)
  - Désactive le forwarding X11
  - Force l'utilisation de la clé `ed25519` uniquement
  - Limite les tentatives d'authentification à 3
  - Restreint les algorithmes aux recommandations modernes :
    - **Kex** : `curve25519-sha256`
    - **Ciphers** : `aes256-gcm`, `aes256-ctr`, `aes192-ctr`, `aes128-gcm`, `aes128-ctr`
    - **MACs** : `hmac-sha2-512-etm`, `hmac-sha2-256-etm`

> **Attention** : `PasswordAuthentication` reste activé par défaut. Penser à le désactiver dans `/etc/ssh/sshd_config.d/<user>.conf` après avoir configuré les clés SSH.

## Configuration

Un fichier de configuration sous `config/<mode>/config.cfg` permet de paramétrer l'exécution du script selon vos préférences.
Commentez les fonctions que vous ne voulez pas utiliser. Exemple avec le mode `desktop` :

```txt
# dnfinstall desktop config

install_packages

enable_locate

# disable_tty1
# disable_sudofile
# disable_sudopasswd

# configure_fail2ban
# configure_sshd

```

Avec le fichier de config se trouve un fichier contenant la liste des paquets à installer si `install_packages` est actif.

Exemple avec le fichier `config/desktop/packages.cfg` :

```txt
# dnfinstall desktop list

colordiff
curl
duf
fd-find
jetbrains-mono-nl-fonts
fzf
gnome-extensions-app
gnome-tweaks
htop
ncdu
papirus-icon-theme
ripgrep
rsync
tree
unzip
vim
zip
zoxide
```

## Utilisation

Une fois le fichier `config/<mode>/config.cfg` modifié, lancez le script avec les droits root :

```bash
sudo ./aptinstall.sh <mode>
```
