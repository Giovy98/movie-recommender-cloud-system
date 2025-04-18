# Usa un'immagine di base con Python
FROM python:3.10-slim

# Imposta la directory di lavoro nel container
WORKDIR /app

# Copia il file delle dipendenze e installale
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia tutto il codice della UI
COPY . .

# Espone la porta 8501 per Streamlit
EXPOSE 8501

# Comando di avvio per Streamlit
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
