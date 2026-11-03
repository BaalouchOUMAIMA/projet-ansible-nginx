#!/usr/bin/env bash
set -euo pipefail

export ANSIBLE_CONFIG="${ANSIBLE_CONFIG:-ansible.cfg}"
export ANSIBLE_SSH_PORT="${ANSIBLE_SSH_PORT:-2222}"
mkdir -p .ansible
if [ ! -f .ansible/ansible_key ]; then
    ssh-keygen -q -t ed25519 -N '' -f .ansible/ansible_key
fi
chmod 600 .ansible/ansible_key

export ANSIBLE_PUBLIC_KEY
ANSIBLE_PUBLIC_KEY="$(cat .ansible/ansible_key.pub)"
if [ -z "${ANSIBLE_VAULT_PASSWORD_FILE:-}" ]; then
    printf '%s\n' 'dev-only-password' > .ansible/vault_password
    export ANSIBLE_VAULT_PASSWORD_FILE=.ansible/vault_password
fi
trap 'docker compose down --remove-orphans' EXIT INT TERM
docker compose down --remove-orphans
docker compose up -d --build

until ssh -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes -o ConnectTimeout=2 \
    -i .ansible/ansible_key -p "$ANSIBLE_SSH_PORT" ansible@127.0.0.1 true; do
    sleep 2
done

ansible-playbook playbooks/deploy.yml -e "ansible_port=${ANSIBLE_SSH_PORT}"
second_run="$(ansible-playbook playbooks/deploy.yml -e "ansible_port=${ANSIBLE_SSH_PORT}")"
printf '%s\n' "$second_run"
grep -q 'changed=0' <<<"$second_run"
curl --fail --silent --show-error http://127.0.0.1:8082/ >/dev/null
