# Bot Traducteur - Azure Functions

Service de traduction de documents basé sur Azure Functions et Azure Translator.

## Structure

```
src/
├── check_status/       # Endpoint: vérifier le statut d'une traduction
├── formats/            # Endpoint: formats de fichiers supportés
├── get_result/         # Endpoint: récupérer le document traduit
├── health/             # Endpoint: health check
├── languages/          # Endpoint: langues disponibles
├── start_translation/  # Endpoint: démarrer une traduction
├── shared/             # Code partagé (services, config, utils)
├── Solution/           # Solution Power Platform (.zip)
├── images/             # Images pour la documentation
├── clients/            # Rapports d'intervention par client
└── GUIDE_POWER_PLATFORM_COMPLET.md  # Guide de déploiement
```

## Endpoints API

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/api/health` | GET | Health check |
| `/api/start_translation` | POST | Démarrer une traduction |
| `/api/check_status/{id}` | GET | Vérifier le statut |
| `/api/get_result/{id}` | GET | Récupérer le fichier traduit |
| `/api/languages` | GET | Langues supportées |
| `/api/formats` | GET | Formats supportés |

## Déploiement

Le guide complet est disponible sur : http://localhost:5545/procedure

### Ressources Azure créées

- **Resource Group**: `rg-translation-{client}`
- **Storage Account**: `sttrad{client}` (containers: `doc-to-trad`, `doc-trad`)
- **Azure Translator**: Service de traduction
- **Function App**: Application Azure Functions

### Solution Power Platform

Le fichier `Solution/BotCopilotTraducteur_1_0_0_4.zip` contient le bot Copilot Studio à importer chez le client.
