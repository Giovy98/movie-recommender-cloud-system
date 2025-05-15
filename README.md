# 🎬 Sistema di Raccomandazione Film su Google Cloud Platform

Questo progetto implementa un sistema di raccomandazione di film content-base su GCP (Google Cloud Platform), utilizzando Kubernetes (GKE) per l'orchestrazione dei container, Terraform per fare il provisioning  dell'infrastruttura e Argo Workflows per la gestione di job sequenziali.

![cloud-based-gcp-rcsys-1](https://github.com/user-attachments/assets/af9369cf-41db-41ad-866d-6ce1f4eec34b)


## 📋 Indice
- [Struttura del Progetto](#strutturadelprogetto)
- [Prerequisiti](#prerequisiti)
- [Configurazione](#configurazione)
- [Deployment](#deployment)
- [Utilizzo](#utilizzo)
- [Troubleshooting](#troubleshooting)

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
└── .gitignore 
```

## 📝 Prerequisiti

- Account Google Cloud con fatturazione abilitata
- Progetto GCP creato
- Service Account con i permessi necessari
- Terraform Cloud account (per la gestione dell'infrastruttura)
- Opzionale per test locale:
  - Docker installato localmente 
  - Gcloud CLI e il suoi plugin installati localmente 
      - ```gke-gcloud-auth-plugin```    
      -  ```gcloud components install kubectl``` 
  - Terraform installato localmente 

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
- `DOCKER_EMAIL`: Indirizzo email personale utilizzato per l’autenticazione su
 Docker
- `ENV_FILE`: Environment file `.env`

### 3. Service Account

1. Crea un service account con i seguenti ruoli:
    - Artifact Registry administrator
    - Compute security Admin
    - Compute Network Admin 
    - Service Usage Admin 
    - Service Account User 
    - Storage Admin 
    - Kubernetes Engine Admin 
2. Crea e Scarica una chiave JSON e salvala come `gcs-key.json` nella root del progetto.

## 🚀 Deployment

### 1. Provisioning dell'infrastruttura

Il workflow `infra.yml` viene eseguito automaticamente quando vengono apportate modifiche alla directory `terraform-gcp` o al workflow stesso. Altrimenti, può essere eseguito manualmente dall'interfaccia di gitaction.

```bash
 1 git add terraform-gcp
 2 git commit-m "Modifiche alla configurazione Terraform"
 3 git push origin google-cloud-project-main
```
or
```bash
 git add .github/workflow/infra.yml
 2 git commit-m "Aggiornamento del workflow infra.yml"
 3 git push origin google-cloud-project-main
```

### 2. Deployment dei servizi

Il workflow `deploy.yml` viene eseguito automaticamente quando vengono apportate modifiche ai servizi, oppure da una modifica al file di deployment di kubernetes nella cartella `k8s-gke` o al workflow stesso. Altrimenti, può essere eseguito manualmente dall'interfaccia di gitaction.

```bash
 1 git add api_service/preprocessing_service/recommender_service/ui_service
 2 git commit-m "Aggiornamento dei microservizi"
 3 git push origin google-cloud-project-main
``` 
or
```bash
 1 git add k8s-gke/**
 2 git commit-m "Aggiornamento dei file di deployment k8s""
 3 git push origin google-cloud-project-main
``` 
or 

```bash
 1 git add .github/workflow/deploy.yml
 2 git commit-m "Modifica al workflow deploy.yml""
 3 git push origin google-cloud-project-main
``` 
### 3. Accesso al Cluster Kubernetes
Dopo aver creato e configurato il cluster GKE, è possibile connettersi ad esso tramite la Google Cloud CLI, a condizione che l’ambiente locale sia correttamente configurato. Il comando da eseguire è il seguente:

```bash
gcloud container clusters get-credentials GCP_GKE_CLUSTER_NAME \
  --zone GCP_ZONE \
  --project GCP_PROJECT_ID

 ```
Sostituire **GCP_GKE_CLUSTER_NAME**, **GCP_ZONE** e **GCP_PROJECT_ID** con i valori corrispondenti al proprio ambiente.

In alternativa, è possibile accedere al cluster tramite `l’interfaccia grafica di Google Cloud`: selezionare il progetto desiderato, quindi navigare nella sezione `Kubernetes Engine` → `Cluster`, da cui è possibile visualizzare e gestire il cluster direttamente via UI.


## 🖥️ Utilizzo

Una volta completato il deployment:

1. Ottieni l'indirizzo IP esterno del servizio UI da configurazione locale:
   ```bash
   kubectl get service ui-service -n deployment
   ```
   oppure direttamente nella sezione `Gateway, servizi e Ingress`  di GKE

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

5. **Configurione Locale non corretta**:
    - Verificare che tutti i componenti siano installati correttamente. In particolare, un'installazione non corretta di `kubectl` potrebbe causare errori durante la connessione o l'interazione con il cluster.


## Autore

| NOME | COGNOME    | MARICOLA    |
| :-----: | :---: | :---: |
| Giovanni |Salerno | 1000052299   |
---



© 2025 - Sistema di Raccomandazione Film su GCP



