import pandas as pd
import numpy as np
import pickle
import os
import logging
import gcsfs

from sklearn.feature_extraction.text import CountVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# Configurazione logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

BUCKET_NAME = 'dataset_sistema_raccomandazione'
PROCESSED_PATH = f'gs://{BUCKET_NAME}/processed/'
MODEL_PATH = f'gs://{BUCKET_NAME}/model/'


def compute_similarity():
    logging.info("1°: Caricamento del dataset dal bucket GCS")

    dataset_path = PROCESSED_PATH + 'recsys_df.csv'

    try:
        recsys_df = pd.read_csv(dataset_path)
    except Exception as e:
        logging.error(f"Errore nel caricamento del dataset: {e}")
        return

    logging.info("2°: Inizializzazione del modello CountVectorizer")
    cv = CountVectorizer(max_features=5000, stop_words='english')

    logging.info("3°: Calcolo della matrice dei vettori")
    X = cv.fit_transform(recsys_df['tags']).toarray()

    logging.info("4°: Calcolo della similarità coseno")
    similarity = cosine_similarity(X)

    logging.info("5°: Salvataggio della matrice di similarità nel bucket GCS")
    similarity_path = MODEL_PATH + 'similarity.pkl'

    try:
        fs = gcsfs.GCSFileSystem()
        with fs.open(similarity_path, 'wb') as f:
            pickle.dump(similarity, f)
        logging.info(f"Matrice salvata correttamente in {similarity_path}")
    except Exception as e:
        logging.error(f"Errore nel salvataggio della matrice: {e}")

if __name__ == '__main__':
    logging.info("INIZIO ESECUZIONE")
    compute_similarity()
    logging.info("FINE ESECUZIONE")
