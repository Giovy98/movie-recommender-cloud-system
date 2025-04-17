from fastapi import FastAPI, HTTPException
import pickle
import pandas as pd
import logging
from pathlib import Path
from pydantic import BaseModel

# Configurazione del logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

app = FastAPI()

# Percorsi dei file
DATA_PATH = Path("/app/data/recsys_df.csv")
MODEL_PATH = Path("/app/model/similarity.pkl")

# Caricamento dei file
logging.info("Caricamento del dataset e della matrice di similarità")

if not DATA_PATH.exists() or not MODEL_PATH.exists():
    logging.error("Errore: Dataset o modello non trovati. Verifica i percorsi.")
    raise RuntimeError("Dataset o modello non trovati!")

movies = pd.read_csv(DATA_PATH)
similarity = pickle.load(open(MODEL_PATH, "rb"))

# Normalizziamo i titoli per evitare problemi di matching
movies['title_lower'] = movies['title'].str.lower()
movie_title_map = {title.lower(): title for title in movies['title'].values}  # Mappatura case-insensitive

class MovieRequest(BaseModel):
    movie_name: str

def recommend(movie: str):
    movie_lower = movie.lower()
    
    if movie_lower not in movie_title_map:
        raise HTTPException(status_code=404, detail="Movie not found")

    actual_movie_name = movie_title_map[movie_lower]
    index = movies[movies['title'] == actual_movie_name].index[0]
    distances = sorted(list(enumerate(similarity[index])), reverse=True, key=lambda x: x[1])
    recommended_movie_names = [movies.iloc[i[0]].title for i in distances[1:6]]

    return {"recommendations": recommended_movie_names}

@app.get("/")
def root():
    return {"message": "Recommendation API is running Now!"}

@app.get("/recommend/{movie_name}")
def get_recommendations(movie_name: str):
    return recommend(movie_name)

@app.post("/recommend")
def recommend_movie(request: MovieRequest):
    return recommend(request.movie_name)
