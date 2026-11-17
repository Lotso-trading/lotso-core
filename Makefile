# ==============================================================================
# Makefile - Polymarket Copy-Trading Workspace
# ==============================================================================

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Couleurs pour le terminal
BLUE   := \033[0;34m
GREEN  := \033[0;32m
YELLOW := \033[1;33m
BOLD   := \033[1m
NC     := \033[0m

.PHONY: help update check-update update-check lint lint-fix format check test install dev down logs

help: ## Affiche ce menu d'aide
	@echo -e "${BOLD}Commandes disponibles :${NC}"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  ${BLUE}%-18s${NC} %s\n", $$1, $$2}'

## ==============================================================================
## Dépendances & Sécurité Chaîne d'Approvisionnement
## ==============================================================================

update: ## Met à jour les dépendances (ncu -u) avec cooldown de sécurité 7 jours
	@./scripts/update-dependencies.sh

check-update: ## Vérifie les mises à jour disponibles en lecture seule (dry-run 7j cooldown)
	@./scripts/check-updates.sh

update-check: check-update ## Alias pour check-update

install: ## Synchronise les dépendances Deno et le lockfile
	@echo -e "${BLUE}▶ Synchronisation des dépendances Deno...${NC}"
	@deno install

## ==============================================================================
## Qualité de Code, Linting & Tests
## ==============================================================================

lint: ## Vérifie le format et le code avec Biome sur tous les projets
	@./scripts/lint.sh

lint-fix: ## Corrige automatiquement les erreurs de format et de linting Biome
	@./scripts/lint.sh --fix

format: lint-fix ## Alias pour lint-fix

check: ## Vérifie les types TypeScript sur tous les packages et services
	@echo -e "${BLUE}▶ Vérification des types TypeScript...${NC}"
	@deno task check

test: ## Lance la suite de tests Deno sur l'ensemble du workspace
	@echo -e "${BLUE}▶ Lancement des tests Deno...${NC}"
	@deno task test

## ==============================================================================
## Docker & Environnement Local
## ==============================================================================

dev: ## Démarre les services Docker en arrière-plan avec reconstruction
	@echo -e "${BLUE}▶ Démarrage des conteneurs Docker...${NC}"
	@docker compose up -d --build

down: ## Arrête et supprime les conteneurs Docker
	@echo -e "${BLUE}▶ Arrêt des conteneurs Docker...${NC}"
	@docker compose down

logs: ## Affiche et suit les logs de tous les conteneurs Docker
	@docker compose logs -f
