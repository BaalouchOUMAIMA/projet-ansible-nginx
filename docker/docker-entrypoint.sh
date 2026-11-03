#!/bin/bash
set -e

mkdir -p /run/sshd

if [ -z "${ANSIBLE_PUBLIC_KEY:-}" ]; then
    echo "ANSIBLE_PUBLIC_KEY must contain the Ansible client's public key" >&2
    exit 1
fi

printf '%s\n' "$ANSIBLE_PUBLIC_KEY" > /home/ansible/.ssh/authorized_keys
chown ansible:ansible /home/ansible/.ssh/authorized_keys
chmod 600 /home/ansible/.ssh/authorized_keys

# Après installation de Nginx par Ansible,
# le démarrer automatiquement au redémarrage du conteneur.
if command -v nginx >/dev/null 2>&1; then
    nginx
fi

exec /usr/sbin/sshd -D
