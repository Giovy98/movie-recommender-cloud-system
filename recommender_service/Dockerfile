# Usa un'immagine Python ufficiale
FROM python:3.10-slim

# Imposta la directory di lavoro 
WORKDIR /app

RUN mkdir -p /app/similiarityMatrix

COPY requirements.txt .

# Installa le dipendenze
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python3","-u","recommender.py"]