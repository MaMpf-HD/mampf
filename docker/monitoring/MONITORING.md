# Monitoring

## Prometheus & Grafana Stack einrichten (Development)

Ziel ist es Prometheus Server- und Grafana Kontainer außhalb des Mampf-Developments Kontainer-Stacks zu haben. Im Development können die Kontainer über Ports und das Network `mampf_development`die Daten abfragen. Wie das dann in Produktion ist, muss noch geschaut werden.

### 1. Monitoring-Verzeichnis erstellen

Erstelle **außerhalb** deines `mampf`-Projektordners ein neues Verzeichnis namens `Monitoring`. und erstelle folgende Dateinen:

### 2. Datei 1: `docker-compose.yml`

siehe: /workspaces/mampf/docker/monitoring/docker-compose.yml
    
### 3. Datei 2: `prometheus.yml`

Diese Datei teilt Prometheus mit, was es überwachen soll.

siehe: /workspaces/mampf/docker/monitoring/prometheus.yml

### 4. Gesamter Ordner: `Grafana`

siehe: /workspaces/mampf/docker/monitoring/grafana

# Grafana Ordner

### 5. Wichtig!

Damit die Network Verbindung funktioniert muss der Monitoring Container Stack nach dem Mampf Stack gestartet werden. Dies geht mit ´cd ../Monitoring `cd ../Monitoring` und `docker compose up -d`.

Standard Grafana Login
  Username: admin
  Password: admin

Standard MaMpf Login
  Username: admin@mampf.edu
  Password: dockermampf


### TODOO

1. Cleanup legende dashbord
2. 0er worker rausfiltern
3. users ubennenen zu registered users
4. add online users
5. Mimir Datenbank
6. add other metrices:
    - http metrics
    - request duration
    - alerts
    - error rate
    - singnups...
    - ...
7. Node exporter?