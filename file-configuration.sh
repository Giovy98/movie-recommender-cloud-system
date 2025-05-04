#!/bin/bash

echo "Avvio configurazione del cluster Kubernetes..."
echo "---------------------------------------------"

# Creazione del namespace 'deployment' se non esiste
echo "Verifica e creazione del namespace 'deployment'..."
if ! kubectl get namespace deployment > /dev/null 2>&1; then
  kubectl create namespace deployment
else
  echo "Namespace 'deployment' già esistente. Skip."
fi

echo "---------------------------------------------"

# Creazione dei Secret Docker nei namespace 'argo' e 'deployment'
echo "Creazione dei Secret Docker nei namespace 'argo' e 'deployment'..."
for namespace in argo deployment; do
  if ! kubectl get namespace "$namespace" > /dev/null 2>&1; then
    echo "Namespace '$namespace' non esiste. Skip."
    continue
  fi

  echo "Creazione del Secret Docker per il namespace '$namespace'..."
  kubectl create secret docker-registry gcr-json-key-gke-$namespace \
    --docker-server=GCP-REGION-docker.pkg.dev \
    --docker-username=_json_key \
    --docker-password="$(cat gcs-key.json)" \
    --docker-email=email-login-docker \
    --namespace=$namespace
done

echo "---------------------------------------------"

# Creazione delle ConfigMap da .env nei namespace 'argo' e 'deployment'
echo "Creazione delle ConfigMap nei namespace 'argo' e 'deployment'..."
for namespace in argo deployment; do
  if ! kubectl get namespace "$namespace" > /dev/null 2>&1; then
    echo "Namespace '$namespace' non esiste. Skip."
    continue
  fi

  echo "Creazione della ConfigMap per il namespace '$namespace'..."
  kubectl create configmap service-config-gke-$namespace \
    --from-env-file=.env \
    --namespace=$namespace
done

echo "---------------------------------------------"

# Creazione del RoleBinding per il namespace 'argo'
if kubectl get namespace argo > /dev/null 2>&1; then
  echo "Creazione RoleBinding per il namespace 'argo'..."
  kubectl create rolebinding default-admin \
    --clusterrole=admin \
    --serviceaccount=argo:default \
    --namespace=argo
else
  echo "Namespace 'argo' non esiste. RoleBinding non creato."
fi

echo "---------------------------------------------"

# Creazione del Secret generico gcs-key (chiave JSON) nei namespace
echo "Creazione del Secret per la service account key nei namespace 'argo' e 'deployment'..."
for namespace in argo deployment; do
  if ! kubectl get namespace "$namespace" > /dev/null 2>&1; then
    echo "Namespace '$namespace' non esiste. Skip."
    continue
  fi

  echo "Creazione del Secret generico per il namespace '$namespace'..."
  kubectl create secret generic gcs-key-gke-$namespace \
    --from-file=key.json=./gcs-key.json \
    --namespace=$namespace
done

echo "---------------------------------------------"
echo "✅ Configurazione completata con successo."
