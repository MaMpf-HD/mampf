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
- add online users
- add other metrics:
    - Mimir storage usage?
    - alerts
    - bandwidth usage
    - signups...
    - sidekiq
    - puma metrics in grafana 
    - quiz participation/completion
    - ...
-

Priority:


1. Alerts
2. active sessions = online users
3. singups, Änderungsrate registerd users, deleted users