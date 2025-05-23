# Base image con Python
FROM python:3.10-slim

# Variabili d'ambiente per evitare buffer e impostare UTF-8
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    LANG=C.UTF-8

# Crea una directory di lavoro
WORKDIR /app

# Copia requirements (può essere generato anche automaticamente se serve)
COPY requirements.txt .

# Installa le dipendenze
RUN pip install --no-cache-dir -r requirements.txt

# Copia tutti i file del progetto nella directory del container
COPY . .

# Comando di default
CMD ["python", "preprocessing.py"]
