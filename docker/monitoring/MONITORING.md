# Monitoring

## Prometheus & Grafana Stack einrichten (Development)

Ziel ist es Prometheus Server- und Grafana Kontainer außhalb des Mampf-Developments Kontainer-Stacks zu haben. Im Development können die Kontainer über Ports und das Network `mampf_development`die Daten abfragen. Wie das dann in Produktion ist, muss noch geschaut werden.

### 1. Monitoring-Verzeichnis erstellen

Erstelle **außerhalb** deines `mampf`-Projektordners ein neues Verzeichnis namens `Monitoring`. und erstelle folgende Dateinen:

### 2. Datei 1: `docker-compose.yml`

Diese Datei definiert deine Prometheus- und Grafana-Dienste.

```yaml
version: "3.8"
services:
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    ports:
      - "9090:9090"
    networks:
      - mampf_development
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
    restart: unless-stopped

  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - "2345:2345"
    networks:
      - mampf_development
    environment:
      - GF_SERVER_HTTP_PORT=2345
    restart: unless-stopped

networks:
  mampf_development:
    external: true
```
    
### 3. Datei 2: `prometheus.yml`

Diese Datei teilt Prometheus mit, was es überwachen soll.

```yaml
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# A scrape configuration containing exactly one endpoint to scrape:
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'mampf'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s
    scrape_timeout:  5s

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ['app:9394']
```
### 4. Wichtig!

Damit die Network Verbindung funktioniert muss der Monitoring Container Stack nach dem Mampf Stack gestartet werden. Dies geht mit ´cd ../Monitoring `cd ../Monitoring` und `docker compose up -d`.

Standard Grafana Login
  Username: admin
  Password: admin

Standard MaMpf Login
  Username: admin@mampf.edu
  Password: dockermampf