from google.cloud import storage

import streamlit as st
import requests
import pandas as pd
import io
import os

# === CONFIG ===
API_URL = os.getenv("API_URL")
GCS_KEY_PATH = "/var/secrets/key.json"  # Percorso al file di credenziali
BUCKET_NAME = os.getenv("GCS_BUCKET_NAME")
DATA_BLOB = os.getenv("GCS_PROCESSED_BLOB")

# === Funzione per leggere il CSV da GCS ===
@st.cache_data(show_spinner=False)
def load_movies_from_gcs():
    try:
        client = storage.Client.from_service_account_json(GCS_KEY_PATH) #
        bucket = client.bucket(BUCKET_NAME) 
        blob = bucket.blob(DATA_BLOB) 

        data_bytes = blob.download_as_bytes() # file CSV convertito in byte
        df = pd.read_csv(io.BytesIO(data_bytes)) # fiel CSV convertito in DataFrame
        return sorted(df['title'].dropna().unique())
    
    except Exception as e:
        st.error(f"Errore nel caricamento del dataset da GCS: {e}")
        return []
    
# === Funzione per ottenere raccomandazioni dall’API ===
def get_recommendations(movie_title: str):
    try:
        response = requests.post(API_URL, json={"movie_name": movie_title}, timeout=10)
        response.raise_for_status() # Controlla se la risposta è OK
        return response.json()["recommendations"]
    except requests.exceptions.RequestException as e:
        st.error(f"Errore durante la richiesta all'API: {e}")
        return None

# === Interfaccia Streamlit ===
def main():
    st.set_page_config(page_title="Movie Recommender", layout="centered")
    st.title("🎬 Sistema di Raccomandazione di film!")

    movie_list = load_movies_from_gcs()

    if not movie_list:
        st.warning("❌ Nessun film trovato nel dataset... Riprova con un altro film.")
        return

    selected_movie = st.selectbox("🎞️ Seleziona un film tra quelli disponibili:", movie_list)

    if st.button('⌛ Mostra film simili:'):
        with st.spinner("Sto cercando film simili a quello selezionato..."):
            recommendations = get_recommendations(selected_movie)

            if recommendations:
                st.success(f" ✔️ Ecco i 5 film consigliati per: **{selected_movie}**")
                for idx, title in enumerate(recommendations, start=1):
                    st.markdown(f"{idx}. **{title}**") # mostra raccomandazioni 
            else:
                st.warning("Nessuna raccomandazione trovata.")

if __name__ == "__main__":
    main()
    

    
    
    