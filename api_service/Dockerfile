# Usa un'immagine di base con Python
FROM python:3.10-slim

# Imposta la directory di lavoro nel container
WORKDIR /app

# Copia il file delle dipendenze e installale
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia tutto il codice nel container
COPY . .

# Espone la porta 8000 per il servizio FastAPI
EXPOSE 8000

# Comando di avvio per FastAPI
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
