# Instructions de Deploiement - Bot Traducteur

---

# 🚨 REGLES CRITIQUES - LIRE AVANT TOUT 🚨

> **ARRETEZ-VOUS ICI** et lisez ces regles AVANT de faire quoi que ce soit.
> Ces regles sont NON NEGOCIABLES et doivent etre suivies a la lettre.
> Le non-respect de ces regles entraine des couts supplementaires ou des deploiements casses.

---

## ✅ TOUJOURS (ALWAYS)

### 1. TOUJOURS utiliser Azure Function **Flex Consumption** plan

```
--sku FC1
```

**Pourquoi ?** Le plan Consumption simple est **deprecie par Microsoft** et sera supprime.
Flex Consumption est le seul plan supporte pour les nouveaux deploiements.

**Commande correcte :**
```bash
az functionapp create \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --storage-account $STORAGE_NAME \
  --flexconsumption-location francecentral \
  --runtime python \
  --runtime-version 3.11
```

---

### 2. TOUJOURS utiliser Azure Translator SKU **F0** (gratuit)

```
--sku F0
```

**Pourquoi ?**
- **F0 = GRATUIT** (2 millions de caracteres/mois)
- **S1 = 35$/mois** ❌ JAMAIS utiliser sauf demande EXPLICITE du client

**Commande correcte :**
```bash
az cognitiveservices account create \
  --name "translator-$CLIENT_NAME" \
  --resource-group $RESOURCE_GROUP \
  --kind TextTranslation \
  --sku F0 \
  --location francecentral \
  --yes
```

---

### 3. TOUJOURS utiliser `az login --tenant <tenantid>`

```bash
az login --tenant <TENANT_ID>
```

**Pourquoi ?** Be-Cloud utilise l'**acces delegue** aux tenants clients.
Sans le parametre `--tenant`, la connexion echoue ou cible le mauvais tenant.

**Commande correcte :**
```bash
# Pour Phase 0 (tenant client)
az login --tenant "tenant-id-du-client"

# Pour Phase 1 (acces delegue Be-Cloud)
az login --tenant "tenant-id-du-client"
```

---

### 4. TOUJOURS deployer avec `func azure functionapp publish`

```bash
func azure functionapp publish $FUNCTION_APP_NAME
```

**Pourquoi ?** C'est la **seule methode de deploiement approuvee**.
Elle garantit un deploiement coherent et reproductible.

**Commande correcte :**
```bash
func azure functionapp publish $FUNCTION_APP_NAME --python
```

---

## ❌ JAMAIS (NEVER)

### 1. JAMAIS utiliser le plan Consumption simple

```
❌ --consumption-plan-location
❌ az functionapp create ... (sans --flexconsumption-location)
```

**Consequence :** Plan deprecie, deploiement non supporte.

---

### 2. JAMAIS utiliser SKU S1 pour Translator

```
❌ --sku S1
```

**Consequence :** Cout de **35$/mois** par client, inutile pour ce cas d'usage.

---

### 3. JAMAIS utiliser `az login` sans `--tenant`

```
❌ az login
❌ az login --use-device-code
```

**Consequence :** Connexion au mauvais tenant, echec de l'acces delegue.

---

### 4. JAMAIS utiliser zip deploy ou autres methodes

```
❌ az functionapp deployment source config-zip
❌ az webapp deployment
❌ deploiement manuel via portail Azure
```

**Consequence :** Deploiement inconsistant, difficile a reproduire ou debugger.

---

### 5. JAMAIS modifier les variables Azure auto-creees

```
❌ WEBSITE_CONTENTAZUREFILECONNECTIONSTRING
❌ WEBSITE_CONTENTSHARE
❌ WEBSITE_RUN_FROM_PACKAGE
❌ AzureWebJobsStorage
❌ FUNCTIONS_EXTENSION_VERSION
❌ FUNCTIONS_WORKER_RUNTIME
```

**Consequence :** Deploiement casse, necessite une **reconstruction complete**.

**Variables QUE vous pouvez modifier :** uniquement les variables d'application personnalisees
(TRANSLATOR_KEY, CLIENT_ID, STORAGE_KEY, etc.)

---

### 6. JAMAIS fournir les credentials Translator au lieu des credentials Function

```
❌ Donner TRANSLATOR_KEY pour Power Platform
❌ Donner TRANSLATOR_ENDPOINT pour Power Platform
```

**Les credentials corrects pour Power Platform sont :**
- Function URL: `https://{function-name}.azurewebsites.net/api`
- Function Key: (la cle de fonction, PAS la cle Translator)
- Container: `doc-to-trad`
- Storage Key: (la cle du Storage Account)

---

## 📋 CHECKLIST PRE-DEPLOIEMENT

Avant de commencer, verifiez :

- [ ] Vous avez lu et compris les regles TOUJOURS/JAMAIS ci-dessus
- [ ] Vous connaissez le nom du client
- [ ] Vous avez acces au tenant client (Phase 0 et 2)
- [ ] Vous avez acces delegue a la souscription Azure (Phase 1)
- [ ] Vous avez verifie qu'aucun Translator F0 n'existe deja (voir section ressources)

---

## 🛡️ VARIABLES AZURE PROTEGEES - GUIDE DETAILLE

### ⚠️ AVERTISSEMENT CRITIQUE

> **Modifier une variable auto-creee par Azure = DEPLOIEMENT CASSE**
>
> La seule solution est une **reconstruction complete** : supprimer la Function App et la recreer.
> Cela prend du temps, peut causer des interruptions de service, et necessite de reconfigurer tout.

---

### ❌ Variables a NE JAMAIS modifier (auto-creees par Azure)

Ces variables sont creees et gerees automatiquement par Azure. **Ne les touchez JAMAIS** :

| Variable | Role | Pourquoi ne pas modifier |
|----------|------|--------------------------|
| `WEBSITE_CONTENTAZUREFILECONNECTIONSTRING` | Connexion au stockage de fichiers | Casse le deploiement du code |
| `WEBSITE_CONTENTSHARE` | Nom du partage de fichiers | Perte d'acces aux fichiers de la fonction |
| `WEBSITE_RUN_FROM_PACKAGE` | Mode d'execution du package | Empeche le demarrage de la fonction |
| `AzureWebJobsStorage` | Stockage interne Azure Functions | Perte des triggers et bindings |
| `FUNCTIONS_EXTENSION_VERSION` | Version du runtime Azure Functions | Incompatibilite de version |
| `FUNCTIONS_WORKER_RUNTIME` | Type de runtime (python, node, etc.) | Echec de l'execution du code |
| `APPINSIGHTS_INSTRUMENTATIONKEY` | Cle Application Insights | Perte du monitoring (si configure) |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Connexion Application Insights | Perte du monitoring (si configure) |

**Autres patterns a eviter :**
- Toute variable commencant par `WEBSITE_*`
- Toute variable commencant par `FUNCTIONS_*`
- Toute variable commencant par `AZURE_FUNCTIONS_*`

---

### ✅ Variables que vous POUVEZ modifier (application personnalisee)

Ces variables sont les parametres de **votre application**. Vous pouvez les ajouter, modifier ou supprimer :

| Variable | Description | Quand modifier |
|----------|-------------|----------------|
| `AZURE_ACCOUNT_NAME` | Nom du Storage Account | Si le storage change |
| `AZURE_ACCOUNT_KEY` | Cle du Storage Account | Si la cle est regeneree |
| `TRANSLATOR_KEY` | Cle API Azure Translator | Si la cle est regeneree |
| `TRANSLATOR_ENDPOINT` | Endpoint Translator | Si le service change |
| `TRANSLATOR_REGION` | Region du Translator | Si le service change |
| `INPUT_CONTAINER` | Conteneur d'entree (doc-to-trad) | Configuration initiale |
| `OUTPUT_CONTAINER` | Conteneur de sortie (doc-trad) | Configuration initiale |
| `CLIENT_ID` | ID de l'App Entra | Configuration initiale |
| `SECRET_ID` | Secret de l'App Entra | Si le secret est regenere |
| `TENANT_ID` | ID du tenant client | Configuration initiale |
| `ONEDRIVE_UPLOAD_ENABLED` | Activer upload OneDrive | Configuration initiale |
| `ONEDRIVE_FOLDER` | Dossier OneDrive cible | Personnalisation client |

---

### 📝 Exemples : Modification SAFE vs UNSAFE

#### ✅ SAFE - Modifier une variable d'application

```bash
# Regenerer la cle Translator et mettre a jour
NEW_KEY=$(az cognitiveservices account keys regenerate \
  --name $TRANSLATOR_NAME \
  --resource-group $RESOURCE_GROUP \
  --key-name key1 \
  --query key1 -o tsv)

az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings "TRANSLATOR_KEY=$NEW_KEY"
```

**Resultat :** La fonction continue de fonctionner avec la nouvelle cle.

---

#### ❌ UNSAFE - Modifier une variable systeme

```bash
# ❌ NE JAMAIS FAIRE CECI
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings "AzureWebJobsStorage=nouvelle-valeur"
```

**Resultat :** La fonction ne demarre plus. Erreur "Function host is not running".

---

#### ❌ UNSAFE - Supprimer une variable systeme

```bash
# ❌ NE JAMAIS FAIRE CECI
az functionapp config appsettings delete \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --setting-names "WEBSITE_CONTENTSHARE"
```

**Resultat :** Deploiement casse. La fonction ne peut plus acceder a son code.

---

### 🔧 Comment verifier les variables actuelles

Pour voir toutes les variables d'une Function App :

```bash
az functionapp config appsettings list \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "[].{Nom:name, Valeur:value}" \
  -o table
```

Les variables systeme sont marquees avec des noms en MAJUSCULES commencant par `WEBSITE_`, `FUNCTIONS_`, ou `AzureWebJobs`.

---

### 🚨 Que faire si vous avez modifie une variable systeme ?

**Si la fonction ne demarre plus :**

1. **Ne paniquez pas** - la situation est recuperable mais prend du temps
2. **Documentez ce qui a ete modifie** (pour eviter de refaire l'erreur)
3. **Supprimez la Function App** :
   ```bash
   az functionapp delete \
     --name $FUNCTION_APP_NAME \
     --resource-group $RESOURCE_GROUP
   ```
4. **Recreez la Function App** avec les bonnes options (Flex Consumption)
5. **Redeployez le code** avec `func azure functionapp publish`
6. **Reconfigurez les variables d'application** (TRANSLATOR_KEY, etc.)

**Temps estime de recuperation :** 30-60 minutes

---

## 🔍 VERIFICATION DES RESSOURCES EXISTANTES - OBLIGATOIRE

> **⚠️ AVANT de creer une ressource Azure, TOUJOURS verifier si elle existe deja !**
>
> Ne JAMAIS creer de doublons. Reutiliser les ressources existantes quand possible.

---

### Etape 1 : Selectionner la souscription

Avant toute verification, assurez-vous d'etre sur la bonne souscription Azure :

```bash
# Lister les souscriptions disponibles
az account list --query "[].{Nom:name, ID:id, Defaut:isDefault}" -o table

# Selectionner la souscription du client
az account set --subscription "ID-de-la-souscription"

# Verifier la souscription active
az account show --query "{Nom:name, ID:id}" -o table
```

---

### Etape 2 : Verifier les Translator existants

**C'est l'etape la plus importante !** Un Translator F0 peut etre partage entre plusieurs clients.

```bash
# Lister TOUS les Translator de la souscription avec leur SKU
az cognitiveservices account list \
  --query "[?kind=='TextTranslation'].{Nom:name, SKU:sku.name, RG:resourceGroup, Region:location}" \
  -o table
```

**Interpretation des resultats :**

| Resultat | Action |
|----------|--------|
| Un Translator **F0** existe | ✅ **REUTILISER** - Ne pas en creer un nouveau |
| Un Translator **S1** existe | ⚠️ Verifier avec le client s'il veut garder S1 ou migrer vers F0 |
| Aucun Translator | ✅ Creer un nouveau avec `--sku F0` |
| Plusieurs Translator F0 | ⚠️ Choisir celui du bon Resource Group ou le plus recent |

**Si un F0 existe, recuperer ses credentials :**

```bash
# Remplacer par le nom et RG trouves ci-dessus
TRANSLATOR_NAME="nom-trouve"
RESOURCE_GROUP="rg-trouve"

TRANSLATOR_KEY=$(az cognitiveservices account keys list \
  --name $TRANSLATOR_NAME \
  --resource-group $RESOURCE_GROUP \
  --query key1 -o tsv)

TRANSLATOR_ENDPOINT=$(az cognitiveservices account show \
  --name $TRANSLATOR_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.endpoint -o tsv)

echo "TRANSLATOR_KEY: $TRANSLATOR_KEY"
echo "TRANSLATOR_ENDPOINT: $TRANSLATOR_ENDPOINT"
```

---

### Etape 3 : Verifier les Storage Accounts existants

```bash
# Lister tous les Storage Accounts
az storage account list \
  --query "[].{Nom:name, RG:resourceGroup, Region:location, Type:kind}" \
  -o table
```

**Interpretation des resultats :**

| Resultat | Action |
|----------|--------|
| Un Storage Account existe pour ce client | ✅ **REUTILISER** si possible |
| Aucun Storage Account | ✅ Creer un nouveau |
| Storage Account d'un autre projet | ⚠️ Creer un nouveau dedie au bot traducteur |

**Si reutilisation, recuperer la cle :**

```bash
STORAGE_NAME="nom-trouve"
RESOURCE_GROUP="rg-trouve"

STORAGE_KEY=$(az storage account keys list \
  --account-name $STORAGE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "[0].value" -o tsv)

echo "STORAGE_KEY: $STORAGE_KEY"
```

---

### Etape 4 : Verifier les Function Apps existantes

```bash
# Lister toutes les Function Apps
az functionapp list \
  --query "[].{Nom:name, RG:resourceGroup, Region:location, Runtime:siteConfig.linuxFxVersion}" \
  -o table
```

**Interpretation des resultats :**

| Resultat | Action |
|----------|--------|
| Une Function App "TradBot" existe | ⚠️ Verifier si c'est un deploiement existant a mettre a jour |
| Aucune Function App | ✅ Creer une nouvelle avec Flex Consumption |
| Function App avec mauvais plan | ⚠️ Supprimer et recreer avec Flex Consumption |

**Verifier le plan d'une Function App existante :**

```bash
FUNCTION_APP_NAME="nom-trouve"
RESOURCE_GROUP="rg-trouve"

az functionapp show \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "{Nom:name, Plan:appServicePlanId, State:state}" \
  -o table
```

---

### Etape 5 : Verifier les Resource Groups

```bash
# Lister les Resource Groups existants
az group list --query "[].{Nom:name, Region:location}" -o table
```

**Recommandation :** Creer un Resource Group dedie par client :
- Nom suggere : `rg-tradbot-{nom-client}`
- Region : `francecentral` (coherent avec les autres ressources)

```bash
# Creer un nouveau Resource Group si necessaire
CLIENT_NAME="nom-du-client"
RESOURCE_GROUP="rg-tradbot-$CLIENT_NAME"

az group create \
  --name $RESOURCE_GROUP \
  --location francecentral
```

---

### 📋 Resume : Quand creer vs reutiliser

| Ressource | Creer | Reutiliser |
|-----------|-------|------------|
| **Translator F0** | Si aucun F0 n'existe | Si un F0 existe deja |
| **Storage Account** | Toujours creer un nouveau dedie | Jamais (separation des donnees) |
| **Function App** | Si aucune n'existe | Jamais (deploiement specifique) |
| **Resource Group** | Si aucun dedie au client | Si un RG client existe deja |

**Regle d'or :** Le Translator F0 peut etre partage (c'est un service sans etat).
Les autres ressources doivent etre dedies au projet pour eviter les conflits.

---

## 🔑 COMPTES AZURE - COMPRENDRE LA DIFFERENCE

### Compte delegue (Be-Cloud)
- **in-the-cloud.fr** : pour les clients directs
- **becsp.onmicrosoft.com** : pour les clients partenaires
- Utilise pour : deployer les ressources Azure (Phase 1)

### Compte Admin Client
- Cree depuis le **Partner Center**
- Doit etre **Administrateur Global** du tenant client
- Utilise pour : App Entra ID (Phase 0) et Power Platform (Phase 2)

---

## 🎯 CREDENTIALS POUR POWER PLATFORM - SECTION CRITIQUE

> **⚠️ ATTENTION : Cette section est CRITIQUE**
>
> Les credentials ci-dessous sont les **SEULS** a fournir pour Power Platform.
> **NE DONNEZ PAS les credentials Translator !**

---

### ❌ CE QU'IL NE FAUT PAS DONNER (Credentials Translator)

```
❌ TRANSLATOR_KEY = xxxxx      ← NE PAS DONNER
❌ TRANSLATOR_ENDPOINT = xxxxx ← NE PAS DONNER
```

**Ces credentials sont utilises en interne par la Function App.**
Power Platform n'a PAS besoin de ces informations.

---

### ✅ CE QU'IL FAUT DONNER (Credentials Function App + Storage)

Power Platform a besoin de **4 informations** :

| Information | Format | Exemple |
|-------------|--------|---------|
| **Function URL** | `https://{nom}.azurewebsites.net/api` | `https://tradbot-client.azurewebsites.net/api` |
| **Function Key** | Cle alphanumerique (environ 50 caracteres) | `abc123...xyz789` |
| **Container Name** | Toujours `doc-to-trad` | `doc-to-trad` |
| **Storage Key** | Cle Base64 (environ 88 caracteres) | `AbCdEf...12345==` |

---

### 📋 Commandes pour recuperer les credentials

**Etape 1 : Function URL**

```bash
FUNCTION_URL=$(az functionapp show \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query defaultHostName -o tsv)

echo "Function URL: https://$FUNCTION_URL/api"
```

**Etape 2 : Function Key**

```bash
FUNCTION_KEY=$(az functionapp keys list \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query functionKeys.default -o tsv)

echo "Function Key: $FUNCTION_KEY"
```

**Etape 3 : Storage Key** (si pas deja recuperee)

```bash
STORAGE_KEY=$(az storage account keys list \
  --account-name $STORAGE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "[0].value" -o tsv)

echo "Storage Key: $STORAGE_KEY"
```

**Etape 4 : Affichage complet pour le technicien**

```bash
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         CREDENTIALS POUR POWER PLATFORM                      ║"
echo "║         (A copier pour configurer la solution)               ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  Function URL: https://$FUNCTION_URL/api"
echo "║  Function Key: $FUNCTION_KEY"
echo "║                                                              ║"
echo "║  Container:    doc-to-trad"
echo "║  Storage Key:  $STORAGE_KEY"
echo "║                                                              ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  ⚠️  NE PAS DONNER LES CREDENTIALS TRANSLATOR !              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
```

---

### 🔄 Resume visuel : Translator vs Power Platform

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARCHITECTURE DES CREDENTIALS                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   TRANSLATOR_KEY ──────────┐                                    │
│   TRANSLATOR_ENDPOINT ─────┤                                    │
│                            ▼                                    │
│                    ┌──────────────┐                             │
│                    │ FUNCTION APP │ ◄─── FUNCTION_KEY           │
│                    │  (tradbot)   │ ◄─── FUNCTION_URL           │
│                    └──────┬───────┘                             │
│                           │                                     │
│                           ▼                                     │
│                    ┌──────────────┐                             │
│                    │   STORAGE    │ ◄─── STORAGE_KEY            │
│                    │ (doc-to-trad)│ ◄─── CONTAINER_NAME         │
│                    └──────────────┘                             │
│                                                                  │
│   ═══════════════════════════════════════════════════════════   │
│                                                                  │
│   POWER PLATFORM a besoin de :                                  │
│     ✅ FUNCTION_URL + FUNCTION_KEY (pour appeler l'API)        │
│     ✅ STORAGE_KEY + CONTAINER_NAME (pour deposer les fichiers)│
│                                                                  │
│   POWER PLATFORM N'a PAS besoin de :                            │
│     ❌ TRANSLATOR_KEY (utilise en interne par la Function)     │
│     ❌ TRANSLATOR_ENDPOINT (utilise en interne)                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

> **📌 RAPPEL :** Afficher ces credentials a la fin de la **Phase 1** pour que le technicien puisse configurer Power Platform dans la **Phase 2**.

---

## ⚠️ REGLES CRITIQUES - A LIRE EN PREMIER ⚠️

### NE JAMAIS creer de ressources en double !

**AVANT de creer une ressource Azure, TOUJOURS verifier si elle existe deja :**

```bash
# Lister les Translator existants dans la souscription
az cognitiveservices account list --query "[?kind=='TextTranslation'].{Nom:name, SKU:sku.name, RG:resourceGroup}" -o table

# Lister les Storage Accounts
az storage account list --query "[].{Nom:name, RG:resourceGroup}" -o table

# Lister les Function Apps
az functionapp list --query "[].{Nom:name, RG:resourceGroup}" -o table
```

### Azure Translator : TOUJOURS utiliser F0 (gratuit) !

- **F0** = Gratuit (2M caracteres/mois)
- **S1** = Payant (~35$/mois) ❌ NE PAS UTILISER SAUF DEMANDE EXPLICITE

**Si un Translator F0 existe deja** → Reutiliser ses credentials, NE PAS en creer un nouveau !

```bash
# Recuperer les credentials d'un Translator existant
TRANSLATOR_NAME="nom-du-translator-existant"
RESOURCE_GROUP="son-resource-group"

TRANSLATOR_KEY=$(az cognitiveservices account keys list \
  --name $TRANSLATOR_NAME \
  --resource-group $RESOURCE_GROUP \
  --query key1 -o tsv)

TRANSLATOR_ENDPOINT=$(az cognitiveservices account show \
  --name $TRANSLATOR_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.endpoint -o tsv)

echo "TRANSLATOR_KEY: $TRANSLATOR_KEY"
echo "TRANSLATOR_ENDPOINT: $TRANSLATOR_ENDPOINT"
```

---

## 📋 WORKFLOW DE DEPLOIEMENT - VUE D'ENSEMBLE

Le deploiement se fait en **3 phases** avec **2 comptes Azure differents** :

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        WORKFLOW DE DEPLOIEMENT                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   PHASE 0          PHASE 1              PHASE 2                        │
│   App Entra ID     Azure Backend        Power Platform                 │
│   ─────────────    ─────────────        ─────────────                  │
│   👤 Admin Client  👤 Compte delegue    👤 Admin Client                │
│   🔧 az CLI        🔧 az CLI            🌐 NAVIGATEUR                  │
│                                                                         │
│   8 etapes         6 etapes             5 etapes                       │
│   ~15 min          ~20 min              ~10 min                        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

| Phase | Compte requis | Outil | Description |
|-------|---------------|-------|-------------|
| **Phase 0** | Admin Global du tenant CLIENT | `az CLI` | Creer l'App Entra ID pour OneDrive |
| **Phase 1** | Compte delegue Be-Cloud | `az CLI` | Deployer les ressources Azure |
| **Phase 2** | Admin du tenant CLIENT | **NAVIGATEUR** | Configurer Power Platform |

---

# ══════════════════════════════════════════════════════════════════════════
# PHASE 0 : CREATION APP ENTRA ID (OneDrive)
# ══════════════════════════════════════════════════════════════════════════

```
╔══════════════════════════════════════════════════════════════════════════╗
║  PHASE 0 - APP ENTRA ID                                                  ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  👤 COMPTE REQUIS : Admin Global du tenant CLIENT                        ║
║                                                                          ║
║  📋 OBJECTIF : Creer l'App Registration pour acceder a OneDrive         ║
║                                                                          ║
║  ⏱️  DUREE ESTIMEE : ~15 minutes                                         ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
```

> **⚠️ RAPPEL COMPTE** : Pour cette phase, vous devez etre connecte avec un compte
> **Admin Global du tenant client** (PAS le compte delegue Be-Cloud).

---

### Pourquoi cette phase ?

Les fichiers traduits sont sauvegardes dans le OneDrive des utilisateurs.
Cela necessite une App Registration Entra ID avec des permissions Microsoft Graph.

---

### Etape 0.1 : Verifier la connexion Azure

La connexion Azure a ete faite au demarrage du container (via Windows avec navigateur).
Verifier que le bon compte est connecte :

```bash
az account show --query "{Compte:user.name, Tenant:tenantId}" -o table
```

**Verification :**
- Le compte doit etre un **Admin Global** du tenant client
- Le Tenant ID doit correspondre au tenant du client

**Si le mauvais compte est connecte** : quitter le container (`exit`) et relancer `start.bat` pour changer de tenant.

---

### Etape 0.2 : Recuperer le Tenant ID

```bash
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "Tenant ID: $TENANT_ID"
```

**📝 Noter cette valeur** - elle sera necessaire en Phase 1.

---

### Etape 0.3 : Creer l'App Registration

```bash
CLIENT_NAME="nom-du-client"
APP_NAME="TradBot-OneDrive-$CLIENT_NAME"

CLIENT_ID=$(az ad app create \
  --display-name "$APP_NAME" \
  --sign-in-audience AzureADMyOrg \
  --query appId -o tsv)

echo "Client ID: $CLIENT_ID"
```

**📝 Noter le Client ID** - il sera necessaire en Phase 1.

---

### Etape 0.4 : Creer le Service Principal

```bash
az ad sp create --id $CLIENT_ID
```

---

### Etape 0.5 : Ajouter les permissions Microsoft Graph

```bash
# User.Read.All (Application permission)
az ad app permission add \
  --id $CLIENT_ID \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions df021288-bdef-4463-88db-98f22de89214=Role

# Files.ReadWrite.All (Application permission)
az ad app permission add \
  --id $CLIENT_ID \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions 01d4889c-1287-42c6-ac1f-5d1e02578ef6=Role
```

---

### Etape 0.6 : Accorder le consentement administrateur

```bash
# Attendre quelques secondes que les permissions se propagent
sleep 5

az ad app permission admin-consent --id $CLIENT_ID
```

---

### Etape 0.7 : Verification manuelle du consentement

> **⚠️ IMPORTANT** : La commande `admin-consent` peut parfois echouer silencieusement.
> Toujours verifier manuellement !

**Demander au technicien de verifier :**

1. Aller sur **https://entra.microsoft.com**
2. Menu **Applications** > **Inscriptions d'applications**
3. Cliquer sur l'application **TradBot-OneDrive-{client}**
4. Aller dans **Permissions API**
5. Verifier que les permissions ont un **check vert** ✅ (consentement accorde)
6. Si pas de check vert : cliquer sur **Accorder le consentement administrateur pour {tenant}**

---

### Etape 0.8 : Creer un secret client

```bash
CLIENT_SECRET=$(az ad app credential reset \
  --id $CLIENT_ID \
  --append \
  --display-name "TradBot-Secret" \
  --years 2 \
  --query password -o tsv)

echo "Client Secret: $CLIENT_SECRET"
```

**📝 Noter le Client Secret** - il sera necessaire en Phase 1.

---

### ✅ FIN PHASE 0 - Recapitulatif des credentials

```bash
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           FIN PHASE 0 - CREDENTIALS A NOTER                  ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  CLIENT_ID:     $CLIENT_ID"
echo "║  CLIENT_SECRET: $CLIENT_SECRET"
echo "║  TENANT_ID:     $TENANT_ID"
echo "║                                                              ║"
echo "║  ⚠️  GARDEZ CES VALEURS - Necessaires pour la Phase 1       ║"
echo "║                                                              ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  PROCHAINE ETAPE : Phase 1 avec compte DELEGUE              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
```

---

# ══════════════════════════════════════════════════════════════════════════
# PHASE 1 : DEPLOIEMENT AZURE BACKEND
# ══════════════════════════════════════════════════════════════════════════

```
╔══════════════════════════════════════════════════════════════════════════╗
║  PHASE 1 - DEPLOIEMENT AZURE                                             ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  👤 COMPTE REQUIS : Compte DELEGUE Be-Cloud                              ║
║     - in-the-cloud.fr (clients directs)                                  ║
║     - becsp.onmicrosoft.com (clients partenaires)                        ║
║                                                                          ║
║  📋 OBJECTIF : Deployer Function App, Storage, Translator               ║
║                                                                          ║
║  ⏱️  DUREE ESTIMEE : ~20 minutes                                         ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
```

> **⚠️ CHANGEMENT DE COMPTE** : Vous devez maintenant utiliser le **compte delegue**
> Be-Cloud (PAS le compte Admin client de la Phase 0).

---

### Etape 1.1 : Reconnexion avec compte delegue

**Verifier le compte actuel :**

```bash
az account show --query "{Compte:user.name, Tenant:tenantId}" -o table
```

**Verification :**
- Le compte doit etre un compte Be-Cloud (in-the-cloud.fr ou becsp.onmicrosoft.com)
- Le compte doit avoir acces delegue a la souscription Azure du client

**Si besoin de changer de compte** : quitter le container (`exit`) et relancer `start.bat`.

---

### Etape 1.2 : Verifier les ressources existantes

> **⚠️ OBLIGATOIRE** : Cette etape est CRITIQUE. Ne JAMAIS creer de ressources
> sans avoir d'abord verifie ce qui existe deja !

```bash
# 1. Lister et selectionner la souscription
az account list --query "[].{Nom:name, ID:id, Defaut:isDefault}" -o table
az account set --subscription "ID-de-la-souscription"

# 2. Verifier les Translator existants
az cognitiveservices account list \
  --query "[?kind=='TextTranslation'].{Nom:name, SKU:sku.name, RG:resourceGroup}" \
  -o table
```

**Decision :**

| Si vous voyez... | Alors... |
|------------------|----------|
| Un Translator **F0** | ✅ **REUTILISER** celui-ci → Passer a l'etape 1.4 |
| Aucun Translator | ✅ Creer un nouveau avec `--sku F0` |
| Un Translator **S1** | ⚠️ Verifier avec le client avant de continuer |

---

### Etape 1.3 : Creer les ressources Azure (seulement si necessaire)

**Translator** (seulement si aucun F0 n'existe) :

```bash
az cognitiveservices account create \
  --name "translator-$CLIENT_NAME" \
  --resource-group $RESOURCE_GROUP \
  --kind TextTranslation \
  --sku F0 \
  --location francecentral \
  --yes
```

> **⚠️ RAPPEL** : TOUJOURS utiliser `--sku F0` (gratuit).
> S1 coute **35$/mois** - Ne JAMAIS utiliser sauf demande explicite du client.

---

### Etape 1.4 : Recuperer les credentials du Translator

```bash
# Adapter TRANSLATOR_NAME au nom reel (existant ou nouvellement cree)
TRANSLATOR_KEY=$(az cognitiveservices account keys list \
  --name $TRANSLATOR_NAME \
  --resource-group $RESOURCE_GROUP \
  --query key1 -o tsv)

TRANSLATOR_ENDPOINT=$(az cognitiveservices account show \
  --name $TRANSLATOR_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.endpoint -o tsv)

echo "TRANSLATOR_KEY: $TRANSLATOR_KEY"
echo "TRANSLATOR_ENDPOINT: $TRANSLATOR_ENDPOINT"
```

---

### Etape 1.5 : Configurer les variables d'environnement

Configurer la Function App avec **toutes** les variables necessaires :

```bash
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings \
    "AZURE_ACCOUNT_NAME=$STORAGE_NAME" \
    "AZURE_ACCOUNT_KEY=$STORAGE_KEY" \
    "TRANSLATOR_KEY=$TRANSLATOR_KEY" \
    "TRANSLATOR_ENDPOINT=$TRANSLATOR_ENDPOINT" \
    "TRANSLATOR_REGION=$REGION" \
    "INPUT_CONTAINER=doc-to-trad" \
    "OUTPUT_CONTAINER=doc-trad" \
    "CLIENT_ID=$CLIENT_ID" \
    "SECRET_ID=$CLIENT_SECRET" \
    "TENANT_ID=$TENANT_ID" \
    "ONEDRIVE_UPLOAD_ENABLED=true" \
    "ONEDRIVE_FOLDER=Translated Documents"
```

> **Rappel** : `CLIENT_ID`, `CLIENT_SECRET`, et `TENANT_ID` viennent de la Phase 0.

---

### Etape 1.6 : Afficher les credentials pour Power Platform

> **⚠️ ETAPE OBLIGATOIRE** : Le technicien a besoin de ces credentials pour la Phase 2.
> Ne pas oublier de les afficher !

```bash
FUNCTION_URL=$(az functionapp show \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query defaultHostName -o tsv)

FUNCTION_KEY=$(az functionapp keys list \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query functionKeys.default -o tsv)

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║               ✅ PHASE 1 TERMINEE - CREDENTIALS                      ║"
echo "╠══════════════════════════════════════════════════════════════════════╣"
echo "║                                                                      ║"
echo "║  📋 CREDENTIALS POUR POWER PLATFORM (a copier) :                    ║"
echo "║  ─────────────────────────────────────────────────                   ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "  Function URL : https://$FUNCTION_URL/api"
echo "  Function Key : $FUNCTION_KEY"
echo "  Container    : doc-to-trad"
echo "  Storage Key  : $STORAGE_KEY"
echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║  💾 SAUVEGARDEZ CES CREDENTIALS POUR LA PHASE 2 !                   ║"
echo "╠══════════════════════════════════════════════════════════════════════╣"
echo "║                                                                      ║"
echo "║  ⚠️  NE PAS DONNER LES CREDENTIALS TRANSLATOR !                      ║"
echo "║      (TRANSLATOR_KEY et TRANSLATOR_ENDPOINT sont internes)          ║"
echo "║                                                                      ║"
echo "╠══════════════════════════════════════════════════════════════════════╣"
echo "║  PROCHAINE ETAPE : Phase 2 (dans le NAVIGATEUR)                     ║"
echo "║  👉 Ouvrir : http://localhost:5545/procedure                        ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
```

---

# ══════════════════════════════════════════════════════════════════════════
# PHASE 2 : POWER PLATFORM (NAVIGATEUR UNIQUEMENT)
# ══════════════════════════════════════════════════════════════════════════

```
╔══════════════════════════════════════════════════════════════════════════╗
║  PHASE 2 - POWER PLATFORM                                                ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  👤 COMPTE REQUIS : Admin du tenant CLIENT                               ║
║                                                                          ║
║  🌐 OUTIL : NAVIGATEUR WEB uniquement                                    ║
║                                                                          ║
║  ❌ AUCUNE COMMANDE az login NECESSAIRE                                  ║
║                                                                          ║
║  📋 OBJECTIF : Importer et configurer la solution Copilot Studio        ║
║                                                                          ║
║  ⏱️  DUREE ESTIMEE : ~10 minutes                                         ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
```

> **⚠️ PHASE 2 = DOCUMENTATION !**
>
> Cette phase se fait **UNIQUEMENT dans le navigateur**.
> Il n'y a **AUCUNE commande az CLI** a executer.
>
> 👉 **Ouvrir : http://localhost:5545/procedure**

---

### Resume des etapes manuelles

Le technicien doit suivre la documentation illustree sur `http://localhost:5545/procedure`.

**Etapes :**

1. Se connecter a **https://make.powerapps.com** avec le compte Admin du tenant client
2. Selectionner l'environnement cible
3. Importer la solution depuis `Solution/BotCopilotTraducteur_1_0_0_4.zip`
4. Configurer les connexions avec les credentials de la Phase 1 :
   - Function URL
   - Function Key
   - Container name
   - Storage Key
5. Publier le bot

---

### Credentials necessaires (de la Phase 1)

| Credential | Valeur |
|------------|--------|
| Function URL | `https://{function-name}.azurewebsites.net/api` |
| Function Key | (cle affichee en fin de Phase 1) |
| Container | `doc-to-trad` |
| Storage Key | (cle affichee en fin de Phase 1) |

> **📖 Documentation complete** : http://localhost:5545/procedure
>
> La documentation contient des captures d'ecran pour chaque etape.

---

# ══════════════════════════════════════════════════════════════════════════
# ANNEXES
# ══════════════════════════════════════════════════════════════════════════

## Variables d'environnement requises

### Azure Storage

- `AZURE_ACCOUNT_NAME` : Nom du Storage Account
- `AZURE_ACCOUNT_KEY` : Cle d'acces Storage Account

### Azure Translator

- `TRANSLATOR_KEY` : Cle API Translator
- `TRANSLATOR_ENDPOINT` : Endpoint Translator
- `TRANSLATOR_REGION` : Region (ex: francecentral)

### Containers Blob

- `INPUT_CONTAINER` : doc-to-trad (defaut)
- `OUTPUT_CONTAINER` : doc-trad (defaut)

### Microsoft Graph (OneDrive) - OBLIGATOIRE

- `CLIENT_ID` : ID de l'App Registration Entra
- `SECRET_ID` : Secret de l'App Registration
- `TENANT_ID` : ID du tenant client
- `ONEDRIVE_UPLOAD_ENABLED` : **true** (obligatoire pour sauvegarder les traductions)
- `ONEDRIVE_FOLDER` : Nom du dossier OneDrive (defaut: "Translated Documents")

---

## Permissions API requises pour l'App Entra

| Permission | Type | ID | Description |
|------------|------|-------|-------------|
| User.Read.All | Application | df021288-bdef-4463-88db-98f22de89214 | Lire les infos utilisateurs |
| Files.ReadWrite.All | Application | 01d4889c-1287-42c6-ac1f-5d1e02578ef6 | Lire/ecrire fichiers OneDrive |

---

## Documentation en ligne

La documentation est accessible a tout moment sur :

👉 **http://localhost:5545/procedure**

Elle contient :

- Guide pas-a-pas avec captures d'ecran
- Configuration Power Platform
- Import de la solution Copilot Studio

---

## 🔧 ERREURS COURANTES ET SOLUTIONS

> **📋 Reference de depannage**
>
> Cette section contient les erreurs les plus frequentes et leurs solutions.
> Consulter cette section AVANT d'escalader un probleme.

---

### Erreur 1 : Mauvais SKU selectionne (S1 au lieu de F0)

**Symptome :**
```
Le Translator a ete cree avec SKU S1 (payant) au lieu de F0 (gratuit)
```

**Consequence :** Cout de **35$/mois** inutile

**Diagnostic :**
```bash
# Verifier le SKU du Translator
az cognitiveservices account show \
  --name $TRANSLATOR_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "{Nom:name, SKU:sku.name}" -o table
```

**Solution : Supprimer et recreer avec F0**
```bash
# 1. Supprimer le Translator S1
az cognitiveservices account delete \
  --name $TRANSLATOR_NAME \
  --resource-group $RESOURCE_GROUP

# 2. Recreer avec le bon SKU (F0)
az cognitiveservices account create \
  --name $TRANSLATOR_NAME \
  --resource-group $RESOURCE_GROUP \
  --kind TextTranslation \
  --sku F0 \
  --location francecentral \
  --yes

# 3. Recuperer les nouvelles credentials
TRANSLATOR_KEY=$(az cognitiveservices account keys list \
  --name $TRANSLATOR_NAME \
  --resource-group $RESOURCE_GROUP \
  --query key1 -o tsv)

# 4. Mettre a jour la Function App
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings "TRANSLATOR_KEY=$TRANSLATOR_KEY"
```

**Prevention :** Toujours utiliser `--sku F0` lors de la creation.

---

### Erreur 2 : Mauvais plan Function App (Consumption au lieu de Flex)

**Symptome :**
```
La Function App a ete creee avec le plan Consumption simple (deprecie)
```

**Consequence :** Plan non supporte, deploiement peut echouer a l'avenir

**Diagnostic :**
```bash
# Verifier le type de plan
az functionapp show \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "{Nom:name, Plan:kind, SKU:sku}" -o table
```

**Solution : Supprimer et recreer avec Flex Consumption**
```bash
# 1. Noter les variables d'environnement actuelles
az functionapp config appsettings list \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  -o table > /tmp/appsettings-backup.txt

# 2. Supprimer la Function App
az functionapp delete \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP

# 3. Recreer avec Flex Consumption
az functionapp create \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --storage-account $STORAGE_NAME \
  --flexconsumption-location francecentral \
  --runtime python \
  --runtime-version 3.11

# 4. Reconfigurer les variables d'environnement
# (voir etape 1.5 de la Phase 1)

# 5. Redeployer le code
func azure functionapp publish $FUNCTION_APP_NAME --python
```

**Prevention :** Toujours utiliser `--flexconsumption-location` au lieu de `--consumption-plan-location`.

---

### Erreur 3 : Echec de connexion Azure (az login)

**Symptome :**
```
az login echoue ou cible le mauvais tenant
"AADSTS50020: User account from identity provider does not exist in tenant"
```

**Consequence :** Impossible de deployer sur le bon tenant

**Diagnostic :**
```bash
# Verifier le compte et tenant actuels
az account show --query "{Compte:user.name, Tenant:tenantId}" -o table
```

**Solution : Utiliser az login avec --tenant**
```bash
# 1. Se deconnecter completement
az logout

# 2. Se reconnecter avec le bon tenant
az login --tenant "TENANT_ID_DU_CLIENT"

# 3. Verifier la connexion
az account show --query "{Compte:user.name, Tenant:tenantId}" -o table

# 4. Selectionner la bonne souscription
az account set --subscription "ID-de-la-souscription"
```

**Si le probleme persiste :**
```bash
# Quitter le container
exit

# Relancer start.bat pour une nouvelle authentification
# (sur Windows, le navigateur s'ouvrira pour l'authentification)
```

**Prevention :** Toujours utiliser `az login --tenant <TENANT_ID>` pour l'acces delegue.

---

### Erreur 4 : Deploiement echoue / Function ne demarre pas

**Symptome :**
```
"Function host is not running"
"The function app is not running"
Erreur 500 lors de l'appel de l'API
```

**Consequence :** Le service de traduction ne fonctionne pas

**Diagnostic :**
```bash
# Verifier l'etat de la Function App
az functionapp show \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "{Nom:name, Etat:state, URL:defaultHostName}" -o table

# Verifier les logs
az functionapp log tail \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP
```

**Cause probable : Variable systeme modifiee**

```bash
# Lister les variables pour identifier une modification
az functionapp config appsettings list \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "[].name" -o tsv | sort
```

**Solution : Reconstruire la Function App**
```bash
# 1. Supprimer la Function App corrompue
az functionapp delete \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP

# 2. Recreer la Function App
az functionapp create \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --storage-account $STORAGE_NAME \
  --flexconsumption-location francecentral \
  --runtime python \
  --runtime-version 3.11

# 3. Reconfigurer les variables d'application
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings \
    "AZURE_ACCOUNT_NAME=$STORAGE_NAME" \
    "AZURE_ACCOUNT_KEY=$STORAGE_KEY" \
    "TRANSLATOR_KEY=$TRANSLATOR_KEY" \
    "TRANSLATOR_ENDPOINT=$TRANSLATOR_ENDPOINT" \
    "TRANSLATOR_REGION=francecentral" \
    "INPUT_CONTAINER=doc-to-trad" \
    "OUTPUT_CONTAINER=doc-trad" \
    "CLIENT_ID=$CLIENT_ID" \
    "SECRET_ID=$CLIENT_SECRET" \
    "TENANT_ID=$TENANT_ID" \
    "ONEDRIVE_UPLOAD_ENABLED=true" \
    "ONEDRIVE_FOLDER=Translated Documents"

# 4. Redeployer le code
func azure functionapp publish $FUNCTION_APP_NAME --python
```

**Prevention :** NE JAMAIS modifier les variables commencant par `WEBSITE_*`, `FUNCTIONS_*`, ou `AzureWebJobs*`.

---

### Erreur 5 : Credentials ne fonctionnent pas dans Power Platform

**Symptome :**
```
Power Platform ne peut pas se connecter a l'API
Erreur d'authentification ou "Unauthorized"
La traduction ne se lance pas
```

**Consequence :** Le bot Copilot ne peut pas utiliser le service de traduction

**Diagnostic : Verifier quels credentials ont ete fournis**

| Credential fourni | Correct ? | Commentaire |
|-------------------|-----------|-------------|
| TRANSLATOR_KEY | ❌ **NON** | C'est le credential interne de la Function |
| TRANSLATOR_ENDPOINT | ❌ **NON** | C'est le credential interne de la Function |
| FUNCTION_KEY | ✅ **OUI** | C'est la cle pour appeler l'API |
| FUNCTION_URL | ✅ **OUI** | C'est l'URL de l'API |
| STORAGE_KEY | ✅ **OUI** | Pour deposer les fichiers |

**Solution : Recuperer les BONS credentials**
```bash
# 1. Function URL (l'URL de l'API)
FUNCTION_URL=$(az functionapp show \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query defaultHostName -o tsv)
echo "Function URL: https://$FUNCTION_URL/api"

# 2. Function Key (la cle pour authentifier les appels)
FUNCTION_KEY=$(az functionapp keys list \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query functionKeys.default -o tsv)
echo "Function Key: $FUNCTION_KEY"

# 3. Storage Key
STORAGE_KEY=$(az storage account keys list \
  --account-name $STORAGE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "[0].value" -o tsv)
echo "Storage Key: $STORAGE_KEY"

# 4. Container (toujours le meme)
echo "Container: doc-to-trad"
```

**Dans Power Platform, configurer :**

| Champ | Valeur |
|-------|--------|
| API URL | `https://{function-name}.azurewebsites.net/api` |
| API Key | La **Function Key** (PAS la Translator Key !) |
| Container | `doc-to-trad` |
| Storage Key | La cle du Storage Account |

**Prevention :** Consulter la section "Credentials pour Power Platform" et le diagramme d'architecture.

---

### 📋 Resume rapide des erreurs

| Erreur | Cause | Solution rapide |
|--------|-------|-----------------|
| SKU S1 au lieu de F0 | Mauvaise commande | Supprimer + recreer avec `--sku F0` |
| Plan Consumption | Commande obsolete | Supprimer + recreer avec `--flexconsumption-location` |
| Login echoue | Mauvais tenant | `az login --tenant <TENANT_ID>` |
| Function ne demarre pas | Variable systeme modifiee | Supprimer + recreer + redeployer |
| Credentials Power Platform | Mauvais credentials | Utiliser Function Key, pas Translator Key |

---

### ⏱️ Temps de resolution estime

| Erreur | Temps estime |
|--------|--------------|
| SKU S1 → F0 | 5-10 minutes |
| Plan → Flex Consumption | 20-30 minutes |
| Login echoue | 5 minutes |
| Function corrompue | 30-60 minutes |
| Mauvais credentials | 5 minutes |

---

## 📄 RAPPORT DE DEPLOIEMENT - TEMPLATE

> **⚠️ IMPORTANT : Generer un rapport apres chaque deploiement**
>
> Le rapport documente le deploiement pour reference future.
> **NE JAMAIS inclure de credentials, cles API, ou Tenant IDs dans le rapport !**

---

### Instructions pour generer le rapport

1. **Creer le dossier client** (si n'existe pas) :
   ```bash
   mkdir -p clients/{nom-client}
   ```

2. **Creer le fichier rapport** avec la date :
   ```bash
   # Format: deployment-YYYY-MM-DD.md
   touch clients/{nom-client}/deployment-$(date +%Y-%m-%d).md
   ```

3. **Copier le template** ci-dessous et remplir les informations

---

### Template de rapport

```markdown
# Rapport de Deploiement - Bot Traducteur

## Informations Generales

| Champ | Valeur |
|-------|--------|
| **Client** | {NOM_DU_CLIENT} |
| **Date de deploiement** | {YYYY-MM-DD} |
| **Heure de deploiement** | {HH:MM} |
| **Technicien** | {NOM_DU_TECHNICIEN} |
| **Statut** | ✅ Succes / ❌ Echec |

---

## Ressources Azure Creees

| Ressource | Nom | Resource Group | Region |
|-----------|-----|----------------|--------|
| Resource Group | {rg-tradbot-client} | - | francecentral |
| Storage Account | {storageaccount} | {rg-tradbot-client} | francecentral |
| Function App | {functionapp} | {rg-tradbot-client} | francecentral |
| Translator | {translator} (F0) | {rg-tradbot-client} | francecentral |
| App Registration | TradBot-OneDrive-{client} | - | - |

---

## Checklist des Phases

### Phase 0 : App Entra ID
- [ ] App Registration creee
- [ ] Permissions Microsoft Graph ajoutees
- [ ] Consentement administrateur accorde
- [ ] Secret client cree

### Phase 1 : Azure Backend
- [ ] Ressources existantes verifiees
- [ ] Resource Group cree/identifie
- [ ] Storage Account cree
- [ ] Containers blob crees (doc-to-trad, doc-trad)
- [ ] Function App creee (Flex Consumption)
- [ ] Translator F0 cree/reutilise
- [ ] Variables d'environnement configurees
- [ ] Code deploye avec `func publish`
- [ ] Credentials Power Platform affiches

### Phase 2 : Power Platform
- [ ] Solution importee
- [ ] Connexions configurees
- [ ] Bot publie
- [ ] Test de traduction reussi

---

## Notes de Deploiement

{Ajouter ici toute note pertinente : problemes rencontres, solutions appliquees, particularites du client, etc.}

---

## Verification Post-Deploiement

- [ ] API Function App repond (test curl)
- [ ] Upload de fichier fonctionne
- [ ] Traduction fonctionne
- [ ] Fichier traduit apparait dans OneDrive

---

**Rapport genere le :** {DATE}
**Par :** {TECHNICIEN}
```

---

### ⚠️ Rappel : Informations a NE PAS inclure

Le rapport ne doit **JAMAIS** contenir :

| Information | Pourquoi |
|-------------|----------|
| ❌ `TRANSLATOR_KEY` | Credential sensible |
| ❌ `STORAGE_KEY` | Credential sensible |
| ❌ `FUNCTION_KEY` | Credential sensible |
| ❌ `CLIENT_SECRET` | Credential sensible |
| ❌ `TENANT_ID` | Information sensible du client |
| ❌ Mots de passe | Securite |
| ❌ Tokens d'acces | Securite |

**Le rapport doit contenir UNIQUEMENT :**
- Noms des ressources (pas les cles)
- Dates et heures
- Statuts (succes/echec)
- Notes de deploiement (sans credentials)

---

### Emplacement du rapport

```
trad-bot-src/
├── clients/
│   ├── client-alpha/
│   │   ├── deployment-2026-01-15.md
│   │   └── deployment-2026-01-20.md
│   ├── client-beta/
│   │   └── deployment-2026-01-16.md
│   └── ...
├── CLAUDE.md
└── ...
```

> **Note** : Le dossier `clients/` est **TRACKE par git** (les rapports de deploiement sont securitaires).
> Seuls les fichiers sensibles dans `clients/` sont ignores (voir section `.gitignore` ci-dessous).

---

## 🔒 CONFIGURATION .GITIGNORE - SECURITE DES CREDENTIALS

> **⚠️ IMPORTANT : Le fichier `.gitignore` protege contre les commits accidentels de credentials**
>
> NE JAMAIS modifier cette configuration sans comprendre les implications.

---

### Fichiers exclus (JAMAIS commites)

Le `.gitignore` exclut automatiquement les fichiers sensibles :

| Pattern | Description | Exemple |
|---------|-------------|---------|
| `.env*` | Fichiers d'environnement | `.env`, `.env.local`, `.env.production` |
| `credentials.*` | Fichiers de credentials | `credentials.json`, `credentials.yaml` |
| `*secret*` | Tout fichier contenant "secret" | `client-secret.txt`, `my-secrets.json` |
| `*.key` | Fichiers de cles | `api.key`, `storage.key` |
| `*.pem`, `*.pfx`, `*.p12` | Certificats | `certificate.pem` |
| `local.settings.json` | Config locale Azure Functions | (genere automatiquement) |

---

### Fichiers TRACKES (peuvent etre commites)

| Fichier/Dossier | Pourquoi | Contenu attendu |
|-----------------|----------|-----------------|
| `clients/*/deployment-*.md` | Rapports de deploiement | **Noms de ressources UNIQUEMENT** (pas de credentials) |
| `CLAUDE.md` | Instructions de deploiement | Documentation (pas de credentials) |
| `docs/` | Documentation projet | Guides, architecture, etc. |

---

### Verification de la configuration

Pour verifier que `.gitignore` fonctionne correctement :

```bash
# Lister les fichiers qui seraient commites
git status

# Verifier qu'un fichier est bien ignore
git check-ignore -v chemin/vers/fichier

# Exemple : verifier qu'un fichier .env est ignore
echo "test" > .env.test
git check-ignore -v .env.test
# Doit afficher: .gitignore:XX:.env*  .env.test
rm .env.test
```

---

### ⚠️ Si vous trouvez un fichier sensible non ignore

1. **NE PAS COMMITER** le fichier
2. Ajouter le pattern au `.gitignore`
3. Si deja commite par erreur :
   ```bash
   # Retirer du suivi git (garde le fichier local)
   git rm --cached chemin/vers/fichier-sensible

   # Ajouter au .gitignore
   echo "chemin/vers/fichier-sensible" >> .gitignore

   # Commiter la suppression du suivi
   git add .gitignore
   git commit -m "Remove sensitive file from tracking"
   ```

---

### Dossier clients/ : Regles speciales

Le dossier `clients/` est **TRACKE** mais avec des exclusions :

```
clients/                          ✅ Tracke (dossier)
├── client-alpha/                 ✅ Tracke (dossier)
│   ├── deployment-2026-01-15.md  ✅ Tracke (rapport sans credentials)
│   ├── credentials.json          ❌ IGNORE (pattern credentials.*)
│   └── api.key                   ❌ IGNORE (pattern *.key)
└── client-beta/
    ├── deployment-2026-01-16.md  ✅ Tracke
    └── config-secret.json        ❌ IGNORE (pattern *secret*)
```

**Rappel** : Les rapports de deploiement ne doivent JAMAIS contenir de credentials !

---

## 🔍 SCRIPTS DE VALIDATION

> **⚠️ UTILISER CES SCRIPTS AVANT CHAQUE DEPLOIEMENT**
>
> Les scripts de validation permettent de verifier l'etat des ressources Azure
> et d'eviter les erreurs courantes (doublons, mauvais SKU, mauvais plan).

---

### Script : check-resources.sh

**Objectif :** Lister toutes les ressources Azure existantes avant deploiement

**Emplacement :** `scripts/check-resources.sh`

**Usage :**

```bash
# Prerequis : etre connecte a Azure et avoir selectionne une souscription
az login --tenant <TENANT_ID>
az account set --subscription <SUBSCRIPTION_ID>

# Executer le script
./scripts/check-resources.sh
```

**Ce que le script affiche :**

| Section | Information |
|---------|-------------|
| Resource Groups | Nom, Region |
| Translators | Nom, SKU (F0/S1), Resource Group, Region |
| Storage Accounts | Nom, Resource Group, Region, Type |
| Function Apps | Nom, Resource Group, Region, Etat |

**Exemple de sortie :**

```
════════════════════════════════════════════════════════════════════════
  CHECK AZURE RESOURCES - Pre-Deployment Verification
════════════════════════════════════════════════════════════════════════

▶ Pre-Flight Checks
────────────────────────────────────────────────────────────────────────
  Checking Azure CLI... OK
  Checking Azure login... OK
  Checking subscription... OK
  Subscription: Client-Azure-Subscription
  ID:           xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

▶ Azure Translator (Cognitive Services - TextTranslation)
────────────────────────────────────────────────────────────────────────
Nom                 SKU    ResourceGroup       Region
------------------  -----  ------------------  ------------
translator-client   F0     rg-tradbot-client   francecentral

✓ F0 SKU found - this is the FREE tier (recommended)

▶ Storage Accounts
────────────────────────────────────────────────────────────────────────
Nom                  ResourceGroup       Region         Kind
-------------------  ------------------  -------------  -----------
storageclient        rg-tradbot-client   francecentral  StorageV2

▶ Function Apps
────────────────────────────────────────────────────────────────────────
Nom               ResourceGroup       Region         State
----------------  ------------------  -------------  -------
tradbot-client    rg-tradbot-client   francecentral  Running

ℹ Found 1 Function App(s)

════════════════════════════════════════════════════════════════════════
  Summary
════════════════════════════════════════════════════════════════════════

  Review the resources above before creating new ones.

  Key reminders:
    - Reuse existing Translator F0 if available (free tier)
    - Never use Translator S1 unless explicitly requested
    - Use Flex Consumption for Function Apps
    - Create dedicated Resource Group per client: rg-tradbot-{client}

✓ Resource check complete
```

**Caracteristiques :**

- ✅ **Lecture seule** - Ne modifie aucune ressource
- ✅ **Idempotent** - Peut etre execute plusieurs fois sans effet
- ✅ **Alertes automatiques** - Detecte les SKU S1 (payant) et avertit
- ✅ **Suggestions** - Propose les commandes pour creer les ressources manquantes

**Quand l'utiliser :**

| Situation | Action |
|-----------|--------|
| Debut de Phase 1 | Executer pour voir les ressources existantes |
| Avant de creer un Translator | Verifier qu'un F0 n'existe pas deja |
| Verification post-deploiement | Confirmer que les ressources sont creees |
| Diagnostic d'erreur | Verifier l'etat des ressources

---

### Script : validate-sku.sh

**Objectif :** Verifier qu'un Azure Translator utilise le SKU F0 (gratuit)

**Emplacement :** `scripts/validate-sku.sh`

**Usage :**

```bash
# Verifier le SKU d'un Translator specifique
./scripts/validate-sku.sh <translator_name> <resource_group>

# Exemple
./scripts/validate-sku.sh translator-client rg-tradbot-client
```

**Codes de sortie :**

| Code | Signification |
|------|---------------|
| 0 | SKU est F0 (gratuit) - OK |
| 1 | SKU est S1 (payant) ou Translator non trouve - ERREUR |

**Exemple de sortie (F0 - OK) :**

```
════════════════════════════════════════════════════════════════════════
  VALIDATE TRANSLATOR SKU
════════════════════════════════════════════════════════════════════════

  Translator: translator-client
  Resource Group: rg-tradbot-client

  Checking Azure CLI... OK
  Checking Azure login... OK
  Checking if Translator exists... FOUND
  Checking SKU... F0

════════════════════════════════════════════════════════════════════════
✓ SKU is F0 (FREE tier) - Correct!
════════════════════════════════════════════════════════════════════════

  The Translator uses the free tier:
    - 2 million characters/month included
    - No monthly cost
    - Recommended for this project
```

**Exemple de sortie (S1 - ERREUR) :**

```
════════════════════════════════════════════════════════════════════════
✗ SKU is S1 (PAID tier) - WARNING!
════════════════════════════════════════════════════════════════════════

⚠ This Translator costs approximately $35/month!

  Unless explicitly requested by the client, you should:

  Option 1: Delete and recreate with F0

    # Delete the S1 Translator
    az cognitiveservices account delete \
      --name translator-client \
      --resource-group rg-tradbot-client

    # Recreate with F0 (free)
    az cognitiveservices account create \
      --name translator-client \
      --resource-group rg-tradbot-client \
      --kind TextTranslation \
      --sku F0 \
      --location francecentral --yes
```

**Quand l'utiliser :**

| Situation | Action |
|-----------|--------|
| Apres creation d'un Translator | Verifier que le SKU est F0 |
| Avant deploiement de la Function | S'assurer que les couts sont minimises |
| Audit de ressources existantes | Detecter les Translators S1 non necessaires |

---

### Script : validate-plan.sh

**Objectif :** Verifier qu'une Function App utilise le plan Flex Consumption (pas le plan Consumption deprecie)

**Emplacement :** `scripts/validate-plan.sh`

**Usage :**

```bash
# Prerequis : etre connecte a Azure
az login --tenant <TENANT_ID>

# Executer le script
./scripts/validate-plan.sh <function_app_name> <resource_group>

# Exemple
./scripts/validate-plan.sh tradbot-client rg-tradbot-client
```

**Codes de sortie :**

| Code | Signification |
|------|---------------|
| 0 | Flex Consumption (FC1) - Correct |
| 1 | Mauvais plan ou Function App non trouvee |

**Exemple de sortie (Flex Consumption - OK) :**

```
════════════════════════════════════════════════════════════════════════
  VALIDATE FUNCTION APP PLAN
════════════════════════════════════════════════════════════════════════

  Function App: tradbot-client
  Resource Group: rg-tradbot-client

  Checking Azure CLI... OK
  Checking Azure login... OK
  Checking if Function App exists... FOUND
  Checking plan type... FC1

════════════════════════════════════════════════════════════════════════
✓ Plan is Flex Consumption - Correct!
════════════════════════════════════════════════════════════════════════

  The Function App uses the recommended plan:
    - Flex Consumption (FC1)
    - Pay-per-execution model
    - Supported by Microsoft
```

**Exemple de sortie (Consumption deprecie - ERREUR) :**

```
════════════════════════════════════════════════════════════════════════
  VALIDATE FUNCTION APP PLAN
════════════════════════════════════════════════════════════════════════

  Function App: tradbot-client
  Resource Group: rg-tradbot-client

  Checking Azure CLI... OK
  Checking Azure login... OK
  Checking if Function App exists... FOUND
  Checking plan type... Y1

════════════════════════════════════════════════════════════════════════
✗ Plan is Consumption (DEPRECATED) - WARNING!
════════════════════════════════════════════════════════════════════════

⚠ This plan is DEPRECATED by Microsoft!

  The simple Consumption plan will be phased out.
  You should migrate to Flex Consumption.

  Action required: Delete and recreate with Flex Consumption

    # Delete the Function App
    az functionapp delete \
      --name tradbot-client \
      --resource-group rg-tradbot-client

    # Recreate with Flex Consumption
    az functionapp create \
      --name tradbot-client \
      --resource-group rg-tradbot-client \
      --storage-account $STORAGE_NAME \
      --flexconsumption-location francecentral \
      --runtime python --runtime-version 3.11

    # Then redeploy the code
    func azure functionapp publish tradbot-client --python
```

**Quand l'utiliser :**

| Situation | Action |
|-----------|--------|
| Apres creation d'une Function App | Verifier que le plan est Flex Consumption |
| Avant deploiement du code | S'assurer que le plan est supporte |
| Audit de ressources existantes | Detecter les Function Apps avec plan deprecie |

---

### Script : check-all.sh (Script Master)

**Objectif :** Executer toutes les validations en une seule commande

**Emplacement :** `scripts/check-all.sh`

**Usage :**

```bash
# Prerequis : etre connecte a Azure
az login --tenant <TENANT_ID>
az account set --subscription <SUBSCRIPTION_ID>

# Lister les ressources uniquement
./scripts/check-all.sh

# Valider un Translator specifique
./scripts/check-all.sh -t translator-client -g rg-tradbot-client

# Valider une Function App specifique
./scripts/check-all.sh -f tradbot-client -g rg-tradbot-client

# Validation complete (ressources + Translator + Function App)
./scripts/check-all.sh -t translator-client -f tradbot-client -g rg-tradbot-client
```

**Options :**

| Option | Description |
|--------|-------------|
| `-t, --translator <name>` | Nom du Translator a valider |
| `-f, --function-app <name>` | Nom de la Function App a valider |
| `-g, --resource-group <name>` | Resource group (requis si -t ou -f) |
| `-h, --help` | Afficher l'aide |

**Codes de sortie :**

| Code | Signification |
|------|---------------|
| 0 | Toutes les validations passees |
| 1 | Une ou plusieurs validations echouees |

**Checks effectues :**

| Check | Script | Condition |
|-------|--------|-----------|
| 1. Liste ressources | check-resources.sh | Toujours execute |
| 2. Validation SKU | validate-sku.sh | Si -t specifie |
| 3. Validation Plan | validate-plan.sh | Si -f specifie |

**Exemple de sortie (tout OK) :**

```
════════════════════════════════════════════════════════════════════════
  PRE-DEPLOYMENT VALIDATION - check-all.sh
════════════════════════════════════════════════════════════════════════

  Configuration:
    Translator:    translator-client
    Function App:  tradbot-client
    Resource Group: rg-tradbot-client

▶ CHECK 1: List Existing Resources
────────────────────────────────────────────────────────────────────────
[... output de check-resources.sh ...]
✓ Resource check completed

▶ CHECK 2: Validate Translator SKU
────────────────────────────────────────────────────────────────────────
  Validating: translator-client in rg-tradbot-client
[... output de validate-sku.sh ...]
✓ SKU validation passed (F0)

▶ CHECK 3: Validate Function App Plan
────────────────────────────────────────────────────────────────────────
  Validating: tradbot-client in rg-tradbot-client
[... output de validate-plan.sh ...]
✓ Plan validation passed (Flex Consumption)

════════════════════════════════════════════════════════════════════════
  VALIDATION SUMMARY
════════════════════════════════════════════════════════════════════════

  Total checks run:    3
  Checks passed:       3
  Checks failed:       0

════════════════════════════════════════════════════════════════════════
✓ ALL CHECKS PASSED!
════════════════════════════════════════════════════════════════════════

  Your Azure resources are correctly configured.
  You can proceed with deployment.
```

**Exemple de sortie (echec) :**

```
════════════════════════════════════════════════════════════════════════
  VALIDATION SUMMARY
════════════════════════════════════════════════════════════════════════

  Total checks run:    3
  Checks passed:       2
  Checks failed:       1

════════════════════════════════════════════════════════════════════════
✗ 1 CHECK(S) FAILED!
════════════════════════════════════════════════════════════════════════

  Please review the errors above and fix them before deployment.

  Common issues:
    - Translator using S1 instead of F0 (costs $35/month)
    - Function App using deprecated Consumption plan
```

**Quand l'utiliser :**

| Situation | Commande |
|-----------|----------|
| Debut de deploiement | `./scripts/check-all.sh` |
| Apres creation ressources | `./scripts/check-all.sh -t ... -f ... -g ...` |
| Verification pre-production | `./scripts/check-all.sh -t ... -f ... -g ...` |
| CI/CD pipeline | `./scripts/check-all.sh -t ... -f ... -g ...` (exit code pour succes/echec)
