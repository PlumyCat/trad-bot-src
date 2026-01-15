# Instructions de Deploiement - Bot Traducteur

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

## 📋 CREDENTIALS POUR POWER PLATFORM

A la fin du deploiement, le technicien a besoin de **seulement 2 infos** pour configurer la solution Power Platform :

### 1. Storage Account (pour importer les documents)
```bash
echo "CONTAINER_NAME: doc-to-trad"
echo "STORAGE_KEY: $STORAGE_KEY"
```

### 2. Function App (URL de l'API)
```bash
FUNCTION_URL=$(az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query defaultHostName -o tsv)
FUNCTION_KEY=$(az functionapp keys list --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query functionKeys.default -o tsv)

echo "========================================"
echo "  CREDENTIALS POUR POWER PLATFORM"
echo "========================================"
echo ""
echo "Function URL: https://$FUNCTION_URL/api"
echo "Function Key: $FUNCTION_KEY"
echo ""
echo "Container:    doc-to-trad"
echo "Storage Key:  $STORAGE_KEY"
echo "========================================"
```

> ⚠️ **Afficher ces credentials a la fin de la Phase 1** pour que le technicien puisse configurer Power Platform.

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

## Workflow de Deploiement Complet

Le deploiement se fait en **3 phases** avec **2 comptes Azure differents** :

### Phase 0 : Creation App Entra ID (OneDrive)
**Compte requis** : Admin Global du tenant CLIENT

### Phase 1 : Deploiement Azure Backend
**Compte requis** : Compte delegue avec acces a la souscription Azure

### Phase 2 : Power Platform
**Compte requis** : Admin du tenant CLIENT

---

## PHASE 0 : App Entra ID pour OneDrive

### Pourquoi ?
Les fichiers traduits sont sauvegardes dans le OneDrive des utilisateurs.
Cela necessite une App Registration Entra ID avec des permissions Microsoft Graph.

### Etape 0.1 : Verifier la connexion Azure

La connexion Azure a ete faite au demarrage du container (via Windows avec navigateur).
Verifier que le bon compte est connecte :

```bash
az account show --query "{Compte:user.name, Tenant:tenantId}" -o table
```

**Si le mauvais compte est connecte**, quitter le container (`exit`) et relancer `start.bat` pour changer de tenant.

**IMPORTANT** : Pour cette phase, le technicien doit etre connecte avec un compte **Admin Global du tenant client** (pas le compte delegue Azure).

### Etape 0.2 : Recuperer le Tenant ID
```bash
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "Tenant ID: $TENANT_ID"
```

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

### Etape 0.4 : Creer le Service Principal
```bash
az ad sp create --id $CLIENT_ID
```

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

### Etape 0.6 : Accorder le consentement administrateur
```bash
# Attendre quelques secondes que les permissions se propagent
sleep 5

az ad app permission admin-consent --id $CLIENT_ID
```

### Etape 0.6b : VERIFICATION MANUELLE DU CONSENTEMENT

**IMPORTANT** : La commande `admin-consent` peut parfois echouer silencieusement.

Demander au technicien de verifier manuellement :

1. Aller sur **https://entra.microsoft.com**
2. Menu **Applications** > **Inscriptions d'applications**
3. Cliquer sur l'application **TradBot-OneDrive-{client}**
4. Aller dans **Permissions API**
5. Verifier que les permissions ont un **check vert** (consentement accorde)
6. Si pas de check vert : cliquer sur **Accorder le consentement administrateur pour {tenant}**

Une fois le consentement valide, continuer.

### Etape 0.7 : Creer un secret client
```bash
CLIENT_SECRET=$(az ad app credential reset \
  --id $CLIENT_ID \
  --append \
  --display-name "TradBot-Secret" \
  --years 2 \
  --query password -o tsv)

echo "Client Secret: $CLIENT_SECRET"
```

### Etape 0.8 : Sauvegarder les credentials
**IMPORTANT** : Noter ces valeurs pour la Phase 1 !
- CLIENT_ID: $CLIENT_ID
- SECRET_ID: $CLIENT_SECRET (variable nommee SECRET_ID dans l'app)
- TENANT_ID: $TENANT_ID

---

## PHASE 1 : Deploiement Azure Backend

### Etape 1.1 : Reconnexion avec compte delegue

Le technicien doit maintenant se connecter avec le **compte delegue** qui a acces a la souscription Azure.

```bash
# Verifier le compte actuel
az account show --query "{Compte:user.name, Tenant:tenantId}" -o table
```

**Si besoin de changer de compte** : quitter le container (`exit`) et relancer `start.bat` pour se reconnecter avec le compte delegue.

### Etape 1.2 : Verifier les ressources existantes

**⚠️ OBLIGATOIRE avant toute creation :**

```bash
# Selectionner la souscription
az account list --query "[].{Nom:name, ID:id, Defaut:isDefault}" -o table
az account set --subscription "ID-de-la-souscription"

# Verifier les Translator existants (NE PAS CREER SI F0 EXISTE !)
az cognitiveservices account list --query "[?kind=='TextTranslation'].{Nom:name, SKU:sku.name, RG:resourceGroup}" -o table
```

**Si un Translator F0 existe** → utiliser celui-la, passer a l'etape 1.4

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

> ⚠️ **TOUJOURS utiliser `--sku F0`** (gratuit). Ne JAMAIS utiliser S1 sauf demande explicite du client.

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
```

### Etape 1.5 : Configurer les variables d'environnement
Lors de la configuration de la Function App, inclure les variables OneDrive :

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

### Etape 1.6 : Afficher les credentials pour Power Platform

**⚠️ OBLIGATOIRE - Afficher ces infos au technicien :**

```bash
FUNCTION_URL=$(az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query defaultHostName -o tsv)
FUNCTION_KEY=$(az functionapp keys list --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query functionKeys.default -o tsv)

echo ""
echo "========================================"
echo "  ✅ PHASE 1 TERMINEE"
echo "========================================"
echo ""
echo "  Credentials pour Power Platform :"
echo ""
echo "  Function URL: https://$FUNCTION_URL/api"
echo "  Function Key: $FUNCTION_KEY"
echo ""
echo "  Container:    doc-to-trad"
echo "  Storage Key:  $STORAGE_KEY"
echo ""
echo "========================================"
echo ""
echo "  Prochaine etape : Phase 2 (navigateur)"
echo "  Ouvrir : http://localhost:5545/procedure"
echo ""
echo "========================================"
```

---

## PHASE 2 : Power Platform (etapes manuelles)

### ⚠️ Cette phase se fait dans le NAVIGATEUR, pas en ligne de commande !

**Aucune commande `az login` n'est necessaire pour cette phase.**

Le technicien doit suivre la documentation illustree :

👉 **Ouvrir dans le navigateur : http://localhost:5545/procedure**

### Resume des etapes manuelles :

1. Se connecter a **https://make.powerapps.com** avec le compte Admin du tenant client
2. Selectionner l'environnement cible
3. Importer la solution depuis `Solution/BotCopilotTraducteur_1_0_0_4.zip`
4. Configurer les connexions (Azure Functions URL)
5. Publier le bot

> 📖 **La documentation complete avec captures d'ecran est disponible sur : http://localhost:5545/procedure**

---

## Documentation

La documentation est accessible a tout moment sur :

👉 **http://localhost:5545/procedure**

Elle contient :
- Guide pas-a-pas avec captures d'ecran
- Configuration Power Platform
- Import de la solution Copilot Studio

---

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

## Rappel : Ordre des operations

| Phase | Compte requis | Actions |
|-------|---------------|---------|
| **Phase 0** | Admin Global client | `az login --tenant` + Creer App Entra |
| **Phase 1** | Compte delegue | `az login --tenant` + Deployer Azure |
| **Phase 2** | Admin client | **NAVIGATEUR uniquement** (pas de az login) |

### Phase 2 = Documentation !

Pour la Phase 2, **ne pas demander de az login**. Dire au technicien :

> "La Phase 2 se fait dans le navigateur. Ouvrez http://localhost:5545/procedure et suivez les etapes illustrees."

> **Note** : La connexion Azure (Phases 0 et 1) se fait sur Windows avec navigateur, puis les credentials sont partages avec le container automatiquement.
