import pandas as pd
import ast
import logging
import os

# Configurazione logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

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
    logging.info("1°: Caricamento Dataset")
    
    if not os.path.exists('data/tmdb_5000_movies.csv') or not os.path.exists('data/tmdb_5000_credits.csv'):
        logging.error("File CSV non trovati! Assicurati che i file siano presenti nella directory 'data'.")
        return
    
    movies = pd.read_csv('data/tmdb_5000_movies.csv')
    credits = pd.read_csv('data/tmdb_5000_credits.csv')

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

    logging.info("7°: Salvataggio del dataframe finale")
    os.makedirs('processedDataset', exist_ok=True)
    recsys_df.to_csv('processedDataset/recsys_df.csv', index=False)

if __name__ == '__main__':
    logging.info("INIZIO ESECUZIONE")
    preprocessing()
    logging.info("FINE ESECUZIONE")
