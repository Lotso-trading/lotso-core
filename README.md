# Lotso Core — Polymarket Trading Suite

Architecture micro-services conteneurisée et hautement typée pour le trading algorithmique et le mirroring temps réel sur Polymarket.

---

## 🏛️ Architecture du Projet

```text
lotso-core/
├── packages/
│   └── shared/              # Submodule: Contrats de types, DTOs Zod et utilitaires partagés
├── services/
│   ├── api/                 # Submodule: Backend d'entreprise sous NestJS + MongoDB optimisé
│   ├── bot/                 # Submodule: Moteur de trading haute fréquence (Clean Architecture, CLOB & Polygon)
│   └── dashboard/           # Submodule: Interface utilisateur financière en Vue 3 + Vite + Tailwind CSS
├── deno.json                # Workspace racine Deno 2 avec configuration stricte
├── biome.json               # Standard unique de formattage et de linting Biome (règle bloquante noExplicitAny)
├── docker-compose.yml       # Stack multi-services pour le développement local
├── docker-compose.swarm.yml # Stack de déploiement pour la production Docker Swarm
└── graphify-out/            # Graphe de connaissances de l'architecture logicielle
```

---

## 🚀 Démarrage Rapide & Clonage

### 1. Cloner l'écosystème complet avec ses sous-modules
```bash
git clone --recurse-submodules https://github.com/Lotso-trading/lotso-core.git
cd lotso-core
```

Si le dépôt a été cloné sans l'option `--recurse-submodules` :
```bash
git submodule update --init --recursive
```

### 2. Mettre à jour tous les sous-modules vers la dernière version
```bash
git submodule update --remote --merge
```

### 3. Démarrer l'infrastructure locale
```bash
cp .env.example .env
docker compose up -d --build
```

---

## ⚡ Les 5 Règles d'Or du Projet

1. **Typage Strict & Zéro `any`** : Mode strict TypeScript permanent. L'utilisation du type `any` est proscrite et bloquée au linting et à la compilation.
2. **Standard Unique Biome** : Tous les fichiers sont formatés et analysés par Biome (`biome check .`).
3. **Base de Données Optimisée** : Schémas MongoDB indexés sur les requêtes fréquentes (wallets cibles, statut, timestamp) avec pipelines d'agrégation natifs.
4. **Clean Code & Architecture Hexagonale** : Séparation stricte *Domain / Application / Infrastructure / Interfaces*.
5. **Cartographie Graphify** : Graphe relationnel automatisé permettant d'auditer et d'explorer les dépendances du système.

---

## 🚀 Commandes Rapides

```bash
# Vérifier le code et les types avec Biome
deno task lint

# Formater l'ensemble du monorepo avec Biome
deno task format

# Vérifier la compilation TypeScript de tous les fichiers
deno task check

# Démarrer l'environnement local complet (MongoDB + API + Bot + Dashboard)
deno task docker:dev

# Arrêter l'environnement local
deno task docker:down
```

Consultez les fichiers `SPEC.md` dédiés dans chaque sous-dossier pour le plan détaillé de chaque composant :
- [`packages/shared/SPEC.md`](./packages/shared/SPEC.md)
- [`services/api/SPEC.md`](./services/api/SPEC.md)
- [`services/bot/SPEC.md`](./services/bot/SPEC.md)
- [`services/dashboard/SPEC.md`](./services/dashboard/SPEC.md)
