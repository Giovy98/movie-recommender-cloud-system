# 🎬 Sistema di Raccomandazione Film su Google Cloud Platform

Questo progetto implementa un sistema di raccomandazione content-based di film  su GCP (Google Cloud Platform), utilizzando Kubernetes (GKE) per l'orchestrazione dei container, Terraform per il provisioning dell'infrastruttura e Argo Workflows per la gestione di job sequenziali.

![cloud-based-gcp-rcsys drawio](https://github.com/user-attachments/assets/b9d69041-d75c-4ed2-b056-83f24aca89e0)


## 📋 Indice

- [Struttura del Progetto](#struttura-del-progetto)
- [Prerequisiti](#prerequisiti)
- [Configurazione](#configurazione)
- [Deployment](#deployment)
- [Utilizzo](#utilizzo)
- [Troubleshooting](#troubleshooting)

## 📂 Struttura del Progetto

```
.
├── .github/workflows      # Workflow CI/CD
│   ├── deploy-application.yml      # Workflow per il deployment dei servizi API e UI
│   ├── deploy-configuration.yml    # Workflow per il deployment dei servizi Preprocessing e Recommender (ArgoWorkflow)
│   └── infra.yml                   # Workflow per il provisioning dell'infrastruttura
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
- Account Terraform Cloud (per la gestione dell'infrastruttura)
- Repository GitHub per utilizzare GitHub Actions
- Opzionale per test locale:
  - Docker installato localmente
  - Google Cloud CLI e i suoi plugin installati localmente:
    - `gke-gcloud-auth-plugin`
    - `gcloud components install kubectl`
  - Terraform installato localmente

## ⚙️ Configurazione

### 1. Variabili d'ambiente

Crea o modifica il file `.env` nella root del progetto (se non è presente):

```env
# API
API_URL=http://api-service.deployment.svc.cluster.local:8000/recommend

# Bucket
GCS_BUCKET_NAME= ADD_BUCKET_NAME_HERE (Il nome del GCS_BUCKET_NAME deve essere uguale a quello salvato sui secret di github)

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
- `GCP_SA_KEY`: JSON della chiave del service account (base64 encoded)
- `ARTIFACT_REPOSITORY`: Nome del repository Artifact Registry
- `GCP_GKE_CLUSTER_NAME`: Nome del cluster GKE
- `TFC_TOKEN`: Token di accesso Terraform Cloud
- `DOCKER_EMAIL`: Indirizzo email personale utilizzato per l'autenticazione su Docker
- `ENV_FILE`: Environment file `.env`

### 3. Service Account

1. Crea un service account con i seguenti ruoli:
   - Artifact Registry Administrator
   - Compute Security Admin
   - Compute Network Admin
   - Service Usage Admin
   - Service Account User
   - Storage Admin
   - Kubernetes Engine Admin

2. Crea e scarica una chiave JSON e salvala come `gcs-key.json` nella root del progetto.

## 🚀 Deployment

### 1. Provisioning dell'infrastruttura

Il workflow `infra.yml` viene eseguito automaticamente quando vengono apportate modifiche alla directory `terraform-gcp` o al workflow stesso. Altrimenti, può essere eseguito manualmente dall'interfaccia di GitHub Actions.

```bash
git add terraform-gcp
git commit -m "Modifiche alla configurazione Terraform"
git push origin main
```

### 2. Deployment dei servizi

#### Preprocessing e Recommender (ArgoWorkflow)

Il workflow `deploy-configuration.yml` viene eseguito automaticamente quando vengono apportate modifiche ai servizi `preprocessing_service` o `recommender_service`, oppure da una modifica al file di deployment di Kubernetes nella cartella `k8s-gke/argoWorkflow`. Altrimenti, può essere eseguito manualmente dall'interfaccia di GitHub Actions.

```bash
git add preprocessing_service/ recommender_service/
git commit -m "Aggiornamento dei microservizi"
git push origin main
```

oppure

```bash
git add k8s-gke/argoWorkflow/
git commit -m "Aggiornamento dei file di deployment di k8s su argoworkflow"
git push origin main
```

#### API e UI Services

Il workflow `deploy-application.yml` viene eseguito automaticamente quando vengono apportate modifiche ai servizi `api_service` o `ui_service`, oppure ai file di deployment nella cartella `k8s-gke/deployment`. Può anche essere eseguito manualmente dall'interfaccia di GitHub Actions.

```bash
git add api_service/ ui_service/
git commit -m "Aggiornamento dei servizi API e UI"
git push origin main
```
oppure

```bash
git add  k8s-gke/deployment/
git commit -m "Aggiornamento dei file di deployment di k8s per API e UI"
git push origin main
```

### 3. Accesso al Cluster Kubernetes

Dopo aver creato e configurato il cluster GKE, è possibile connettersi ad esso tramite la Google Cloud CLI sfruttando la Cloud Shell. Il comando da eseguire è il seguente:

```bash
gcloud container clusters get-credentials <GCP_GKE_CLUSTER_NAME> \
  --zone <GCP_ZONE> \
  --project <GCP_PROJECT_ID>
```

Sostituire `<GCP_GKE_CLUSTER_NAME>`, `<GCP_ZONE>` e `<GCP_PROJECT_ID>` con i valori corrispondenti al proprio ambiente.

In alternativa, è possibile accedere al cluster tramite l'interfaccia grafica di Google Cloud: selezionare il progetto desiderato, quindi navigare nella sezione **Kubernetes Engine** → **Cluster**, da cui è possibile visualizzare e gestire il cluster direttamente via UI.

## 🖥️ Utilizzo

Una volta completato il deployment:

1. Ottieni l'indirizzo IP esterno del servizio UI da configurazione locale (o sfruttando la Cloud Shell offerta come servizio da Google):
   ```bash
   kubectl get service ui-service -n deployment
   ```
   oppure direttamente nella sezione **Gateway, servizi e Ingress** di GKE

2. Accedi all'interfaccia web tramite browser all'indirizzo `http://<EXTERNAL-IP>:8501`
   - **EXTERNAL-IP**: corrisponde all’indirizzo IP esterno assegnato dal Load Balancer o da altra configurazione di rete.

4. Seleziona un film e ricevi raccomandazioni!

## ❓ Troubleshooting

### Problemi comuni

#### 1. API non raggiungibile

- Verifica lo stato dei pod:
  ```bash
  kubectl get pods -n deployment
  ```
- Controlla i log:
  ```bash
  kubectl logs deployment/api-deployment -n deployment
  ```

#### 2. Errori nel caricamento dei dati

- Verifica che i file CSV siano correttamente caricati nel bucket GCS
- Controlla i permessi del service account

#### 3. Errori di Argo Workflow

- Controlla lo stato del workflow:
  ```bash
  argo list -n argo
  ```
- Visualizza i dettagli:
  ```bash
  argo get <workflow-name> -n argo
  ```

#### 4. Accesso UI non funzionante

- Verifica che il servizio abbia un IP esterno:
  ```bash
  kubectl get service ui-service -n deployment
  ```
- Controlla i log UI:
  ```bash
  kubectl logs deployment/ui-deployment -n deployment
  ```

#### 5. Configurazione locale non corretta

- Verificare che tutti i componenti siano installati correttamente. In particolare, un'installazione non corretta di `kubectl` potrebbe causare errori durante la connessione o l'interazione con il cluster.

## Autore

| NOME     | COGNOME | MATRICOLA  |
|:--------:|:-------:|:----------:|
| Giovanni | Salerno | 1000052299 |

---

© 2025 - Sistema di Raccomandazione Film su GCP
