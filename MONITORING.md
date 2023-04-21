# Monitoring

## Getting started (development mode): Setting up prometheus & grafana

0. Start prometheus_exporter in the mampf container
`sudo docker-compose exec mampf prometheus_exporter -b 0.0.0.0 -a lib/collectors/mampf_collector.rb `
1. Setup prometheus in development

```sh
cd docker/development
sudo docker run -d \
-p 9090:9090 \
--name prometheus -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
prom/prometheus
# Add to mampf dev network
sudo docker network connect development_default prometheus
```
2. setup Grafana:

```sh
sudo docker run -d \                                      
-p 2345:2345 \
--name grafana \
-e "GF_SERVER_HTTP_PORT=2345" \
grafana/grafana
```
3. Now visit localhost:2345 and configure the datasource (`prometheus:9090`)
4.  Setup the dashboard, interisting metrics:
  - `rate(ruby_collector_sessions_total[5m])`
  - `rate(ruby_http_requests_total[5m])`
  - `ruby_user_count`: Number of users in the DB
  - `ruby_uploaded_medium_count`: Number of Media
  - `ruby_tag_count`: Number of Tags
  - `ruby_submissions_count`: Number of Submissions
