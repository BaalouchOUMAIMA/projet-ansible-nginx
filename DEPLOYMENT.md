# Guide détaillé de déploiement

Ce guide explique comment construire le serveur Docker, le configurer avec
Ansible, déployer le site Nginx et vérifier l'idempotence.

## 1. Prérequis

Vérifier que les outils suivants sont installés :

```bash
docker --version
docker compose version
ssh -V
ansible-playbook --version
ansible-vault --version
```

Installer Ansible si nécessaire :

```bash
python3 -m pip install --user ansible-core
```

Se placer dans le dépôt :

```bash
cd /workspaces/projet-ansible-nginx
```

## 2. Architecture utilisée

Le projet utilise un conteneur Docker Ubuntu 24.04 comme serveur web :

- utilisateur SSH : `ansible` ;
- port SSH exposé : `2222` ;
- port Nginx dans le conteneur : `80` ;
- port HTTP sur la machine hôte : `8082` ;
- répertoire du site : `/var/www/html`.

Ansible se connecte au conteneur en SSH et applique le rôle `nginx`.

## 3. Déploiement automatique recommandé

Rendre le script exécutable :

```bash
chmod +x scripts/check-idempotence.sh
```

Lancer le déploiement complet :

```bash
./scripts/check-idempotence.sh
```

Le script :

1. configure Ansible ;
2. crée `.ansible/` ;
3. génère `.ansible/ansible_key` si nécessaire ;
4. démarre le conteneur Docker ;
5. attend la disponibilité du serveur SSH ;
6. installe Nginx ;
7. copie les fichiers du dossier `site/` ;
8. configure le serveur virtuel Nginx ;
9. relance le playbook ;
10. vérifie `changed=0` ;
11. vérifie que le site répond en HTTP.

## 4. Résoudre un conflit de port SSH

Si le port `2222` est déjà utilisé :

```bash
ANSIBLE_SSH_PORT=22022 ./scripts/check-idempotence.sh
```

Le port HTTP reste `8082`.

## 5. Déploiement manuel

Créer une clé SSH locale :

```bash
mkdir -p .ansible
ssh-keygen -t ed25519 -N '' -f .ansible/ansible_key
chmod 600 .ansible/ansible_key
```

Exporter la clé publique et démarrer le conteneur :

```bash
export ANSIBLE_PUBLIC_KEY="$(cat .ansible/ansible_key.pub)"
docker compose up -d --build
```

Tester la connexion SSH :

```bash
ssh -o StrictHostKeyChecking=accept-new \
    -o IdentitiesOnly=yes \
    -i .ansible/ansible_key \
    -p 2222 ansible@127.0.0.1
```

Créer le fichier de mot de passe Vault local :

```bash
printf '%s\n' 'mot-de-passe-vault' > .ansible/vault_password
chmod 600 .ansible/vault_password
```

Lancer Ansible :

```bash
ANSIBLE_CONFIG=ansible.cfg \
ANSIBLE_VAULT_PASSWORD_FILE=.ansible/vault_password \
ansible-playbook playbooks/deploy.yml
```

Avec un port SSH différent :

```bash
ANSIBLE_CONFIG=ansible.cfg \
ANSIBLE_VAULT_PASSWORD_FILE=.ansible/vault_password \
ansible-playbook playbooks/deploy.yml \
  -e ansible_port=22022
```

## 6. Vérifier le déploiement

Vérifier le conteneur :

```bash
docker ps
docker logs serveur-web
```

Tester la configuration Nginx :

```bash
docker exec serveur-web nginx -t
```

Tester le site :

```bash
curl http://127.0.0.1:8082/
```

Le contenu doit comporter notamment :

```text
Bienvenue sur mon serveur Web !
Ce site a été déployé automatiquement avec Ansible.
```

Dans GitHub Codespaces, ouvrir l'onglet **Ports**, repérer le port `8082` et
ouvrir son URL transférée. `127.0.0.1:8082` est l'adresse locale au Codespace.

## 7. Vérifier l'idempotence

Lancer le playbook deux fois :

```bash
ansible-playbook playbooks/deploy.yml
ansible-playbook playbooks/deploy.yml
```

La seconde exécution doit afficher :

```text
changed=0
failed=0
unreachable=0
```

Le mode de vérification est également disponible :

```bash
ansible-playbook playbooks/deploy.yml --check
```

Le script automatisé réalise cette vérification avec :

```bash
./scripts/check-idempotence.sh
```

## 8. Vérifier Ansible Vault

Vérifier l'en-tête du fichier chiffré :

```bash
head -n 1 vault/deploy-secrets.yml
```

La sortie doit commencer par :

```text
$ANSIBLE_VAULT;1.1;AES256
```

Modifier le fichier Vault :

```bash
ansible-vault edit vault/deploy-secrets.yml
```

Afficher son contenu :

```bash
ansible-vault view vault/deploy-secrets.yml
```

Ne jamais commiter :

- `.ansible/ansible_key` ;
- `.ansible/ansible_key.pub` ;
- `.ansible/vault_password` ;
- les mots de passe Vault.

## 9. Pipeline GitHub Actions

Le workflow se trouve dans `.github/workflows/deploy.yml`. Il se déclenche
sur un `push` vers `main` ou manuellement.

Ajouter dans GitHub, dans **Settings > Secrets and variables > Actions** :

### `ANSIBLE_PRIVATE_KEY`

```bash
cat .ansible/ansible_key
```

### `ANSIBLE_PUBLIC_KEY`

```bash
cat .ansible/ansible_key.pub
```

### `VAULT_PASSWORD`

Le mot de passe utilisé pour Ansible Vault.

Pour lancer le pipeline manuellement :

1. ouvrir l'onglet **Actions** ;
2. choisir **Deploy Nginx** ;
3. cliquer sur **Run workflow** ;
4. sélectionner `main` ;
5. confirmer avec **Run workflow**.

## 10. Validation avant livraison

Vérifier la syntaxe Ansible :

```bash
ANSIBLE_CONFIG=ansible.cfg \
ANSIBLE_VAULT_PASSWORD_FILE=.ansible/vault_password \
ansible-playbook --syntax-check playbooks/deploy.yml
```

Vérifier les espaces et erreurs de format :

```bash
git diff --check
```

Vérifier l'état Git :

```bash
git status --short
```

## 11. Arrêter l'environnement

Arrêter le conteneur :

```bash
docker compose down
```

Arrêter et supprimer les ressources orphelines :

```bash
docker compose down --remove-orphans
```

## 12. Démonstration finale

Pour présenter le projet :

```bash
./scripts/check-idempotence.sh
curl http://127.0.0.1:8082/
```

Expliquer que Docker simule le serveur, qu'Ansible installe et configure Nginx,
que le site est copié automatiquement et que `changed=0` prouve l'idempotence.
