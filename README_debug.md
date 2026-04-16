# bc_boilerplate.sh — Debug & Documentation

## Prérequis

- Utiliser Linux / macOS ou WSL/Git Bash sur Windows, les .sh ne fonctionnent pas sur Windows natif
- Git installé et configuré (`git config --global user.name` doit correspondre exactement au **login GitHub**)
- Une clé SSH configurée et ajoutée sur GitHub ([doc officielle](https://docs.github.com/fr/authentication/connecting-to-github-with-ssh))
- Le repo `bc_sign_<nom>` doit exister au préalable sur le GitHub
- Node.js + npm installés
- VS Code avec la commande `code` dans le PATH

---

## Utilisation

```bash
chmod +x bc_boilerplate.sh
./bc_boilerplate.sh <pseudo_Github>
```

Exemple :

```bash
./bc_boilerplate.sh Giremuu
```

---

## Note sur le mot de passe SSH

Lors du `git push`, Git utilise la clé SSH configurée. Si ta clé est protégée par une **passphrase**, le terminal te demandera de la saisir.

---

## Fonction `check_prerequisites`

Ajoutée en début de script, elle vérifie les prérequis avant toute action.

| Check | Méthode |
|---|---|
| `git` présent | `command -v git` + affiche la version |
| `node` présent | `command -v node` + affiche la version |
| `npm` présent | `command -v npm` + affiche la version |
| `code` dans le PATH | `command -v code` |
| Clé SSH présente | cherche `id_ed25519`, `id_rsa` ou `id_ecdsa` dans `~/.ssh/` |
| Connexion SSH GitHub OK | `ssh -T git@github.com` avec timeout 5s |

Si au moins un check échoue, le script liste tous les problèmes et s'arrête. Exemple de sortie :

```
🔍 Checking prerequisites...
✅ git found: git version 2.39.5
✅ node found: v22.14.0
✅ npm found: 10.9.2
✅ VS Code found
✅ SSH key found: /home/user/.ssh/id_ed25519
✅ SSH connection to GitHub OK

✅ All prerequisites OK
```

---

## Bugs corrigés dans le code

### 1. README.md jamais créé (ligne 58)

**Avant :**
```bash
echo "# BC Sign Test Code Repose of ${name}" README.md
```

**Après :**
```bash
echo "# BC Sign Test Code Repo of ${name}" > README.md
```

Le `>` de redirection était absent : le fichier `README.md` n'était jamais créé.  
De plus, correction de la faute de frappe `Repose` → `Repo`.

---

### 2. Logique de vérification incorrecte (ligne 46)

**Avant :**
```bash
if [ -z "$(git config --global user.name)" ] && [ -z "$(git config --global user.email)" ]
```

**Après :**
```bash
if [ -z "$(git config --global user.name)" ] || [ -z "$(git config --global user.email)" ]
```

Avec `&&`, l'erreur n'était levée que si les deux champs étaient vides simultanément.  
Avec `||`, elle est levée dès qu'un seul des deux a échoué (Si l'un des deux manque > Erreur)

---

### 3. Messages de commit non quotés (lignes 60 et 78)

**Avant :**
```bash
git commit -m feat/README.md
git commit -m feat/dev/basics
```

**Après :**
```bash
git commit -m "feat/README.md"
git commit -m "feat/dev/basics"
```

Fonctionnel sans guillemets ici (pas d'espaces), mais les guillemets sont obligatoires dès que le message en contient.

---

## `user.name` vs login GitHub

Le script utilise `git config --global user.name` pour construire l'URL SSH du remote :

```bash
git remote add origin git@github.com:"${username}"/bc_sign_"${name}".git
```

Si les deux diffèrent, le push échouera avec une erreur de repository introuvable

Donc le {username} = {name} = Votre pseudo Github
