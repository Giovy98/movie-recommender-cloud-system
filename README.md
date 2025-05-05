# 🎬 Sistema di Raccomandazione Film su Google Cloud Platform

Questo progetto implementa un sistema di raccomandazione di film basato su GCP (Google Cloud Platform), utilizzando Kubernetes (GKE) per l'orchestrazione dei container e Argo Workflows per l'automazione dei processi di elaborazione dati.

![cloud-based-gcp-rcsys-1](https://github.com/user-attachments/assets/af9369cf-41db-41ad-866d-6ce1f4eec34b)


## 📋 Indice
- [Panoramica](#panoramica)
- [Architettura](#architettura)
- [Prerequisiti](#prerequisiti)
- [Configurazione](#configurazione)
- [Deployment](#deployment)
- [Utilizzo](#utilizzo)
- [Troubleshooting](#troubleshooting)

## 🔍 Panoramica

Il sistema offre raccomandazioni di film basate sulla similarità coseno tra le caratteristiche dei film, utilizzando un dataset TMDB (The Movie Database). L'architettura è completamente containerizzata e deployata su GKE (Google Kubernetes Engine), con la gestione dell'infrastruttura tramite Terraform.


## 📂 Struttura del Progetto

```
.
├── .github/workflows      # Workflow CI/CD
│   ├── deploy.yml         # Workflow per il deployment dei servizi
│   └── infra.yml          # Workflow per il provisioning dell'infrastruttura
├── api_service            # Servizio API FastAPI
├── preprocessing_service  # Servizio di preprocessing dati
├── recommender_service    # Servizio di calcolo similarità
├── ui_service             # Interfaccia utente Streamlit
├── k8s-gke                # Configurazioni Kubernetes
│   ├── argoWorkflow       # Definizioni workflow Argo
│   └── deployment         # Manifesti Kubernetes per i servizi
├── terraform-gcp          # Configurazione Terraform per GCP
├── .env                   # Variabili d'ambiente
├── file-configuration.sh  # Script di configurazione Kubernetes
└── pipe-cloud-gke.sh      # Script di avvio pipeline e servizi
```

## 📝 Prerequisiti

- Account Google Cloud con fatturazione abilitata
- Progetto GCP creato
- Service Account con i permessi necessari
- Terraform Cloud account (per la gestione dell'infrastruttura)
- Docker installato localmente (per sviluppo e test)
- kubectl e gcloud CLI installati localmente

## ⚙️ Configurazione

### 1. Variabili d'ambiente

Crea un file `.env` nella root del progetto:

```
# API
API_URL=http://api-service.deployment.svc.cluster.local:8000/recommend

# Bucket
GCS_BUCKET_NAME=your-bucket-name

# Percorsi nel bucket
GCS_RAW_MOVIES_BLOB=raw/tmdb_5000_movies.csv
GCS_RAW_CREDITS_BLOB=raw/tmdb_5000_credits.csv
GCS_PROCESSED_BLOB=processed/recsys_df.csv
GCS_MODEL_BLOB=model/similarity.pkl.gz
```

### 2. Secrets GitHub

Configura i seguenti segreti nel tuo repository GitHub:

- `GCP_PROJECT_ID`: ID del tuo progetto GCP
- `GCP_REGION`: Regione GCP (es. europe-west1)
- `GCP_ZONE`: Zona GCP (es. europe-west1-b)
- `GCP_BUCKET_NAME`: Nome del bucket GCS
- `GCP_SERVICE_ACCOUNT`: Email del service account
- `GCP_SA_KEY`: JSON della chiave del service account (base64 encoded)
- `ARTIFACT_REPOSITORY`: Nome del repository Artifact Registry
- `GCP_GKE_CLUSTER_NAME`: Nome del cluster GKE
- `TFC_TOKEN`: Token di accesso Terraform Cloud

### 3. Service Account

1. Crea un service account con i seguenti ruoli:
   - Artifact Registry amministrator
   - Compute security Admin
   - Service Usage Admin
   - Storage Admin
   - Kubernetes Engine Admin
   - Service Account User
3. Crea una chiave JSON e salvala come `gcs-key.json` nella root del progetto.

## 🚀 Deployment

### 1. Provisioning dell'infrastruttura

Il workflow `infra.yml` viene eseguito automaticamente quando vengono apportate modifiche alla directory `terraform-gcp`. Altrimenti, può essere eseguito manualmente:

```bash
# Esecuzione manuale del workflow di infrastruttura
git push origin google-cloud-project-main
```

### 2. Deployment dei servizi

Il workflow `deploy.yml` viene eseguito automaticamente quando vengono apportate modifiche ai servizi. Altrimenti, può essere eseguito manualmente:

```bash
# Esecuzione manuale del workflow di deployment
git push origin google-cloud-project-main
```

### 3. Configurazione del cluster Kubernetes

Dopo il deployment, esegui lo script di configurazione:

```bash
chmod +x file-configuration.sh
./file-configuration.sh
```

### 4. Avvio del pipeline e dei servizi

```bash
chmod +x pipe-cloud-gke.sh
./pipe-cloud-gke.sh
```

## 🖥️ Utilizzo

Una volta completato il deployment:

1. Ottieni l'indirizzo IP esterno del servizio UI:
   ```bash
   kubectl get service ui-service -n deployment
   ```

2. Accedi all'interfaccia web tramite browser all'indirizzo `http://<EXTERNAL-IP>:8501`

3. Seleziona un film e ricevi raccomandazioni!

## ❓ Troubleshooting

### Problemi comuni:

1. **API non raggiungibile**:
   - Verifica lo stato dei pod: `kubectl get pods -n deployment`
   - Controlla i log: `kubectl logs deployment/api-deployment -n deployment`

2. **Errori nel caricamento dei dati**:
   - Verifica che i file CSV siano correttamente caricati nel bucket GCS
   - Controlla i permessi del service account

3. **Errori di Argo Workflow**:
   - Controlla lo stato del workflow: `argo list -n argo`
   - Visualizza i dettagli: `argo get <workflow-name> -n argo`

4. **Accesso UI non funzionante**:
   - Verifica che il servizio abbia un IP esterno: `kubectl get service ui-service -n deployment`
   - Controlla i log UI: `kubectl logs deployment/ui-deployment -n deployment`

## Autore

| NOME | COGNOME    | MARICOLA    |
| :-----: | :---: | :---: |
| Giovanni |Salerno | 1000052299   |
---



© 2025 - Sistema di Raccomandazione Film su GCP



