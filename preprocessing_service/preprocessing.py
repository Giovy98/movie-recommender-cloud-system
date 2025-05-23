import pandas as pd
import ast
import logging
import os
import tempfile

from google.cloud import storage

# Logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# === Variabili d'Ambiente ===
GCS_KEY_PATH = "/var/secrets/key.json"
BUCKET_NAME = os.getenv("GCS_BUCKET_NAME")
MOVIES_BLOB = os.getenv("GCS_RAW_MOVIES_BLOB")
CREDITS_BLOB = os.getenv("GCS_RAW_CREDITS_BLOB")
PROCESSED_BLOB = os.getenv("GCS_PROCESSED_BLOB")

# === Funzioni utili ===
def init_gcs_client():
    return storage.Client.from_service_account_json(GCS_KEY_PATH)

def download_csv_to_df(bucket, blob_name):
    try:
        blob = bucket.blob(blob_name)
        df_bytes = blob.download_as_bytes()
        return pd.read_csv(pd.io.common.BytesIO(df_bytes))
    except Exception as e:
        logging.error(f"Errore nel download di {blob_name}: {e}")
        raise

def extract_names(text, limit=None, key='name'):
    try:
        elements = ast.literal_eval(text)
        names = [element[key] for element in elements[:limit]] if limit else [element[key] for element in elements]
        return [name.replace(" ", "") for name in names]
    except (ValueError, SyntaxError):
        return []

def extract_director(text):
    try:
        elements = ast.literal_eval(text)
        for element in elements:
            if element.get('job') == 'Director':
                return [element['name'].replace(" ", "")]
        return []
    except (ValueError, SyntaxError):
        return []

def preprocessing():
    logging.info("==== INIZIO PREPROCESSING ====")

    storage_client = init_gcs_client()
    bucket = storage_client.bucket(BUCKET_NAME)

    logging.info("1°: Caricamento Dataset dal bucket GCS")
    movies = download_csv_to_df(bucket, MOVIES_BLOB)
    credits = download_csv_to_df(bucket, CREDITS_BLOB)

    logging.info("2°: Merging dei due dataset")
    movies_full = movies.merge(credits, on='title')

    logging.info("3°: Pulizia e trasformazione dati")
    movies_full = movies_full[['movie_id', 'title', 'overview', 'genres', 'keywords', 'cast', 'crew']]
    movies_full.dropna(inplace=True)

    movies_full['genres'] = movies_full['genres'].apply(extract_names)
    movies_full['keywords'] = movies_full['keywords'].apply(extract_names)
    movies_full['cast'] = movies_full['cast'].apply(lambda x: extract_names(x, limit=3))
    movies_full['director'] = movies_full['crew'].apply(extract_director)
    movies_full.drop(columns=['crew'], inplace=True)

    movies_full['overview'] = movies_full['overview'].apply(lambda x: x.lower().split() if isinstance(x, str) else [])
    movies_full['tags'] = movies_full['overview'] + movies_full['genres'] + movies_full['keywords'] + movies_full['cast'] + movies_full['director']
    movies_full['tags'] = movies_full['tags'].apply(lambda x: " ".join(x))

    recsys_df = movies_full[['movie_id', 'title', 'tags']]

    logging.info("4°: Scrittura su GCS del dataset processato!")
    tmp_file_path = tempfile.mktemp(suffix='.csv')
    recsys_df.to_csv(tmp_file_path, index=False)

    try:
        blob = bucket.blob(PROCESSED_BLOB)
        blob.upload_from_filename(tmp_file_path)
        logging.info(f"File processato salvato con successo in gs://{BUCKET_NAME}/{PROCESSED_BLOB}")
    except Exception as e:
        logging.error(f"Errore durante l'upload del file su GCS!: {e}")
        raise
    finally:
        os.remove(tmp_file_path)

    logging.info("==== FINE PREPROCESSING ====")

if __name__ == '__main__':
    preprocessing()
