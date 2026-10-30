FROM python:3.12-slim
WORKDIR /app
COPY netwatch/ ./netwatch/
COPY pyproject.toml README.md ./
RUN pip install --no-cache-dir . && apt-get update && apt-get install -y --no-install-recommends iputils-ping && rm -rf /var/lib/apt/lists/*
EXPOSE 8000
CMD ["python", "-m", "netwatch", "serve", "--port", "8000"]
