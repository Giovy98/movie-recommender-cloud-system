import streamlit as st
import requests
import pandas as pd
import os

# URL del servizio API
API_URL = os.getenv("API_URL", "http://localhost:8000/recommendations")

st.header('Movie Recommender System')

movies = pd.read_csv("data/recsys_df.csv")

movie_list = movies['title'].values
selected_movie = st.selectbox(
    "Seleziona un film tra quelli disponibili:",
    movie_list
)
if st.button('Mostra Raccomandazioni') and selected_movie:
    response = requests.post(API_URL, json={"movie_name": selected_movie})

    if response.status_code == 200:
        recommendations = response.json()["recommendations"]
        for name in recommendations:
            st.write(name)
    else:
        st.error("Film non trovato! Riprova con un altro titolo.")
