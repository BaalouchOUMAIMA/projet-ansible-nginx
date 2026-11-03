#!/bin/bash
set -e

mkdir -p /run/sshd

# Après installation de Nginx par Ansible,
# le démarrer automatiquement au redémarrage du conteneur.
if command -v nginx >/dev/null 2>&1; then
    nginx
fi

exec /usr/sbin/sshd -D
