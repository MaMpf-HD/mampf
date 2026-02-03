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
  a. If you query a system metric and don't care about differentiating sessions/pids:
      - In the top right corner of your panel click on the drop-down menu
      - Select `Edit`
      - In your query row switch to `Code` view
      - Change you Query to `sum by (job, role) (your_system_metric)`
      This Groups our data by job and role, meaning all data from the master process
      (and from indexed worker processes) is aggregated
      - If your legend includes different tags, include them in the grouping

4. Click `Save dashboard` in the top right corner

5. `Copy JSON to Clipboard` or `Save JSON to file`

6. Open `/workspaces/mampf/docker/monitoring/grafana/dashboards` and either paste into or replace existing JSON file (e.g. monitoring/grafana/dashboards/mampf-overview.json)

### TODO

- Mimir Database
- rename users to registered users
- node exporter instead of ps command?
- aggregate different pids in dashboard
    - filter tags
- add online users
- add other metrics:
    - active sessions
    - Mimir storage usage?
    - alerts
    - RAM % usage
      - systemwide
      - MaMpf
    - http metrics
      - latency? from log? per controller, mediacontroller show
        through Controller action (in application_controller.rb?)
      - bandwidth usage
    - error rate
    - signups...
    - sidekiq
    - puma metrics in grafana 
    - quiz participation/completion
    - ...
- Node exporter?
- Index Worker role in mampf_collector.rb 

Priority:

~~1. Aggregate PIDs~~
~~2. RAM %~~
3. Compactor configuren
4. Alerts
5. Latency
6. Puma Metrics in Grafana