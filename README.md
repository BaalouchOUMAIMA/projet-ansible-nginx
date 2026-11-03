# Projet Ansible Nginx

Projet d'automatisation d'un serveur web Nginx avec Ansible et Docker.

## Architecture cible

L'architecture comporte un serveur web (le conteneur `serveur-web`) basé sur
Ubuntu 24.04. Ansible s'y connecte en SSH sur le port 2222 et installe Nginx.
Le port HTTP 80 du conteneur est publié sur le port 8082 de la machine hôte.
Le dépôt contient le site statique, l'inventaire, un rôle Nginx et un pipeline
de déploiement.

## Démarrage local

Le script suivant construit le conteneur, prépare une clé SSH locale, déploie
le site et vérifie l'idempotence :

```bash
./scripts/check-idempotence.sh
curl http://127.0.0.1:8082
```

La seconde exécution du playbook doit afficher `changed=0`.
Si le port SSH 2222 est déjà utilisé, lancer le script avec
`ANSIBLE_SSH_PORT=22022`.

## Organisation Ansible

- `inventory/hosts.ini` : inventaire du serveur web ;
- `playbooks/deploy.yml` : point d'entrée du déploiement ;
- `roles/nginx/` : installation, configuration et déploiement du site ;
- `site/` : contenu statique ;
- `vault/deploy-secrets.yml` : variables chiffrées avec Ansible Vault.

Pour remplacer le mot de passe de démonstration par un vrai secret :

```bash
ansible-vault edit vault/deploy-secrets.yml
```

Le mot de passe ne doit jamais être commité. Le pipeline utilise les secrets
GitHub `ANSIBLE_PRIVATE_KEY` et `VAULT_PASSWORD`.

## Pipeline

Le workflow `.github/workflows/deploy.yml` se déclenche sur `main` ou
manuellement. Il installe Ansible, prépare les identifiants, démarre Docker,
déploie le site et vérifie l'idempotence.