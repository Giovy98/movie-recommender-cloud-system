import pandas as pd
import pickle
import logging
import tempfile
import os
import gzip

from google.cloud import storage
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# Logging configurato
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Costanti
GCS_KEY_PATH = "/var/secrets/key.json"
BUCKET_NAME = os.getenv("GCS_BUCKET_NAME")
DATA_BLOB = os.getenv("GCS_PROCESSED_BLOB")
MODEL_BLOB = os.getenv("GCS_MODEL_BLOB")


def init_gcs_client():
    try:
        return storage.Client.from_service_account_json(GCS_KEY_PATH)
    except Exception as e:
        logging.error(f"Errore durante l'autenticazione con GCS: {e}")
        raise

def load_dataset(bucket):
    logging.info("1°: Caricamento del dataset dal bucket GCS")
    try:
        blob = bucket.blob(DATA_BLOB)
        df_bytes = blob.download_as_bytes()
        df = pd.read_csv(pd.io.common.BytesIO(df_bytes))
        if 'tags' not in df.columns:
            raise ValueError("La colonna 'tags' non è presente nel dataset..")
        return df
    except Exception as e:
        logging.error(f"Errore nel caricamento del dataset: {e}")
        raise

def compute_similarity_matrix(tags_series):
    logging.info("2°: Inizializzazione CountVectorizer")
    cv = CountVectorizer(max_features=5000, stop_words='english')

    logging.info("3°: Trasformazione del dataset in matrice di feature")
    matrix = cv.fit_transform(tags_series.fillna('')).toarray()

    logging.info("4°: Calcolo della similarità coseno")
    return cosine_similarity(matrix)

def upload_to_gcs(bucket, data, destination_blob):
    logging.info("5°: Salvataggio della matrice di similarità su GCS")
    tmp_file_path = None

    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix='.pkl.gz') as tmp_file:
            with gzip.GzipFile(fileobj=tmp_file, mode='wb') as f_out:
                pickle.dump(data, f_out)
            tmp_file_path = tmp_file.name

        blob = bucket.blob(destination_blob)

        # Upload con timeout esteso e upload riprendibile abilitato
        blob.upload_from_filename(
            tmp_file_path,
            content_type="application/octet-stream",
            timeout=600 # Timeout aumentato a 10 minuti
        )

        logging.info(f" Matrice salvata con successo in gs://{BUCKET_NAME}/{destination_blob}")

    except Exception as e:
        logging.error(f" Errore durante il salvataggio della matrice: {e}")
        raise

    finally:
        if tmp_file_path and os.path.exists(tmp_file_path):
            os.remove(tmp_file_path)

def compute_similarity():
    logging.info("==== INIZIO CALCOLO SIMILARITÀ ====")

    try:
        storage_client = init_gcs_client()
        bucket = storage_client.bucket(BUCKET_NAME)

        df = load_dataset(bucket)
        similarity = compute_similarity_matrix(df['tags'])
        upload_to_gcs(bucket, similarity, MODEL_BLOB)

    except Exception as e:
        logging.error(f"Errore generale nel processo: {e}")
    finally:
        logging.info("==== FINE CALCOLO SIMILARITÀ  ====")

if __name__ == '__main__':
    compute_similarity()
