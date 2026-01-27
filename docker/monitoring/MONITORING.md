# Monitoring

### Credentials

Standard Grafana Login
  Username: admin
  Password: admin

Standard MaMpf Login
  Username: admin@mampf.edu
  Password: dockermampf


### How to get to the dashboard

After `just up`:

1. http://localhost:2345/d/adzzdvc/mampf-general-overview

2. Manually: Go on localhost:2345, login with the credentials above, press on "Dashboards", then on the arrow to the right of "Local" and then on "MaMpf General Overview"


### How to edit a dashboard

1. Head to your dashboard (e.g. http://localhost:2345/d/adzzdvc/mampf-general-overview)

2. Click `Edit` in the top right corner

3. Drag around or Add Visualizations as you wish

4. Click `Save dashboard` in the top right corner

5. `Copy JSON to Clipboard` or `Save JSON to file`

6. Open `/workspaces/mampf/docker/monitoring/grafana/dashboards` and either paste into or replace existing JSON file (e.g. monitoring/grafana/dashboards/mampf-overview.json)

### TODO

- Mimir Database
- rename users to registered users
- node exporter instead of ps command?
- tutorial dashboard creation
- add online users
- add other metrics:
    - RAM % usage
    - http metrics
      - latency
      - bandwidth usage
    - quiz participation/completion
    - request duration
    - alerts
    - error rate
    - signups...
    - sidekiq
    - ...
-  Node exporter?