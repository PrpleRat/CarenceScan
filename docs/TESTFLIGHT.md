# CarenceScan — Déploiement TestFlight

## Ordre recommandé

1. **Créer le repo GitHub** (déjà fait) et ajouter les **3 secrets**
2. **Developer Apple** — App ID `com.carencescan.app`
3. **App Store Connect** — créer l’app **CarenceScan**
4. Lancer **CarenceScan TestFlight** dans GitHub Actions

## Secrets GitHub (Settings → Secrets and variables → Actions)

| Secret | Description |
|--------|-------------|
| `ASC_KEY_ID` | ID de la clé API App Store Connect |
| `ASC_ISSUER_ID` | Issuer ID (Users and Access → Integrations) |
| `ASC_PRIVATE_KEY` | Contenu complet du fichier `.p8` (copier-coller) |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Certificat `.p12` (bootstrap, **réutilisé**) |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Mot de passe du `.p12` |
| `KEYCHAIN_PASSWORD` | Mot de passe trousseau CI |

**Important :** un seul certificat **Apple Distribution** suffit pour **toutes** tes apps. Le workflow **réutilise** le `.p12` et ne régénère que le **profil** App Store à chaque build.

Créer la clé API : [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)

### Première fois — Bootstrap (sans Mac)

1. Ajouter les 3 secrets `ASC_*`
2. **Actions** → **CarenceScan — Bootstrap signing (sans Mac)** → **Run workflow** (ou utiliser le `.p12` d'un autre repo)
3. Copier les 3 secrets certificat dans ce repo GitHub

## Apple Developer — App ID

1. [Identifiers](https://developer.apple.com/account/resources/identifiers/list) → **+** → App IDs
2. Description : `CarenceScan`
3. Bundle ID explicite : **`com.carencescan.app`**
4. Capabilities : aucune obligatoire pour v1 (pas de push, HealthKit, etc.)

## App Store Connect — Nouvelle app

| Champ | Valeur |
|-------|--------|
| **Nom** | CarenceScan |
| **Langue principale** | Français |
| **Bundle ID** | `com.carencescan.app` |
| **SKU** | `carencescan-ios` (ou autre identifiant interne unique) |
| **Accès utilisateur** | Accès complet |

Catégorie suggérée : **Santé et forme**  
Sous-titre : *Bilan carences & solutions*

## Envoyer une build TestFlight

1. Vérifier que les 3 secrets `ASC_*` sont renseignés
2. **Actions** → **CarenceScan TestFlight** → **Run workflow**
3. Attendre ~15–25 min
4. App Store Connect → **TestFlight** → build **Processing** → **Ready to test**

## Build simulateur (sans secrets)

**Actions** → **CarenceScan iOS** → **Run workflow**

## Dépannage

| Problème | Action |
|----------|--------|
| Secrets manquants | Ajouter `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY` |
| App ID inconnu | Créer `com.carencescan.app` sur developer.apple.com **avant** TestFlight |
| App ASC absente | Créer l’app dans App Store Connect avec le même Bundle ID |
| 2 certificats Distribution max | Révoquer un ancien cert sur developer.apple.com puis relancer |
