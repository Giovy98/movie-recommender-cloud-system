import pandas as pd
import ast
import logging
import os
import gcsfs  # Importante per autenticazione esplicita con gcsfs

# Path al file di credenziali del Service Account (montato dal Secret)
GCS_KEY_PATH = "/var/secrets/key.json"

# Configurazione logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Bucket e path
BUCKET_NAME = 'dataset_sistema_raccomandazione'
RAW_PATH = f'gs://{BUCKET_NAME}/raw/'
PROCESSED_PATH = f'gs://{BUCKET_NAME}/processed/'

# Inizializza GCS filesystem con credenziali
gcs = gcsfs.GCSFileSystem(token=GCS_KEY_PATH)

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
    logging.info("1°: Caricamento Dataset dal bucket GCS")

    movies_path = RAW_PATH + 'tmdb_5000_movies.csv'
    credits_path = RAW_PATH + 'tmdb_5000_credits.csv'

    try:
        movies = pd.read_csv(movies_path, storage_options={"token": GCS_KEY_PATH})
        credits = pd.read_csv(credits_path, storage_options={"token": GCS_KEY_PATH})
    except Exception as e:
        logging.error(f"Errore nel caricamento dei file da GCS: {e}")
        return

    logging.info("2°: Merging dei due dataset")
    movies_full = movies.merge(credits, on='title')

    logging.info("3°: Selezione delle colonne di interesse")
    movies_full = movies_full[['movie_id', 'title', 'overview', 'genres', 'keywords', 'cast', 'crew']]

    logging.info("4°: Rimozione valori nulli")
    movies_full.dropna(inplace=True)

    logging.info("5°: Applicazione delle trasformazioni")
    movies_full['genres'] = movies_full['genres'].apply(extract_names)
    movies_full['keywords'] = movies_full['keywords'].apply(extract_names)
    movies_full['cast'] = movies_full['cast'].apply(lambda x: extract_names(x, limit=3))
    movies_full['director'] = movies_full['crew'].apply(extract_director)
    movies_full.drop(columns=['crew'], inplace=True)

    movies_full['overview'] = movies_full['overview'].apply(lambda x: x.lower().split() if isinstance(x, str) else [])

    logging.info("6°: Creazione della feature combinata 'tags'")
    movies_full['tags'] = movies_full['overview'] + movies_full['genres'] + movies_full['keywords'] + movies_full['cast'] + movies_full['director']
    movies_full['tags'] = movies_full['tags'].apply(lambda x: " ".join(x))

    recsys_df = movies_full[['movie_id', 'title', 'tags']]

    logging.info("7°: Salvataggio del dataframe finale sul bucket GCS")
    output_path = PROCESSED_PATH + 'recsys_df.csv'
    try:
        recsys_df.to_csv(output_path, index=False, storage_options={"token": GCS_KEY_PATH})
    except Exception as e:
        logging.error(f"Errore nel salvataggio su GCS: {e}")

if __name__ == '__main__':
    logging.info("INIZIO ESECUZIONE")
    preprocessing()
    logging.info("FINE ESECUZIONE")
