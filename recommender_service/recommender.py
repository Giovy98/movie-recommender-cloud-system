import pandas as pd
import numpy as np
import pickle
import os
import logging

from sklearn.feature_extraction.text import CountVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# Configurazione logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

def compute_similarity():
    logging.info("1°: Caricamento del dataset")

    dataset_path = 'data/recsys_df.csv'
        
    recsys_df = pd.read_csv(dataset_path)

    logging.info("2°: Inizializzazione del modello CountVectorizer")
    cv = CountVectorizer(max_features=5000, stop_words='english')  # Manteniamo solo le 5000 parole più frequenti nel corpus

    logging.info("3°: Calcolo della matrice dei vettori")
    X = cv.fit_transform(recsys_df['tags']).toarray()

    logging.info("4°: Calcolo della similarità coseno")
    similarity = cosine_similarity(X)

    logging.info("5°: Salvataggio della matrice di similarità")
    pickle.dump(similarity, open('similiarityMatrix/similarity.pkl', 'wb'))

if __name__ == '__main__':
    logging.info("INIZIO ESECUZIONE")
    compute_similarity()
    logging.info("FINE ESECUZIONE")
