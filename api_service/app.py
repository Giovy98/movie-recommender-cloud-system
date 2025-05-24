from fastapi import FastAPI, HTTPException
from functools import lru_cache
from pydantic import BaseModel
from google.cloud import storage

import pickle
import pandas as pd
import logging
import io
import os
import gzip

# Configurazione logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Config
GCS_KEY_PATH = "/var/secrets/key.json"
BUCKET_NAME = os.getenv("GCS_BUCKET_NAME")
DATA_BLOB_PROCESSED = os.getenv("GCS_PROCESSED_BLOB")
MODEL_BLOB = os.getenv("GCS_MODEL_BLOB")



app = FastAPI(title="Movie Recommendation API!", version="1.0.0")

# === Google Cloud Storage Setup ===
@lru_cache()
def get_gcs_bucket():
    try:
        client = storage.Client.from_service_account_json(GCS_KEY_PATH)
        return client.bucket(BUCKET_NAME)
    except Exception as e:
        logging.error(f"Errore inizializzazione client GCS: {e}")
        raise RuntimeError("Impossibile inizializzare il client GCS!")

# === Caricamento dati e modello con cache ===
@lru_cache()
def load_data():
    bucket = get_gcs_bucket()
    try:
        logging.info("Caricamento dataset da GCS")
        data_blob = bucket.blob(DATA_BLOB_PROCESSED)
        df_bytes = data_blob.download_as_bytes()
        df = pd.read_csv(io.BytesIO(df_bytes))
        df['title_lower'] = df['title'].str.lower()
        return df
    except Exception as e:
        logging.error(f"Errore nel caricamento del dataset: {e}")
        raise RuntimeError("Errore nel caricamento del dataset")

@lru_cache()
def load_model():
    bucket = get_gcs_bucket()
    try:
        logging.info("Caricamento matrice di similarità da GCS")
        model_blob = bucket.blob(MODEL_BLOB)
        model_bytes = model_blob.download_as_bytes()
        
        with gzip.GzipFile(fileobj=io.BytesIO(model_bytes), mode='rb') as f:
           return pickle.load(f)
    except Exception as e:
        logging.error(f"Errore nel caricamento del modello: {e}")
        raise RuntimeError("Errore nel caricamento del modello")

# === Schema per richieste POST ===
class MovieRequest(BaseModel):
    movie_name: str

# === Funzione di raccomandazione ===
def recommend(movie: str):
    movies = load_data()
    similarity = load_model()

    movie_lower = movie.strip().lower()
    movie_title_map = {title.lower(): title for title in movies['title'].values}

    if movie_lower not in movie_title_map:
        raise HTTPException(status_code=404, detail="🎥 Film non trovato nel dataset.")

    actual_title = movie_title_map[movie_lower]
    idx = movies[movies['title'] == actual_title].index[0]

    distances = sorted(enumerate(similarity[idx]), key=lambda x: x[1], reverse=True)
    recommended = [movies.iloc[i[0]].title for i in distances[1:6]]  # Salta se stesso

    return {
        "input_movie": actual_title,
        "recommendations": recommended
    }

# === Endpoints ===
@app.get("/", tags=["Info"])
def root():
    return {"message": "Recommendation API is running!"}

@app.get("/healthz", tags=["Monitoring!"])
def health_check():
    try:
        load_data()
        load_model()
        return {"status": "ok"}
    except:
        raise HTTPException(status_code=500, detail="API non pronta")

@app.get("/recommend/{movie_name}", tags=["Recommend"])
def get_recommendations(movie_name: str):
    return recommend(movie_name)

@app.post("/recommend", tags=["Recommend"])
def recommend_movie(request: MovieRequest):
    return recommend(request.movie_name)
